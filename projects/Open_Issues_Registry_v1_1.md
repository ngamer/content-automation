# Open Issues Registry
## Risepoint Content Automation Program — Projects 1, 2, and 3

**Version:** 1.1
**Date:** March 29, 2026
**Owner:** Noah Gamer, AI Enablement for Digital Experience
**Purpose:** Single-source-of-truth for every blocking issue, open question, and pending decision across all three projects. All issues must be resolved or formally deferred before the AI Engineer begins building.

**Change from v1.0:** KI-02 (Article Refresh Workflow version mismatch) resolved and moved to archive. KI-01 reclassified from CRITICAL/blocking to pre-automation prerequisite — risk applies to automation builds, not current manual operations. OC-2 (schema references Article Refresh Workflow v2.1) noted as covered by KI-02 resolution.

---

## How to Use This Document

Issues are organized by severity: blocking (must resolve before any build work in affected area), high (must resolve before pilot), and medium (must resolve before production). Each issue includes the specific action required and who owns it.

Update this document whenever an issue is resolved. Add new issues as they are discovered. This is a living registry — not a snapshot.

---

## BLOCKING ISSUES — Must Resolve Before Build Work Begins

### KI-01 — Content Cluster Analysis v3.2 Output Field Names Unverified

**Severity:** PRE-AUTOMATION PREREQUISITE (reclassified from CRITICAL — not blocking current manual operations)
**Affects:** Connections C1, C2, C5 — the three connections that originate from the Content Cluster Analysis prompt and fan out to the Content Gap Analysis prompt, Content Creation Workflow Phase 0D (Topic Prioritization), and the Article Refresh Identification prompt respectively. Also affects schema parser design for any table that receives Content Cluster Analysis output.

**What the problem is:** The Content Cluster Analysis v3.2 prompt file uses plain-language labeled fields in a freeform block structure — not named YAML keys. The translation maps in WorkflowConfig v1.9 for Connections C1, C2, and C5 use snake_case semantic descriptors that describe the intent of those fields rather than exact key-matched field names. Human operators act as the translator and this works correctly in the current manual workflow. However, any automated agent that attempts to extract fields by name from Content Cluster Analysis output will fail silently — the field names in the config do not match what the prompt actually outputs verbatim.

**Why it matters for automation:** An automated connection reading field names from the config and extracting accordingly will produce empty handoff blocks with no error thrown. This is the workflow entry point — every orchestrated run begins at the Content Cluster Analysis prompt. Bad data at the entry point propagates to every downstream step.

**Additional finding:** The C5 translation map is missing the `Draft content flagged as poor fit` field from the Content Cluster Analysis v3.2 handoff template. Low impact (the Article Refresh Identification prompt handles only published articles) but should be added to the C5 translation map in a future WorkflowConfig update.

**Action required:** Before the Databricks automation layer is built, a formal field-name schema must be added to WorkflowConfig that maps Content Cluster Analysis output fields to machine-parseable identifiers. This is a one-session task — bring Content Cluster Analysis v3.2 into a session and produce the schema against the actual prompt output structure.
**Estimated time:** 30–60 minutes.
**Owner:** Noah Gamer (provide file) → Claude (produce field-name schema)
**Status:** Open — pre-automation prerequisite. Not blocking current manual operations.

---

### Q8 — Execution Environment Decision Unresolved

**Severity:** BLOCKING for Tool Services Layer addendum finalization
**Affects:** Project 2 Addendum (Tool Services Layer), Phase 0 of build sequence, all agent build decisions involving Playwright and the docx skill

**What the problem is:** The Project 2 architecture does not specify whether agents run on Claude Code on a VM/server or via Databricks API calls. The Tool Services Layer addendum defines three services (URL Verification Service, Document Generation Service, Orchestration Runtime Service) that have different implementation paths depending on which environment is chosen. This decision must be made before Phase 0 of the build sequence, which is the prerequisite gate for Phase 1.

**Options:**
- Option A: Claude Code on VM/server — Playwright and Node.js install natively, easier to debug, harder to scale beyond ~10 concurrent articles
- Option B: Databricks + Anthropic API — native horizontal scaling, Playwright requires Python port, docx skill requires port or subprocess
- Option C (recommended): Hybrid — Claude Code for pilot (Weeks 1–20), port to Databricks after pilot validates agent logic. Agent system prompts and WorkflowConfig are unchanged by the port.

