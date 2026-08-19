const { z } = require('zod');

const schema = z.object({
  NODE_ENV: z.enum(['development','test','production']).default('development'),
  PORT: z.coerce.number().int().positive().default(3000),
  DATABASE_URL: z.string().min(1).default('postgres://smartpos:smartpos@localhost:5432/smartpos'),
  JWT_SECRET: z.string().min(32).default('development-only-secret-change-me-000000'),
  JWT_ISSUER: z.string().default('atelier-pos'),
  CORS_ORIGINS: z.string().default(''),
  PAYMENT_WEBHOOK_SECRET: z.string().default(''),
  TRUST_PROXY: z.enum(['true','false']).default('false')
});
const parsed=schema.safeParse(process.env);
if(!parsed.success) throw new Error(`Invalid environment: ${parsed.error.message}`);
if(parsed.data.NODE_ENV==='production'&&parsed.data.JWT_SECRET.startsWith('development-')) throw new Error('JWT_SECRET must be changed in production');
module.exports={...parsed.data,TRUST_PROXY:parsed.data.TRUST_PROXY==='true',CORS_ORIGINS:parsed.data.CORS_ORIGINS.split(',').map(x=>x.trim()).filter(Boolean)};
