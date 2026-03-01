/**
 * Seed Rwanda administrative hierarchy: country + provinces (+ a few example districts).
 * Run after prisma db push: npx ts-node prisma/seed-locations.ts
 * Or import and call from main seed.
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const rwanda = await prisma.location.upsert({
    where: { code: 'RW' },
    update: {},
    create: {
      code: 'RW',
      name: 'Rwanda',
      location_type: 'COUNTRY',
      parent_id: null,
    },
  });

  const provinces = [
    { code: '01', name: 'Kigali City' },
    { code: '02', name: 'Southern Province' },
    { code: '03', name: 'Western Province' },
    { code: '04', name: 'Northern Province' },
    { code: '05', name: 'Eastern Province' },
  ];

  for (const p of provinces) {
    await prisma.location.upsert({
      where: { code: p.code },
      update: {},
      create: {
        code: p.code,
        name: p.name,
        location_type: 'PROVINCE',
        parent_id: rwanda.id,
      },
    });
  }

  const provinceRecords = await prisma.location.findMany({
    where: { location_type: 'PROVINCE' },
  });
  const provinceByCode = new Map(provinceRecords.map((p) => [p.code, p]));

  const districts = [
    // Kigali City
    { code: '01-01', name: 'Nyarugenge', provinceCode: '01' },
    { code: '01-02', name: 'Gasabo', provinceCode: '01' },
    { code: '01-03', name: 'Kicukiro', provinceCode: '01' },
    // Southern
    { code: '02-01', name: 'Huye', provinceCode: '02' },
    { code: '02-02', name: 'Gisagara', provinceCode: '02' },
    // Western
    { code: '03-01', name: 'Rubavu', provinceCode: '03' },
    { code: '03-02', name: 'Rusizi', provinceCode: '03' },
    // Northern
    { code: '04-01', name: 'Musanze', provinceCode: '04' },
    { code: '04-02', name: 'Gicumbi', provinceCode: '04' },
    // Eastern
    { code: '05-01', name: 'Nyagatare', provinceCode: '05' },
    { code: '05-02', name: 'Rwamagana', provinceCode: '05' },
  ];

  for (const d of districts) {
    const parent = provinceByCode.get(d.provinceCode);
    if (!parent) {
      console.warn(`Skipping district ${d.name} – province code ${d.provinceCode} not found`);
      continue;
    }
    await prisma.location.upsert({
      where: { code: d.code },
      update: {},
      create: {
        code: d.code,
        name: d.name,
        location_type: 'DISTRICT',
        parent_id: parent.id,
      },
    });
  }

  console.log('Locations seeded: Rwanda + 5 provinces + sample districts');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
