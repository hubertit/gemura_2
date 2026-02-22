# Orora - Cattle Farming Platform

> A comprehensive livestock farm management system for cattle farmers in Rwanda

## Overview

Orora is a digital platform designed to help cattle farmers manage their livestock operations efficiently. The platform provides tools for:

- **Animal Management** - Register and track individual cattle
- **Milk Collection** - Record daily milk production and sales
- **Financial Operations** - Manage payments, loans, and payroll
- **Inventory Management** - Track feed, medicine, and farm supplies
- **Analytics & Reporting** - Data-driven insights for better decisions

## Platform Components

| Component | Description | Technology |
|-----------|-------------|------------|
| **Orora Mobile** | Android/iOS app for farmers and collectors | Flutter |
| **Orora Web** | Admin dashboard and management portal | Next.js |
| **Backend API** | Shared API serving all clients | NestJS + PostgreSQL |

## Quick Links

- [Architecture](./architecture.md)
- [Development Roadmap](./roadmap.md)
- [Feature Specifications](./features.md)
- [API Documentation](./api.md)
- [Database Schema](./database.md)
- [Deployment Guide](./deployment.md)
- [Mobile App Guide](./mobile.md)
- [Feedback & Communication Strategy](./feedback-strategy.md)

## Project Timeline

| Milestone | Target Date | Status |
|-----------|-------------|--------|
| Soft Launch | March 15, 2026 | In Progress |
| Beta Release | April 15, 2026 | Planned |
| Production Release | June 15, 2026 | Planned |

## Getting Started

### Prerequisites

- Node.js 18+
- Flutter 3.x
- PostgreSQL 15+
- Docker (for deployment)

### Development Setup

```bash
# Clone repository
git clone https://github.com/hubertit/gemura_2.git orora
cd orora

# Backend setup
cd backend
npm install
cp .env.example .env
npm run start:dev

# Web app setup
cd ../apps/orora-web
npm install
npm run dev

# Mobile app setup
cd ../apps/orora-mobile
flutter pub get
flutter run
```

## Contact

- **Project Lead**: Orora Investment Group
- **Repository**: https://github.com/hubertit/gemura_2
