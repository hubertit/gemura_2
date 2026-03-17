# IMMIS Integration Documentation

## Overview

IMMIS (Rwanda National Dairy Platform membership system) integration allows Gemura to:
- View IMMIS member records
- Link Gemura users to IMMIS members
- Verify membership status
- Keep member data synchronized

**Integration Type**: Read-only API proxy (IMMIS → Gemura backend → Gemura web/mobile)

**Base URL**: `https://immis.hillygeeks.com/api/integration`

**Authentication**: API Key stored securely in database

## Architecture

```
IMMIS API (HillyGeeks)
    ↓ (HTTPS with X-API-Key header)
Gemura Backend (NestJS)
    ↓ (Authenticated REST API)
Gemura Web/Mobile Apps
```

### Security Design

- IMMIS API key is **stored in the database** (`api_keys` table), not in code or env files
- Web/mobile apps **never call IMMIS directly**
- Backend acts as authenticated proxy, enforcing access control
- API key lookup uses same pattern as other integrations (Mista SMS)

## Backend Implementation

### Module Structure

```
backend/src/modules/immis/
├── immis.module.ts       # NestJS module registration
├── immis.service.ts      # IMMIS API client service
└── immis.controller.ts   # REST endpoints for web/mobile
```

### API Key Storage

The IMMIS API key is stored in the `api_keys` table:

```sql
INSERT INTO api_keys (key, name, description, is_active, scopes, rate_limit)
VALUES (
  'D2PWxiNLmN7RIsax6M7fH99yVcXsZldG',
  'IMMIS Integration',
  'IMMIS API key for member data integration',
  true,
  ARRAY['immis:read'],
  1000
);
```

**Key Lookup Logic** (in `ImmisService`):
```typescript
const apiKeyRecord = await prisma.apiKey.findFirst({
  where: {
    name: { contains: 'immis', mode: 'insensitive' },
    is_active: true,
  },
  orderBy: { created_at: 'desc' },
});
```

### Backend Endpoints

#### 1. List IMMIS Members

**Endpoint**: `GET /api/immis/members`

**Auth**: Bearer token (Gemura user token)

**Query Parameters**:
- `page` (optional): Zero-based page index
- `limit` (optional): Page size

**Example Request**:
```bash
curl -X GET "http://localhost:3004/api/immis/members?page=0&limit=5" \
  -H "Authorization: Bearer <gemura-user-token>"
```

**Example Response**:
```json
{
  "status": 200,
  "message": "Members retrieved successfully",
  "data": {
    "page": "0",
    "limit": "5",
    "totalPages": 2,
    "totalCount": 9,
    "totalOnPage": 5,
    "members": {
      "count": 9,
      "rows": [
        {
          "id": 10,
          "document_number": "123356575",
          "rca_number": "124565",
          "document_type": "NATIONAL_ID",
          "type": "INDIVIDUAL",
          "gender": "MALE",
          "cluster": "Service Providers",
          "disability": "NONE",
          "representative_name": "Festo",
          "representative_title": "Managing director",
          "certificate_issued_at": "2025-07-22T00:00:00.000Z",
          "phone": "0788112233",
          "email": "festo@gemura.com",
          "created_at": "2026-03-16T08:16:21.691Z",
          "updated_at": "2026-03-16T08:16:21.691Z",
          "location": {
            "id": 5519,
            "type": "VILLAGE",
            "code": "208120505",
            "name": "RUGAZI",
            "parent_id": 5514,
            "parent": {
              "id": 5514,
              "type": "CELL",
              "code": "2081205",
              "name": "RUYENZI",
              "parent_id": 5488
            }
          },
          "group": null,
          "organization": {
            "id": 1,
            "name": "Rwanda National Dairy Platform",
            "abbreviation": "RNDP"
          }
        }
      ]
    }
  }
}
```

#### 2. Get Single IMMIS Member

**Endpoint**: `GET /api/immis/members/:id`

**Auth**: Bearer token (Gemura user token)

**Example Request**:
```bash
curl -X GET "http://localhost:3004/api/immis/members/10" \
  -H "Authorization: Bearer <gemura-user-token>"
```

