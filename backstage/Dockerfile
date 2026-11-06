# syntax=docker/dockerfile:1

#### Stage 1: scaffold ########################################################
# Generates a fresh Backstage app using the official scaffolder. The CLI
# prompts interactively for an app name, so we pipe it via stdin to make the
# build fully non-interactive (see README for context on this workaround).
FROM node:22-bookworm-slim AS scaffold

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 make g++ git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN echo "backstage" | npx --yes @backstage/create-app@latest --path /app --skip-install

#### Stage 2: dependencies #####################################################
FROM node:22-bookworm-slim AS deps

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 make g++ git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=scaffold /app /app

RUN yarn install --network-timeout 600000

#### Stage 3: runtime ##########################################################
FROM node:22-bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 make g++ git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=deps /app /app

ENV HOST=0.0.0.0
EXPOSE 3000 7007

CMD ["yarn", "start"]
