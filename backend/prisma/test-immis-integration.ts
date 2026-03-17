import { PrismaClient } from '@prisma/client';
import * as https from 'https';
import * as http from 'http';

const prisma = new PrismaClient();

async function testImmisIntegration() {
  console.log('🧪 Testing IMMIS Integration...\n');

  console.log('1️⃣ Checking IMMIS API key in database...');
  const immisKey = await prisma.apiKey.findFirst({
    where: {
      name: {
        contains: 'immis',
        mode: 'insensitive',
      },
      is_active: true,
    },
  });

  if (!immisKey) {
    console.error('❌ IMMIS API key not found in database');
    return;
  }

  console.log('✅ IMMIS API key found:', immisKey.name);
  console.log('   ID:', immisKey.id);
  console.log('   Active:', immisKey.is_active);
  console.log('');

  console.log('2️⃣ Testing direct IMMIS API call...');
  const directResult = await callImmisApi(immisKey.key);
  
  if (directResult.success) {
    console.log('✅ Direct IMMIS API call successful');
    console.log('   Status:', directResult.data?.status);
    console.log('   Total members:', directResult.data?.data?.totalCount);
    console.log('   Members on page:', directResult.data?.data?.members?.count);
  } else {
    console.error('❌ Direct IMMIS API call failed:', directResult.error);
    return;
  }
  console.log('');

  console.log('3️⃣ Getting test user token...');
  const testUser = await prisma.user.findFirst({
    where: {
      status: 'active',
    },
    include: {
      user_accounts: {
        where: {
          status: 'active',
        },
        take: 1,
      },
    },
  });

  if (!testUser || !testUser.token) {
    console.error('❌ No active user with token found');
    return;
  }

  console.log('✅ Test user found:', testUser.name);
  console.log('   Token exists:', !!testUser.token);
  console.log('');

  console.log('4️⃣ Testing backend IMMIS endpoint...');
  const backendResult = await callBackendImmisEndpoint(testUser.token);
  
  if (backendResult.success) {
    console.log('✅ Backend IMMIS endpoint successful');
    console.log('   Status:', backendResult.data?.status);
    console.log('   Total members:', backendResult.data?.data?.totalCount);
    console.log('   Members on page:', backendResult.data?.data?.members?.count);
  } else {
    console.error('❌ Backend IMMIS endpoint failed:', backendResult.error);
  }
  console.log('');

  console.log('✅ IMMIS Integration test complete!');
}

function callImmisApi(apiKey: string): Promise<{ success: boolean; data?: any; error?: string }> {
  return new Promise((resolve) => {
    const options = {
      hostname: 'immis.hillygeeks.com',
      port: 443,
      path: '/api/integration/members?page=0&limit=3',
      method: 'GET',
      headers: {
        'X-API-Key': apiKey,
        'Content-Type': 'application/json',
      },
      timeout: 10000,
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (res.statusCode === 200) {
            resolve({ success: true, data: parsed });
          } else {
            resolve({ success: false, error: `HTTP ${res.statusCode}: ${parsed.message || data}` });
          }
        } catch (e) {
          resolve({ success: false, error: `Parse error: ${data}` });
        }
      });
    });

    req.on('error', (e) => resolve({ success: false, error: e.message }));
    req.on('timeout', () => {
      req.destroy();
      resolve({ success: false, error: 'Timeout' });
    });

    req.end();
  });
}

function callBackendImmisEndpoint(token: string): Promise<{ success: boolean; data?: any; error?: string }> {
  return new Promise((resolve) => {
    const options = {
      hostname: 'localhost',
      port: 3004,
      path: '/api/immis/members?page=0&limit=3',
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      timeout: 10000,
    };

    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          const parsed = JSON.parse(data);
          if (res.statusCode === 200) {
            resolve({ success: true, data: parsed });
          } else {
            resolve({ success: false, error: `HTTP ${res.statusCode}: ${parsed.message || data}` });
          }
        } catch (e) {
          resolve({ success: false, error: `Parse error: ${data}` });
        }
      });
    });

    req.on('error', (e) => resolve({ success: false, error: e.message }));
    req.on('timeout', () => {
      req.destroy();
      resolve({ success: false, error: 'Timeout' });
    });

    req.end();
  });
}

testImmisIntegration()
  .catch((e) => {
    console.error('❌ Test failed:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
