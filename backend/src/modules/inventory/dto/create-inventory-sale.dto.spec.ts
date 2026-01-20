import { validate } from 'class-validator';
import { plainToInstance } from 'class-transformer';
import { CreateInventorySaleDto, InventorySaleBuyerType } from './create-inventory-sale.dto';

describe('CreateInventorySaleDto', () => {
  describe('Validation', () => {
    it('should pass validation with valid supplier data', async () => {
      const dto = plainToInstance(CreateInventorySaleDto, {
        buyer_type: InventorySaleBuyerType.SUPPLIER,
        buyer_account_id: '123e4567-e89b-12d3-a456-426614174000',
        quantity: 5,
        unit_price: 1000,
        amount_paid: 3000,
        sale_date: '2025-01-20T10:00:00Z',
      });

      const errors = await validate(dto);
      expect(errors.length).toBe(0);
    });

    it('should fail when buyer_type is supplier but buyer_account_id is missing', async () => {
      const dto = plainToInstance(CreateInventorySaleDto, {
        buyer_type: InventorySaleBuyerType.SUPPLIER,
        quantity: 5,
        unit_price: 1000,
        amount_paid: 5000,
      });

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      expect(errors.some(e => e.property === 'buyer_account_id')).toBe(true);
    });

    it('should pass validation with customer type (buyer_account_id optional)', async () => {
      const dto = plainToInstance(CreateInventorySaleDto, {
        buyer_type: InventorySaleBuyerType.CUSTOMER,
        quantity: 3,
        unit_price: 500,
        amount_paid: 1500, // Must equal total for customer
      });

      const errors = await validate(dto);
      expect(errors.length).toBe(0);
    });

    it('should pass validation with other type (no buyer_account_id)', async () => {
      const dto = plainToInstance(CreateInventorySaleDto, {
        buyer_type: InventorySaleBuyerType.OTHER,
        buyer_name: 'John Doe',
        buyer_phone: '250788606765',
        quantity: 2,
        unit_price: 1000,
        amount_paid: 2000, // Must equal total for other
      });

      const errors = await validate(dto);
      expect(errors.length).toBe(0);
    });

    it('should fail when quantity is 0 or negative', async () => {
      const dto = plainToInstance(CreateInventorySaleDto, {
        buyer_type: InventorySaleBuyerType.SUPPLIER,
        buyer_account_id: '123e4567-e89b-12d3-a456-426614174000',
        quantity: 0,
        unit_price: 1000,
        amount_paid: 0,
      });

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      expect(errors.some(e => e.property === 'quantity')).toBe(true);
    });

    it('should fail when unit_price is negative', async () => {
      const dto = plainToInstance(CreateInventorySaleDto, {
        buyer_type: InventorySaleBuyerType.SUPPLIER,
        buyer_account_id: '123e4567-e89b-12d3-a456-426614174000',
        quantity: 5,
        unit_price: -100,
        amount_paid: 0,
      });

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      expect(errors.some(e => e.property === 'unit_price')).toBe(true);
    });

    it('should fail when amount_paid is negative', async () => {
      const dto = plainToInstance(CreateInventorySaleDto, {
        buyer_type: InventorySaleBuyerType.SUPPLIER,
        buyer_account_id: '123e4567-e89b-12d3-a456-426614174000',
        quantity: 5,
        unit_price: 1000,
        amount_paid: -100,
      });

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      expect(errors.some(e => e.property === 'amount_paid')).toBe(true);
    });

    it('should fail when sale_date is invalid format', async () => {
      const dto = plainToInstance(CreateInventorySaleDto, {
        buyer_type: InventorySaleBuyerType.SUPPLIER,
        buyer_account_id: '123e4567-e89b-12d3-a456-426614174000',
        quantity: 5,
        unit_price: 1000,
        amount_paid: 3000,
        sale_date: 'invalid-date',
      });

      const errors = await validate(dto);
      expect(errors.length).toBeGreaterThan(0);
      expect(errors.some(e => e.property === 'sale_date')).toBe(true);
    });
  });
});
