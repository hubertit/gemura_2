# Backend Dockerfile - NestJS Application
FROM node:20-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
# Use legacy-peer-deps to avoid peer dependency resolution failures on production builds
# (matches ResolveIt deployment behavior)
RUN npm ci --legacy-peer-deps

# Generate Prisma Client
RUN npx prisma generate

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Build the application
RUN npm run build

# Production image, copy all the files and run the app
FROM base AS runner
WORKDIR /app

ENV NODE_ENV=production

# Don't run as root
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nestjs

# Copy necessary files
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma

# Set ownership
RUN chown -R nestjs:nodejs /app

USER nestjs

EXPOSE 3004

# Health check (uses PORT env variable, defaults to 3004)
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD sh -c 'node -e "const port = process.env.PORT || \"3004\"; require(\"http\").get(\"http://localhost:\" + port + \"/api/health\", (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"'

CMD ["node", "dist/src/main.js"]