**Example Response**:
```json
{
  "status": 200,
  "message": "Member retrieved successfully",
  "data": {
    "id": 10,
    "document_number": "123356575",
    "rca_number": "124565",
    "document_type": "NATIONAL_ID",
    "type": "INDIVIDUAL",
    "gender": "MALE",
    "cluster": "Service Providers",
    "disability": "NONE",
    "representative_name": "Festo",
    "representative_title": "Managing director",
    "certificate_issued_at": "2025-07-22T00:00:00.000Z",
    "phone": "0788112233",
    "email": "festo@gemura.com",
    "location": { ... },
    "group": null,
    "organization": { ... }
  }
}
```

## Frontend Implementation

### Web App (Next.js)

**Location**: `apps/gemura-web/app/(authenticated)/immis/page.tsx`

**Features**:
- Paginated member list
- Real-time refresh
- Displays key member fields:
  - ID, Name, Type (INDIVIDUAL/COMPANY)
  - Document type & number
  - RCA number
  - Cluster
  - Contact (phone, email)
  - Organization
  - Location (village/cell hierarchy)

**Navigation**: Added to sidebar for all users (admin + operations sections)

### API Client

**Location**: `apps/gemura-web/lib/api/immis.ts`

**TypeScript Types** (based on actual IMMIS responses):

```typescript
export interface ImmisMember {
  id: number;
  document_number: string;
  rca_number: string;
  document_type: string;
  type: 'INDIVIDUAL' | 'COMPANY';
  gender: 'MALE' | 'FEMALE' | 'UNKNOWN';
  cluster: string;
  disability: string;
  representative_name: string;
  representative_title: string;
  certificate_issued_at: string;
  phone: string;
  email: string;
  location: ImmisLocation | null;
  group: ImmisGroup | null;
  organization: ImmisOrganization | null;
  // ... timestamps
}
```

## IMMIS Member Data Structure

### Key Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `id` | number | IMMIS member ID (primary key) | `10` |
| `type` | string | Member type | `INDIVIDUAL` or `COMPANY` |
| `document_type` | string | ID document type | `NATIONAL_ID`, `TIN` |
| `document_number` | string | Document number | `123356575` |
| `rca_number` | string | RCA registration number | `124565` |
| `representative_name` | string | Member or representative name | `Festo` |
| `representative_title` | string | Title/position | `Managing director` |
| `cluster` | string | Industry cluster | `Service Providers`, `Farmers / Producers` |
| `phone` | string | Contact phone | `0788112233` |
| `email` | string | Contact email | `festo@gemura.com` |
| `gender` | string | Gender | `MALE`, `FEMALE`, `UNKNOWN` |
| `disability` | string | Disability status | `NONE`, `VISUAL_IMPAIRMENT`, etc. |
| `certificate_issued_at` | ISO date | Membership certificate date | `2025-07-22T00:00:00.000Z` |

### Nested Objects

**Location** (hierarchical administrative structure):
```json
{
  "id": 5519,
  "type": "VILLAGE",
  "code": "208120505",
  "name": "RUGAZI",
  "parent_id": 5514,
  "parent": {
    "id": 5514,
    "type": "CELL",
    "code": "2081205",
    "name": "RUYENZI",
    "parent_id": 5488
  }
}
```

**Organization**:
```json
{
  "id": 1,
  "name": "Rwanda National Dairy Platform",
  "abbreviation": "RNDP",
  "location_id": null,
  "phone": null,
  "email": null
}
```

**Group** (optional):
```json
{
  "id": 123,
  "name": "Group Name"
}
```

## Member Types & Clusters

### Member Types
- `INDIVIDUAL` - Individual member
- `COMPANY` - Company/organization member

### Clusters (Industry Categories)
Based on actual data:
- `Service Providers`
- `Farmers / Producers`
- `Milk and Dairy Product Sellers`
- `Milk Consumers`
- `Importers of DoC` (Dairy or Cattle)

### Document Types
- `NATIONAL_ID` - Rwanda National ID
- `TIN` - Tax Identification Number

### Disability Status
- `NONE`
- `VISUAL_IMPAIRMENT`
- (Others may exist)

## Testing

### 1. Direct IMMIS API Test

```bash
curl -X GET "https://immis.hillygeeks.com/api/integration/members?page=0&limit=5" \
  -H "X-API-Key: D2PWxiNLmN7RIsax6M7fH99yVcXsZldG"
```

### 2. Backend Proxy Test

