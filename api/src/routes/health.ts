import { Router, Request, Response } from 'express';

const router = Router();

/**
 * 健康检查接口
 */
router.get('/health', (req: Request, res: Response) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'production',
    version: process.env.npm_package_version || '1.0.0'
  });
});

export default router;