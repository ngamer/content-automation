# Risepoint Content Automation — Project Status
## Master Content Automation Program: Projects 1, 2, and 3

**Version:** 1.0  
**Date:** March 25, 2026  
**Owner:** Noah Gamer, AI Enablement for Digital Experience  
**Purpose:** Single-source-of-truth status document for all three automation projects and supporting infrastructure. Reflects the state of the project as of the March 25 review session.

---

## Executive Summary

All three projects are pre-build. Scoping and architecture are complete. The primary gap between current state and build-readiness is: (1) several blocking issues unresolved, (2) key artifacts living only in chat history rather than version-controlled files, and (3) a set of open questions that require stakeholder input before the AI Engineer can begin.

The SQL schema (v2.1, 1,748 lines) is the most significant artifact not yet in version control. Getting it committed to GitHub is the single highest-priority action before any build work begins.

---

## Artifact Inventory

### Core Scoping and Architecture Documents — All Complete

| Document | File | Status |
|---|---|---|
| Project 1: Editorial Interface Design | `Project1_EditorialInterface_Risepoint.docx` | Complete |
| Project 2: Full Automation Architecture | `Project2_FullAutomation_Architecture_Risepoint.docx` | Complete |
| Project 2 Addendum: Tool Services Layer | `Project2_Addendum_ToolServicesLayer_DRAFT_Risepoint.docx` | Draft — awaiting Q8 resolution |
| Project 3: Topic Intelligence Database Scope | `Project3_TopicIntelligenceDatabase_Scope_Risepoint.docx` | Complete |
| Project 3: Executive Summary | `Project3_ExecutiveSummary_Risepoint.docx` | Complete |
| Human Checkpoint Analysis v1.0 | `Human_Checkpoint_Analysis_v1.md` | Complete |
| Workflow Risk Assessment v1.0 | `Workflow_Risk_Assessment_v1.md` | Complete |
| Deliverable Completion Protocol v1.0 | `Deliverable_Completion_Protocol_v1.md` | Complete |

### Supporting Research — Complete

| Document | File | Status |
|---|---|---|
| n8n Implementation Guide | `Building_a_Multi-Step_AI_Content_Pipeline_in_n8n.md` | Complete — hybrid architecture recommended |
| Confluence/SharePoint Dual-Publish Analysis | `Automating_Artifact_Delivery_to_Confluence_and_SharePoint.md` | Complete |

### Atlassian POC Taxonomy — Skeleton Complete, Leaf Nodes Pending

| Layer | Count | Status |
|---|---|---|
| Partner pages (A-State, BGSU, FIT) | 3 | Complete |
| Vertical pages | 8 | Complete |
| Area-of-Study pages | 29 | Complete |
| Synthetic test program pages | 3 | Complete (A-State MSN Nurse Admin, FIT MBA General, BGSU MBA General) |
| Glossary page | 1 | Complete |
| Program-level leaf node pages | 187 | Not built |
| Direct-program pages (no Area of Study) | 33 | Not built |

Taxonomy IDs documented in `confluence_taxonomy_id_map.md` and `confluence_taxonomy_ids.json`.

### Artifacts Living in Chat — Must Be Committed to GitHub

| Artifact | Source Session | Priority |
|---|---|---|
| `Content_Orchestration_Schema_v2_1.sql` | March 22 session | CRITICAL — blocking |
| Schema Decision Summary | March 21–22 sessions | High |

---

## Project-by-Project Status

### Project 1 — Editorial Team Interface Design

**Status:** Scoped. Not started.

**What exists:** Complete design specification covering all 20 human checkpoints across both workflow paths, classified as Confirm / Review / Decision types, with automation trajectory documented per checkpoint. Session launch templates, revised Operator Checklist, and Pre-Session Package guides are defined but not yet produced.

**What's needed to start:**
- Sign-off from three stakeholders: SEO Leadership, Content Operations Leadership, Editorial Team Lead
- Decision on which workflow path to pilot first (recommendation in spec: new article path, Entry Point B)

**Deliverables defined:**
- Revised Operator Checklist v2.0 (Week 2)
- Session Launch Templates (Week 2)
- Pre-Session Package Guides (Week 3)
- Confidence Tracking Template (Week 3)
- 90-Day Readiness Report (Week 16)

**Blockers:** None technical. Awaiting leadership sign-off.

---

### Project 2 — Full Content Pipeline Automation

**Status:** Architecture complete. Tool Services Layer addendum drafted. Not started.

**What exists:** Complete 10-section architecture specification covering all 11 agents, Jira schema, Confluence page structure, 20-week build sequence, Atlassian MCP validation test protocol, and post-publish feedback loop design.

**What's needed to start:**
- AI Engineer hire (onboarding requires this document as primary brief)
- Atlassian MCP write operation validation test (6-test protocol defined in Section 5 of spec)
- Resolution of Q8 (execution environment decision) to finalize Tool Services Layer addendum
- IT/Systems answers to Q3, Q5, Q9, Q11 (see Open Issues below)
- Jira admin confirmation that company-managed projects with shared workflow schemes are available on current plan (email sent March 23, response pending)

**Build sequence:** 20 weeks across 7 phases, starting with Pre-Work Assembly Agent against existing A-State MSN Nurse Admin artifacts.

**Blockers:** Q8 (execution environment), Atlassian plan tier confirmation (Q3), AI Engineer hire.

---

### Project 2 Addendum — Tool Services Layer

**Status:** Draft. Not approved for implementation.

**What exists:** Architecture for three services (URL Verification Service wrapping Playwright, Document Generation Service wrapping docx skill, Orchestration Runtime Service) that decouple tool execution from agent execution.

