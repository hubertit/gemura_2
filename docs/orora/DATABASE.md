# Orora Database Schema

## Overview

Orora uses PostgreSQL as the primary database with Prisma ORM for type-safe database access.

**Database:** `gemura_db` (shared with Gemura, same backend)

**ORM:** Prisma 5.x

---

## Entity Relationship Diagram

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              CORE ENTITIES                                       │
└─────────────────────────────────────────────────────────────────────────────────┘

┌──────────────┐       ┌──────────────┐       ┌──────────────┐
│   Account    │◄──────│  UserAccount │───────►│    User      │
│  (Farm/MCC)  │       │  (junction)  │        │  (Person)    │
└──────┬───────┘       └──────────────┘        └──────────────┘
       │
       ├──────────────────────────────────────────────────────┐
       │                                                      │
       ▼                                                      ▼
┌──────────────┐       ┌──────────────┐       ┌──────────────────┐
│   Animal     │       │   MilkSale   │       │ SupplierCustomer │
│  (Cattle)    │       │ (Collection) │       │   (Relation)     │
└──────┬───────┘       └──────────────┘       └──────────────────┘
       │
       ├─────────────┬─────────────┬─────────────┐
       ▼             ▼             ▼             ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│AnimalWeight │ │AnimalHealth │ │AnimalBreeding│ │AnimalCalving│
└─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘
```

---

## New Models for Orora (Animals Module)

### Animal

The core model for livestock registration.

```prisma
model Animal {
  id                String       @id @default(uuid()) @db.Uuid
  account_id        String       @map("account_id") @db.Uuid
  tag_number        String       @map("tag_number")
  name              String?
  breed             String
  gender            AnimalGender
  date_of_birth     DateTime     @map("date_of_birth")
  source            AnimalSource
  purchase_date     DateTime?    @map("purchase_date")
  purchase_price    Decimal?     @map("purchase_price") @db.Decimal(10, 2)
  mother_id         String?      @map("mother_id") @db.Uuid
  father_id         String?      @map("father_id") @db.Uuid
  status            AnimalStatus @default(active)
  photo_url         String?      @map("photo_url")
  notes             String?      @db.Text
  created_at        DateTime     @default(now()) @map("created_at")
  updated_at        DateTime     @updatedAt @map("updated_at")
  created_by        String?      @map("created_by") @db.Uuid
  
  // Relations
  account           Account         @relation(fields: [account_id], references: [id])
  mother            Animal?         @relation("AnimalMother", fields: [mother_id], references: [id])
  father            Animal?         @relation("AnimalFather", fields: [father_id], references: [id])
  offspring_mother  Animal[]        @relation("AnimalMother")
  offspring_father  Animal[]        @relation("AnimalFather")
  weights           AnimalWeight[]
  health_records    AnimalHealth[]
  breedings         AnimalBreeding[] @relation("AnimalBreedingFemale")
  pregnancies       AnimalPregnancy[]
  calvings          AnimalCalving[]
  milk_sales        MilkSale[]

  @@unique([account_id, tag_number])
  @@index([account_id])
  @@index([status])
  @@index([breed])
  @@index([gender])
  @@map("animals")
}

enum AnimalGender {
  male
  female
}

enum AnimalSource {
  born_on_farm
  purchased
  donated
  other
}

enum AnimalStatus {
  active
  lactating
  dry
  pregnant
  sick
  sold
  dead
  culled
}
```

### AnimalWeight

Track weight history for growth monitoring.

```prisma
model AnimalWeight {
  id          String   @id @default(uuid()) @db.Uuid
  animal_id   String   @map("animal_id") @db.Uuid
  weight_kg   Decimal  @map("weight_kg") @db.Decimal(6, 2)
  recorded_at DateTime @map("recorded_at")
  notes       String?  @db.Text
  created_at  DateTime @default(now()) @map("created_at")
  created_by  String?  @map("created_by") @db.Uuid

  // Relations
  animal Animal @relation(fields: [animal_id], references: [id], onDelete: Cascade)

  @@index([animal_id])
  @@index([recorded_at])
  @@map("animal_weights")
}
```

### AnimalHealth

Track health events, vaccinations, and treatments.

```prisma
model AnimalHealth {
  id              String          @id @default(uuid()) @db.Uuid
  animal_id       String          @map("animal_id") @db.Uuid
  event_type      HealthEventType @map("event_type")
  event_date      DateTime        @map("event_date")
  description     String          @db.Text
  diagnosis       String?         @db.Text
  treatment       String?         @db.Text
  medicine_name   String?         @map("medicine_name")
  dosage          String?
  administered_by String?         @map("administered_by")
  next_due_date   DateTime?       @map("next_due_date")
  cost            Decimal?        @db.Decimal(10, 2)
  notes           String?         @db.Text
  created_at      DateTime        @default(now()) @map("created_at")
  created_by      String?         @map("created_by") @db.Uuid

  // Relations
  animal Animal @relation(fields: [animal_id], references: [id], onDelete: Cascade)

  @@index([animal_id])
  @@index([event_type])
  @@index([event_date])
  @@index([next_due_date])
  @@map("animal_health")
}

