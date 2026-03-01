import { Client as PgClient } from 'pg';
import { PrismaClient, LocationType } from '@prisma/client';

/**
 * Import full Rwanda administrative hierarchy from dsacco_uat.m01_adm.adm_location
 * into Gemura's locations table.
 *
 * Source DB (read-only):
 *   host: 10.20.1.250  port: 5432  db: dsacco_uat
 *   user: sacco_app    password: Nimba@@321
 *
 * Target DB (Prisma): DATABASE_URL in backend/.env (gemura_db).
 */

const prisma = new PrismaClient();

async function main() {
  console.log('🔄 Importing locations from dsacco_uat.m01_adm.adm_location...');

  const pg = new PgClient({
    host: '10.20.1.250',
    port: 5432,
    database: 'dsacco_uat',
    user: 'sacco_app',
    password: 'Nimba@@321',
  });

  await pg.connect();

  type Row = {
    id: string;
    code: string;
    name: string;
    location_type: string;
    parent_id: string | null;
  };

  const { rows } = await pg.query<Row>(
    `SELECT id::text, code, name, location_type, parent_id::text
     FROM m01_adm.adm_location
     ORDER BY location_type, code`
  );

  console.log(`Found ${rows.length} locations in dsacco.`);

  // Map dsacco location_type strings to Prisma enum
  const mapType = (t: string): LocationType => {
    const upper = t.toUpperCase();
    if (upper === 'COUNTRY') return LocationType.COUNTRY;
    if (upper === 'PROVINCE') return LocationType.PROVINCE;
    if (upper === 'DISTRICT') return LocationType.DISTRICT;
    if (upper === 'SECTOR') return LocationType.SECTOR;
    if (upper === 'CELL') return LocationType.CELL;
    if (upper === 'VILLAGE') return LocationType.VILLAGE;
    throw new Error(`Unsupported location_type: ${t}`);
  };

  // First, upsert all rows without parent relations to guarantee ids exist
  console.log('⬆️  Upserting locations (basic fields)...');
  for (const row of rows) {
    await prisma.location.upsert({
      where: { code: row.code },
      update: {
        name: row.name,
        location_type: mapType(row.location_type),
      },
      create: {
        code: row.code,
        name: row.name,
        location_type: mapType(row.location_type),
        parent_id: null, // set in second pass
      },
    });
  }

  console.log('🔗 Updating parent relationships...');
  for (const row of rows) {
    if (!row.parent_id) continue;
    // In Gemura DB we key by code, so we need the parent code from dsacco id
    const parentRow = rows.find((r) => r.id === row.parent_id);
    if (!parentRow) continue;

    await prisma.location.updateMany({
      where: { code: row.code },
      data: {
        parent_id: (
          await prisma.location.findUnique({ where: { code: parentRow.code }, select: { id: true } })
        )?.id ?? null,
      },
    });
  }

  console.log('✅ Locations import completed.');
  await pg.end();
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
