import fs from 'fs';
import path from 'path';
import { PrismaClient, LocationType } from '@prisma/client';

const prisma = new PrismaClient();

interface Row {
  id: string;
  code: string;
  name: string;
  location_type: string;
  parent_id: string | null;
}

function mapType(t: string): LocationType {
  const upper = t.toUpperCase();
  switch (upper) {
    case 'COUNTRY':
      return LocationType.COUNTRY;
    case 'PROVINCE':
      return LocationType.PROVINCE;
    case 'DISTRICT':
      return LocationType.DISTRICT;
    case 'SECTOR':
      return LocationType.SECTOR;
    case 'CELL':
      return LocationType.CELL;
    case 'VILLAGE':
      return LocationType.VILLAGE;
    default:
      throw new Error(`Unsupported location_type: ${t}`);
  }
}

async function main() {
  const filePath = path.join(__dirname, 'dsacco_adm_location.tsv');
  console.log('📄 Reading CSV from', filePath);
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split(/\r?\n/).filter((l) => l.trim().length > 0);
  const [header, ...dataLines] = lines;
  console.log('Header:', header);

  const rows: Row[] = dataLines.map((line) => {
    const [id, code, name, location_type, parent_id] = line.split(',');
    if (!id || !code || !name || !location_type) {
      return null as any;
    }
    return {
      id: id.trim(),
      code: code.trim(),
      name: name.trim(),
      location_type: location_type.trim(),
      parent_id: parent_id && parent_id.trim().length > 0 && parent_id !== 'null' ? parent_id.trim() : null,
    };
  }).filter((row): row is Row => !!row && !!row.code && !!row.name);

  console.log(`Parsed ${rows.length} rows.`);

  const idToCode = new Map<string, string>();
  for (const r of rows) {
    idToCode.set(r.id, r.code);
  }

  console.log('⬆️ Upserting basic location rows (code, name, type)...');
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
        parent_id: null,
      },
    });
  }

  console.log('🔗 Updating parent relationships...');
  const allLocations = await prisma.location.findMany({ select: { id: true, code: true } });
  const codeToId = new Map(allLocations.map((l) => [l.code, l.id] as const));

  for (const row of rows) {
    if (!row.parent_id) continue;
    const parentCode = idToCode.get(row.parent_id);
    if (!parentCode) continue;
    const locId = codeToId.get(row.code);
    const parentId = codeToId.get(parentCode);
    if (!locId || !parentId) continue;

    await prisma.location.update({
      where: { id: locId },
      data: { parent_id: parentId },
    });
  }

  console.log('✅ Import from TSV complete.');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
