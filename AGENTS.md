# AGENTS.md

Docker Compose stack for a local API-governance demo (nginx "governance"
registry + Swagger Editor + Backstage portal). No app code to build/test -
this repo is config/docs/compose only.

Full details live in [README.md](README.md) (architecture) and
[GUIDE.md](GUIDE.md) (day-to-day workflow). Read `GUIDE.md` before making
changes - it covers the full edit/restart/verify loop. Highlights:

## Commands
- `make up` / `make down` / `make restart` - manage the stack
- `make build` / `make build-no-cache` - rebuild the Backstage image (needed after editing `backstage/Dockerfile`)
- `make verify` - curl all 5 acceptance endpoints, expect 200s
- `make logs` / `make backstage-logs` / `make governance-logs`
- `make clean` - full teardown incl. volumes and built images
- No `make`? Run the equivalent raw `docker compose ...` commands shown in GUIDE.md.

## Critical gotchas
- **Proxy**: always verify with `curl --noproxy '*' <url>`, never PowerShell
  `Invoke-WebRequest` - proxy-aware tools route `localhost` through a
  corporate proxy and hang.
- **Backstage config is bind-mounted** (`backstage/app-config.local.yaml`),
  not baked into the image - just `docker compose restart backstage` after
  editing it. Only the `Dockerfile` requires a rebuild (`make build`).
- **Catalog locations must be `type: url`**, not `type: file` - Backstage's
  `$text` placeholder resolver needs a URL-schemed base to resolve relative
  `./openapi.yaml` refs; a bare filesystem path breaks it silently (check
  `docker compose logs backstage` for resolver errors).
- **`HOST` env var does nothing** for the Backstage dev server; host binding
  is controlled only by `app.listen.host` / `backend.listen.host` in
  `app-config.local.yaml` (must stay `0.0.0.0` for host access).
- **`governance/shared-models.yaml`** is served directly by nginx - edits
  take effect on refresh, no rebuild/restart needed.
- Swagger Editor image is pinned to `docker.swagger.io/swaggerapi/swagger-editor`
  (not the plain `swaggerapi/...` Docker Hub ref) to dodge a mirror block -
  preserve this if touching `docker-compose.yml`.
- Windows: if a file rename/move fails with "in use" after `docker compose
  down`, Docker Desktop is still holding a lock on the bind mount - retry
  the `down`, or use `robocopy /MOVE` instead of `Rename-Item`/`Move-Item`.

## Adding a new API contract
See "Adding a new API contract to the catalog" in GUIDE.md - requires a new
`apis/<name>/` folder (`openapi.yaml` + `catalog-info.yaml`) and a matching
`type: url` entry in `backstage/app-config.local.yaml`, then
`docker compose restart backstage`.
