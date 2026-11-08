# OpenAPI / Event Contract Tooling — Architectural Decision

> Architectural decision document on OpenAPI / Event-contract tooling.
> All references to the original company name have been replaced with
> **Company X** for use as a de-identified case study.
>
> See [`../START-HERE.md`](../START-HERE.md) for the full doc index, and
> [`standard-tooling-rebuttal.md`](standard-tooling-rebuttal.md) for why
> this repo contradicts the "no standard tool can do this" argument below.

## Current State

The current tooling for developing OpenAPI / Event specifications is a set
of sparsely integrated and/or unsupported tools with limited support for
supporting teams in the design and review process.

- **SwaggerHub**: OpenAPI editor of decent quality but with no support for
  Company X specific requirements/best practices or integration with
  Company X data sources/MCP servers. The tool has good support for
  collaboration and review/commenting functionality. The tool has limited
  support for API specification validations and the tool is not well
  integrated with developers' preferred workflows.
  Good integration with GitHub is supported in the platform but requires a
  level of repository access that is not recommended (and requires approval
  from IT Security). Thus integration is limited to pushing OpenAPI
  specifications from SwaggerHub to GitHub via webhook.
- **Text/file editors**: Developers can use editors like VS Code or even
  Notepad++ to develop API specifications. IDEs can utilize plugins and AI
  tooling like Copilot and MCP servers to develop the API specifications.
  Business Analysts and Developers can also use the unsupported Company X
  OpenAPI Editor (also called the Company X Swagger Editor), which has good
  integration capabilities with Company X specific API design data sources
  and validation requirements. It currently has limited support for data
  governance requirements, and the review/commenting collaboration features
  are not as developed as e.g., SwaggerHub.

The current OpenAPI tooling flow (conceptually):

```
VS Code / Notepad++ / Company X OpenAPI Editor (unsupported)
        |
        v  Edit / Commit / Push
   Git Repository  --(webhook)-->  APIM (Azure API Management)
        |
        v  Package and Deploy (via Artifact Repository)
   Misc. file editors / DB
```

## Target State

The following requirements should be supported:

- Tooling should be usable for non-developers (e.g., business analysts).
- Should integrate well with Company X tools and data sources:
  - Data governance data definitions
  - API standards
  - Existing API definitions
- Must support **Contract First** API design (the selected standard for
  business APIs at Company X — see AD-031 "Contract first vs. code first"
  and the 2026-04-28 Architecture Council minutes).
- Integrate well with GitHub.
- Validations should be available in both the build pipeline and
  development tools.
- *Nice to have*: a flexible API design process where developers can use
  their preferred tools (e.g., an IDE enhanced with custom MCPs).

## Alternative 1 - SwaggerHub with custom OpenAPI validation rules

Reuse the existing SwaggerHub setup, enhanced with Company X specific API
specification validation rules. Recommendations for using standalone
services like Company X MCP servers would be provided, but not integrated
with SwaggerHub directly — those services could only be supported via other
tools (home-built, IDEs, or other).

**Pros**
- COTS - standard solution to a standard problem.
- Supports Contract First.
- In use in a business unit for API specification reviews for the last 8
  years.
- Deterministic validations integrated in the editor.

**Cons**
- Built-in validation rules feature may not be able to support all desired
  kinds of validations in a good/complete way (experience suggests this is
  likely).
- Slow progress on tool improvements/integration capabilities and bugfixes;
  SwaggerHub has not been an optimal vendor partner, and enhancements have
  introduced breaking changes multiple times.
- Deep integration with custom Company X services is not possible.
- Ongoing license cost; high price relative to value.
- Ongoing operations/support cost, estimated at:
  - 1 MM/year (SwaggerHub integration, etc.)
  - 3-4 MM/year for building new functionality like MCP servers.
- Cannot integrate well with Company X's custom tools and APIs (e.g., data
  governance).
- Shadow investment in a custom editor would continue "under the radar."
- Difficult/impossible to track who committed changes in Git, since
  integration is via webhook.

## Alternative 2 - Custom "Integration Contract Studio" with OpenAPI validation and Company X specific API/MCP support

Upgrade the existing "home-built" Company X Swagger/OpenAPI Editor into a
supported tool (rebranded "Integration Contract Studio"). Company X
services/APIs/MCPs, data sources, and AI functionality would be tightly
integrated into the editor; comment/review functionality would be
enhanced; and direct GitHub integration would be developed. The existing
SwaggerHub setup would be decommissioned. The source of truth remains
plain-text YAML files in GitHub, so there is no vendor lock-in — developers
can still use VS Code or other IDEs if preferred.

**Pros**
- Highly tuned/optimized to Company X specific requirements; tools and data
  sources tightly integrated.
- An AI proof-of-concept in the data governance area has already
  demonstrated the benefits of this custom integration.
- Supports Contract First.
- Changes to API definitions can be tracked to a user in Git.
- Developers will, in time, be able to use tooling of their choice (e.g.,
  VS Code), initially via core VS Code OpenAPI functionality, enhanced over
  time with custom features.