**Action required:** Formally accept Option C or choose an alternative. Update the Tool Services Layer addendum to remove DRAFT status and incorporate it as Section 11 of the Project 2 architecture document.
**Owner:** Noah Gamer (accept or modify recommendation)
**Status:** Open — Option C is recommended but not formally accepted

---

### Schema A/B — Problem Scope Boundary Not Formally Accepted

**Severity:** BLOCKING for AI Engineer schema build
**Affects:** Project 3 database build, SQL schema scope

**What the problem is:** The Project 3 scoping document describes a Topic Intelligence Database (Problem A) with approximately 5 tables covering topic records, performance history, cluster health, qualification scores, and cannibalization mapping. The SQL schema v2.1 committed to GitHub covers 64 tables across 11 schemas — incorporating both Problem A (topic intelligence, pre-production planning) and Problem B (production intelligence, operational telemetry from gate-level pass/fail data, citation maps, RPS component scores, artifact tracking). The AI Engineer cannot build the correct schema without a formal decision on which scope to build.

**Action required:** Produce a one-page Schema Scope Decision memo answering: (1) Should the initial build cover Problem A only, Problem B only, or both? (2) What is the recommended phasing if both are in scope? Recommendation is to build Problem A tables in Phase 1 and Problem B tables in Phase 2, with clear table ownership between the two problems documented in the schema header.
**Owner:** Noah Gamer
**Status:** Open

---

## HIGH PRIORITY — Must Resolve Before Pilot Begins

### Q3 — Atlassian Plan Tier Confirmation

**Severity:** HIGH
**Affects:** Jira pipeline project creation, shared workflow scheme availability across 85+ university projects

**What the problem is:** Company-managed Jira projects with shared workflow schemes are required for the pipeline (confirmed March 23 session). Shared workflow schemes allow the same status sequences and transition rules to be applied consistently across all 85+ university-specific Jira projects without configuring each individually. Shared workflow schemes require a specific Atlassian plan tier. The current tier has not been confirmed as supporting this feature.

**Action required:** Confirm IT/Jira admin email response from March 23. If response not received, follow up. If current tier does not support shared workflow schemes, escalate plan tier decision before Jira pipeline project creation begins.
**Owner:** Noah Gamer (follow up with IT/Jira admin)
**Status:** Pending — email sent March 23, response unknown

---

### Q4 — Viability Scoring Formula Not Accepted

**Severity:** HIGH
**Affects:** Project 3 database maintenance skill, qualification scores table, all recommended action logic

**What the problem is:** The database maintenance skill calculates a Topic Viability Score (0–10) for every topic record and attaches a recommended action (Write New / Refresh / Retire / Hold / Monitor). The proposed formula weights: prior article performance in same program (40%), keyword difficulty relative to program authority (30%), gap opportunity size (20%), recency of similar content (10%). This formula has not been reviewed or accepted by SEO leadership. The maintenance skill cannot be built without an accepted formula.

**Action required:** Schedule a review of the proposed formula with SEO leadership. Accept, modify, or replace. Document the accepted formula in the Project 3 technical scope document.
**Owner:** Noah Gamer + SEO leadership
**Status:** Open

---

### Q5 — Databricks SQL MCP Permission Scope

**Severity:** HIGH
**Affects:** 90-Day Review Agent (Project 2), Project 3 database read/write operations

**What the problem is:** The post-publish 90-Day Review Agent queries Google Search Console data and Databricks analytics data. The Project 3 database lives in Databricks Unity Catalog. Confirm that the Databricks SQL MCP connection has SELECT and INSERT/UPDATE access to the relevant tables in the GenAI workspace, and that Google Search Console property permissions cover all 85+ university domains.

**Action required:** IT/Systems to confirm Databricks SQL MCP permission scope. Test a write operation against the GenAI workspace using the current MCP connection.
**Owner:** IT/Systems
**Status:** Open

---

### Q9 — Python Playwright Availability in Databricks

**Severity:** HIGH (conditional on Q8 resolving to Option B or C)
**Affects:** URL Verification Service (Tool Services Layer, Service 1) in Databricks environment

**What the problem is:** If Databricks is the production execution environment (Option B or C from Q8), the URL Verification Service requires Python Playwright installed on Databricks cluster nodes via an initialization script. Some Databricks cluster configurations do not support browser automation packages.

**Action required:** IT/Systems to confirm whether Python Playwright can be installed on Databricks cluster nodes via an initialization script. Test on the GenAI workspace cluster before Phase 0 begins.
**Owner:** IT/Systems
**Status:** Open — conditional on Q8

