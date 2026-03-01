# Animal Module – Design & Best Practices

**Scope:** Milk production tracking, breeding & calving, health & vaccination, and linking production to milk sales.  
**Last updated:** March 2026

---

## 1. What you already have

### 1.1 Schema (existing)

| Model | Purpose |
|-------|--------|
| **Animal** | Core registration: account_id, farm_id, tag_number, name, breed, gender, date_of_birth, source, mother_id, father_id, status (active, lactating, dry, pregnant, sick, sold, dead, culled), photo_url, notes. |
| **AnimalWeight** | Weight history: animal_id, weight_kg, recorded_at, notes. |
| **AnimalHealth** | Health events: animal_id, event_type (vaccination, treatment, deworming, examination, surgery, injury, illness, other), event_date, description, diagnosis, treatment, medicine_name, dosage, administered_by, **next_due_date**, cost, notes. |
| **Farm** | account_id, name, code, location_id, status; has many animals. |
| **MilkSale** | supplier_account_id, customer_account_id, **animal_id (optional)**, quantity, unit_price, status, sale_at, payment fields, recorded_by. |

### 1.2 API (existing)

- **Animals:** List, Get, Create, Update, Delete; scoped by account (and optional farm).
- **Weights:** POST `animals/:id/weights`, GET `animals/:id/weights`, DELETE weight.
- **Health:** POST `animals/:id/health`, GET `animals/:id/health`, DELETE health record.
- **Collections:** Create collection (creates MilkSale with optional `animal_id`).
- **Sales:** Create sale (creates MilkSale; animal_id can be added in DTO if needed).

### 1.3 Gaps

- **Milk production:** No table for “produced milk” (per animal/per day). Milk is only recorded when sold/collected (MilkSale).
- **Breeding & calving:** No breeding events or calving records; only mother_id/father_id on Animal.
- **Production ↔ sales link:** No way to record “we produced X litres” then “we sold Y of that”; no traceability from production to sale.

---

## 2. Best-practice design

### 2.1 Principles (align with existing docs)

- **Single source of truth:** Production is recorded in one place; sales in another; link via IDs.
- **Reference, don’t duplicate:** Use FKs (e.g. `milk_production_id` on MilkSale) so reports and audits can trace back.
- **Same account scope:** All new tables (milk production, breeding, calving) use the same account (and optional farm) as Animals and MilkSale.
- **Accounting:** Milk **sales** (already in MilkSale) remain the place that drives revenue/postings when you add accounting integration; production is operational only (no direct posting).

### 2.2 Milk production tracking

**Concept:** Record “how much milk was produced” per animal (or per farm) per day, independent of whether it was sold. Then optionally link a sale to that production.

**New table: `MilkProduction`**

| Field | Type | Purpose |
|-------|------|--------|
| id | UUID | PK |
| account_id | UUID | Tenant scope (required). |
| farm_id | UUID? | Optional farm. |
| animal_id | UUID? | Optional: production per animal; null = farm-level/bulk. |
| production_date | Date | Day of production. |
| quantity_litres | Decimal | Litres produced. |
| notes | String? | e.g. morning/evening, quality. |
| created_at, updated_at, created_by | - | Audit. |

**Link to sales (two options; recommend Option A):**

- **Option A (recommended):** Add optional `milk_production_id` on **MilkSale**. When creating a sale, user can attach it to a specific production record. One production record can be “partially sold” by having multiple MilkSales reference it and sum of sale quantities ≤ production quantity (enforced in app or reporting).
- **Option B:** No FK; report “production vs sold” by joining on animal_id + date. Simpler schema, less explicit traceability.

**Business rules:**

- Production can exist without any sale (milk retained, consumed, or recorded for metrics).
- Sale can exist without production_id (legacy or bulk sales).
- When `milk_production_id` is set, `animal_id` on MilkSale should match production’s animal_id (or be null if production was farm-level).
- Reports: “Production by animal/farm/date”, “Sold vs produced” (by animal or farm).

### 2.3 Breeding & calving records

**Concept:** Record breeding events (natural/AI, date, bull/insemination details) and calving outcomes (date, calf link, live/stillborn, gender, weight). These feed lineage (mother_id/father_id can be set when a calf is registered).

**New table: `AnimalBreeding`**

