# Orora Feature Specifications

## Overview

This document details all features planned for the Orora Cattle Farming Platform, organized by module.

---

## 1. Animal Management Module

### 1.1 Animal Registration

**Description:** Register individual cattle with unique identification and tracking information.

**User Stories:**
- As a farmer, I want to register my cattle so I can track each animal individually
- As a farm manager, I want to see all animals in my farm organized by status
- As an MCC, I want to view animals from all my registered suppliers

**Data Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| tag_number | String | Yes | Unique identifier (ear tag) |
| name | String | No | Optional animal name |
| breed | String | Yes | Cattle breed |
| date_of_birth | Date | Yes | Birth date |
| gender | Enum | Yes | Male, Female |
| source | Enum | Yes | Born on farm, Purchased |
| purchase_date | Date | Conditional | If purchased |
| purchase_price | Decimal | No | Purchase cost |
| mother_id | UUID | No | Link to mother animal |
| father_id | UUID | No | Link to father animal |
| status | Enum | Yes | Active, Sold, Dead, Sick |
| photo_url | String | No | Animal photo |
| notes | Text | No | Additional notes |

**Status Values:**
- `active` - Currently on farm, healthy
- `lactating` - Female, currently producing milk
- `dry` - Female, not producing milk
- `pregnant` - Female, confirmed pregnant
- `sick` - Under treatment
- `sold` - Sold/transferred
- `dead` - Deceased

**API Endpoints:**

```
POST   /api/animals              # Create animal
GET    /api/animals              # List animals (with filters)
GET    /api/animals/:id          # Get animal details
PATCH  /api/animals/:id          # Update animal
DELETE /api/animals/:id          # Delete/archive animal
GET    /api/animals/:id/history  # Get animal history (weights, health, etc.)
```

**Mobile UI:**
- Animal list with search and filters
- Add animal form with camera for photo
- Animal detail card with tabs (Info, Health, Production)
- Quick status change buttons

**Web UI:**
- Animal data table with sorting/filtering
- Animal detail page with full history
- Bulk import via CSV
- Print animal reports

---

### 1.2 Weight Tracking

**Description:** Track animal weight changes over time for growth monitoring.

**User Stories:**
- As a farmer, I want to record weights when I weigh my cattle
- As a manager, I want to see weight trends to monitor growth
- As a vet, I want weight history to assess animal health

**Data Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| animal_id | UUID | Yes | Link to animal |
| weight_kg | Decimal | Yes | Weight in kilograms |
| recorded_at | DateTime | Yes | When weight was taken |
| notes | Text | No | Observations |

**API Endpoints:**

```
POST   /api/animals/:id/weights     # Record weight
GET    /api/animals/:id/weights     # Get weight history
DELETE /api/animals/:id/weights/:wid # Delete weight record
```

---

### 1.3 Health Records

**Description:** Track health events, vaccinations, treatments, and vet visits.

**User Stories:**
- As a farmer, I want to record vaccinations to track immunization schedules
- As a vet, I want to see treatment history when examining an animal
- As a manager, I want alerts when vaccinations are due

**Health Event Types:**
- `vaccination` - Immunization
- `treatment` - Medical treatment
- `deworming` - Parasite control
- `examination` - Vet checkup
- `surgery` - Surgical procedure
- `injury` - Injury record
- `illness` - Disease/sickness

**Data Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| animal_id | UUID | Yes | Link to animal |
| event_type | Enum | Yes | Type of health event |
| event_date | Date | Yes | When it occurred |
| description | Text | Yes | Details |
| diagnosis | Text | No | Diagnosis (for illness) |
| treatment | Text | No | Treatment given |
| medicine_name | String | No | Medicine used |
| dosage | String | No | Dosage info |
| administered_by | String | No | Who administered |
| next_due_date | Date | No | For recurring events |
| cost | Decimal | No | Cost of treatment |
| notes | Text | No | Additional notes |

**API Endpoints:**