---

### Q11 — Anthropic API Egress from Databricks

**Severity:** HIGH (conditional on Q8 resolving to Option B or C)
**Affects:** All agent execution in Databricks environment

**What the problem is:** If Databricks API is the production execution environment (Option B or C), agents must make outbound HTTPS calls to api.anthropic.com. Enterprise Databricks environments frequently have egress restrictions that block outbound API calls to external services.

**Action required:** IT/Systems to confirm that the Databricks workspace can make outbound HTTPS calls to api.anthropic.com. If egress restrictions exist, determine the process for whitelisting the Anthropic API endpoint.
**Owner:** IT/Systems
**Status:** Open — conditional on Q8

---

### Q12 — Tool Services Layer Service Ownership

**Severity:** HIGH
**Affects:** URL Verification Service and Document Generation Service production uptime

**What the problem is:** The AI Engineer builds the Tool Services Layer. Once built, the services require monitoring and maintenance for production uptime. Who owns this infrastructure is not defined.

**Action required:** Agree on ownership split: AI Engineer owns build and deployment; IT/Systems or DevOps owns infrastructure provisioning and uptime monitoring. Document in CLAUDE.md once confirmed.
**Owner:** Noah Gamer + IT/Systems + AI Engineer hire
**Status:** Open

---

## MEDIUM PRIORITY — Must Resolve Before Production Deployment

### Q1 — Portfolio Scope for Project 3 Initial Population

**Severity:** MEDIUM
**Affects:** Project 3 initial population timeline (2-week vs. 8-week job)

**What the problem is:** The Project 3 executive summary recommends starting with the top 20 programs and expanding quarterly, rather than attempting all 85+ university domains at once. This decision has not been formally confirmed.

**Action required:** Confirm whether initial population covers top 20 programs or full 85+ portfolio. Document decision in Project 3 technical scope document.
**Owner:** Noah Gamer + SEO leadership
**Status:** Open — top 20 is the documented recommendation

---

### Q2 — Google Search Console Property Access Coverage

**Severity:** MEDIUM
**Affects:** Project 3 weekly performance refresh, 90-Day Review Agent

**What the problem is:** The weekly performance refresh queries Google Search Console for all published article URLs. If the Google Search Console MCP connection does not have read access to all 85+ university domain properties, the performance refresh will be incomplete.

**Action required:** Confirm which Google Search Console properties the current connection has access to. If not all 85+ domains, determine the process for adding missing properties.
**Owner:** Noah Gamer + IT/Systems
**Status:** Open

---

### Q6 — Existing Article Refresh Identification Workbook Consolidation Decision

**Severity:** MEDIUM
**Affects:** Project 3 initial population — seed data strategy

**What the problem is:** Multiple Article Refresh Identification workbooks exist for different programs and dates (confirmed fixtures: Florida Institute of Technology MBA General, Arkansas State University MSN Nurse Admin). A decision is needed on whether to import all existing workbooks as seed data or start fresh with a Google Search Console-only baseline.

**Action required:** Decision: import existing Article Refresh Identification workbooks as seed data (faster, richer starting state) or Google Search Console-only baseline (cleaner, more consistent). Recommendation: import existing workbooks for confirmed fixture programs; Google Search Console-only for all others.
**Owner:** Noah Gamer
**Status:** Open

---

### Q7 — Module 0 Automated Topic Selection Acceptance

**Severity:** MEDIUM
**Affects:** Project 2 Spec Agent design for Route D articles (Ideate Then Create)

**What the problem is:** Project 2 Section 4.2 notes that Route D automated topic selection deviates from Project 1's human-in-the-loop design. In the full automation path, the highest CTA-potential-scoring topic from Module 0's Top 5 is selected automatically. This trade-off requires explicit acceptance from editorial and SEO leadership before the Spec Agent is built with automated topic selection.

**Action required:** Editorial and SEO leadership to explicitly accept or reject automated topic selection for Route D. If rejected, Route D must retain a human selection step even in the Project 2 full automation path.
**Owner:** Noah Gamer + editorial leadership + SEO leadership
**Status:** Open

---

### Q13 — Tool Services Layer Service Failure Handling

**Severity:** MEDIUM
**Affects:** Agent behavior when URL Verification Service or Document Generation Service fails

**What the problem is:** If the URL Verification Service returns an error or times out mid-pipeline, the agent's fallback behavior is not defined. Options: retry up to N times, fall back to web_fetch only, halt and flag to Needs Attention status.

