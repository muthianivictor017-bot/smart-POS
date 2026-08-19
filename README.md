# Atelier Smart POS

Retail checkout, inventory, expenses and double-entry accounting application for multi-location stores.

## Run the interface

```bash
npm ci
npm start
```

Open `http://localhost:3000`. The interface uses demonstration data until authenticated API integration is configured.

## Production API

The API requires PostgreSQL:

```bash
cp .env.example .env
npm run migrate
SEED_ADMIN_PASSWORD='a-strong-unique-password' npm run seed
npm start
npm test
```

See [PRODUCTION.md](PRODUCTION.md) for deployment controls, operating procedures, integration constraints and launch requirements.

## API modules

- `/api/v1/auth` — secure login, logout, session identity and password changes
- `/api/v1/security` — user provisioning, roles, lockouts, sessions and security summary
- `/api/v1/products` — location inventory, barcode/PLU search and alerts
- `/api/v1/shifts` — register opening, closing and till variance
- `/api/v1/sales` — idempotent atomic checkout and controlled refunds
- `/api/v1/expenses` — capture and independent approval
- `/api/v1/accounting` — journals, ledger, trial balance, statements and VAT
- `/api/v1/audit` — role-protected audit history
- `/health` and `/ready` — runtime and database probes
