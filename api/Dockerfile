# 构建阶段
FROM node:18-alpine AS builder

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apk add --no-cache \
    git \
    python3 \
    make \
    g++

# 复制package.json
COPY package.json ./

# 安装所有依赖（包括开发依赖，用于编译）
RUN npm install --no-package-lock && npm cache clean --force

# 复制源代码
COPY . .

# 编译TypeScript
RUN npm run build

# 运行阶段
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 安装curl用于健康检查
RUN apk add --no-cache curl

# 复制package.json
COPY package.json ./

# 只安装生产依赖
RUN npm install --production --no-package-lock && npm cache clean --force

# 从构建阶段复制编译后的代码
COPY --from=builder /app/dist ./dist

# 创建非root用户
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# 更改文件所有权
RUN chown -R nodejs:nodejs /app
USER nodejs

# 暴露端口
EXPOSE 8080

# 健康检查
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# 启动应用
CMD ["node", "dist/index.js"]