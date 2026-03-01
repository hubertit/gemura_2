/**
 * Clean all locations and seed from full Rwanda hierarchy (dsacco_adm_location.tsv).
 * - Removes duplicates and failed data by wiping locations, then
 * - Imports only Rwanda subtree from TSV with canonical province names.
 *
 * Run from backend: npx ts-node prisma/clean-and-seed-locations.ts
 */
import fs from 'fs';
import path from 'path';
import { PrismaClient, LocationType } from '@prisma/client';

const prisma = new PrismaClient();

const PROVINCE_NAMES: Record<string, string> = {
  '1': 'Kigali City',
  '2': 'Southern Province',
  '3': 'Western Province',
  '4': 'Northern Province',
  '5': 'Eastern Province',
};

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

/** Build set of location ids that belong to Rwanda (RW + provinces 1-5 + all descendants). */
function buildRwandaSubtree(rows: Row[]): Set<string> {
  const byId = new Map(rows.map((r) => [r.id, r]));
  const rootCodes = new Set(['RW', '1', '2', '3', '4', '5']);
  const rootIds = new Set(rows.filter((r) => rootCodes.has(r.code)).map((r) => r.id));
  const out = new Set<string>(rootIds);
  let changed = true;
  while (changed) {
    changed = false;
    for (const row of rows) {
      if (out.has(row.id)) continue;
      if (row.parent_id && out.has(row.parent_id)) {
        out.add(row.id);
        changed = true;
      }
    }
  }
  return out;
}

/** Order rows so parents come before children (by depth). */
function sortByDepth(rows: Row[], idToDepth: Map<string, number>): Row[] {
  return [...rows].sort((a, b) => (idToDepth.get(a.id) ?? 0) - (idToDepth.get(b.id) ?? 0));
}

function computeDepth(rows: Row[]): Map<string, number> {
  const byId = new Map(rows.map((r) => [r.id, r]));
  const depth = new Map<string, number>();
  function getDepth(id: string): number {
    if (depth.has(id)) return depth.get(id)!;
    const row = byId.get(id);
    if (!row || !row.parent_id) {
      depth.set(id, 0);
      return 0;
    }
    const d = 1 + getDepth(row.parent_id);
    depth.set(id, d);
    return d;
  }
  for (const r of rows) getDepth(r.id);
  return depth;
}

