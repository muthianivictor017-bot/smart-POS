process.env.NODE_ENV='test';
const test=require('node:test');const assert=require('node:assert/strict');const request=require('supertest');
const app=require('../src/app');const {pool}=require('../src/db');const {passwordSchema}=require('../src/routes/auth');
test('health endpoint is available',async()=>{const res=await request(app).get('/health').expect(200);assert.equal(res.body.status,'ok');assert.equal(res.body.service,'Atelier Smart POS');assert.ok(res.headers['x-request-id'])});
test('production API endpoints require authentication',async()=>{const res=await request(app).get('/api/v1/products?locationId=11111111-1111-4111-8111-111111111111').expect(401);assert.equal(res.body.error.code,'AUTH_REQUIRED')});
test('unknown API routes return structured errors',async()=>{const res=await request(app).get('/api/v1/missing').expect(404);assert.equal(res.body.error.code,'NOT_FOUND')});
test('password policy rejects weak passwords',()=>{assert.equal(passwordSchema.safeParse('password123').success,false);assert.equal(passwordSchema.safeParse('A-longer!Secure9Password').success,true)});
test('store registration validates input before provisioning',async()=>{const res=await request(app).post('/api/v1/auth/register-store').send({storeName:'A'}).expect(400);assert.equal(res.body.error.code,'VALIDATION_ERROR')});
test.after(async()=>pool.end());
