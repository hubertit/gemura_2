import { Injectable, BadRequestException, NotFoundException, InternalServerErrorException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { User } from '@prisma/client';
import { CreateInventoryDto } from './dto/create-inventory.dto';
import { UpdateInventoryDto } from './dto/update-inventory.dto';
import { UpdateStockDto } from './dto/update-stock.dto';
import { ToggleListingDto } from './dto/toggle-listing.dto';
import { CreateInventorySaleDto, InventorySaleBuyerType, InventorySalePaymentStatus } from './dto/create-inventory-sale.dto';
import { TransactionsService } from '../accounting/transactions/transactions.service';
import { TransactionType } from '../accounting/transactions/dto/create-transaction.dto';
import * as bcrypt from 'bcrypt';
import { randomBytes } from 'crypto';

@Injectable()
export class InventoryService {
  constructor(
    private prisma: PrismaService,
    private transactionsService: TransactionsService,
  ) {}

  async getInventory(user: User, filters?: { status?: string; low_stock?: boolean }) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const where: any = {
      account_id: user.default_account_id,
    };

    // By default, exclude inactive items (soft-deleted items)
    // Only include inactive items if explicitly requested via status filter
    if (filters?.status) {
      where.status = filters.status;
    } else {
      // Exclude inactive items by default
      where.status = { not: 'inactive' };
    }

    // Note: Low stock filtering will be done in application logic
    // Prisma doesn't easily support comparing two columns in where clause

    const products = await this.prisma.product.findMany({
      where,
      include: {
        categories: { include: { category: true } },
        images: { where: { is_primary: true }, take: 1 },
      },
      orderBy: { created_at: 'desc' },
    });

    let filteredProducts = products;

    // Filter low stock items if requested
    if (filters?.low_stock) {
      filteredProducts = products.filter((p) => {
        if (p.min_stock_level !== null) {
          return p.stock_quantity <= p.min_stock_level;
        }
        return p.stock_quantity <= 0;
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Inventory fetched successfully.',
      data: filteredProducts.map((p) => ({
        id: p.id,
        name: p.name,
        description: p.description,
        price: Number(p.price),
        stock_quantity: p.stock_quantity,
        min_stock_level: p.min_stock_level,
        status: p.status,
        is_listed_in_marketplace: p.is_listed_in_marketplace,
        categories: p.categories.map((c) => c.category),
        image: p.images[0]?.image_url || null,
        created_at: p.created_at,
        updated_at: p.updated_at,
      })),
    };
  }

  async getInventoryItem(user: User, productId: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const product = await this.prisma.product.findFirst({
      where: {
        id: productId,
        account_id: user.default_account_id,
      },
      include: {
        categories: { include: { category: true } },
        images: { orderBy: { sort_order: 'asc' } },
      },
    });

    if (!product) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Inventory item not found.',
      });
    }

    return {
      code: 200,
      status: 'success',
      message: 'Inventory item fetched successfully.',
      data: {
        id: product.id,
        name: product.name,
        description: product.description,
        price: Number(product.price),
        stock_quantity: product.stock_quantity,
        min_stock_level: product.min_stock_level,
        status: product.status,
        is_listed_in_marketplace: product.is_listed_in_marketplace,
        categories: product.categories.map((c) => c.category),
        images: product.images.map((img) => ({
          id: img.id,
          image_url: img.image_url,
          is_primary: img.is_primary,
        })),
        created_at: product.created_at,
        updated_at: product.updated_at,
      },
    };
  }

  async createInventoryItem(user: User, createDto: CreateInventoryDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Determine status based on stock
    let status: 'active' | 'inactive' | 'out_of_stock' = 'active';
    if ((createDto.stock_quantity || 0) === 0) {
      status = 'out_of_stock';
    }

    const product = await this.prisma.product.create({
      data: {
        name: createDto.name,
        description: createDto.description,
        price: createDto.price,
        stock_quantity: createDto.stock_quantity || 0,
        min_stock_level: createDto.min_stock_level || null,
        status: status as any,
        account_id: user.default_account_id,
        is_listed_in_marketplace: createDto.is_listed_in_marketplace || false,
        created_by: user.id,
        updated_by: user.id,
      },
    });

    // Add categories if provided
    if (createDto.category_ids && createDto.category_ids.length > 0) {
      await Promise.all(
        createDto.category_ids.map((catId) =>
          this.prisma.productCategory.create({
            data: {
              product_id: product.id,
              category_id: catId,
            },
          }),
        ),
      );
    }

    return {
      code: 200,
      status: 'success',
      message: 'Inventory item created successfully.',
      data: {
        id: product.id,
        name: product.name,
        description: product.description,
        price: Number(product.price),
        stock_quantity: product.stock_quantity,
        min_stock_level: product.min_stock_level,
        status: product.status,
        is_listed_in_marketplace: product.is_listed_in_marketplace,
      },
    };
  }

  async updateInventoryItem(user: User, productId: string, updateDto: UpdateInventoryDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Verify ownership
    const existing = await this.prisma.product.findFirst({
      where: {
        id: productId,
        account_id: user.default_account_id,
      },
    });

    if (!existing) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Inventory item not found.',
      });
    }

    // Determine status if stock_quantity is being updated
    let status = updateDto.status || existing.status;
    if (updateDto.stock_quantity !== undefined) {
      if (updateDto.stock_quantity === 0) {
        status = 'out_of_stock';
      } else if (status === 'out_of_stock' && updateDto.stock_quantity > 0) {
        status = 'active';
      }
    }

    // Can't list if out of stock
    if (updateDto.is_listed_in_marketplace && 
        (updateDto.stock_quantity !== undefined ? updateDto.stock_quantity === 0 : existing.stock_quantity === 0)) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Cannot list item in marketplace when stock is 0.',
      });
    }

    const product = await this.prisma.product.update({
      where: { id: productId },
      data: {
        ...(updateDto.name && { name: updateDto.name }),
        ...(updateDto.description !== undefined && { description: updateDto.description }),
        ...(updateDto.price !== undefined && { price: updateDto.price }),
        ...(updateDto.stock_quantity !== undefined && { stock_quantity: updateDto.stock_quantity }),
        ...(updateDto.min_stock_level !== undefined && { min_stock_level: updateDto.min_stock_level }),
        ...(updateDto.is_listed_in_marketplace !== undefined && { is_listed_in_marketplace: updateDto.is_listed_in_marketplace }),
        ...(status && { status: status as any }),
        updated_by: user.id,
      },
    });

    // Update categories if provided
    if (updateDto.category_ids !== undefined) {
      // Delete existing categories
      await this.prisma.productCategory.deleteMany({
        where: { product_id: productId },
      });

      // Add new categories
      if (updateDto.category_ids.length > 0) {
        await Promise.all(
          updateDto.category_ids.map((catId) =>
            this.prisma.productCategory.create({
              data: {
                product_id: productId,
                category_id: catId,
              },
            }),
          ),
        );
      }
    }

    return {
      code: 200,
      status: 'success',
      message: 'Inventory item updated successfully.',
      data: {
        id: product.id,
        name: product.name,
        description: product.description,
        price: Number(product.price),
        stock_quantity: product.stock_quantity,
        min_stock_level: product.min_stock_level,
        status: product.status,
        is_listed_in_marketplace: product.is_listed_in_marketplace,
      },
    };
  }

  async updateStock(user: User, productId: string, updateStockDto: UpdateStockDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Verify ownership
    const existing = await this.prisma.product.findFirst({
      where: {
        id: productId,
        account_id: user.default_account_id,
      },
    });

    if (!existing) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Inventory item not found.',
      });
    }

    // Determine status based on new stock
    let status = existing.status;
    if (updateStockDto.stock_quantity === 0) {
      status = 'out_of_stock';
    } else if (existing.status === 'out_of_stock' && updateStockDto.stock_quantity > 0) {
      status = 'active';
    }

    const product = await this.prisma.product.update({
      where: { id: productId },
      data: {
        stock_quantity: updateStockDto.stock_quantity,
        status: status as any,
        updated_by: user.id,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Stock updated successfully.',
      data: {
        id: product.id,
        stock_quantity: product.stock_quantity,
        status: product.status,
      },
    };
  }

  async toggleMarketplaceListing(user: User, productId: string, toggleDto: ToggleListingDto) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Verify ownership
    const existing = await this.prisma.product.findFirst({
      where: {
        id: productId,
        account_id: user.default_account_id,
      },
    });

    if (!existing) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Inventory item not found.',
      });
    }

    // Can't list if out of stock
    if (toggleDto.is_listed_in_marketplace && existing.stock_quantity === 0) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Cannot list item in marketplace when stock is 0.',
      });
    }

    const product = await this.prisma.product.update({
      where: { id: productId },
      data: {
        is_listed_in_marketplace: toggleDto.is_listed_in_marketplace,
        updated_by: user.id,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: toggleDto.is_listed_in_marketplace
        ? 'Item listed in marketplace successfully.'
        : 'Item removed from marketplace successfully.',
      data: {
        id: product.id,
        is_listed_in_marketplace: product.is_listed_in_marketplace,
      },
    };
  }

  async deleteInventoryItem(user: User, productId: string) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // Verify ownership
    const existing = await this.prisma.product.findFirst({
      where: {
        id: productId,
        account_id: user.default_account_id,
      },
    });

    if (!existing) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Inventory item not found.',
      });
    }

    // Soft delete by setting status to inactive
    await this.prisma.product.update({
      where: { id: productId },
      data: {
        status: 'inactive',
        is_listed_in_marketplace: false,
        updated_by: user.id,
      },
    });

    return {
      code: 200,
      status: 'success',
      message: 'Inventory item deleted successfully.',
    };
  }

  async getInventoryStats(user: User) {
    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    const [totalItems, activeItems, outOfStockItems, listedItems, lowStockItems] = await Promise.all([
      this.prisma.product.count({
        where: { account_id: user.default_account_id, status: { not: 'inactive' } },
      }),
      this.prisma.product.count({
        where: { account_id: user.default_account_id, status: 'active' },
      }),
      this.prisma.product.count({
        where: { account_id: user.default_account_id, status: 'out_of_stock' },
      }),
      this.prisma.product.count({
        where: { 
          account_id: user.default_account_id, 
          is_listed_in_marketplace: true,
          status: { not: 'inactive' }, // Exclude deleted/inactive items
        },
      }),
      // Count low stock items (fetch and filter in memory, excluding inactive items)
      (async () => {
        const allProducts = await this.prisma.product.findMany({
          where: { 
            account_id: user.default_account_id,
            status: { not: 'inactive' }, // Exclude deleted/inactive items
          },
          select: { stock_quantity: true, min_stock_level: true },
        });
        return allProducts.filter((p) => {
          if (p.min_stock_level !== null) {
            return p.stock_quantity <= p.min_stock_level;
          }
          return p.stock_quantity <= 0;
        }).length;
      })(),
    ]);

    return {
      code: 200,
      status: 'success',
      message: 'Inventory statistics fetched successfully.',
      data: {
        total_items: totalItems,
        active_items: activeItems,
        out_of_stock_items: outOfStockItems,
        listed_in_marketplace: listedItems,
        low_stock_items: lowStockItems,
      },
    };
  }

  async sellInventoryItem(user: User, productId: string, createSaleDto: CreateInventorySaleDto) {
    console.log('📦 [Inventory Sale] Starting sale process');
    console.log('📦 [Inventory Sale] Product ID:', productId);
    console.log('📦 [Inventory Sale] Buyer type:', createSaleDto.buyer_type);
    console.log('📦 [Inventory Sale] Buyer account ID/code:', createSaleDto.buyer_account_id);
    console.log('📦 [Inventory Sale] Buyer name:', createSaleDto.buyer_name);
    console.log('📦 [Inventory Sale] Buyer phone:', createSaleDto.buyer_phone);
    console.log('📦 [Inventory Sale] Quantity:', createSaleDto.quantity);
    console.log('📦 [Inventory Sale] Unit price:', createSaleDto.unit_price);
    console.log('📦 [Inventory Sale] Amount paid:', createSaleDto.amount_paid);

    if (!user.default_account_id) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'No valid default account found.',
      });
    }

    // 1. Validate product exists and belongs to user
    const product = await this.prisma.product.findFirst({
      where: {
        id: productId,
        account_id: user.default_account_id,
      },
    });

    if (!product) {
      throw new NotFoundException({
        code: 404,
        status: 'error',
        message: 'Inventory item not found.',
      });
    }

    // 2. Validate product is listed in marketplace
    if (!product.is_listed_in_marketplace) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'Item must be listed in marketplace to sell.',
      });
    }

    // 3. Validate stock availability
    if (product.stock_quantity < createSaleDto.quantity) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: `Insufficient stock. Available: ${product.stock_quantity}, Requested: ${createSaleDto.quantity}`,
      });
    }

    // 4. Handle new customer/supplier creation on-the-fly if phone provided
    let finalBuyerAccountId = createSaleDto.buyer_account_id;
    let buyerAccount = null;

    // If buyer_account_id is not provided but phone is provided, try to create/find account
    if (!finalBuyerAccountId && createSaleDto.buyer_phone) {
      const normalizedPhone = createSaleDto.buyer_phone.replace(/\D/g, '');

      // Find existing user by phone
      const existingUser = await this.prisma.user.findUnique({
        where: { phone: normalizedPhone },
        include: {
          user_accounts: {
            where: { status: 'active' },
            include: { account: true },
            take: 1,
          },
        },
      });

      if (existingUser && existingUser.user_accounts.length > 0) {
        // User exists with account - use it
        finalBuyerAccountId = existingUser.user_accounts[0].account_id;
        buyerAccount = existingUser.user_accounts[0].account;
      } else if (createSaleDto.buyer_name) {
        // Create new customer account (for 'other' buyers, we create as customer)
        // For 'supplier' or 'customer' types, we also create if phone/name provided
        const accountCode = `A_${randomBytes(3).toString('hex').toUpperCase()}`;
        const walletCode = `W_${randomBytes(3).toString('hex').toUpperCase()}`;
        const token = randomBytes(32).toString('hex');
        const passwordHash = await bcrypt.hash('default123', 10);

        let newUser;
        if (existingUser) {
          // User exists but no account - create account for existing user
          newUser = existingUser;
        } else {
          // Create new user
          const userCode = `U_${randomBytes(3).toString('hex').toUpperCase()}`;
          newUser = await this.prisma.user.create({
            data: {
              code: userCode,
              name: createSaleDto.buyer_name,
              phone: normalizedPhone,
              password_hash: passwordHash,
              token,
              status: 'active',
              account_type: createSaleDto.buyer_type === InventorySaleBuyerType.SUPPLIER ? 'supplier' : 'customer',
              created_by: user.id,
            },
          });
        }

        // Create account
        const newAccount = await this.prisma.account.create({
          data: {
            code: accountCode,
            name: createSaleDto.buyer_name,
            type: 'tenant',
            status: 'active',
            created_by: user.id,
          },
        });

        // Link user to account
        await this.prisma.userAccount.create({
          data: {
            user_id: newUser.id,
            account_id: newAccount.id,
            role: createSaleDto.buyer_type === InventorySaleBuyerType.SUPPLIER ? 'supplier' : 'customer',
            status: 'active',
            created_by: user.id,
          },
        });

        // Set default account if user doesn't have one
        if (!newUser.default_account_id) {
          await this.prisma.user.update({
            where: { id: newUser.id },
            data: { default_account_id: newAccount.id },
          });
        }

        // Create wallet
        await this.prisma.wallet.create({
          data: {
            code: walletCode,
            account_id: newAccount.id,
            type: 'regular',
            is_default: true,
            balance: 0,
            currency: 'RWF',
            status: 'active',
            created_by: user.id,
          },
        });

        finalBuyerAccountId = newAccount.id;
        buyerAccount = newAccount;
      }
    }

    // 5. Validate buyer_account_id is required for suppliers
    if (createSaleDto.buyer_type === InventorySaleBuyerType.SUPPLIER && !finalBuyerAccountId) {
      throw new BadRequestException({
        code: 400,
        status: 'error',
        message: 'buyer_account_id is required when buyer_type is supplier. Provide buyer_account_id or buyer_phone with buyer_name.',
      });
    }

    // 6. Validate buyer account exists if we have an ID
    // Handle both UUID and account code
    if (finalBuyerAccountId && !buyerAccount) {
      console.log('📦 [Inventory Sale] Looking up buyer account:', finalBuyerAccountId);
      
      // Try to find by ID first (UUID), then by code
      buyerAccount = await this.prisma.account.findFirst({
        where: {
          OR: [
            { id: finalBuyerAccountId },
            { code: finalBuyerAccountId },
          ],
        },
      });

      if (!buyerAccount) {
        console.log('📦 [Inventory Sale] ❌ Buyer account not found:', finalBuyerAccountId);
        throw new NotFoundException({
          code: 404,
          status: 'error',
          message: 'Buyer account not found.',
        });
      }
      
      console.log('📦 [Inventory Sale] ✅ Found buyer account:', buyerAccount.code, buyerAccount.id);
      // Update finalBuyerAccountId to use the UUID
      finalBuyerAccountId = buyerAccount.id;
    }

    // 7. Calculate total amount and payment status
    const totalAmount = createSaleDto.quantity * createSaleDto.unit_price;
    const amountPaid = createSaleDto.amount_paid || 0;
    let paymentStatus: InventorySalePaymentStatus;

    if (amountPaid >= totalAmount) {
      paymentStatus = InventorySalePaymentStatus.PAID;
    } else if (amountPaid > 0) {
      paymentStatus = InventorySalePaymentStatus.PARTIAL;
    } else {
      paymentStatus = InventorySalePaymentStatus.UNPAID;
    }

    // 8. Validate payment rules
    // Only suppliers can take debt (unpaid/partial payment)
    // Customers and others must pay full amount upfront
    if (createSaleDto.buyer_type !== InventorySaleBuyerType.SUPPLIER) {
      if (amountPaid < totalAmount) {
        throw new BadRequestException({
          code: 400,
          status: 'error',
          message: 'Customers and other buyers must pay the full amount upfront. Only suppliers can buy on credit.',
        });
      }
    }

    // 9. Parse sale date
    const saleDate = createSaleDto.sale_date 
      ? new Date(createSaleDto.sale_date) 
      : new Date();

    try {
      console.log('📦 [Inventory Sale] Creating inventory sale record...');
      console.log('📦 [Inventory Sale] Final buyer account ID:', finalBuyerAccountId);
      
      // 10. Create inventory sale record
      const inventorySale = await this.prisma.inventorySale.create({
        data: {
          product_id: productId,
          buyer_type: createSaleDto.buyer_type as any,
          buyer_account_id: finalBuyerAccountId || null,
          buyer_name: createSaleDto.buyer_name || null,
          buyer_phone: createSaleDto.buyer_phone || null,
          quantity: createSaleDto.quantity,
          unit_price: createSaleDto.unit_price,
          total_amount: totalAmount,
          amount_paid: amountPaid,
          payment_status: paymentStatus as any,
          sale_date: saleDate,
          notes: createSaleDto.notes || null,
          created_by: user.id,
        },
        include: {
          product: true,
          buyer_account: true,
        },
      });

      // 11. Reduce product stock
      const newStockQuantity = product.stock_quantity - createSaleDto.quantity;
      let newStatus = product.status;
      
      if (newStockQuantity === 0) {
        newStatus = 'out_of_stock';
        // Also unlist from marketplace if stock reaches 0
        await this.prisma.product.update({
          where: { id: productId },
          data: {
            stock_quantity: newStockQuantity,
            status: newStatus as any,
            is_listed_in_marketplace: false,
            updated_by: user.id,
          },
        });
      } else {
        await this.prisma.product.update({
          where: { id: productId },
          data: {
            stock_quantity: newStockQuantity,
            status: newStatus as any,
            updated_by: user.id,
          },
        });
      }

      // 12. Create finance transaction if amount_paid > 0
      if (amountPaid > 0) {
        try {
          const buyerName = buyerAccount?.name || createSaleDto.buyer_name || 'Unknown Buyer';
          await this.transactionsService.createTransaction(user, {
            type: TransactionType.REVENUE,
            amount: amountPaid,
            description: `Sale of ${product.name} - ${createSaleDto.quantity} units to ${buyerName}`,
            transaction_date: saleDate.toISOString().split('T')[0],
          });
        } catch (error) {
          // Log error but don't fail the sale creation
          console.error('Failed to create finance transaction for inventory sale:', error);
        }
      }

      return {
        code: 200,
        status: 'success',
        message: 'Inventory item sold successfully.',
        data: {
          id: inventorySale.id,
          product_id: inventorySale.product_id,
          product_name: inventorySale.product.name,
          buyer_type: inventorySale.buyer_type,
          buyer_account_id: inventorySale.buyer_account_id,
          buyer_name: inventorySale.buyer_name,
          buyer_phone: inventorySale.buyer_phone,
          quantity: Number(inventorySale.quantity),
          unit_price: Number(inventorySale.unit_price),
          total_amount: Number(inventorySale.total_amount),
          amount_paid: Number(inventorySale.amount_paid),
          payment_status: inventorySale.payment_status,
          sale_date: inventorySale.sale_date,
          notes: inventorySale.notes,
          remaining_stock: newStockQuantity,
        },
      };
    } catch (error) {
      console.error('📦 [Inventory Sale] ❌ Error creating inventory sale:', error);
      console.error('📦 [Inventory Sale] Error stack:', error.stack);
      throw new InternalServerErrorException({
        code: 500,
        status: 'error',
        message: 'Failed to create inventory sale.',
        error: error.message,
      });
    }
  }
}
