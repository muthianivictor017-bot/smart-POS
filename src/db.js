const { Pool } = require('pg');
const config = require('./config');
const pool = new Pool({connectionString:config.DATABASE_URL,ssl:config.NODE_ENV==='production'?{rejectUnauthorized:false}:false,max:20,idleTimeoutMillis:30000,connectionTimeoutMillis:5000});
pool.on('error',err=>console.error('Unexpected PostgreSQL error',err));
async function transaction(fn){const client=await pool.connect();try{await client.query('BEGIN');const result=await fn(client);await client.query('COMMIT');return result}catch(err){await client.query('ROLLBACK');throw err}finally{client.release()}}
module.exports={pool,query:(text,params)=>pool.query(text,params),transaction};