**Blocking question:** Q8 — execution environment decision (Claude Code on VM vs. Databricks API vs. hybrid). The entire addendum forks on this answer. Option C (hybrid) is the documented recommendation.

**Next step:** Once Q8 is accepted, update addendum to remove draft status and incorporate as Section 11 of Project 2 architecture.

---

### Project 3 — Topic Intelligence Database

**Status:** Concept scoping complete. Pre-architecture.

**What exists:** Full scoping document (technical) and executive summary (leadership-facing) covering database platform (Databricks Unity Catalog), table schema (5 core tables), maintenance skill design, initial population plan, and open questions.

**SQL Schema v2.1:** A full 1,748-line schema was produced March 22 covering 64 tables across 11 schemas — significantly expanding the 5-table concept in the scoping document. This represents a scope evolution from Problem A (Topic Intelligence, ~5 tables) to a combined Problem A + Problem B (Production Intelligence, ~64 tables). The A/B scope boundary decision has not been formally accepted.

**What's needed to move to architecture:**
- Commit SQL schema v2.1 to GitHub (CRITICAL)
- Formal acceptance of Problem A vs. Problem B scope (one-page decision memo needed)
- Q1: Portfolio scope for initial population (top 20 programs recommended)
- Q2: GSC property access confirmation across all 85+ domains
- Q3: Databricks schema ownership assignment
- Q4: Viability scoring formula acceptance by SEO leadership
- AI Engineer hire (Project 3 initial population is recommended first assignment)

---

## Jira Pipeline Configuration Status

**March 23 session:** Confirmed that company-managed Kanban projects with shared workflow schemes are the correct Jira project type for the pipeline. Email drafted to IT/Jira admin requesting four specific permissions:
1. Create company-managed projects
2. Create and assign custom workflow schemes
3. Create custom fields
4. Confirm current Atlassian plan tier supports shared workflow schemes across multiple projects

**Status of admin response:** Unknown. Follow up required.

**Why this matters:** The entire Jira pipeline schema — status sequences, agent work queue design, custom field set — cannot be finalized until the plan tier is confirmed. If shared workflow schemes are not available on the current tier, a plan upgrade or alternative architecture is required before any Jira pipeline projects are created.

---

## GitHub Repository Status

**Repo:** github.com/ngamer/workflow-designs  
**Structure:** Domain-organized folders (content, SEO, brand, analytics, paid media, outreach)

**What's committed:** All 6 active prompt files, CHANGELOG.md, DEPENDENCY_MAP.md

**What's NOT committed and should be:**

| Artifact | Target Path | Priority |
|---|---|---|
| `Content_Orchestration_Schema_v2_1.sql` | `/projects/project-3/database/` | CRITICAL |
| `Project_Status_Current_v1.md` (this file) | `/projects/` | High |
| `Open_Issues_Registry_v1.md` | `/projects/` | High |
| `Architecture_Reconciliation_v1.md` | `/projects/project-2/` | High |
| `GitHub_Handoff_v1.md` | `/projects/` | Medium |
| All 8 scoping/architecture .docx files | `/projects/project-1/`, `/projects/project-2/`, `/projects/project-3/` | Medium |
| `confluence_taxonomy_id_map.md` | `/projects/project-2/atlassian/` | Medium |
| `confluence_taxonomy_ids.json` | `/projects/project-2/atlassian/` | Medium |
| n8n implementation guide | `/projects/project-2/research/` | Low |
| Confluence/SharePoint analysis | `/projects/project-2/research/` | Low |

**Known issues tracked in repo:**
- KI-01: CCA1 v3.2 output field names unverified against C1/C2/C5 translation maps
- KI-02: WorkflowConfig Prompt Registry lists ARV20 at v2.0; live file is v2.5

---

## Active Prompt File Versions

| Prompt | Version | Location |
|---|---|---|
| WorkflowConfig | v1.8 | Master Content Workflow project |
| CCW68 (Content Creation Workflow) | v6.8 | Master Content Workflow project |
| ARV20 (Article Refresh Workflow) | v2.5 | Master Content Workflow project |
| ARID14 (Article Refresh Identification) | v1.6 | Master Content Workflow project |
| GAP17 (Content Gap Analysis) | v1.8 | Master Content Workflow project |
| CCA1 (Content Cluster Analysis) | v3.2 | Master Content Workflow project |
| OperatorChecklist | v1.4 | Master Content Workflow project |

**Note on KI-02:** WorkflowConfig v1.8 Prompt Registry lists ARV20 at v2.0. The live file is v2.5 — two versions ahead. The config's C6 and C9 translation maps must be verified against the v2.5 gate structure before any refresh path agent is built.

---

## Key Decisions Made (Documented for AI Engineer Onboarding)

| Decision | What Was Decided | Date |
|---|---|---|
| Database platform | Databricks Unity Catalog, GenAI workspace | March 2026 |
| Orchestration platform (pilot) | n8n Enterprise with hybrid HTTP Request / AI Agent node pattern | March 2026 |
| Jira project type | Company-managed Kanban with shared workflow schemes | March 2026 |
| Execution environment (recommendation) | Option C hybrid: Claude Code for pilot, Databricks API for production | March 2026 (not yet formally accepted) |
| Confluence taxonomy structure | Partner → Vertical → Area of Study → Program/Concentration | March 2026 |
| Pilot university | FIT Online MBA (primary), A-State MSN Nurse Admin (existing fixture data) | March 2026 |
| Agent model | Opus 4.6 with thinking mode enabled | Architecture spec |
| Zero-coupling principle | WorkflowConfig v1.8 is the machine-readable source of truth; no prompt modifications | Architecture spec |

---

*Document generated March 25, 2026. To be committed to `/projects/` in github.com/ngamer/workflow-designs.*
