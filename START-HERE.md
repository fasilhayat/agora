# Start Here

This repo has grown a few markdown files. This is the index and suggested
reading order - start here, then branch out depending on what you need.

## 1. Run the stack

- [`README.md`](README.md) - what Agora is, which components are real vs.
  emulated, key endpoints, and how to start/stop the stack.
- [`GUIDE.md`](GUIDE.md) - day-to-day commands (`make up`/`down`/`verify`),
  how to add a new API contract, troubleshooting.

## 2. Understand the practice this demonstrates

- [`CONTRACT-FIRST.md`](CONTRACT-FIRST.md) - the Contract-First / governed
  API workflow this stack is meant to prove out: shared schemas, a
  Spectral governance ruleset, and the **Tiwaz** case study (a real,
  already-deployed external service used as the worked example, with
  verified before/after lint results).

## 3. The organizational context (why this repo exists)

- [`docs/openapi-tooling-decision.md`](docs/openapi-tooling-decision.md) -
  the (de-identified) architectural decision record this repo is a
  response to: "Company X" evaluated reusing standard tooling (SwaggerHub +
  custom rules) vs. building a bespoke in-house editor, and chose to build
  custom, partly on the claim that standard tooling can't integrate with
  internal governance/standards/data sources.
- [`docs/standard-tooling-rebuttal.md`](docs/standard-tooling-rebuttal.md) -
  maps every requirement from that decision doc to a standard, unmodified
  component already running in this repo, and answers each "con" raised
  against standard tooling, using the real Tiwaz lint results as evidence.
- [`docs/implementation-roadmap.md`](docs/implementation-roadmap.md) -
  the practical "where do we start" follow-up: clarifies that the
  governance platform (Collibra/DataGalaxy, emulated by
  `governance/shared-models.yaml`) publishes *data definitions* consumed
  via `$ref`, not the API contract itself; CI always lints the contract
  file. Lays out the build order (ruleset+CI gate first, schema publishing
  third, catalog last) and the recommended first concrete move.

## 4. For AI agents / contributors

- [`AGENTS.md`](AGENTS.md) - condensed operational gotchas and pointers for
  anyone (human or agent) making changes to this repo.

## Suggested path depending on your goal

| Goal | Read |
|---|---|
| Just want to run it locally | README.md -> GUIDE.md |
| Understand the governance workflow being demonstrated | CONTRACT-FIRST.md |
| Need the business case / "why not just buy SwaggerHub" argument | docs/openapi-tooling-decision.md -> docs/standard-tooling-rebuttal.md |
| Ready to actually start building this for a real team | docs/implementation-roadmap.md |
| Making changes to this repo (incl. as an AI agent) | AGENTS.md |
