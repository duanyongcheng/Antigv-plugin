# --- 基础阶段 (Base Stage) ---
# 定义一个基础阶段，包含通用的Node.js环境。
# 使用Alpine版本来保持镜像小巧。node:20-alpine是一个很好的现代选择。
# 确保这个基础镜像支持您需要的所有架构（官方镜像都支持）。
FROM node:20-alpine AS base

# 设置工作目录
WORKDIR /usr/src/app


# --- 依赖阶段 (Dependencies Stage) ---
# 这个阶段专门用于安装生产环境的依赖。
FROM base AS dependencies

# 复制 package.json 和 package-lock.json (或 yarn.lock, pnpm-lock.yaml)
# 这样做可以充分利用Docker的层缓存。只要这些文件不改变，就不需要重新安装依赖。
COPY package.json package-lock.json* ./

# 安装生产环境依赖
RUN npm install --omit=dev


# --- 源码阶段 (Source Stage) ---
# 纯 JavaScript 项目无需构建，直接复制源码。
FROM base AS source

# 复制项目源代码
COPY src ./src
COPY package.json ./


# --- 生产/运行阶段 (Production/Runtime Stage) ---
# 这是最终的镜像，它将非常轻量。
FROM base AS production

# 设置环境变量，表明这是生产环境
ENV NODE_ENV=production

# 从“依赖阶段”复制生产环境的 node_modules
COPY --from=dependencies /usr/src/app/node_modules ./node_modules

# 从"源码阶段"复制源代码
COPY --from=source /usr/src/app/src ./src
COPY --from=source /usr/src/app/package.json ./

# 创建一个非root用户来运行应用，以增强安全性。
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# 将工作目录的所有权交给新用户
RUN chown -R appuser:appgroup /usr/src/app/src /usr/src/app/node_modules /usr/src/app/package.json

# 切换到这个非root用户
USER appuser

# 暴露您的应用程序正在监听的端口。请务必修改为您的实际端口。
EXPOSE 8046

# 定义容器启动时执行的命令
CMD [ "node", "src/server/index.js" ]
