# Apps

Frontend applications for the Orora platform.

## Structure

```
apps/
├── gemura-mobile/     # Gemura Mobile (Flutter)
├── gemura-web/        # Gemura Web (Next.js)
├── orora-mobile/      # Orora Mobile (Flutter) - future
└── orora-web/         # Orora Web (Next.js) - ready
```

## Gemura Apps

Gemura is a dairy/agricultural management app with the following modules:
- Milk Collections
- Milk Sales
- Suppliers/Customers
- Inventory
- Payroll
- Loans
- Finance (Payables/Receivables)

## Orora Apps

Orora includes all Gemura features plus:
- Human Resources (HR)
- Procurement
- Asset Management
- Project Management
- Advanced Reporting
- Multi-branch Management
- And more...

## Running Apps

### Mobile (Flutter)
```bash
cd gemura-mobile  # or orora-mobile
flutter pub get
flutter run
```

### Web (Next.js)
```bash
cd gemura-web  # or orora-web
npm install
npm run dev
```

## Building for Release

### Android APK/AAB
```bash
cd gemura-mobile
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
cd gemura-mobile
flutter build ios --release
```

### Web Production
```bash
cd gemura-web
npm run build
```
