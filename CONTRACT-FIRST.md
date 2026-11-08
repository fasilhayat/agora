# Contract-First / Design-First Practice

> See [START-HERE.md](START-HERE.md) for the full doc index.

This doc captures the practice Agora is meant to demonstrate: design REST API
contracts before writing code, govern them with shared schemas + lint rules,
catalog them centrally, and gate CI on contract quality - and it uses a real
external service, **Tiwaz** (`repos/tiwaz`, a .NET Bonds Management API
deployed at `https://tiwaz.hayatnet.local/swagger`), as the worked example.

> **Scope note:** Tiwaz's own repository and CI pipeline were **not**
> modified as part of this. Everything below lives in Agora: a mirrored
> snapshot of Tiwaz's real contract, a governance ruleset, and an illustrative
> CI snippet. If a team wants to actually adopt the CI gate in their own repo,
> they copy the ruleset and pipeline steps into *their* repo deliberately.

## The pieces

| Piece | Location | Purpose |
|-------|----------|---------|
| Shared schemas | `governance/shared-models.yaml` | Common types (e.g. `Customer`) that multiple contracts `$ref` instead of redefining. |
| Lint ruleset | `governance/.spectral.yaml` | The governance gate: Spectral rules every contract should pass before merge/deploy. |
| Draft contract | `apis/sample-orders-api/` | A contract authored from scratch in Swagger Editor, `$ref`-ing shared schemas - the "design-first, nothing exists yet" case. |
| Real contract snapshot | `apis/tiwaz-bonds-api/` | A point-in-time mirror of an **already-deployed** service's contract, pulled from its live Swagger JSON - the "bring an existing API into governance" case. |
| Catalog | `backstage/app-config.local.yaml` → `catalog.locations` | Registers both contracts so they show up in the Backstage API catalog/docs. |

## Case study: bringing Tiwaz into governance

Tiwaz (`Bonds Management API`, see `repos/tiwaz/README.md`) is a real, deployed
.NET 8 service. Its CI (`repos/tiwaz/.github/workflows/ci.yml`) currently does
`restore → build → test → dotnet-format → publish → docker build/push`, and
its CD (`cd.yml`) deploys to a Proxmox-hosted Docker host. **Neither pipeline
currently validates the OpenAPI contract itself** - only the code.

### Step 1 - pull the real contract

```powershell
curl --noproxy '*' -k -L -o apis/tiwaz-bonds-api/openapi.json `
  https://tiwaz.hayatnet.local/swagger/v1/swagger.json
```

The downloaded spec is committed as a static snapshot in
`apis/tiwaz-bonds-api/openapi.json` (Tiwaz uses Swashbuckle's in-process
generation, gated to `Development`/`LocalDev`/`Test` environments in
`Tiwaz.Api/MiddlewareExtensions.cs` - there is no standalone spec file in that
repo today, so a snapshot is the only way to catalog it without re-deploying).

### Step 2 - catalog it

`apis/tiwaz-bonds-api/catalog-info.yaml` registers it as a Backstage `API`
entity (`owner: treasury`, `lifecycle: production`), linking back to the live
Swagger UI. Registered via `type: url` in `backstage/app-config.local.yaml`,
same pattern as `sample-orders-api` (see GUIDE.md's "Adding a new API
contract" section for why `type: url` is required, not `type: file`).

### Step 3 - lint it against the governance ruleset (verified results)

Run locally with no Node.js install required:

```powershell
docker run --rm -v "${PWD}:/tmp/work" stoplight/spectral lint `
  /tmp/work/apis/tiwaz-bonds-api/openapi.json `
  --ruleset /tmp/work/governance/.spectral.yaml
```

This was actually run against the live contract pulled on 2026-11-08. Results:

| Ruleset | Problems found |
|---|---|
| Stock `spectral:oas` only | 49 (0 errors, 49 warnings) |
| Agora's `governance/.spectral.yaml` | 95 (33 errors, 62 warnings) |

The governance ruleset promotes `oas3-api-servers`, `operation-operationId`,
`operation-tags`, and `info-contact`/`info-description` from warning to
**error**, and adds repo-specific rules:

- `governed-operation-description` (error) - every operation needs a description.
- `governed-versioned-paths` (error) - every path must start with `/v{n}/` (Tiwaz already does this - 0 violations).
- `governed-schema-description` (warn) - every schema should document what it represents.
- `governed-no-generic-responses` (warn) - responses shouldn't just say "OK".

Real gaps this surfaced in Tiwaz's actual contract: no `servers` entry, no
`operationId` on any of the 18 operations, no operation descriptions, enum
schemas (`BondType`, `RedemptionType`, etc.) exposed as bare integers with no
description of what each value means, and every response documented as just
`"OK"`. These are exactly the kind of things that break generated SDKs and
confuse API consumers, and exactly what a CI gate is for.

### Step 4 - the CI gate (illustrative, not applied to Tiwaz)

If/when this is adopted in `tiwaz/.github/workflows/ci.yml`, it would look
like this, inserted after the `dotnet publish` step and before the Docker
build so a failing contract never gets an image pushed:

```yaml
- name: Generate OpenAPI spec from the built app
  run: |
    dotnet tool install -g Swashbuckle.AspNetCore.Cli --version 9.0.1
    ASPNETCORE_ENVIRONMENT=Test dotnet swagger tofile \
      --output ./openapi/tiwaz-bonds-api.json ./publish/Tiwaz.Api.dll v1

- name: Lint OpenAPI contract
  run: |
    docker run --rm -v "${{ github.workspace }}:/tmp/work" stoplight/spectral lint \
      /tmp/work/openapi/tiwaz-bonds-api.json --ruleset /tmp/work/.spectral.yaml \
      --fail-severity=error

- name: Upload OpenAPI contract artifact
  uses: actions/upload-artifact@v4
  with:
    name: openapi-contract
    path: ./openapi/tiwaz-bonds-api.json
```

(`.spectral.yaml` here would be a copy of `governance/.spectral.yaml` vendored
into the Tiwaz repo - keep them in sync by hand, or promote the ruleset to its
own small shared repo later if more services adopt it.)

## Keeping the snapshot current

`apis/tiwaz-bonds-api/openapi.json` is a snapshot, not a live proxy - it will
drift from the real service as Tiwaz's contract changes. Re-run the `curl`
command in Step 1 whenever you want to re-validate against the current
deployed contract. Automating this (e.g. Tiwaz's own CI publishing the spec
artifact somewhere Agora/Backstage can pull from) is the natural next step
once/if the CI gate above is adopted for real.
