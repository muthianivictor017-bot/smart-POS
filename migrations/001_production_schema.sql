BEGIN;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS organizations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), name text NOT NULL,
  kra_pin text, currency char(3) NOT NULL DEFAULT 'KES', timezone text NOT NULL DEFAULT 'Africa/Nairobi',
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS locations (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES organizations(id),
  code text NOT NULL, name text NOT NULL, address text, active boolean NOT NULL DEFAULT true,
  UNIQUE(organization_id, code)
);
CREATE TABLE IF NOT EXISTS users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES organizations(id),
  name text NOT NULL, email text NOT NULL, password_hash text NOT NULL,
  role text NOT NULL CHECK(role IN ('cashier','supervisor','manager','accountant','admin')),
  active boolean NOT NULL DEFAULT true, token_version integer NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(organization_id,email)
);
CREATE TABLE IF NOT EXISTS registers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), location_id uuid NOT NULL REFERENCES locations(id), code text NOT NULL,
  active boolean NOT NULL DEFAULT true, UNIQUE(location_id,code)
);
CREATE TABLE IF NOT EXISTS shifts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), register_id uuid NOT NULL REFERENCES registers(id), user_id uuid NOT NULL REFERENCES users(id),
  opened_at timestamptz NOT NULL DEFAULT now(), closed_at timestamptz, opening_float numeric(14,2) NOT NULL DEFAULT 0,
  expected_cash numeric(14,2), counted_cash numeric(14,2), variance numeric(14,2), status text NOT NULL DEFAULT 'open' CHECK(status IN ('open','closed'))
);
CREATE UNIQUE INDEX IF NOT EXISTS one_open_shift_per_register ON shifts(register_id) WHERE status='open';

CREATE TABLE IF NOT EXISTS products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES organizations(id),
  sku text NOT NULL, barcode text, plu text, name text NOT NULL, category text, unit text NOT NULL DEFAULT 'each' CHECK(unit IN ('each','kg','litre')),
  sell_price numeric(14,2) NOT NULL CHECK(sell_price>=0), cost_price numeric(14,2) NOT NULL DEFAULT 0 CHECK(cost_price>=0),
  tax_rate numeric(6,4) NOT NULL DEFAULT .16, reorder_level numeric(14,3) NOT NULL DEFAULT 0,
  active boolean NOT NULL DEFAULT true, version integer NOT NULL DEFAULT 1,
  UNIQUE(organization_id,sku), UNIQUE(organization_id,barcode)
);
CREATE TABLE IF NOT EXISTS stock_batches (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), product_id uuid NOT NULL REFERENCES products(id), location_id uuid NOT NULL REFERENCES locations(id),
  batch_number text NOT NULL, expiry_date date, quantity numeric(14,3) NOT NULL DEFAULT 0 CHECK(quantity>=0),
  unit_cost numeric(14,2) NOT NULL DEFAULT 0, received_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(product_id,location_id,batch_number)
);
CREATE INDEX IF NOT EXISTS stock_batch_fifo_idx ON stock_batches(product_id,location_id,expiry_date,received_at) WHERE quantity>0;

