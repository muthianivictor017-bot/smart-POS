class AppError extends Error{constructor(status,message,code='REQUEST_FAILED'){super(message);this.status=status;this.code=code}}
function notFound(req,res){res.status(404).json({error:{code:'NOT_FOUND',message:`Route ${req.method} ${req.path} was not found`}})}
function errorHandler(err,req,res,_next){const status=err.status||((err.name==='ZodError')?400:500);if(status>=500)console.error(err);res.status(status).json({error:{code:err.code||'INTERNAL_ERROR',message:status>=500?'An unexpected error occurred':err.message,requestId:req.id}})}
module.exports={AppError,notFound,errorHandler};
