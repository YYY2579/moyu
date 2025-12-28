import type { FastifyInstance } from "fastify"
import type { Db } from "../db.js"

export async function registerHealthRoutes(app: FastifyInstance, db: Db): Promise<void> {
  app.get("/health", async () => {
    try {
      // 检查数据库连接
      await db.query("SELECT 1")
      
      return {
        status: "healthy",
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        memory: process.memoryUsage(),
        version: process.env.npm_package_version || "1.0.0"
      }
    } catch (error) {
      app.log.error("Health check failed:", error)
      throw app.httpErrors.serviceUnavailable("Service unavailable")
    }
  })
}