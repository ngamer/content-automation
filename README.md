# workflow-designs

Noah Gamer — AI Enablement for Digital Experience, Risepoint

Repository for workflow design documentation, AI automation architecture, and SEO/content operations specifications. Domain-organized folders cover active operational workflows; the `/projects/` folder covers the three-project Master Content Automation Program.

---

## Repository Structure

| Folder | Contents |
|---|---|
| `/content/` | Content creation and refresh workflow prompts and configs |
| `/seo/` | SEO analysis and reporting workflow specifications |
| `/brand/` | Brand compliance and style workflow documentation |
| `/analytics/` | Analytics reporting workflow specifications |
| `/paid-media/` | Paid media workflow specifications |
| `/outreach/` | Outreach workflow specifications |
| `/projects/` | Master Content Automation Program — Projects 1, 2, and 3 |

---

## Master Content Automation Program

Three interconnected projects that build on top of the manually-operated Master Content Workflow Orchestration system. All three are pre-build as of March 2026. Scoping and architecture are complete.

| Project | Name | Status | Primary Doc |
|---|---|---|---|
| Project 1 | Editorial Team Interface | Scoped — not started | `projects/project-1/Project1_EditorialInterface_Risepoint.docx` |
| Project 2 | Full Pipeline Automation | Scoped — not started | `projects/project-2/Project2_FullAutomation_Architecture_Risepoint.docx` |
| Project 2 Addendum | Tool Services Layer | Draft — awaiting Q8 | `projects/project-2/Project2_Addendum_ToolServicesLayer_DRAFT_Risepoint.docx` |
| Project 3 | Topic Intelligence Database | Concept scoping complete | `projects/project-3/Project3_TopicIntelligenceDatabase_Scope_Risepoint.docx` |

**Current status document:** `projects/Project_Status_Current_v1.md`  
**Open issues registry:** `projects/Open_Issues_Registry_v1.md`  
**Architecture reconciliation (n8n + Claude Code):** `projects/project-2/Architecture_Reconciliation_v1.md`  
**Deliverable completion protocol:** `projects/Deliverable_Completion_Protocol_v1.md`

### Project Relationships

```
Project 3 (Topic Intelligence Database)
    ↓ provides pre-computed intelligence to
Project 1 (Editorial Interface) + Project 2 (Full Pipeline Automation)
    ↓ feed performance data back to
Project 3 (closes the feedback loop)
```

---

## Active Prompt File Versions

| Prompt | ID | Version |
|---|---|---|
| WorkflowConfig | — | v1.8 |
| Content Creation Workflow | CCW68 | v6.8 |
| Article Refresh Workflow | ARV20 | v2.5 |
| Article Refresh Identification | ARID14 | v1.6 |
| Content Gap Analysis | GAP17 | v1.8 |
| Content Cluster Analysis | CCA1 | v3.2 |
| Operator Checklist | — | v1.4 |

Prompt source files: `C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\Prompt Design\Content\Master Content Workflow - All Core Prompts\`

---

## Known Issues

| ID | Issue | Severity | Blocks |
|---|---|---|---|
| KI-01 | CCA1 v3.2 output field names unverified against C1/C2/C5 translation maps in WorkflowConfig v1.8 | CRITICAL | Agent execution of any CCA1-dependent step; schema parser Phase 4 |
| KI-02 | WorkflowConfig Prompt Registry lists ARV20 at v2.0; live file is v2.5 | CRITICAL | C6/C9 connection logic; any refresh path agent build |

Full issue registry with all open questions and pending decisions: `projects/Open_Issues_Registry_v1.md`

---

## Database Schema

SQL schema for the content orchestration system (Databricks Delta, 64 tables, 12 views):  
`projects/project-3/database/Content_Orchestration_Schema_v2_1.sql`

---

## Atlassian POC

Confluence taxonomy skeleton live at btcentral.atlassian.net — 44 pages across Partner, Vertical, Area of Study, and synthetic test program layers. 187 program-level leaf nodes and 33 direct-program pages not yet built.

Taxonomy IDs and structure: `projects/project-2/atlassian/`

---

## University Partners (Primary)

| Partner | Short Name | Domain |
|---|---|---|
| Arkansas State University | A-State | degree.astate.edu |
| Florida Institute of Technology | FIT | online.fit.edu |
| Bowling Green State University | BGSU | onlinedegree.bgsu.edu |

---

*Contact: Noah Gamer, AI Enablement for Digital Experience — Risepoint*
