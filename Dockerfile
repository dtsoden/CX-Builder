# CX-Builder Dockerfile - Multi-stage to avoid chown layer bloat
#
# OPTIMIZATION: The single-stage build creates a 2.9GB duplicate layer when
# running chown -R. This multi-stage approach uses COPY --chown to set
# ownership during copy, avoiding the duplicate layer.

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

WORKDIR /usr/src/cxbuilder

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

WORKDIR /usr/src/cxbuilder

# Copy entire built application with correct ownership (avoids 2.9GB chown layer)
COPY --from=builder --chown=node:node /usr/src/cxbuilder /usr/src/cxbuilder

# Create data directory for uploads and storage
RUN mkdir -p /home/node/.flowise && chown -R node:node /home/node/.flowise

# Switch to non-root user
USER node

EXPOSE 3000

CMD [ "pnpm", "start" ]
