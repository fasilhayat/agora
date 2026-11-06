# Working with Agora - Day-to-Day Guide

This guide covers the practical workflow for running, changing, and verifying
the Agora stack. For the architecture overview, see [README.md](README.md).

## Prerequisites

- Docker Desktop running (Windows: WSL2 backend).
- `make` available (ships with Git Bash / WSL, or use the raw
  `docker compose` commands shown below each `make` target).
- On a network with a corporate HTTP proxy: always verify endpoints with
  `curl --noproxy '*' <url>` (or `make verify`). Proxy-aware tools -
  including PowerShell's `Invoke-WebRequest` - will try to route
  `localhost` through the proxy and hang/timeout.

## Everyday commands

| Task                                   | Command                  |
|-----------------------------------------|--------------------------|
| Start the stack (builds backstage first time) | `make up`          |
| Stop and remove containers              | `make down`              |
| Restart everything                      | `make restart`           |
| Check container status                  | `make ps` / `docker compose ps` |
| Tail all logs                           | `make logs`              |
| Tail just Backstage logs                | `make backstage-logs`    |
| Tail just governance (nginx) logs       | `make governance-logs`   |
| Rebuild the Backstage image (code/dep changes) | `make build`      |
| Rebuild Backstage from scratch (no cache) | `make build-no-cache`  |
| Run the acceptance checks               | `make verify`            |
| Stop + remove containers, volumes, and built images | `make clean`  |

Run `make help` any time for this list from the terminal.

## Typical session

```powershell
cd D:\source\repos\agora
make up            # start governance, swagger-editor, backstage
make ps             # confirm all 3 containers are "Up"
make verify          # confirm all 5 acceptance endpoints return 200
```

Then open:

- http://localhost:8081/shared-models.yaml - governed shared schemas
- http://localhost:8082 - Swagger Editor
- http://localhost:3000 - Backstage catalog UI
- http://localhost:7007/api/catalog/entities - Backstage catalog API (raw JSON)

When done:

```powershell
make down
```

## Adding a new API contract to the catalog

1. Create a new folder under `apis/`, e.g. `apis/my-new-api/`.
2. Add `openapi.yaml` (the contract itself). If it needs shared schemas,
   `$ref` them against the governance server, e.g.:
   ```yaml
   $ref: 'http://localhost:8081/shared-models.yaml#/components/schemas/Customer'
   ```
3. Add `catalog-info.yaml` modeled on
   `apis/sample-orders-api/catalog-info.yaml`:
   - `kind: API`, `spec.type: openapi`
   - `spec.definition` using a `$text: ./openapi.yaml` placeholder (relative
     path, resolved against the catalog location's URL).
4. Register the new location in
   `backstage/app-config.local.yaml` under `catalog.locations`, as a
   **`type: url`** entry pointing through the governance nginx server, e.g.:
   ```yaml
   - type: url
     target: http://governance/apis/my-new-api/catalog-info.yaml
   ```
   Do **not** use `type: file` with an absolute path - see the Gotchas
   section below for why.
5. Restart backstage so it picks up the config change:
   ```powershell
   docker compose restart backstage
   ```
6. Verify: `curl --noproxy '*' http://localhost:7007/api/catalog/entities`
   should list the new API, and it should also render in the Backstage UI
   catalog at http://localhost:3000/catalog.

## Editing governed shared schemas

- Edit `governance/shared-models.yaml` directly - it's served as a static
  file by the `governance` nginx container, so changes take effect
  immediately on refresh (no rebuild needed, nginx just re-reads the file).
- Any `openapi.yaml` that `$ref`s a schema from it will pick up changes on
  the next request (no caching in this nginx config).

## Changing nginx/governance config

- Edit `governance/nginx.conf` (e.g. to change CORS behavior or serving
  paths), then:
  ```powershell
  docker compose restart governance
  ```

## Changing Backstage config

- Edit `backstage/app-config.local.yaml` (it's bind-mounted, not baked into
  the image), then:
  ```powershell
  docker compose restart backstage
  ```
- Only touch `backstage/Dockerfile` if you need to change how the app is
  scaffolded/built (new native deps, different Node version, etc.) - that
  requires `make build` or `make build-no-cache` followed by `make up`.

## Troubleshooting

- **`curl`/browser hangs on localhost**: you're behind a corporate proxy.
  Use `curl.exe --noproxy '*' <url>` instead of PowerShell's
  `Invoke-WebRequest`.
- **Backstage catalog API/UI unreachable from the host**: confirm
  `app-config.local.yaml` still has `app.listen.host: 0.0.0.0` and
  `backend.listen.host: 0.0.0.0`. The `HOST` env var does **not** work for
  the Backstage CLI dev server - it only honors the `app.listen.host`
  config key.
- **New/edited API doesn't appear in the catalog**: check
  `docker compose logs backstage` for a resolver error. The most common
  cause is a `catalog.locations` entry using `type: file` with an absolute
  path - Backstage's `$text` placeholder resolver needs a URL-schemed base
  to resolve the relative `./openapi.yaml` ref, which a bare filesystem
  path doesn't provide. Switch it to `type: url` pointing at the
  governance server instead.
- **File rename/move fails with "in use" on Windows**: Docker Desktop can
  hold file locks on bind-mounted directories even after
  `docker compose down` appears to finish. Retry `docker compose down`
  first, or use `robocopy /MOVE` instead of `Rename-Item`/`Move-Item`.
- **Image pull fails for swagger-editor**: some networks block
  `swaggerapi/swagger-editor` directly from Docker Hub - this stack already
  uses the `docker.swagger.io/swaggerapi/swagger-editor` mirror, so this
  shouldn't recur, but if you change the image reference, keep that mirror.

## Full teardown / reset

```powershell
make clean    # docker compose down -v --rmi local
```

This removes containers, volumes, and the locally-built Backstage image.
Next `make up` will rebuild Backstage from scratch (several minutes).