```bash
# Get auth token first
TOKEN=$(curl -X POST "http://localhost:3004/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"identifier":"your-phone","password":"your-password"}' \
  -s | jq -r '.data.token')

# Test IMMIS endpoint
curl -X GET "http://localhost:3004/api/immis/members?page=0&limit=5" \
  -H "Authorization: Bearer $TOKEN"
```

### 3. Automated Test Script

```bash
cd backend
npx tsx prisma/test-immis-integration.ts
```

This script:
- Verifies IMMIS API key exists in database
- Tests direct IMMIS API call
- Tests backend proxy endpoint with real auth
- Reports success/failure for each step

## Future Enhancements

### Phase 1: Member Linking (Current - Read-only)
- ✅ View IMMIS members in Gemura web
- ✅ Backend proxy for secure API access
- ✅ API key stored in database

### Phase 2: Automatic Member Matching
- Add `immis_member_id` field to Gemura `User` or `SupplierCustomer` models
- Create backend endpoint: `POST /immis/link-member`
  - Input: Gemura user ID + search criteria (phone, email, document number)
  - Logic: Search IMMIS members, find best match, store `immis_member_id`
- Display IMMIS membership status on user profiles

### Phase 3: Registration Integration (if IMMIS adds write endpoints)
- If IMMIS exposes `POST /members` or similar:
  - On Gemura user registration, create IMMIS member record
  - Store returned `member_id` on Gemura user
- If not available:
  - Queue "pending IMMIS registration" tasks for admin review
  - Manual registration in IMMIS, then link via Phase 2

### Phase 4: Sync & Updates
- Periodic background sync to update member data
- Webhook support (if IMMIS provides)
- Conflict resolution for data mismatches

## UI/UX Considerations

### Current Implementation
- IMMIS menu entry visible to all users (admin + operations)
- Simple member list with pagination
- Consistent with Gemura web design system:
  - Blue sidebar (`#052a54`)
  - White content cards
  - Tailwind utility classes
  - Icon-based navigation

### Future UI Enhancements
- Member search/filter by name, phone, RCA number
- "Link to Gemura user" action button
- Membership status badges (active, expired, etc.)
- Member detail modal/page
- Export to CSV
- Admin-only visibility (add permission check)

## Error Handling

### Backend Errors

| Scenario | HTTP Status | Message |
|----------|-------------|---------|
| IMMIS API key not found in DB | 401 | "IMMIS integration API key is not configured" |
| IMMIS API returns 401 | 401 | "IMMIS API key is invalid or unauthorized" |
| IMMIS API timeout/error | 500 | "IMMIS request failed" or "IMMIS request timeout" |
| Invalid Gemura auth token | 401 | "Invalid or expired token" |

### Frontend Error Display

- Red banner at top of page with error message
- Retry button available
- Clear messaging for configuration issues vs. temporary failures

## Configuration

### Adding/Updating IMMIS API Key

**Option 1: Via Script** (recommended for initial setup)
```bash
cd backend
npx tsx prisma/insert-immis-key.ts
```

**Option 2: Via SQL**
```sql
INSERT INTO api_keys (key, name, description, is_active, scopes, rate_limit)
VALUES (
  'D2PWxiNLmN7RIsax6M7fH99yVcXsZldG',
  'IMMIS Integration',
  'IMMIS API key for member data integration',
  true,
  ARRAY['immis:read'],
  1000
)
ON CONFLICT (key) DO UPDATE SET
  is_active = true,
  updated_at = NOW();
```

**Option 3: Via Gemura API Keys UI** (future)
- Navigate to Settings → API Keys
- Create new key with name containing "IMMIS"
- Paste IMMIS API key value

### Key Rotation

To rotate the IMMIS API key:
1. Get new key from IMMIS/HillyGeeks
2. Update the `api_keys` record (set `is_active = false` on old, create new)
3. No code changes needed

## Monitoring & Maintenance

### Health Checks

Monitor these indicators:
- IMMIS endpoint response times (should be < 2s)
- Error rates on `/api/immis/*` endpoints
- API key `last_used_at` and `request_count` in database

### Logs

Backend logs IMMIS integration events:
- API key lookup failures
- IMMIS API errors (401, timeout, parse errors)
- Request/response for debugging