enum HealthEventType {
  vaccination
  treatment
  deworming
  examination
  surgery
  injury
  illness
  other
}
```

### AnimalBreeding

Track breeding/insemination events.

```prisma
model AnimalBreeding {
  id                 String        @id @default(uuid()) @db.Uuid
  female_animal_id   String        @map("female_animal_id") @db.Uuid
  male_animal_id     String?       @map("male_animal_id") @db.Uuid
  breeding_date      DateTime      @map("breeding_date")
  breeding_method    BreedingMethod @map("breeding_method")
  semen_source       String?       @map("semen_source")
  technician         String?
  heat_detected_date DateTime?     @map("heat_detected_date")
  notes              String?       @db.Text
  created_at         DateTime      @default(now()) @map("created_at")
  created_by         String?       @map("created_by") @db.Uuid

  // Relations
  female_animal Animal  @relation("AnimalBreedingFemale", fields: [female_animal_id], references: [id])
  male_animal   Animal? @relation("AnimalBreedingMale", fields: [male_animal_id], references: [id])
  pregnancy     AnimalPregnancy?

  @@index([female_animal_id])
  @@index([breeding_date])
  @@map("animal_breedings")
}

enum BreedingMethod {
  natural
  ai
}
```

### AnimalPregnancy

Track pregnancy status and expected calving.

```prisma
model AnimalPregnancy {
  id                    String          @id @default(uuid()) @db.Uuid
  animal_id             String          @map("animal_id") @db.Uuid
  breeding_id           String?         @unique @map("breeding_id") @db.Uuid
  status                PregnancyStatus
  confirmation_date     DateTime?       @map("confirmation_date")
  confirmation_method   String?         @map("confirmation_method")
  expected_calving_date DateTime?       @map("expected_calving_date")
  actual_calving_date   DateTime?       @map("actual_calving_date")
  notes                 String?         @db.Text
  created_at            DateTime        @default(now()) @map("created_at")
  updated_at            DateTime        @updatedAt @map("updated_at")

  // Relations
  animal   Animal          @relation(fields: [animal_id], references: [id])
  breeding AnimalBreeding? @relation(fields: [breeding_id], references: [id])
  calving  AnimalCalving?

  @@index([animal_id])
  @@index([status])
  @@index([expected_calving_date])
  @@map("animal_pregnancies")
}

enum PregnancyStatus {
  suspected
  confirmed
  failed
  aborted
  delivered
}
```

### AnimalCalving

Record birth events.

```prisma
model AnimalCalving {
  id             String       @id @default(uuid()) @db.Uuid
  mother_id      String       @map("mother_id") @db.Uuid
  pregnancy_id   String?      @unique @map("pregnancy_id") @db.Uuid
  calving_date   DateTime     @map("calving_date")
  calf_gender    AnimalGender @map("calf_gender")
  calf_weight_kg Decimal?     @map("calf_weight_kg") @db.Decimal(5, 2)
  calving_ease   CalvingEase? @map("calving_ease")
  calf_status    CalfStatus   @map("calf_status")
  calf_animal_id String?      @map("calf_animal_id") @db.Uuid
  notes          String?      @db.Text
  created_at     DateTime     @default(now()) @map("created_at")
  created_by     String?      @map("created_by") @db.Uuid

  // Relations
  mother    Animal           @relation(fields: [mother_id], references: [id])
  pregnancy AnimalPregnancy? @relation(fields: [pregnancy_id], references: [id])

  @@index([mother_id])
  @@index([calving_date])
  @@map("animal_calvings")
}

enum CalvingEase {
  easy
  assisted
  difficult
  cesarean
}