```
POST   /api/animals/:id/health      # Record health event
GET    /api/animals/:id/health      # Get health history
PATCH  /api/animals/:id/health/:hid # Update record
DELETE /api/animals/:id/health/:hid # Delete record
GET    /api/health/due              # Get upcoming due events
```

---

## 2. Reproduction & Breeding Module

### 2.1 Breeding Records

**Description:** Track insemination and breeding activities.

**Breeding Methods:**
- `natural` - Natural mating
- `ai` - Artificial insemination

**Data Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| female_animal_id | UUID | Yes | Cow being bred |
| male_animal_id | UUID | No | Bull (if natural) |
| breeding_date | Date | Yes | Date of breeding |
| breeding_method | Enum | Yes | Natural or AI |
| semen_source | String | No | AI semen details |
| technician | String | No | AI technician name |
| heat_detected_date | Date | No | When heat was detected |
| notes | Text | No | Observations |

### 2.2 Pregnancy Tracking

**Description:** Monitor pregnancy status and expected calving.

**Pregnancy Status:**
- `suspected` - Possible pregnancy
- `confirmed` - Pregnancy confirmed
- `failed` - Pregnancy not established
- `aborted` - Pregnancy lost
- `delivered` - Calf born

**Data Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| animal_id | UUID | Yes | Pregnant cow |
| breeding_id | UUID | No | Link to breeding record |
| status | Enum | Yes | Pregnancy status |
| confirmation_date | Date | No | When confirmed |
| confirmation_method | String | No | Ultrasound, manual, etc. |
| expected_calving_date | Date | No | Calculated due date |
| actual_calving_date | Date | No | When calf was born |
| notes | Text | No | Observations |

### 2.3 Calving Records

**Description:** Record birth details and calf information.

**Data Fields:**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| mother_id | UUID | Yes | Mother cow |
| calving_date | DateTime | Yes | Birth date/time |
| calf_gender | Enum | Yes | Male, Female |
| calf_weight | Decimal | No | Birth weight (kg) |
| calving_ease | Enum | No | Easy, Assisted, Difficult |
| calf_status | Enum | Yes | Alive, Stillborn |
| calf_animal_id | UUID | No | Link to registered calf |
| notes | Text | No | Birth observations |

**API Endpoints:**

```
POST   /api/breeding                # Record breeding
GET    /api/breeding                # List breeding records
POST   /api/animals/:id/pregnancy   # Record/update pregnancy
GET    /api/animals/:id/pregnancy   # Get pregnancy status
POST   /api/animals/:id/calving     # Record calving
GET    /api/calving/expected        # Get upcoming calvings
```

---

## 3. Milk Collection Module

### 3.1 Daily Collection (Existing - Enhanced)

**Description:** Record daily milk collection from farmers/suppliers.

**Enhancements for Orora:**
- Link collection to specific animal (optional)
- Morning/evening session tracking
- Quality indicators (fat content, SNF)

**Data Fields (Additional):**

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| animal_id | UUID | No | Specific cow (optional) |
| session | Enum | No | Morning, Evening |
| fat_content | Decimal | No | Fat percentage |
| snf_content | Decimal | No | Solids-not-fat % |
| quality_grade | Enum | No | A, B, C |

### 3.2 Production Analytics

**Description:** Track and analyze milk production per animal and farm.

**Metrics:**
- Daily production per animal
- Weekly/monthly trends
- Lactation curves
- Top producers ranking
- Production by breed

**API Endpoints:**

```
GET /api/analytics/milk/by-animal/:id     # Production by animal
GET /api/analytics/milk/by-farm           # Farm production summary
GET /api/analytics/milk/trends            # Production trends
GET /api/analytics/milk/top-producers     # Top producing animals
```

---

## 4. Inventory Module (Existing - Enhanced)

### 4.1 Feed Inventory

**Description:** Track animal feed stock and consumption.

