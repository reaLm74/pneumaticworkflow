FROM node:18-bookworm-slim

LABEL org.opencontainers.image.title="Pneumatic web client" \
      org.opencontainers.image.source="https://github.com/pneumaticapp/pneumaticworkflow/frontend" \
      org.opencontainers.image.url="https://www.pneumatic.app" \
      org.opencontainers.image.authors="support@pneumatic.app" \
      org.opencontainers.image.vendor="Pneumatic Software Inc." \
      org.opencontainers.image.documentation="https://github.com/pneumaticapp/pneumaticworkflow/wiki" \
      org.opencontainers.image.licenses="Apache-2.0"

# ===== Build =====

# Install pm2
RUN apt-get update && \
    apt-get install -y sudo curl nano && \
    rm -rf /var/lib/apt/lists/* && \
    npm install pm2 -g

WORKDIR /pneumatic_frontend
ADD package-lock.json /pneumatic_frontend/package-lock.json
ADD package.json /pneumatic_frontend/package.json
RUN npm ci --legacy-peer-deps

ADD . /pneumatic_frontend/

# Build client-side assets (webpack production)
RUN NODE_ENV=production npm run build-client:prod

# ===== Runtime environment (override via Railway Dashboard) =====
ENV NODE_ENV=production \
    SIGNUP=yes \
    BILLING=no \
    CAPTCHA=no \
    GOOGLE_AUTH=no \
    MS_AUTH=no \
    SSO_AUTH=no \
    BACKEND_URL=http://localhost:8000 \
    WSS_URL=ws://localhost:8000

CMD ["pm2-runtime", "start", "pm2.json"]