CREATE TABLE IF NOT EXISTS customers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES organizations(id),
  name text NOT NULL, phone text NOT NULL, email text, loyalty_points integer NOT NULL DEFAULT 0 CHECK(loyalty_points>=0),
  store_credit numeric(14,2) NOT NULL DEFAULT 0 CHECK(store_credit>=0), created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(organization_id,phone)
);
CREATE TABLE IF NOT EXISTS sales (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES organizations(id), location_id uuid NOT NULL REFERENCES locations(id),
  register_id uuid REFERENCES registers(id), shift_id uuid REFERENCES shifts(id), customer_id uuid REFERENCES customers(id),
  receipt_number bigint GENERATED ALWAYS AS IDENTITY, status text NOT NULL CHECK(status IN ('pending','completed','held','refunded','part_refunded','voided')),
  subtotal numeric(14,2) NOT NULL, discount numeric(14,2) NOT NULL DEFAULT 0, tax numeric(14,2) NOT NULL, total numeric(14,2) NOT NULL,
  created_by uuid NOT NULL REFERENCES users(id), completed_at timestamptz, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS sale_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), sale_id uuid NOT NULL REFERENCES sales(id), product_id uuid NOT NULL REFERENCES products(id),
  description text NOT NULL, quantity numeric(14,3) NOT NULL CHECK(quantity>0), unit_price numeric(14,2) NOT NULL,
  discount numeric(14,2) NOT NULL DEFAULT 0, tax numeric(14,2) NOT NULL, line_total numeric(14,2) NOT NULL
);
CREATE TABLE IF NOT EXISTS payments (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), sale_id uuid NOT NULL REFERENCES sales(id),
  method text NOT NULL CHECK(method IN ('cash','card','mobile_wallet','voucher','store_credit')),
  amount numeric(14,2) NOT NULL CHECK(amount>0), status text NOT NULL CHECK(status IN ('pending','confirmed','failed','refunded')),
  provider text, provider_reference text, metadata jsonb NOT NULL DEFAULT '{}', created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(provider,provider_reference)
);
CREATE TABLE IF NOT EXISTS refunds (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), sale_id uuid NOT NULL REFERENCES sales(id), amount numeric(14,2) NOT NULL CHECK(amount>0),
  reason text NOT NULL, approved_by uuid NOT NULL REFERENCES users(id), created_by uuid NOT NULL REFERENCES users(id), created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS stock_movements (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES organizations(id), product_id uuid NOT NULL REFERENCES products(id),
  location_id uuid NOT NULL REFERENCES locations(id), batch_id uuid REFERENCES stock_batches(id),
  movement_type text NOT NULL CHECK(movement_type IN ('sale','refund','receipt','transfer_in','transfer_out','waste','damage','adjustment')),
  quantity numeric(14,3) NOT NULL, reference_type text NOT NULL, reference_id uuid NOT NULL,
  reason text, created_by uuid NOT NULL REFERENCES users(id), created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS accounts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES organizations(id), code text NOT NULL,
  name text NOT NULL, type text NOT NULL CHECK(type IN ('asset','liability','equity','revenue','expense','cogs')),
  active boolean NOT NULL DEFAULT true, UNIQUE(organization_id,code)
);
CREATE TABLE IF NOT EXISTS journal_entries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES organizations(id), entry_number bigint GENERATED ALWAYS AS IDENTITY,
  entry_date date NOT NULL DEFAULT CURRENT_DATE, description text NOT NULL, source_type text NOT NULL, source_id uuid NOT NULL,
  posted_by uuid NOT NULL REFERENCES users(id), posted_at timestamptz NOT NULL DEFAULT now(), reversed_by uuid REFERENCES journal_entries(id)
);
CREATE TABLE IF NOT EXISTS journal_lines (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), journal_entry_id uuid NOT NULL REFERENCES journal_entries(id), account_id uuid NOT NULL REFERENCES accounts(id),
  debit numeric(14,2) NOT NULL DEFAULT 0 CHECK(debit>=0), credit numeric(14,2) NOT NULL DEFAULT 0 CHECK(credit>=0),
  CHECK ((debit>0 AND credit=0) OR (credit>0 AND debit=0))
);
CREATE TABLE IF NOT EXISTS expenses (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES organizations(id), expense_number bigint GENERATED ALWAYS AS IDENTITY,
  merchant text NOT NULL, category text NOT NULL, amount numeric(14,2) NOT NULL CHECK(amount>0), tax_amount numeric(14,2) NOT NULL DEFAULT 0,
  expense_date date NOT NULL, payment_account_id uuid REFERENCES accounts(id), expense_account_id uuid NOT NULL REFERENCES accounts(id),
  reference text, receipt_url text, status text NOT NULL CHECK(status IN ('draft','pending','approved','paid','rejected')),
  created_by uuid NOT NULL REFERENCES users(id), approved_by uuid REFERENCES users(id), journal_entry_id uuid REFERENCES journal_entries(id),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS audit_log (
  id bigserial PRIMARY KEY, organization_id uuid NOT NULL REFERENCES organizations(id), actor_id uuid REFERENCES users(id),
  action text NOT NULL, entity_type text NOT NULL, entity_id text NOT NULL, before_data jsonb, after_data jsonb,
  ip inet, user_agent text, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS idempotency_keys (
  organization_id uuid NOT NULL REFERENCES organizations(id), key text NOT NULL, request_hash text NOT NULL,
  response_code integer, response_body jsonb, created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(organization_id,key)
);
CREATE TABLE IF NOT EXISTS payment_webhook_events (
  provider text NOT NULL, event_id text NOT NULL, payload jsonb NOT NULL, processed_at timestamptz, created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(provider,event_id)
);
CREATE TABLE IF NOT EXISTS outbox_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), organization_id uuid NOT NULL REFERENCES organizations(id),
  event_type text NOT NULL, aggregate_type text NOT NULL, aggregate_id uuid NOT NULL, payload jsonb NOT NULL,
  status text NOT NULL DEFAULT 'pending' CHECK(status IN ('pending','processing','completed','failed')),
  attempts integer NOT NULL DEFAULT 0, next_attempt_at timestamptz NOT NULL DEFAULT now(), last_error text,
  created_at timestamptz NOT NULL DEFAULT now(), processed_at timestamptz
);
CREATE INDEX IF NOT EXISTS outbox_pending_idx ON outbox_events(next_attempt_at) WHERE status IN ('pending','failed');
CREATE TABLE IF NOT EXISTS fiscal_receipts (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(), sale_id uuid NOT NULL UNIQUE REFERENCES sales(id), provider text NOT NULL DEFAULT 'KRA_ETIMS',
  status text NOT NULL CHECK(status IN ('pending','submitted','accepted','rejected')),
  control_unit_invoice_number text, receipt_signature text, request_payload jsonb, response_payload jsonb,
  submitted_at timestamptz, accepted_at timestamptz, created_at timestamptz NOT NULL DEFAULT now()
);

-- Financial and inventory history is append-only. Corrections must use reversals.
CREATE OR REPLACE FUNCTION prevent_mutation() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN RAISE EXCEPTION '% is append-only', TG_TABLE_NAME; END $$;
DROP TRIGGER IF EXISTS journal_entries_immutable ON journal_entries;
CREATE TRIGGER journal_entries_immutable BEFORE UPDATE OR DELETE ON journal_entries FOR EACH ROW EXECUTE FUNCTION prevent_mutation();
DROP TRIGGER IF EXISTS journal_lines_immutable ON journal_lines;
CREATE TRIGGER journal_lines_immutable BEFORE UPDATE OR DELETE ON journal_lines FOR EACH ROW EXECUTE FUNCTION prevent_mutation();
DROP TRIGGER IF EXISTS stock_movements_immutable ON stock_movements;
CREATE TRIGGER stock_movements_immutable BEFORE UPDATE OR DELETE ON stock_movements FOR EACH ROW EXECUTE FUNCTION prevent_mutation();

COMMIT;
