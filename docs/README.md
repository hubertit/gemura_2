# Orora Documentation

Welcome to the Orora project documentation.

## Project Overview

Orora is a comprehensive Cattle Farming Platform built for livestock farmers in Rwanda. It includes web and mobile applications sharing a common backend API.

## Documentation Structure

```
docs/
├── README.md              # This file
│
├── orora/                 # Orora Platform Documentation
│   ├── README.md          # Overview & Quick Start
│   ├── ARCHITECTURE.md    # System Architecture
│   ├── ROADMAP.md         # Development Roadmap
│   ├── FEATURES.md        # Feature Specifications
│   ├── API.md             # API Documentation
│   ├── DATABASE.md        # Database Schema
│   ├── DEPLOYMENT.md      # Deployment Guide
│   └── MOBILE.md          # Mobile App Guide
│
├── gemura/                # Gemura-specific docs (legacy)
│   └── ...
│
└── shared/                # Shared documentation
    └── ...
```

## Quick Links

### Orora Platform

| Document | Description |
|----------|-------------|
| [Overview](./orora/README.md) | Project overview and quick start |
| [Architecture](./orora/ARCHITECTURE.md) | System design and technology stack |
| [Roadmap](./orora/ROADMAP.md) | Development timeline and milestones |
| [Features](./orora/FEATURES.md) | Detailed feature specifications |
| [API](./orora/API.md) | REST API documentation |
| [Database](./orora/DATABASE.md) | Database schema and models |
| [Deployment](./orora/DEPLOYMENT.md) | Deployment and operations guide |
| [Mobile](./orora/MOBILE.md) | Mobile app development guide |

## Project Timeline

| Milestone | Date | Status |
|-----------|------|--------|
| **MVP** | March 15, 2026 | In Progress |
| **Beta** | April 15, 2026 | Planned |
| **v1.0 Release** | June 15, 2026 | Planned |

## Key Features

- **Animal Management** - Register and track individual cattle
- **Milk Collection** - Record daily milk production
- **Health Tracking** - Vaccinations, treatments, vet visits
- **Breeding Management** - Reproduction and calving records
- **Financial Operations** - Payments, loans, payroll
- **Inventory** - Feed, medicine, equipment tracking
- **Analytics** - Reports and data insights

## Platform Components

| Component | Technology | Port |
|-----------|------------|------|
| Orora Web | Next.js | 3011 |
| Orora Mobile | Flutter | - |
| Gemura Web | Next.js | 3006 |
| Backend API | NestJS | 3007 |
| Database | PostgreSQL | 5432 |

## Server

**Production:** 209.74.80.195 (Kwezi Server)

## Repository

https://github.com/hubertit/gemura_2
