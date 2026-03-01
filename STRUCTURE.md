# Repository structure

This document defines the canonical layout and naming for the Orora/Gemura monorepo.

## Root layout

| Directory    | Purpose |
|-------------|--------|
| `apps/`     | Frontend applications (mobile & web) |
| `backend/`  | Shared NestJS API and Prisma |
| `packages/` | Shared libraries (api-client, shared-types, shared-ui) |
| `docs/`     | Documentation (shared, gemura, orora) |
| `scripts/`  | Automation (shared, gemura, orora) |
| `docker/`    | Docker Compose and Nginx configs |
| `database/` | Database dumps / reference files |

## Apps (`apps/`)

- **gemura-mobile** – Flutter app; `lib/` with `core/`, `features/`, `shared/`. Feature folders: `snake_case` (Dart convention).
- **gemura-web** – Next.js app; `app/` (routes), `lib/` (api, config, services). Routes and folders: **kebab-case**; components: **PascalCase**.
- **orora-web** – Next.js app; same conventions as gemura-web; adds animals, farms, locations.
- **orora-mobile** – Placeholder for future Flutter app (see `apps/orora-mobile/README.md`).

## Backend (`backend/`)

- **src/** – NestJS source: `main.ts`, `app.module.ts`, `common/`, `migration/`, `modules/`, `prisma/`.
- **src/modules/** – One folder per feature; **kebab-case** (e.g. `api-keys`, `inventory-items`). Each has `*.module.ts`, `*.controller.ts`, `*.service.ts`, `dto/` (kebab-case DTOs).
- **prisma/** – Schema and migrations at `backend/prisma/` (not under `src`). Migrations are timestamped (e.g. `20260301000000_add_orora_locations_and_farms`).

## Documentation (`docs/`)

- **Naming:** All doc filenames use **kebab-case** (e.g. `migration-plan.md`, `deployment-guide.md`). `README.md` stays as-is per directory.
- **Layout:**
  - `docs/shared/` – API, architecture, backend, deployment, migration, testing, project, archive.
  - `docs/gemura/` – `mobile/`, `web/` (app-specific).
  - `docs/orora/` – Orora platform docs (architecture, api, deployment, features, etc.).

## Scripts (`scripts/`)

- **Layout:** `shared/`, `gemura/`, `orora/` with subfolders (e.g. `deployment/`, `migration/`, `db/`, `testing/`).
- **Naming:** Scripts and configs use **kebab-case** (e.g. `deploy-orora-web.sh`, `migrate-accounts-remote-pg.sh`).

## Numbering

- **Migrations:** Prisma migrations use timestamps; no extra numbering.
- **Docs:** Ordered by directory and optional numbered index in READMEs (e.g. “1. Getting started”, “2. Deployment”) rather than `01-`-prefixed filenames unless a clear sequence is required.
- **Backend modules:** No numeric prefixes; alphabetical or feature-grouped is sufficient.

## References

- Project rules: `.cursorrules`
- Doc organization details: `docs/shared/documentation-organization.md`
- Main doc index: `docs/README.md`
