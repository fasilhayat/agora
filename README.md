# Agora

> A local marketplace for governed API contracts: a Design-First API
> governance ecosystem in Docker, combining a governed shared-schema
> registry, a contract editor, and a developer portal that catalogs it all.

Mimics a Design-First API governance ecosystem with three containers:

| Component                    | Stand-in for          | URL                                      |
|-------------------------------|------------------------|-------------------------------------------|
| Data Governance (nginx)       | Collibra / DataGalaxy  | http://localhost:8081                     |
| API editor (Swagger Editor)   | Stoplight / SwaggerHub | http://localhost:8082                     |
| Developer portal (Backstage)  | -                       | http://localhost:3000 (frontend)          |
|                                |                         | http://localhost:7007 (backend/API)       |

## Key endpoints

- Shared governed data models: http://localhost:8081/shared-models.yaml
- Draft API contract: http://localhost:8081/apis/sample-orders-api/openapi.yaml
- Swagger Editor: http://localhost:8082
- Backstage catalog UI: http://localhost:3000
- Backstage catalog API (should list `sample-orders-api`): http://localhost:7007/api/catalog/entities

## Usage

```
docker compose up -d      # or: make up
docker compose down       # or: make down
```

A `Makefile` is included with convenience targets (`make up`, `make down`,
`make logs`, `make verify`, etc.) - run `make help` for the full list.

> On networks with a corporate HTTP proxy, verify with
> `curl --noproxy '*' http://localhost:<port>` since proxy-aware tools
> (including PowerShell's `Invoke-WebRequest`) may otherwise try to route
> localhost through the proxy and time out.

## Notes on the Backstage container

- The image is built from `backstage/Dockerfile`, a multi-stage build based
  on `node:22-bookworm-slim` that:
  1. Installs `python3 make g++ git` (required to build native deps like
     `better-sqlite3`, `@swc/core`, `keytar`).
  2. Scaffolds a fresh app with `npx @backstage/create-app@latest`, piping
     the app name (`backstage`) via stdin so the otherwise-interactive
     prompt doesn't block the build.
  3. Runs `yarn install` and starts the app with `yarn start` (dev mode),
     which serves the frontend (webpack/rspack dev server, port 3000) and
     backend (port 7007) together.
- `backstage/app-config.local.yaml` is volume-mounted into the container and
  configures:
  - `app.listen.host` / `backend.listen.host` as `0.0.0.0` so both the
    frontend dev server and backend are reachable from the host (by
    default the Backstage CLI dev server only binds to loopback).
  - `backend.auth.dangerouslyDisableDefaultAuthPolicy: true` so the catalog
    API can be queried without a session token (local-dev convenience).
  - `backend.reading.allow` to permit the backend's URL reader to fetch
    from the `governance` container.
  - `catalog.locations` registering `sample-orders-api` via a `type: url`
    location pointing at `http://governance/apis/sample-orders-api/catalog-info.yaml`
    (the `apis/` folder is served by the `governance` nginx container, and
    is also bind-mounted read-only into the Backstage container at
    `/app/apis` for completeness). A `type: file` location with a plain
    absolute path does **not** work here: Backstage's `$text` placeholder
    resolver needs a URL-schemed base to resolve the relative
    `./openapi.yaml` reference in `catalog-info.yaml`, which a bare
    filesystem path doesn't provide - routing through the governance
    server's HTTP URL sidesteps that entirely.
  - The default Backstage app template already ships with
    `@backstage/plugin-api-docs`, so the API's OpenAPI definition renders
    in the catalog out of the box.

## Known pitfalls (and how they're handled here)

- `swaggerapi/swagger-editor` can be blocked on some corporate Docker Hub
  mirrors - this stack pulls `docker.swagger.io/swaggerapi/swagger-editor`
  instead.
- Swagger Editor listens on port 80 inside its container, mapped here as
  `8082:80`.
- The `@backstage/create-app` CLI prompts interactively for an app name;
  the Dockerfile pipes the name through stdin (`echo "backstage" | npx ...`)
  to keep the build non-interactive.
