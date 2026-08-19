const router=require('express').Router();const db=require('../db');const {authenticate,permit}=require('../middleware/auth');
router.use(authenticate,permit('manager','accountant','admin'));
router.get('/',async(req,res,next)=>{try{const limit=Math.min(Math.max(Number(req.query.limit)||100,1),500);const {rows}=await db.query(`SELECT al.*,u.name actor_name FROM audit_log al LEFT JOIN users u ON u.id=al.actor_id WHERE al.organization_id=$1 ORDER BY al.created_at DESC LIMIT $2`,[req.user.organizationId,limit]);res.json({data:rows})}catch(e){next(e)}});module.exports=router;
