import Fastify from "fastify"
import cors from "@fastify/cors"
import sensible from "@fastify/sensible"
import { loadEnv } from "./env.js"
import { createDb, pingDb } from "./db.js"
import { seedIfEmpty } from "./seed/seed.js"
import { registerHealthRoutes } from "./routes/health.js"
import { registerQuestionRoutes } from "./routes/questions.js"
import { registerAttemptRoutes } from "./routes/attempts.js"
import { registerDailyRoutes } from "./routes/daily.js"
import { registerCommandRoutes } from "./routes/commands.js"
import { registerDeviceRoutes } from "./routes/devices.js"
import { registerAdminRoutes } from "./routes/admin.js"

const env = loadEnv()
const isProd = process.env.NODE_ENV === "production"

const app = Fastify({
  logger: isProd ? true : {
    transport: {
      target: "pino-pretty",
      options: { translateTime: "SYS:standard", singleLine: true }
    }
  }
})

async function start() {
  try {
    await app.register(cors, { origin: true })
    await app.register(sensible)

    const db = createDb(env)
    app.log.info("Connecting to database...")
    await pingDb(db)
    
    app.log.info("Checking database seed...")
    await seedIfEmpty(db)

    // 统一注册带 /api 前缀的路由
    await app.register(async (api) => {
      await registerHealthRoutes(api, db)
      await registerDeviceRoutes(api, db)
      await registerQuestionRoutes(api, db)
      await registerAttemptRoutes(api, db)
      await registerDailyRoutes(api, db)
      await registerCommandRoutes(api, db)
      await registerAdminRoutes(api, db, env)
    }, { prefix: "/api" })

    app.get("/", async () => ({ ok: true }))
    app.get("/health", async () => {
      try {
        await db.query("SELECT 1")
        return { ok: true, status: "healthy" }
      } catch (error) {
        app.log.error("Health check failed:", error)
        throw app.httpErrors.serviceUnavailable("Service unavailable")
      }
    })

    await app.listen({ port: env.PORT, host: "0.0.0.0" })
    app.log.info(`Server listening on port ${env.PORT}`)
  } catch (err) {
    app.log.error(err)
    process.exit(1)
  }
}

start()
