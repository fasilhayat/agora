# Rebuttal: Agora Proves the "Standard Tooling" Alternative Works

> Companion to [`openapi-tooling-decision.md`](openapi-tooling-decision.md).
> That document records Company X's decision to build a custom
> "Integration Contract Studio" instead of using standard components,
> partly on the claim that "no tool on the market can deliver this
> workflow." This repo (Agora) is a working counter-example, using a real
> external service - **Tiwaz** (`repos/tiwaz`, a live .NET Bonds Management
> API) - as the proof case, not a toy.
>
> See [`../START-HERE.md`](../START-HERE.md) for the full doc index, and
> [`implementation-roadmap.md`](implementation-roadmap.md) for where to
> start building this for real.

## The claim being tested

From the decision doc's "Decision" section:

> No tool on the market can deliver this workflow. Commercial tools focus
> on generic API design and do not integrate with \[our] data governance,
> standards and internal data sources.

And from Colleague B's review comment:

> The Company X-specific parts (validation rules, data governance
> definitions) can be delivered as rulesets and APIs/MCPs that work with
> standard tools... I suggest the AD adds a standard alternative without
> SwaggerHub (Git + PR review + Spectral + standard editor + governance
> API/MCP).

That is exactly what Agora is. Everything below maps the Target State
requirements and the "only a custom tool can do this" claims to a
component in this repo, with Tiwaz as the live, non-hypothetical test.

## Component-by-component mapping

| Target State requirement | Standard component used here | Where |
|---|---|---|
| Usable by non-developers | Swagger Editor (real open-source tool, run as-is, not emulated) | `docker-compose.yml` service `swagger-editor`, port 8082 |
| Integrate with governed data definitions | `$ref` into a shared-schema registry | `governance/shared-models.yaml`, consumed via `$ref` (see `apis/sample-orders-api/openapi.yaml`) |
| Integrate with API standards | Spectral custom ruleset, generic + repo-specific rules | `governance/.spectral.yaml` |
| Must support Contract First | Design-first authoring in Swagger Editor against a Git-tracked `openapi.yaml`, nothing deployed first | `apis/sample-orders-api/` |
| Integrate well with GitHub | Git repo is the source of truth; PRs are the review mechanism (no webhook relay, no opaque SaaS push) | this repo itself |
| Validation in both pipeline and dev tools | Same `.spectral.yaml` ruleset runnable via `docker run stoplight/spectral` locally **and** in CI | `CONTRACT-FIRST.md` Step 3 (local) / Step 4 (CI) |
| Flexible, developer's-choice tooling | Source of truth is plain YAML/JSON in Git - any IDE works (VS Code, Swagger Editor, CLI) | no lock-in anywhere in this repo |
| Catalog / discoverability for non-developers | Backstage developer portal, real tool not an emulation, with API docs plugin out of the box | `backstage/`, catalog UI at :3000 |

Only one piece of this stack is acknowledged as an emulation at all - the
`governance` nginx container standing in for a commercial data-governance
SaaS (Collibra/DataGalaxy) that can't be run locally (see README.md "Why
some components are emulated and others aren't"). The editor, the
validator, the portal, and Git/GitHub are **not emulated - they are the
real tools**, run as-is.

## Tiwaz as the non-hypothetical proof

The decision doc's strongest argument for the custom tool was that
commercial/standard tooling "does not integrate with \[our] data
governance, standards and internal data sources." Agora tests this
against a real, already-deployed service instead of a greenfield demo:

1. **Pulled the real contract** from Tiwaz's live Swagger endpoint
   (`https://tiwaz.hayatnet.local/swagger/v1/swagger.json`) - no code
   changes to Tiwaz, no special access, just `curl`.
2. **Cataloged it** in Backstage via a standard `type: url` catalog
   location - the same mechanism used for the hand-authored sample API.
3. **Linted it against the governance ruleset**, with the stock
   `spectral:oas` ruleset as a baseline comparison:

   | Ruleset | Problems found |
   |---|---|
   | Stock `spectral:oas` only | 49 (0 errors, 49 warnings) |
   | Agora's `governance/.spectral.yaml` | 95 (33 errors, 62 warnings) |

   This is a real, reproducible run (documented in `CONTRACT-FIRST.md`,
   2026-11-08), not a projection. It surfaced concrete governance gaps in
   a production service: no `servers` entry, no `operationId` on any of 18
   operations, no operation descriptions, enum schemas (`BondType`,
   `RedemptionType`) exposed as bare integers with no documented meaning,
   and every response described as just `"OK"`.
4. **Defined the CI gate** that would enforce this going forward
   (`CONTRACT-FIRST.md` Step 4) - inserted after build, before the Docker
   image is pushed, using the *exact same* `.spectral.yaml` file used
   locally. One ruleset, two enforcement points, satisfying the "validation
   in both pipeline and dev tools" requirement directly.

None of this required forking an editor, building an MCP server, or
committing to 5-7 MM/year of ongoing maintenance. The governance-specific
value - the custom validation rules and the shared schema definitions -
lives in two small, plain-text files (`governance/.spectral.yaml`,
`governance/shared-models.yaml`) that any standard tool can consume.

## Answering the specific "cons" raised against Alternative 1

| Con raised against standard tooling | Answer, demonstrated in this repo |
|---|---|
| "Built-in validation rules feature may not support all desired validations" | Spectral isn't SwaggerHub's built-in rules engine - it's a general-purpose linter with a fully custom DSL (`governance/.spectral.yaml` rules like `governed-versioned-paths`, `governed-no-generic-responses`). Arbitrary custom logic is supported today. |
| "Deep integration with custom \[company] services not possible" | The governance data source here is just an HTTP-served YAML file (`governance/shared-models.yaml`) that any OpenAPI tool can `$ref`. A real internal data-governance API would be consumed the same way - no vendor plugin needed. |
| "Difficult to track who committed changes in Git, integration is via webhook" | There is no webhook in this design - Git **is** the source of truth, so every change has a normal commit author and PR history. This con is specific to SwaggerHub's push-via-webhook model, not to standard tooling in general. |
| "Ongoing license cost" | Swagger Editor, Spectral, Backstage, and Git/GitHub are all open-source/already-licensed. Zero incremental license cost. |
| "Cannot integrate well with custom tools/APIs like data governance" | Directly disproved by the Tiwaz case study pulling a real governance ruleset against a real production contract and getting real, actionable findings. |

## What this doesn't claim

This repo does **not** currently replicate the "AI drafts new data
definitions, Data Governance approves them" submission workflow described
in the decision doc's strengthened argument. That piece (a small
approval-queue service in front of the shared-schema registry) is
additional scope, but it is naturally an **API/service to build**, not a
reason to also own the editor - it would sit alongside
`governance/shared-models.yaml` as another HTTP-served endpoint that
standard tools consume via `$ref`/MCP, following the same pattern already
proven here.

## Bottom line

Agora is a working, Git-native, Contract-First pipeline built entirely
from standard, unmodified components (Swagger Editor, Spectral, Backstage,
Git/GitHub), validated against a real production API (Tiwaz) rather than
a synthetic example. It directly contradicts "no tool on the market can
deliver this workflow" - the workflow doesn't require a market tool to
deliver the *whole* thing, because governance-as-code (`.spectral.yaml`)
and governed-schema-as-data (`shared-models.yaml`) are enough to make
standard tools behave exactly like the proposed custom one, at a fraction
of the \~5-7 MM/year estimated ongoing cost of Alternative 2.
