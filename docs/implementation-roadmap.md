# Implementation Roadmap: Where to Start

> Answers "where do we start building this for real" - what Collibra's
> (`governance/shared-models.yaml` stand-in) actual role is, what feeds the
> CI pipeline, and the build order that delivers value earliest.
> Background: [`openapi-tooling-decision.md`](openapi-tooling-decision.md)
> and [`standard-tooling-rebuttal.md`](standard-tooling-rebuttal.md).

## Two different artifacts, two different owners

It's tempting to assume the data-governance platform (Collibra/DataGalaxy,
emulated here by `governance/shared-models.yaml`) is "where contracts come
from" and feeds the CI pipeline directly. It isn't. Two distinct artifacts
flow through this pipeline, with different owners and different roles:

| Artifact | Owner | Lives in | Role |
|---|---|---|---|
| **Governed data definitions** (e.g. `Customer`, `BondType`) | Data Governance | `governance/shared-models.yaml` (Collibra stand-in) | Reusable schema *fragments*, `$ref`'d by contracts. Not itself an API contract. |
| **API contract** (`openapi.yaml` / `openapi.json`) | The API team (e.g. Tiwaz, Orders team) | The API's own repo (mirrored here under `apis/`) | The thing that actually gets linted in CI and deployed/cataloged. |

Collibra never goes near the CI pipeline directly. **CI always lints the
API contract file**, which happens to `$ref` into a Collibra-published
schema at author time:

```yaml
customer:
  $ref: 'http://.../shared-models.yaml#/components/schemas/Customer'
```

By the time CI lints the contract, that `$ref` is just a URL string in
YAML - Spectral doesn't need to resolve it to check contract-level rules
like versioned paths, `operationId`s, or descriptions (see
`governance/.spectral.yaml`). Resolving the `$ref` to validate the
*referenced schema's* shape is a nice-to-have layered on later, not a
starting requirement.

## Build order

Each step below is independently useful - you get real value before the
whole pipeline is finished, and later steps don't block on earlier ones
being "done," just started.

1. **Spectral ruleset + CI gate, first.** Needs zero Collibra/governance
   integration. Already proved value against a real service with zero
   dependencies: see the Tiwaz lint run in
   [`CONTRACT-FIRST.md`](../CONTRACT-FIRST.md) (33 errors / 62 warnings
   found, vs. 0 errors from stock `spectral:oas`). Highest ROI, lowest
   dependency - do this before anything else.
2. **Contract repo convention.** Decide where each service's
   `openapi.yaml`/`openapi.json` lives (hand-authored, or generated from
   code like Tiwaz's Swashbuckle output) and get it published as a CI
   artifact. This is a prerequisite for step 1 running anywhere for real,
   beyond the one-off manual snapshot used in the Tiwaz case study.
3. **Shared-schema publishing (the Collibra piece).** Expose governed data
   definitions as a static, versioned, HTTP-reachable OpenAPI/JSON-Schema
   file(s) that contracts can `$ref` - an export/sync job from the real
   governance platform into this format. Doesn't require changing Collibra
   itself. Start with the handful of fields people get wrong most often
   today (customer, money/currency, dates), not a full data model.
4. **Catalog (Backstage) last.** Discoverability on top of artifacts that
   already exist from steps 1-3, not a dependency of them.
5. **Governance approval workflow** (AI drafts a new definition, Data
   Governance approves it) is a later layer on top of step 3 - a small
   queue/API in front of the schema publisher. Not needed before steps 1-3
   deliver value; don't let it block starting.

## Practical first move

Pick one real, already-deployed service - Tiwaz is the proof case already
used here - and do steps 1 and 2 against it this week:

- Vendor `governance/.spectral.yaml` into the service's own repo.
- Add the CI lint step shown in `CONTRACT-FIRST.md` Step 4.
- Get it failing/passing on real pull requests.

That's demonstrable progress without waiting on any governance-platform
integration, and it's the same evidence basis used in
[`standard-tooling-rebuttal.md`](standard-tooling-rebuttal.md).
