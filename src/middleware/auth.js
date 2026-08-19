const jwt=require('jsonwebtoken');const db=require('../db');
const config=require('../config');const {AppError}=require('./error');
async function authenticate(req,_res,next){const token=req.headers.authorization?.replace(/^Bearer\s+/i,'');if(!token)return next(new AppError(401,'Authentication required','AUTH_REQUIRED'));try{const claims=jwt.verify(token,config.JWT_SECRET,{issuer:config.JWT_ISSUER,algorithms:['HS256']});const {rows:[user]}=await db.query('SELECT active,token_version,role FROM users WHERE id=$1 AND organization_id=$2',[claims.sub,claims.organizationId]);if(!user?.active||user.token_version!==claims.tokenVersion)throw new Error('revoked');req.user={...claims,role:user.role};next()}catch{return next(new AppError(401,'Invalid, expired or revoked session','INVALID_TOKEN'))}}
const permit=(...roles)=>(req,_res,next)=>roles.includes(req.user?.role)?next():next(new AppError(403,'You do not have permission for this action','FORBIDDEN'));
module.exports={authenticate,permit};