**Feed Categories:**
- Concentrates (dairy meal, calf starter)
- Roughages (hay, silage)
- Minerals and supplements
- Salt blocks

**Features:**
- Stock level tracking
- Low stock alerts
- Consumption recording
- Purchase orders

### 4.2 Medicine Inventory

**Description:** Track veterinary medicines and supplies.

**Features:**
- Medicine stock management
- Expiry date tracking
- Usage recording (linked to health events)
- Prescription tracking

### 4.3 Equipment Tracking

**Description:** Track farm equipment and maintenance.

**Features:**
- Equipment registry
- Maintenance schedules
- Service history
- Asset valuation

---

## 5. Financial Module (Existing)

### 5.1 Payroll

Existing functionality for supplier payments.

### 5.2 Loans

Existing loan management for suppliers.

### 5.3 Charges

Existing fee/charge management.

### 5.4 Expense Tracking (New)

**Description:** Track farm operational expenses.

**Expense Categories:**
- Feed purchases
- Veterinary costs
- Labor costs
- Equipment maintenance
- Utilities
- Transport

---

## 6. Reports & Analytics

### 6.1 Dashboard

**Widgets:**
- Total animals (by status)
- Daily milk production
- Upcoming events (vaccinations, calvings)
- Recent activities
- Financial summary

### 6.2 Reports

| Report | Description |
|--------|-------------|
| Herd Summary | Animal count by breed, gender, status |
| Production Report | Milk production by period |
| Financial Report | Income, expenses, profit |
| Health Report | Vaccinations, treatments |
| Breeding Report | Success rates, calving statistics |

### 6.3 Exports

- CSV export for all data
- PDF reports
- Print-friendly views

---

## 7. User Management (Existing)

### 7.1 Roles

| Role | Description |
|------|-------------|
| Owner | Farm/MCC owner, full access |
| Manager | Day-to-day operations |
| Collector | Milk collection only |
| Vet | Health records access |
| Viewer | Read-only access |

### 7.2 Features

- User registration
- Role assignment
- Account switching
- Activity logging

---

## 8. Mobile-Specific Features

### 8.1 Offline Mode

**Description:** Work without internet connection.

**Features:**
- Local data storage
- Queue operations for sync
- Conflict resolution
- Sync status indicator

### 8.2 Camera Integration

**Features:**
- Animal photo capture
- Document scanning
- QR/barcode scanning for tags

### 8.3 Notifications

**Push Notification Types:**
- Vaccination reminders
- Upcoming calving alerts
- Low stock warnings
- Payment due reminders
- System updates

### 8.4 Quick Actions

- Quick milk entry
- Scan animal tag
- Report sick animal
- Emergency contacts

---

## 9. Integration Points

### 9.1 SMS Notifications (Planned)

- Bulk SMS to farmers
- Payment confirmations
- Appointment reminders

### 9.2 WhatsApp Integration (Planned)

- Collection notifications
- Report sharing

### 9.3 External APIs

- Weather data integration
- Market prices feed
- Payment gateway integration

---

## Feature Status Summary

| Module | MVP | Beta | v1.0 |
|--------|-----|------|------|
| Animal Registration | ✅ | ✅ | ✅ |
| Weight Tracking | ✅ | ✅ | ✅ |
| Basic Health Records | ✅ | ✅ | ✅ |
| Breeding & Reproduction | ❌ | ✅ | ✅ |
| Milk Collection | ✅ | ✅ | ✅ |
| Production Analytics | ❌ | ✅ | ✅ |
| Inventory Management | ✅ | ✅ | ✅ |
| Payroll | ✅ | ✅ | ✅ |
| Loans | ✅ | ✅ | ✅ |
| Dashboard | ✅ | ✅ | ✅ |
| Reports | ❌ | ✅ | ✅ |
| Offline Mode | ❌ | ❌ | ✅ |
| Push Notifications | ❌ | ✅ | ✅ |
| Multi-language | ❌ | ❌ | ✅ |