**Action required:** AI Engineer to define default failure handling behavior for each service. Document in CLAUDE.md as part of the Failure Handling section.
**Owner:** AI Engineer hire (with input from Noah Gamer)
**Status:** Open — depends on AI Engineer hire

---

### Project 1 Sign-Off — Three Stakeholders Required

**Severity:** MEDIUM
**Affects:** Project 1 execution

**What the problem is:** Project 1 requires sign-off from three roles before deliverables begin: SEO Leadership (automation roadmap alignment), Content Operations Leadership (checklist and template design), Editorial Team Lead (90-day tracking protocol commitment). These conversations have not happened.

**Action required:** Schedule sign-off conversations. Provide the Project 1 Editorial Interface design document as the primary brief.
**Owner:** Noah Gamer
**Status:** Open

---

### Project 2 Sign-Off — Four Stakeholders Required

**Severity:** MEDIUM (conditional on AI Engineer hire)
**Affects:** Project 2 execution

**What the problem is:** Project 2 requires sign-off from four roles: Noah Gamer, AI Engineer hire, Editorial Lead, IT/Systems. Cannot be completed until hire is identified. IT/Systems questions (Q3, Q5, Q9, Q11) can be pre-answered before the hire arrives.

**Action required:** Pre-answer IT/Systems questions while hire search is in progress. Schedule sign-off once hire is identified.
**Owner:** Noah Gamer
**Status:** Blocked on hire

---

## Pre-Phase 4 Issues — Content Orchestration Schema (Must Resolve Before Parser Build)

These issues were identified in the March 23 technical review of the SQL schema. They must be resolved before the Phase 4 parser build begins.

| # | Issue | Detail | Owner |
|---|---|---|---|
| OC-1 | Table count discrepancy | Schema header states 64 tables; markdown schema counts 75. Must reconcile before Phase 4. | AI Engineer |
| OC-2 | Article Refresh Workflow version in schema | Schema references Article Refresh Workflow v2.1; live file is v2.5. Gate structure in step5_refresh tables must be verified against v2.5. Covered by KI-02 resolution — WorkflowConfig v1.9 now correctly registers v2.5. Schema tables still need updating. | AI Engineer |
| OC-3 | intelligence.competitor_content population path | Population path is ambiguous — conflates two distinct DataForSEO endpoints. Clarify which endpoint populates which fields before parser is written. | AI Engineer |
| OC-4 | Step identifier format | Step identifier format is not standardized for KI-01 blocking logic. Must standardize before KI-01 blocking queries can run correctly. | AI Engineer |
| OC-5 | Article Refresh Identification tab-to-column mapping | Article Refresh Identification Excel tab-to-column mapping is not documented. Parsers for Article Refresh Identification data cannot be written without it. Recommended: add to Order #0 before Phase 1 deployment. | Noah Gamer (provide workbook structure) |

---

## Resolved Issues — Archive

### KI-02 — Article Refresh Workflow Version Mismatch in Config Registry

**Resolved:** March 27, 2026
**Resolved by:** Noah Gamer

**What the problem was:** WorkflowConfig v1.8 Prompt Registry listed the Article Refresh Workflow at version 2.0. The live prompt file was version 2.5 — two versions ahead. Seven architectural changes between v2.0 and v2.5 were undocumented in the config, including two net-new mandatory Gate 1 outputs (Program Mention Audit and Citation Inheritance Map), expanded Gate 2.5 scope, markdown-first Gate 4 output sequence, and a net-new Gate 4.5 for SWA (Semrush Writing Assistant) Optimization.

**Resolution:** WorkflowConfig updated to v1.9. Article Refresh Workflow v2.5 now correctly registered. Gate names, gate descriptions, Connection C6 translation map, Connection C9 routing note, and output artifact fields all updated to reflect v2.5 behavior. Operator Checklist updated to v1.5 and Human Checkpoint Analysis updated to v1.1 to reflect the same changes.

---

## Resolution Log

| Date | Issue | Resolution | Resolved By |
|---|---|---|---|
| March 27, 2026 | KI-02 — Article Refresh Workflow version mismatch | WorkflowConfig updated to v1.9; Article Refresh Workflow v2.5 registered correctly; downstream documents updated | Noah Gamer |

---

*Document version 1.1 — updated March 29, 2026. Previous version: v1.0 dated March 25, 2026.*
*To be committed to `projects/` in github.com/ngamer/workflow-designs.*