Search logs:
```bash
# Backend logs
grep "IMMIS" backend/logs/*.log

# Or if using PM2/systemd
journalctl -u gemura-backend | grep IMMIS
```

## Troubleshooting

### "IMMIS integration API key is not configured"

**Cause**: No active API key with name containing "IMMIS" in database

**Fix**:
```bash
cd backend
npx tsx prisma/insert-immis-key.ts
```

### "IMMIS API key is invalid or unauthorized"

**Cause**: IMMIS API key is wrong or expired

**Fix**:
1. Contact HillyGeeks to verify/renew key
2. Update database record with new key

### "IMMIS request timeout"

**Cause**: Network issues or IMMIS API slow/down

**Fix**:
- Check IMMIS API status with direct curl test
- Verify network connectivity from backend server
- Check if IMMIS API is rate-limiting

### Members not showing in web app

**Checklist**:
1. Backend running? Check `http://localhost:3004/api/health`
2. IMMIS API key configured? Run test script
3. User authenticated? Check browser localStorage for token
4. Network errors? Check browser console

## Integration Test Results

### Test Run: 2026-03-17

```
🧪 Testing IMMIS Integration...

1️⃣ Checking IMMIS API key in database...
✅ IMMIS API key found: IMMIS Integration
   ID: 3a20b267-ddf0-4a10-aad8-7704c6c91725
   Active: true

2️⃣ Testing direct IMMIS API call...
✅ Direct IMMIS API call successful
   Status: 200
   Total members: 9
   Members on page: 9

3️⃣ Getting test user token...
✅ Test user found: Jean Baptiste Uwimana
   Token exists: true

4️⃣ Testing backend IMMIS endpoint...
✅ Backend IMMIS endpoint successful
   Status: 200
   Total members: 9
   Members on page: 9

✅ IMMIS Integration test complete!
```

**Result**: All integration points working correctly.

## Sample IMMIS Member Records

### Individual Member
```json
{
  "id": 10,
  "document_number": "123356575",
  "rca_number": "124565",
  "document_type": "NATIONAL_ID",
  "type": "INDIVIDUAL",
  "gender": "MALE",
  "cluster": "Service Providers",
  "disability": "NONE",
  "representative_name": "Festo",
  "representative_title": "Managing director",
  "certificate_issued_at": "2025-07-22T00:00:00.000Z",
  "phone": "0788112233",
  "email": "festo@gemura.com",
  "location": {
    "id": 5519,
    "type": "VILLAGE",
    "code": "208120505",
    "name": "RUGAZI",
    "parent": {
      "id": 5514,
      "type": "CELL",
      "code": "2081205",
      "name": "RUYENZI"
    }
  },
  "organization": {
    "id": 1,
    "name": "Rwanda National Dairy Platform",
    "abbreviation": "RNDP"
  }
}
```

### Company Member
```json
{
  "id": 8,
  "document_number": "123456",
  "rca_number": "123456",
  "document_type": "TIN",
  "type": "COMPANY",
  "gender": "UNKNOWN",
  "cluster": "Milk and Dairy Product Sellers",
  "disability": "NONE",
  "representative_name": "Inyange LTD",
  "representative_title": "Managing director",
  "certificate_issued_at": "2025-04-09T00:00:00.000Z",
  "phone": "0788121212",
  "email": "info@inyange.rw",
  "location": { ... },
  "organization": { ... }
}
```

## Next Steps

1. **Test in web browser**:
   - Navigate to http://localhost:3005
   - Login with admin account
   - Click "IMMIS" in sidebar
   - Verify member list loads

2. **Add member linking**:
   - Extend Prisma schema to add `immis_member_id` to `User` or `SupplierCustomer`
   - Create `POST /immis/link-member` endpoint
   - Add "Link to IMMIS" UI in user/supplier profiles

3. **Restrict visibility** (optional):
   - Add `requiresPermission: 'manage_immis'` to nav config
   - Create permission in database
   - Assign to admin users only

4. **Production deployment**:
   - Ensure IMMIS API key is in production database
   - Verify HTTPS connectivity from production server to IMMIS
   - Monitor error rates and response times

## Contact

**IMMIS Support**: HillyGeeks (contact for API issues, key renewal, or new endpoints)

**Gemura Integration Owner**: Backend team (for Gemura-side issues)
