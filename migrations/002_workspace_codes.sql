BEGIN;
ALTER TABLE organizations ADD COLUMN IF NOT EXISTS code text;
UPDATE organizations SET code='ORG-' || upper(substr(replace(id::text,'-',''),1,8)) WHERE code IS NULL OR btrim(code)='';
ALTER TABLE organizations ALTER COLUMN code SET NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS organizations_code_unique_idx ON organizations(upper(code));
COMMIT;