async function main() {
  console.log('🧹 Cleaning locations...');
  await prisma.$transaction(async (tx) => {
    await tx.farm.updateMany({ data: { location_id: null } });
    await tx.location.updateMany({ data: { parent_id: null } });
    const deleted = await tx.location.deleteMany({});
    console.log(`   Removed ${deleted.count} location(s).`);
  });

  const filePath = path.join(__dirname, 'dsacco_adm_location.tsv');
  if (!fs.existsSync(filePath)) {
    console.error('❌ File not found:', filePath);
    console.log('   Falling back to minimal seed (Rwanda + 5 provinces + sample districts).');
    await runMinimalSeed();
    return;
  }

  console.log('📄 Reading', filePath);
  const content = fs.readFileSync(filePath, 'utf8');
  const lines = content.split(/\r?\n/).filter((l) => l.trim().length > 0);
  const [header, ...dataLines] = lines;
  if (!header?.startsWith('id,')) {
    console.error('❌ Unexpected TSV header:', header);
    process.exit(1);
  }

  const allRows: Row[] = dataLines
    .map((line) => {
      const parts = line.split(',');
      const [id, code, name, location_type, parent_id] = parts;
      if (!id?.trim() || !code?.trim() || !name?.trim() || !location_type?.trim())
        return null as unknown as Row;
      return {
        id: id.trim(),
        code: code.trim(),
        name: name.trim(),
        location_type: location_type.trim(),
        parent_id:
          parent_id && parent_id.trim().length > 0 && parent_id.trim().toLowerCase() !== 'null'
            ? parent_id.trim()
            : null,
      };
    })
    .filter((r): r is Row => !!r && !!r.code && !!r.name);

  const rwandaIds = buildRwandaSubtree(allRows);
  const rows = allRows.filter((r) => rwandaIds.has(r.id));
  console.log(`   Rwanda subtree: ${rows.length} locations (of ${allRows.length} total).`);

  const idToCode = new Map(rows.map((r) => [r.id, r.code]));
  const depth = computeDepth(rows);
  const sorted = sortByDepth(rows, depth);

  console.log('⬆️  Inserting locations (pass 1)...');
  for (const row of sorted) {
    const name =
      row.location_type === 'PROVINCE' && PROVINCE_NAMES[row.code]
        ? PROVINCE_NAMES[row.code]
        : row.name;
    await prisma.location.create({
      data: {
        code: row.code,
        name,
        location_type: mapType(row.location_type),
        parent_id: null,
      },
    });
  }

  const codeToId = new Map(
    (await prisma.location.findMany({ select: { id: true, code: true } })).map((l) => [l.code, l.id])
  );
  const rwandaId = codeToId.get('RW') ?? null;

  console.log('🔗 Setting parent relationships...');
  for (const row of sorted) {
    let parentId: string | null = null;
    if (row.parent_id) {
      const parentCode = idToCode.get(row.parent_id);
      if (parentCode) parentId = codeToId.get(parentCode) ?? null;
    }
    // Link provinces to Rwanda if they have no parent in file
    if (!parentId && row.location_type === 'PROVINCE' && rwandaId)
      parentId = rwandaId;
    if (!parentId) continue;
    const locId = codeToId.get(row.code);
    if (!locId) continue;
    await prisma.location.update({
      where: { id: locId },
      data: { parent_id: parentId },
    });
  }

  const total = await prisma.location.count();
  const byType = await prisma.location.groupBy({
    by: ['location_type'],
    _count: true,
  });
  console.log('✅ Done. Total locations:', total);
  byType.forEach((g) => console.log(`   ${g.location_type}: ${g._count}`));
}

async function runMinimalSeed() {
  const rwanda = await prisma.location.create({
    data: {
      code: 'RW',
      name: 'Rwanda',
      location_type: LocationType.COUNTRY,
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
    await prisma.location.create({
      data: {
        code: p.code,
        name: p.name,
        location_type: LocationType.PROVINCE,
        parent_id: rwanda.id,
      },
    });
  }
  const provinceRecords = await prisma.location.findMany({
    where: { location_type: LocationType.PROVINCE },
    orderBy: { code: 'asc' },
  });
  const provinceByCode = new Map(provinceRecords.map((p) => [p.code, p.id]));
  const districts = [
    { code: '01-01', name: 'Nyarugenge', provinceCode: '01' },
    { code: '01-02', name: 'Gasabo', provinceCode: '01' },
    { code: '01-03', name: 'Kicukiro', provinceCode: '01' },
    { code: '02-01', name: 'Huye', provinceCode: '02' },
    { code: '02-02', name: 'Gisagara', provinceCode: '02' },
    { code: '03-01', name: 'Rubavu', provinceCode: '03' },
    { code: '03-02', name: 'Rusizi', provinceCode: '03' },
    { code: '04-01', name: 'Musanze', provinceCode: '04' },
    { code: '04-02', name: 'Gicumbi', provinceCode: '04' },
    { code: '05-01', name: 'Nyagatare', provinceCode: '05' },
    { code: '05-02', name: 'Rwamagana', provinceCode: '05' },
  ];
  for (const d of districts) {
    const parentId = provinceByCode.get(d.provinceCode);
    if (!parentId) continue;
    await prisma.location.create({
      data: {
        code: d.code,
        name: d.name,
        location_type: LocationType.DISTRICT,
        parent_id: parentId,
      },
    });
  }
  const total = await prisma.location.count();
  console.log('✅ Minimal seed done. Total locations:', total);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
