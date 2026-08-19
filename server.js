const app=require('./src/app');const config=require('./src/config');const {pool}=require('./src/db');
const server=app.listen(config.PORT,'0.0.0.0',()=>console.log(`Atelier Smart POS listening on port ${config.PORT}`));
async function shutdown(signal){console.log(`${signal} received; shutting down`);server.close(async()=>{await pool.end();process.exit(0)});setTimeout(()=>process.exit(1),10_000).unref()}
process.on('SIGTERM',()=>shutdown('SIGTERM'));process.on('SIGINT',()=>shutdown('SIGINT'));
