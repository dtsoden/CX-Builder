# Optimized Flowise Dockerfile - Multi-stage to avoid chown layer bloat
# Based on official: https://github.com/FlowiseAI/Flowise/blob/main/Dockerfile
#
# OPTIMIZATION: The single-stage build creates a 2.9GB duplicate layer when
# running chown -R. This multi-stage approach uses COPY --chown to set
# ownership during copy, avoiding the duplicate layer.
#
# Rollback: git checkout 3fa8ac4 -- template_versions/v3.0.12-customized/Dockerfile

# =============================================================================
# Stage 1: Builder - Full build (identical to original single-stage)
# =============================================================================
FROM node:20-alpine AS builder

# Install system dependencies and build tools
RUN apk update && \
    apk add --no-cache \
        libc6-compat \
        python3 \
        make \
        g++ \
        build-base \
        cairo-dev \
        pango-dev \
        chromium \
        curl && \
    npm install -g pnpm

ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV NODE_OPTIONS=--max-old-space-size=8192

WORKDIR /usr/src/flowise

# Copy app source
COPY . .

# Install dependencies and build (identical to original)
RUN pnpm install && \
    pnpm build

# =============================================================================
# Stage 2: Runtime - Copy with ownership set (avoids chown layer)
# =============================================================================
FROM node:20-alpine

# Install runtime dependencies only (no build tools needed)
RUN apk add --no-cache \
        libc6-compat \
        chromium \
        curl && \
    npm install -g pnpm

ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV NODE_OPTIONS=--max-old-space-size=4096

WORKDIR /usr/src/flowise

# Copy entire built application with correct ownership (avoids 2.9GB chown layer)
COPY --from=builder --chown=node:node /usr/src/flowise /usr/src/flowise

# Create .flowise directory for uploads and data
RUN mkdir -p /home/node/.flowise && chown -R node:node /home/node/.flowise

# Switch to non-root user
USER node

EXPOSE 3000

CMD [ "pnpm", "start" ]