- Usable by non-developers.
- No license cost (SwaggerHub license removed).
- Deterministic validations integrated in the editor.
- Preferred by teams (not formally/scientifically verified).
- Easier to include Kafka event topics in the Contract First flow than with
  SwaggerHub.
- Advanced support for the most-used features (editing and compare/diff).
- Home-build is a viable option partly due to improvements in AI; AI
  assisted engineering has proven effective for building such tools.

**Cons**
- Not COTS - not a standard solution to what is argued to be a non-standard
  problem.
- Initial development cost to tightly integrate Company X services/data
  sources (partly already done) and to enhance review/commenting.
- Ongoing maintenance cost, estimated at:
  - 2 MM/year for core OpenAPI editor enhancements.
  - 3 MM/year for developer support (not an added cost — this time is
    already spent today, just currently a hidden cost).
  - 3-4 MM/year for building new functionality like MCP servers.

## Alternative 3 - Market research

Step back and survey available market tools/services (e.g., SwaggerHub,
Postman, Redocly, Apidog, Scalar). It has been some years since SwaggerHub
was selected, and better alternatives may exist.

**Pros**
- COTS - standard solution to a standard problem.
- Lower development and maintenance cost than a home-built tool.

**Cons**
- Time consuming, both in hours spent and calendar time.
- Recent desktop research found low probability of a commercial tool being
  significantly better than SwaggerHub.
- Likely outcome: time spent without finding an alternative where switching
  cost is justified.
- If an alternative is found, significant time would be needed to integrate
  it (plus procurement, etc.).
- Ongoing license cost.

## Decision

The decision is to use **Alternative 2 - custom/home-built tooling**.

Rationale given:
- Highly optimized to Company X specific requirements.
- Short time to market for supporting Company X requirements.
- Great support for non-developer participation in the API/Event design
  process.
- Efficiency gains from enhanced usability.
- Small or no incremental cost (cost shifted from SwaggerHub
  license/management to development).
- Strong support for Contract First (the selected Company X standard for
  business APIs and Events).
- Highest usability score; teams prefer it over SwaggerHub.
- Leads in the most-used features (editor, compare/diff during review).

### Additional argument (added after initial rejection)

> The key requirement is not a better OpenAPI editor, but an integrated
> contract-design workflow for both APIs and Kafka event topics — one that
> makes data governance and integration standards practical to follow.
>
> Designers need to find and reuse approved data definitions, link them to
> API and event fields, and submit proposed new definitions for governance
> approval. AI can help draft new definitions; Data Governance approves
> them.
>
> This moves governance from "spreadsheet governance" to "operational
> governance." Today, governance is largely documented and reported
> separately from the contracts teams actually build, so it has little grip
> on what runs in production. The same applies beyond data — to security
> roles, access rules, and API standards. With governance built into an
> efficient contract-first workflow, it is enforced directly in real APIs
> and events before they are implemented. That allows governing far more, in
> less time than is spent on spreadsheet governance today.
>
> No tool on the market can deliver this workflow. Commercial tools focus on
> generic API design and do not integrate with internal data governance,
> standards, and data sources. Over the last 10 years, the market has been
> repeatedly evaluated, and SmartBear has since acquired the primary
> contender, Stoplight. The latest desktop research found that the best
> alternatives do not close this gap.
>
> Alternative 2 builds on the existing editor and an internal Data
> Governance proof-of-concept, which has already demonstrated the value of
> this workflow.

## Notes / References

- AD-031 - Contract first vs. code first (decision: use contract first for
  business APIs - Architecture Council 2026-04-28 minutes).
- SwaggerHub - home-build or not (outdated; does not account for newer
  home-build editor features).
- Contract First APIs (internal design document, SwaggerHub -> GitHub
  integration).
- Home-build OpenAPI Editor - User Manual.
- Desktop research of commercial solutions indicates that two unnamed
  competitors score ~10% better than SwaggerHub (score 150-158 vs. 143).

### Review comments

**Colleague B (Oct 12, 2026):**
> This decision deviates from the architecture principle "Standard solution
> to standard problem." Designing, validating, reviewing, and versioning
> API/Event contracts is a standard problem with mature standard tooling.
> The company-specific parts (validation rules, data governance definitions)
> can be delivered as rulesets and APIs/MCPs that work with standard tools.
> The arguments against Alternative 1 are mainly about SwaggerHub as a
> vendor, not about standard tooling in general. Before the Architecture
> Council (AC), the AD should (a) add a standard alternative without
> SwaggerHub (Git + PR review + Spectral + standard editor + governance
> API/MCP), (b) explicitly justify the deviation from the principle, and
> (c) include a TCO comparison over 3-5 years.

**Colleague A (Oct 12, 2026):**
> (b) The architecture principle "Standard solution to standard problem"
> needs to be re-evaluated given the changes AI has brought (and will keep
> bringing).
> (a) This is already included in Alternative 2 (and Alternative 1, for
> that matter) — the custom tool does not prevent anyone from using
> Git + pull request + Spectral + ... if that fits their needs. Is the
> suggestion that everyone should use that approach instead?
> (c) See comment in the decision section.
