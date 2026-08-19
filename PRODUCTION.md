# Atelier Smart POS — Production deployment

The repository now contains a PostgreSQL-backed API for authenticated, transactional POS and accounting operations. The browser UI still ships with sample catalogue data for evaluation; connect it to the `/api/v1` endpoints before processing live transactions.

## Controls implemented

- PostgreSQL transactions and row locks for checkout and FIFO batch deduction
- Server-authoritative price, tax, discount and payment-total calculations
- Mandatory checkout idempotency keys
- JWT authentication with server-side revocable sessions
- Cashier/supervisor/manager/accountant/admin RBAC and admin user provisioning
- 12-character password complexity, forced temporary-password changes and password rotation
- Five-attempt account lockout with generic login errors to limit account discovery
- Session inventory, remote revocation and security-event audit history
- Invite-code-protected store registration that atomically creates the organization, first location, register, chart of accounts and administrator
- Separate-user expense approval (segregation of duties)
- Append-only stock movements and accounting journals
- Balanced double-entry validation for every journal
- Full refunds with payment reversal, stock return and accounting reversal
- Shift opening, till close, expected cash and variance calculation
- Audit records for login, sale, refund, expense approval and till close
- Trial balance, general ledger, P&L, balance sheet and VAT APIs
- Security headers, body limits, origin allowlist and API/login rate limits
- Health/readiness probes, graceful shutdown and request IDs
- Docker runtime, PostgreSQL health checks and reproducible migrations

## First deployment

```bash
cp .env.example .env
# Set DATABASE_URL, random JWT_SECRET and STORE_REGISTRATION_CODE values,
# CORS_ORIGINS and a strong database password.
docker compose up -d db
npm ci
npm run migrate
SEED_ADMIN_PASSWORD='use-a-password-manager-value' npm run seed
npm start
```

Save the organization, location and register UUIDs printed by the seed command. Do not run the seed command twice in a production organization.

## API flow

1. `POST /api/v1/auth/login`
2. `POST /api/v1/shifts/open`
3. `GET /api/v1/products?locationId=...`
4. `POST /api/v1/sales` with an unpredictable `Idempotency-Key`
5. `POST /api/v1/shifts/:id/close`

Only cash, voucher and store-credit payments can currently be finalized by the checkout API. Card and mobile-wallet transactions must not be enabled until a certified provider adapter verifies payments server-side.

## External integrations requiring deployment credentials/certification

These cannot be made live safely using placeholder credentials:

- **M-Pesa:** Safaricom Daraja production app, shortcode, passkey, callback URL and transaction-status verification.
- **Cards:** a PCI-compliant hosted terminal/gateway. Never send raw card details to this server.
- **KRA eTIMS:** taxpayer certificate, device registration and approved OSCU/VSCU integration.
- **Scales/printers/cash drawers:** a signed local hardware bridge for the exact device models. The browser should communicate only with that bridge; do not expose serial/USB devices publicly.
- **Digital receipts:** consented SMS/email provider accounts and opt-out handling.

Keep these features disabled until provider certification and end-to-end reconciliation tests pass.

## Required operating procedures

- Run PostgreSQL with encrypted storage and TLS.
- Take encrypted daily backups and continuously archive WAL; perform restore drills quarterly.
- Put the app behind a TLS reverse proxy or managed load balancer.
- Rotate JWT and provider secrets through a secret manager—not `.env` files in Git.
- Restrict database access to the application network.
- Export immutable audit logs to external retention storage.
- Monitor 5xx rates, payment callback failures, stock-negative attempts, till variances and backup age.
- Reconcile bank, M-Pesa and card settlement accounts daily.
- Test refunds, network interruption, duplicate requests and recovery before launch.
- Have a Kenyan accountant validate the chart of accounts and VAT/eTIMS treatment.

## Backups

Example logical backup:

```bash
pg_dump --format=custom --no-owner "$DATABASE_URL" > smartpos-$(date +%F).dump
pg_restore --clean --if-exists --no-owner --dbname="$RESTORE_DATABASE_URL" smartpos-YYYY-MM-DD.dump
```

Store backups outside the application host. A backup is not considered valid until a restore test succeeds.
