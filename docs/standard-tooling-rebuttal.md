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

The copied [`standard-tooling-proposal.md`](standard-tooling-proposal.md)
in this directory is a complementary proposal for a broader standard-tooling
target. Its glossary export and reusable CI workflow are not implemented in
Agora; the evidence below is limited to the current local stack and the
explicitly illustrative CI example.

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
| Validation in both pipeline and dev tools | Local Spectral validation is demonstrated; the CI gate is illustrative, not deployed | `CONTRACT-FIRST.md` Step 3 (local) / Step 4 (illustrative) |
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
4. **Sketched the CI gate** that could enforce this going forward
   (`CONTRACT-FIRST.md` Step 4). It is illustrative and has not been applied
   to Tiwaz; it uses the same `.spectral.yaml` as the demonstrated local
   run. This shows a path to two enforcement points, not a deployed CI gate.

The demonstrated work required neither forking an editor nor building an
MCP server. The governance-specific value - custom validation rules and
shared schema definitions - lives in two plain-text files
(`governance/.spectral.yaml`, `governance/shared-models.yaml`) that standard
tools can consume. The decision document estimates 2 MM/year for editor
enhancements and 3-4 MM/year for new functionality such as MCP servers; the
cost of maintaining Agora's proposed reusable workflow and glossary
integration has not been estimated.

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

The copied proposal in
[`standard-tooling-proposal.md`](standard-tooling-proposal.md) sketches a
glossary export and reusable workflow as possible extensions. It is not
evidence that these components exist in Agora; its workflow example should
be reviewed before being adopted.

## Honest caveats: where the "one workflow fits everything" framing breaks

To keep this rebuttal intellectually honest, not every part of the decision
doc's argument is wrong, and it's worth being precise about where the gaps
actually are - because the gaps reveal a bigger problem with their approach
than with standard tooling.

### Gap 1 - AsyncAPI / Kafka event contracts are genuinely weaker in standard tooling today

Swagger Editor is OpenAPI-only. The decision doc's point that "it's easier
to include Event topics in the Contract First flow" with a custom tool than
with SwaggerHub is **not disproved by anything in this repo** - Agora has no
AsyncAPI editing or linting story yet. This is a legitimate, unanswered gap,
not a vendor complaint in disguise like most of their other cons.

### Gap 2 - CDC-derived Kafka schemas don't fit *either* workflow, and that's the real lesson

Push further on the event-contract point and a sharper problem appears:
schemas produced by **CDC connectors** (e.g. Debezium reading a database's
change log) aren't designed by anyone. The event schema is generated
automatically from the source table's column list the moment the table
exists, and changes the moment the table does. There is no human sitting
in an editor - custom or standard - picking governed field definitions and
submitting new ones for approval. **The decision doc's entire proposed
workflow (find/reuse approved definitions -> link to fields -> submit new
ones for governance approval) has nothing to attach to here.**

This matters most for primary/foreign key fields in CDC payloads:

- A CDC-emitted `customer_id: integer` FK is structural/relational plumbing,
  not a business attribute. It doesn't have its own meaning to "define" -
  it's a pointer to the `Customer` entity, not a value of one. Forcing it
  through a rule like `governed-schema-description` (this repo's own
  ruleset, `governance/.spectral.yaml`) either produces a vacuous
  description or fabricates business meaning that isn't there.
- The thing worth governing for an FK is the **relationship** ("this
  event's `customer_id` references the `Customer` entity"), which belongs
  in a data-lineage/ER model, not in the same field-definition catalog as
  `Email` or `BondType`.
- CDC schema change-safety is a **compatibility** problem (backward/forward
  compatible evolution via a real schema registry - Avro/Protobuf/JSON
  Schema compatibility modes), not a **descriptive-linting** problem like
  "every field needs a description." Spectral-style rules are close to
  meaningless against a schema shape dictated by a DBA's table design that
  can change out from under the event contract at any time.

### Why this is actually an argument *for* standard tooling, not against it

This is the important part: **neither** a custom editor **nor** Swagger
Editor solves the CDC/FK case, because it isn't an editor problem at all -
it's a schema-registry-and-lineage problem. The decision doc's mistake is
assuming one integrated workflow (human designs contract -> picks governed
field -> submits for approval) covers every contract-producing scenario in
the company. It doesn't, and building a single monolithic custom tool
around that one workflow **locks out** the scenarios that don't fit the
assumption - CDC/event-sourced schemas being the clearest example, but the
same would apply to any other schema that's generated rather than
hand-designed.

Standard, composable tooling is more resilient to exactly this kind of
scenario precisely *because* it isn't one tool trying to cover every case:

- Spectral + a shared-schema registry handles hand-authored REST contracts
  (proven here against Tiwaz).
- A real schema registry with compatibility-mode enforcement is the correct
  tool for CDC/Kafka payload safety - a separate, already-standard
  component (e.g. Confluent Schema Registry), not something the OpenAPI
  editor needs to also become.
- A lineage/ER layer handles FK/relationship governance, tagging surrogate
  keys as structural rather than forcing them into the business-glossary
  field catalog.

Painting all of this with one brush - "one integrated contract-design tool
for both APIs and events" - trades flexibility for the appearance of
completeness. When a new scenario shows up that doesn't match the assumed
workflow (CDC being a concrete, not hypothetical, example in event-driven
architectures), a monolithic custom tool has to be extended or bent to fit;
a composable standard-tooling stack just adds the missing component
(schema registry, lineage tool) alongside the ones already working, without
having to touch the editor, the ruleset, or the contracts already governed.

## Bottom line

Agora is a local, Git-native proof of Contract-First governance built from
standard components (Swagger Editor, Spectral, Backstage, and Git/GitHub),
validated against a real production API (Tiwaz) rather than a synthetic
example. It challenges "no tool on the market can deliver this workflow"
for the REST/OpenAPI case: the demonstrated governance does not require a
custom editor, while CI enforcement remains a proposed next step. The
workflow doesn't require a market tool to deliver the *whole* thing, because
governance-as-code (`.spectral.yaml`) and governed-schema-as-data
(`shared-models.yaml`) already support the local proof. The source
decision's 5-7 MM/year figure combines editor enhancements and new MCP
functionality; the ongoing cost of the standard-tooling target has not been
estimated, so this evidence does not establish a like-for-like cost saving.

Where real gaps remain (AsyncAPI editing, CDC-derived schema governance),
the fix is to add the missing standard component for that specific
scenario, not to retroactively justify a single monolithic editor as the
answer to every contract-producing scenario in the company. That one-size
assumption is exactly what causes the custom-tool approach to lock out
scenarios it didn't anticipate - the composable, standard-tooling approach
is the more flexible one precisely because it doesn't require every
scenario to fit through the same workflow.
