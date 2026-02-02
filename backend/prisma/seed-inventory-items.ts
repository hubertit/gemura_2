/**
 * Seed script for predefined inventory item categories and items.
 * Run after providing your list: npm run seed:inventory-items
 *
 * 1. Edit INVENTORY_ITEMS_DATA below with your categories and items.
 * 2. Run: npm run seed:inventory-items
 */

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export type InventoryItemSeed = {
  name: string;
  code?: string;
  unit?: string;
  description?: string;
  sort_order?: number;
};

export type InventoryCategorySeed = {
  name: string;
  description?: string;
  sort_order?: number;
  items: InventoryItemSeed[];
};

/** Predefined inventory items – categories and items for selection in inventory. */
const INVENTORY_ITEMS_DATA: InventoryCategorySeed[] = [
  {
    name: 'Equipment & Supplies',
    sort_order: 0,
    items: [
      { name: 'Milking Machine (Double)', sort_order: 0 },
      { name: 'Chaff Cutter (with dynamo)', sort_order: 1 },
      { name: 'Milking Cooler (1000L)', unit: 'L', sort_order: 2 },
      { name: 'Milk Cans (50L)', unit: 'L', sort_order: 3 },
      { name: 'CMT Kit', sort_order: 4 },
      { name: 'Lactometer', sort_order: 5 },
      { name: 'Surgical Tools', sort_order: 6 },
      { name: 'Cool Box (14L)', unit: 'L', sort_order: 7 },
      { name: 'Coope Onglon', sort_order: 8 },
      { name: 'AI Kit', sort_order: 9 },
      { name: 'Ear Tag Applicator', sort_order: 10 },
    ],
  },
  {
    name: 'Feeds & Supplements',
    sort_order: 1,
    items: [
      { name: 'Maize Bran', unit: 'kg', sort_order: 0 },
      { name: 'Molasses', unit: 'L', sort_order: 1 },
      { name: 'Rice Bran', unit: 'kg', sort_order: 2 },
      { name: 'Salt Block (5kg)', unit: 'kg', sort_order: 3 },
    ],
  },
  {
    name: 'Veterinary Drugs & Consumables',
    sort_order: 2,
    items: [
      { name: 'Semen (Intanga)', sort_order: 0 },
      { name: 'OXY 20%', sort_order: 1 },
      { name: 'Phenylject', sort_order: 2 },
      { name: 'Nilzan Super 1L', unit: 'L', sort_order: 3 },
      { name: 'Ivermectin', sort_order: 4 },
      { name: 'Penstrepton', sort_order: 5 },
      { name: 'Fluconix 100W', sort_order: 6 },
      { name: 'Multiject', sort_order: 7 },
      { name: 'Levinex (Boxes 24pc)', sort_order: 8 },
      { name: 'Albendex', sort_order: 9 },
      { name: 'Nortraz 500ml', unit: 'ml', sort_order: 10 },
      { name: 'Nortraz L', unit: 'L', sort_order: 11 },
      { name: 'Albendazole 2500mg (Boxes)', sort_order: 12 },
      { name: 'Sulfadimidine Bolus', sort_order: 13 },
      { name: 'Almycin Spray', sort_order: 14 },
      { name: 'Multivitamin Inject', sort_order: 15 },
      { name: 'Albendazole 2.5%', sort_order: 16 },
      { name: 'Limoxin Injectable', sort_order: 17 },
      { name: 'Vapaco Digest', sort_order: 18 },
      { name: 'Nilzan Bolus (Boxes 20pc)', sort_order: 19 },
      { name: 'Milking Salve 100gr', unit: 'gr', sort_order: 20 },
      { name: 'Milking Salve 250gr', unit: 'gr', sort_order: 21 },
      { name: 'Milking Salve 500gr', unit: 'gr', sort_order: 22 },
      { name: 'Carbesia 100ml', unit: 'ml', sort_order: 23 },
      { name: 'Butalex (Bupanor 50ml)', unit: 'ml', sort_order: 24 },
      { name: 'Bupanor 20ml', unit: 'ml', sort_order: 25 },
    ],
  },
];

async function main() {
  console.log('🌱 Seeding inventory item categories and items...\n');

  if (INVENTORY_ITEMS_DATA.length === 0) {
    console.log('⚠️  INVENTORY_ITEMS_DATA is empty.');
    console.log('   Add your list to prisma/seed-inventory-items.ts (INVENTORY_ITEMS_DATA), then run:');
    console.log('   npm run seed:inventory-items\n');
    return;
  }

  for (let catIndex = 0; catIndex < INVENTORY_ITEMS_DATA.length; catIndex++) {
    const cat = INVENTORY_ITEMS_DATA[catIndex];
    let category = await prisma.inventoryItemCategory.findFirst({
      where: { name: cat.name },
    });
    if (!category) {
      category = await prisma.inventoryItemCategory.create({
        data: {
          name: cat.name,
          description: cat.description ?? null,
          sort_order: cat.sort_order ?? catIndex,
        },
      });
    }

    for (let itemIndex = 0; itemIndex < cat.items.length; itemIndex++) {
      const item = cat.items[itemIndex];
      const existing = await prisma.inventoryItem.findFirst({
        where: { category_id: category.id, name: item.name },
      });
      if (!existing) {
        await prisma.inventoryItem.create({
          data: {
            category_id: category.id,
            name: item.name,
            code: item.code ?? null,
            unit: item.unit ?? null,
            description: item.description ?? null,
            is_active: true,
            sort_order: item.sort_order ?? itemIndex,
          },
        });
      }
    }
    console.log(`✅ Category "${cat.name}" with ${cat.items.length} items`);
  }

  console.log('\n🎉 Inventory items seed completed.\n');
}

main()
  .catch((e) => {
    console.error('❌ Error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
