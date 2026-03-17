import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const immisApiKey = 'D2PWxiNLmN7RIsax6M7fH99yVcXsZldG';

  const existing = await prisma.apiKey.findFirst({
    where: {
      name: {
        contains: 'immis',
        mode: 'insensitive',
      },
    },
  });

  if (existing) {
    console.log('✅ IMMIS API key already exists:', existing.id);
    console.log('   Name:', existing.name);
    console.log('   Active:', existing.is_active);
    console.log('   Created:', existing.created_at);
    
    if (existing.key !== immisApiKey || !existing.is_active) {
      await prisma.apiKey.update({
        where: { id: existing.id },
        data: {
          key: immisApiKey,
          is_active: true,
        },
      });
      console.log('✅ Updated IMMIS API key');
    }
  } else {
    const newKey = await prisma.apiKey.create({
      data: {
        key: immisApiKey,
        name: 'IMMIS Integration',
        description: 'IMMIS API key for member data integration',
        is_active: true,
        scopes: ['immis:read'],
        rate_limit: 1000,
      },
    });
    console.log('✅ Inserted IMMIS API key:', newKey.id);
    console.log('   Name:', newKey.name);
    console.log('   Created:', newKey.created_at);
  }
}

main()
  .catch((e) => {
    console.error('❌ Error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