| Field | Type | Purpose |
|-------|------|--------|
| id | UUID | PK |
| animal_id | UUID | Female (dam). |
| breeding_date | Date | Date of breeding. |
| method | Enum | e.g. natural, artificial_insemination. |
| bull_animal_id | UUID? | If natural, link to bull. |
| bull_name | String? | Or free text if no animal record. |
| semen_code | String? | For AI. |
| expected_calving_date | Date? | Calculated or manual. |
| outcome | Enum? | e.g. pregnant, not_pregnant, unknown (fill after pregnancy check or calving). |
| notes | String? | |
| created_at, created_by | - | Audit. |

**New table: `AnimalCalving`**

| Field | Type | Purpose |
|-------|------|--------|
| id | UUID | PK |
| mother_id | UUID | Dam (Animal). |
| calving_date | Date | Date of calving. |
| calf_id | UUID? | Link to Animal if calf registered. |
| outcome | Enum | e.g. live, stillborn, aborted. |
| gender | Enum? | male, female (for calf). |
| weight_kg | Decimal? | Birth weight. |
| notes | String? | |
| created_at, created_by | - | Audit. |

**Link to Animal:** When a calf is registered (Animal), set `mother_id` (and optionally `father_id` from breeding record). Optionally set `AnimalCalving.calf_id` when that calf is created.

**Optional:** Link calving to breeding (e.g. `animal_breeding_id` on AnimalCalving) for “this calving was from this breeding event”.

### 2.4 Health & vaccination logs

**Already in place:** `AnimalHealth` with `event_type` including **vaccination**, plus treatment, deworming, examination, surgery, injury, illness, other. Fields: medicine_name, dosage, **next_due_date** (for boosters), administered_by, cost.

**Best practice:**

- Use **event_type = vaccination** for all vaccinations; use **medicine_name** (and optional **description**) for vaccine name; use **next_due_date** for next booster.
- Optionally add a dedicated **vaccination** view or API filter: “GET health records where event_type = vaccination” for vaccination logs and due-date alerts.
- No new table required unless you need a separate vaccine catalogue (e.g. Vaccine product master); then you could add a FK to that later.

### 2.5 Linking production to milk sales (flow)

1. **Record production:** POST `/animals/:id/production` or `/production` (farm-level) with date and quantity_litres. Creates `MilkProduction` (and optionally links animal/farm).
2. **Record sale (existing):** POST collections or sales; when creating, allow optional `milk_production_id` (and ensure animal_id matches if present). Existing accounting/posting from MilkSale stays unchanged.
3. **Reporting:** “Produced vs sold” by animal or farm: sum(MilkProduction.quantity_litres) vs sum(MilkSale.quantity) grouped by animal/farm/period; optionally filter sales by milk_production_id for “sold from recorded production”.

---

## 3. Implementation order

| Order | Item | Effort | Notes |
|-------|------|--------|--------|
| 1 | **MilkProduction table + API** | Small | Migration, CRUD + list by animal/farm/date; optional link from Collections/Sales to production_id. |
| 2 | **MilkSale.milk_production_id** | Small | Optional FK; update create collection/sale DTOs and services to accept and set it. |
| 3 | **AnimalBreeding table + API** | Medium | Migration, CRUD, list by animal. |
| 4 | **AnimalCalving table + API** | Medium | Migration, CRUD, list by mother; optional link to breeding and calf_id when calf is registered. |
| 5 | **Vaccination log / due alerts** | Small | Reuse AnimalHealth; add GET filter by event_type=vaccination and optional “next_due_date” report or alert. |
| 6 | **Reporting** | Medium | “Production vs sold” by animal/farm; breeding/calving summaries; vaccination due list. |

---

## 4. Summary

- **Milk production:** New `MilkProduction` table; record production per animal (or farm) per day; optionally link sales via `MilkSale.milk_production_id`. Produced milk can be sold (linked) or not (unlinked).
- **Breeding & calving:** New `AnimalBreeding` and `AnimalCalving`; link calving to calf via `calf_id` and to mother; lineage (mother_id/father_id) set when registering calf.
- **Health & vaccination:** Use existing `AnimalHealth` with event_type = vaccination and next_due_date; add vaccination-focused API/reports if needed.
- **Production ↔ sales:** Optional FK from MilkSale to MilkProduction; same account scope; accounting remains driven by MilkSale; production is for tracking and reporting only.

This keeps one source of truth per domain, uses IDs for traceability, and fits your existing accounting and module-integration approach.