enum CalfStatus {
  alive
  stillborn
  died_after_birth
}
```

---

## Updated MilkSale Model

Add optional link to specific animal:

```prisma
model MilkSale {
  // ... existing fields ...
  
  animal_id String? @map("animal_id") @db.Uuid  // NEW: Optional link to cow
  session   MilkSession?                        // NEW: Morning/Evening
  
  // Relations
  animal Animal? @relation(fields: [animal_id], references: [id])
  
  // ... existing relations ...
}

enum MilkSession {
  morning
  evening
  combined
}
```

---

## Existing Models (Summary)

### Core Models

| Model | Description | Tables |
|-------|-------------|--------|
| Account | Farm, MCC, or organization | `accounts` |
| User | Individual user | `users` |
| UserAccount | User-account membership | `user_accounts` |
| SupplierCustomer | Business relationship | `suppliers_customers` |

### Milk Collection

| Model | Description | Tables |
|-------|-------------|--------|
| MilkSale | Milk collection record | `milk_sales` |
| MilkRejectionReason | Rejection reasons | `milk_rejection_reasons` |

### Inventory

| Model | Description | Tables |
|-------|-------------|--------|
| Product | Inventory product | `products` |
| InventoryItem | Item type definition | `inventory_items` |
| InventorySale | Product sale | `inventory_sales` |
| InventoryMovement | Stock movement | `inventory_movements` |

### Financial

| Model | Description | Tables |
|-------|-------------|--------|
| Loan | Money lending | `loans` |
| LoanRepayment | Loan payments | `loan_repayments` |
| Charge | Fees/charges | `charges` |
| PayrollRun | Payment batch | `payroll_runs` |
| PayrollPayslip | Individual payment | `payroll_payslips` |

### Social/Feed

| Model | Description | Tables |
|-------|-------------|--------|
| FeedPost | Social media post | `feed_posts` |
| FeedComment | Post comments | `feed_comments` |
| Notification | User notifications | `notifications` |

---

## Indexes

### Performance Indexes

All foreign keys and frequently queried fields have indexes:

```prisma
@@index([account_id])           // Filter by account
@@index([status])               // Filter by status
@@index([created_at])           // Sort by date
@@index([tag_number])           // Search by tag
```

### Composite Indexes

```prisma
@@unique([account_id, tag_number])  // Unique tag per account
@@unique([user_id, account_id])     // One membership per user/account
```

---

## Data Types

### UUID

All primary keys use UUID v4:
```prisma
id String @id @default(uuid()) @db.Uuid
```

### Decimal

Financial and measurement values use precise decimals:
```prisma
price      Decimal @db.Decimal(10, 2)  // Up to 99,999,999.99
weight_kg  Decimal @db.Decimal(6, 2)   // Up to 9999.99 kg
```

### DateTime

All timestamps in UTC:
```prisma
created_at DateTime @default(now())
updated_at DateTime @updatedAt
```

---

## Migration Strategy

### Adding Animal Module

1. Create migration for new tables:
   ```bash
   npx prisma migrate dev --name add_animal_module
   ```

2. Update MilkSale with optional animal_id:
   ```bash
   npx prisma migrate dev --name link_milk_to_animal
   ```

3. Deploy to production:
   ```bash
   npx prisma migrate deploy
   ```

### Data Migration

For existing data, animal_id on MilkSale remains null (no animal linked).

---

## Database Connections

### Development

```
DATABASE_URL="postgresql://user:pass@localhost:5432/gemura_db"
```

### Production (Kwezi Server)

```
DATABASE_URL="postgresql://kwezi:pass@kwezi-postgres:5432/gemura_db"
```

---

## Backup Strategy

### Automated Backups

- Daily pg_dump to backup server
- 30-day retention
- Point-in-time recovery enabled

### Manual Backup

```bash
docker exec kwezi-postgres pg_dump -U kwezi gemura_db > backup.sql
```

### Restore

```bash
docker exec -i kwezi-postgres psql -U kwezi gemura_db < backup.sql
```

---

## Database Administration

### Connect to Database

```bash
# SSH to server
ssh root@209.74.80.195

# Enter PostgreSQL
docker exec -it kwezi-postgres psql -U kwezi -d gemura_db
```

### Common Queries

```sql
-- Count animals by status
SELECT status, COUNT(*) FROM animals GROUP BY status;

-- Today's milk collections
SELECT SUM(quantity) FROM milk_sales 
WHERE DATE(sale_at) = CURRENT_DATE;

-- Active suppliers
SELECT COUNT(*) FROM suppliers_customers 
WHERE relationship_status = 'active';
```
