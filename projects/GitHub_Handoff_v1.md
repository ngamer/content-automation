# GitHub Handoff — Risepoint Content Automation Projects
## Commit Instructions and Repository Update Guide

**Version:** 1.0  
**Date:** March 25, 2026  
**Repo:** github.com/ngamer/workflow-designs  
**Purpose:** Step-by-step instructions for committing all current project artifacts to the workflow-designs GitHub repo and updating the README to reflect the current project state.

---

## Prerequisites

Before running any git commands:

1. Confirm you are on the `main` branch and it is up to date:
```bash
cd "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\workflow-designs"
git status
git pull origin main
```

2. Confirm Node.js and npm are installed (needed for docx validation if any .docx files are converted):
```bash
node --version
npm --version
```

---

## Step 1 — Create the New Folder Structure

The current repo has domain-organized folders (content, SEO, brand, analytics, paid media, outreach). Automation project documents need their own top-level structure. Run these commands to create the new folders:

```bash
# From repo root
mkdir -p projects
mkdir -p projects\project-1
mkdir -p projects\project-2
mkdir -p projects\project-2\research
mkdir -p projects\project-2\atlassian
mkdir -p projects\project-3
mkdir -p projects\project-3\database
```

---

## Step 2 — Copy Files from OneDrive to Repo

### Files already in this Claude.ai project (copy from OneDrive AI Projects folder):

```bash
# Core status and registry docs (produced in this session — copy from wherever Claude delivered them)
Copy-Item "Project_Status_Current_v1.md" "projects\"
Copy-Item "Open_Issues_Registry_v1.md" "projects\"
Copy-Item "Architecture_Reconciliation_v1.md" "projects\project-2\"

# Scoping and architecture docs
Copy-Item "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\[source folder]\Project1_EditorialInterface_Risepoint.docx" "projects\project-1\"
Copy-Item "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\[source folder]\Project2_FullAutomation_Architecture_Risepoint.docx" "projects\project-2\"
Copy-Item "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\[source folder]\Project2_Addendum_ToolServicesLayer_DRAFT_Risepoint.docx" "projects\project-2\"
Copy-Item "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\[source folder]\Project3_TopicIntelligenceDatabase_Scope_Risepoint.docx" "projects\project-3\"
Copy-Item "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\[source folder]\Project3_ExecutiveSummary_Risepoint.docx" "projects\project-3\"

# Supporting analysis docs (already in this project as .md files)
Copy-Item "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\[source folder]\Human_Checkpoint_Analysis_v1.md" "projects\project-2\"
Copy-Item "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\[source folder]\Workflow_Risk_Assessment_v1.md" "projects\project-2\"
Copy-Item "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\[source folder]\Deliverable_Completion_Protocol_v1.md" "projects\"
Copy-Item "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\[source folder]\Building_a_Multi-Step_AI_Content_Pipeline_in_n8n*.md" "projects\project-2\research\"
Copy-Item "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\[source folder]\Automating_Artifact_Delivery_to_Confluence*.md" "projects\project-2\research\"

# Atlassian taxonomy files
Copy-Item "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\[source folder]\confluence_taxonomy_id_map.md" "projects\project-2\atlassian\"
Copy-Item "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\[source folder]\confluence_taxonomy_ids.json" "projects\project-2\atlassian\"
```

### SQL Schema — CRITICAL (copy when you have the file):

```bash
# Once you locate or retrieve Content_Orchestration_Schema_v2_1.sql
Copy-Item "[wherever the file is]\Content_Orchestration_Schema_v2_1.sql" "projects\project-3\database\"
```

**If the SQL file is not on disk:** It was produced in the March 22 session. Open that chat, copy the full SQL content, paste into a new file named `Content_Orchestration_Schema_v2_1.sql`, and copy it to the target path. Do not skip this step — committing all other files without the schema leaves the most important new artifact out of version control.

---

## Step 3 — Update CHANGELOG.md

Add this entry at the top of `CHANGELOG.md` (after the existing header):

```markdown
## [2026-03-25] — Project Organization and Architecture Reconciliation

### Added
- `/projects/` folder structure: project-1, project-2 (with research/ and atlassian/ subfolders), project-3 (with database/ subfolder)
- `Project_Status_Current_v1.md` — current state of all three automation projects
- `Open_Issues_Registry_v1.md` — single source of truth for all blocking issues, open questions, and pending decisions
- `Architecture_Reconciliation_v1.md` — resolves the relationship between Project 2 Claude Code spec and n8n implementation guide; establishes canonical architecture for AI Engineer onboarding
- `Content_Orchestration_Schema_v2_1.sql` — full 64-table, 12-view Databricks Delta schema for content orchestration system
- All Project 1, 2, and 3 scoping/architecture .docx files committed to structured subfolders
- Human Checkpoint Analysis v1.0 and Workflow Risk Assessment v1.0 committed to project-2/
- n8n implementation guide and Confluence/SharePoint analysis committed to project-2/research/
- Atlassian taxonomy ID map and JSON committed to project-2/atlassian/

### Updated
- README.md — updated to reflect current project state, three-project program overview, and known issues

### Known Issues (active)
- KI-01: CCA1 v3.2 output field names unverified against C1/C2/C5 connection maps
- KI-02: ARV20 version mismatch — config registry lists v2.0/v2.1, live file is v2.5
```

---

## Step 4 — Update DEPENDENCY_MAP.md

Add this section to `DEPENDENCY_MAP.md`:

```markdown
## Automation Projects Dependency Map

### Project 3 → Project 1 and Project 2
Project 3 (Topic Intelligence Database) is the data foundation for both downstream projects.
- Project 1 sessions start with pre-loaded topic context from the database rather than requiring upstream CCA1/GAP17 sessions
- Project 2 Pre-Spec Validation Agent queries the database at the start of every article run
- Project 3 initial population should be complete before Project 2 Phase 5 begins

### Project 2 → Project 1
Project 2 (Full Pipeline Automation) is the backend system; Project 1 (Editorial Interface) is the operator-facing frontend.
- Project 1 executes first — it does not require Project 2 infrastructure
- Confidence tracking data from Project 1 determines when Project 2 automation can be expanded
- Project 1 checkpoint classification (Confirm / Review / Decision) directly informs which Project 2 agents replace which human checkpoints

### SQL Schema Dependencies
- `Content_Orchestration_Schema_v2_1.sql` depends on WorkflowConfig v1.8 for gate logic, field names, and routing rules
- Schema's `step5_refresh` tables depend on ARV20 v2.5 gate structure — must be re-verified if ARV20 version changes (see KI-02)
- Schema's CCA1-originating tables (step1, handoff blocks C1/C2/C5) depend on KI-01 resolution

### Config Dependencies
- WorkflowConfig v1.8 → all prompt files (version compatibility matrix)
- CLAUDE.md (to be created) → WorkflowConfig v1.8 (agent reads config at session start)
- n8n sub-workflow system prompts → CLAUDE.md content (injected as API system message)
```

---

## Step 5 — Commit Everything

```bash
cd "C:\Users\Noah.Gamer\OneDrive - Risepoint\A SEO\AI Projects\workflow-designs"

git add projects/
git add CHANGELOG.md
git add DEPENDENCY_MAP.md
git add README.md

git status
# Review the staged files — confirm everything listed above is present
# If Content_Orchestration_Schema_v2_1.sql is missing, do NOT commit yet

git commit -m "Add automation project artifacts and architecture documentation

- Add /projects/ folder structure (project-1, project-2, project-3)
- Add Project_Status_Current_v1.md and Open_Issues_Registry_v1.md
- Add Architecture_Reconciliation_v1.md (n8n + Claude Code relationship)
- Add Content_Orchestration_Schema_v2_1.sql to project-3/database/
- Add all scoping/architecture .docx files to project subfolders
- Add Human Checkpoint Analysis, Workflow Risk Assessment to project-2/
- Add n8n guide and Confluence/SharePoint analysis to project-2/research/
- Add Atlassian taxonomy files to project-2/atlassian/
- Update CHANGELOG.md and DEPENDENCY_MAP.md
- Update README.md

KI-01 and KI-02 remain open — see Open_Issues_Registry_v1.md"

git push origin main
```

---

## README.md Update

Replace the current README.md content with the following:

```markdown
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

Three interconnected projects that build on top of the manually-operated Master Content Workflow Orchestration system.

| Project | Name | Status | Primary Doc |
|---|---|---|---|
| Project 1 | Editorial Team Interface | Scoped — not started | `projects/project-1/Project1_EditorialInterface_Risepoint.docx` |
| Project 2 | Full Pipeline Automation | Scoped — not started | `projects/project-2/Project2_FullAutomation_Architecture_Risepoint.docx` |
| Project 2 Addendum | Tool Services Layer | Draft | `projects/project-2/Project2_Addendum_ToolServicesLayer_DRAFT_Risepoint.docx` |
| Project 3 | Topic Intelligence Database | Concept scoping complete | `projects/project-3/Project3_TopicIntelligenceDatabase_Scope_Risepoint.docx` |

**Current status:** `projects/Project_Status_Current_v1.md`  
**Open issues:** `projects/Open_Issues_Registry_v1.md`  
**Architecture reconciliation (n8n + Claude Code):** `projects/project-2/Architecture_Reconciliation_v1.md`

---

## Active Prompt File Versions

| Prompt | Version |
|---|---|
| WorkflowConfig | v1.8 |
| CCW68 (Content Creation Workflow) | v6.8 |
| ARV20 (Article Refresh Workflow) | v2.5 |
| ARID14 (Article Refresh Identification) | v1.6 |
| GAP17 (Content Gap Analysis) | v1.8 |
| CCA1 (Content Cluster Analysis) | v3.2 |
| OperatorChecklist | v1.4 |

---

## Known Issues

| ID | Issue | Severity |
|---|---|---|
| KI-01 | CCA1 v3.2 output field names unverified against C1/C2/C5 translation maps in WorkflowConfig v1.8 | CRITICAL |
| KI-02 | WorkflowConfig Prompt Registry lists ARV20 at v2.0; live file is v2.5 | CRITICAL |

Full issue registry: `projects/Open_Issues_Registry_v1.md`

---

## Atlassian POC

Confluence taxonomy skeleton live at btcentral.atlassian.net — 44 pages across Partner, Vertical, Area of Study, and synthetic test program layers. Taxonomy IDs: `projects/project-2/atlassian/confluence_taxonomy_ids.json`

---

*Contact: Noah Gamer, AI Enablement for Digital Experience — Risepoint*
```

---

## Verification Checklist — Before Pushing

Run through this list before `git push`:

- [ ] `projects/Project_Status_Current_v1.md` — present and not empty
- [ ] `projects/Open_Issues_Registry_v1.md` — present and not empty
- [ ] `projects/Deliverable_Completion_Protocol_v1.md` — present
- [ ] `projects/project-2/Architecture_Reconciliation_v1.md` — present and not empty
- [ ] `projects/project-3/database/Content_Orchestration_Schema_v2_1.sql` — **CRITICAL** — present and contains full schema (should be ~1,748 lines)
- [ ] `projects/project-1/Project1_EditorialInterface_Risepoint.docx` — present
- [ ] `projects/project-2/Project2_FullAutomation_Architecture_Risepoint.docx` — present
- [ ] `projects/project-2/Project2_Addendum_ToolServicesLayer_DRAFT_Risepoint.docx` — present
- [ ] `projects/project-2/Human_Checkpoint_Analysis_v1.md` — present
- [ ] `projects/project-2/Workflow_Risk_Assessment_v1.md` — present
- [ ] `projects/project-2/research/` — contains n8n guide and Confluence/SharePoint analysis
- [ ] `projects/project-2/atlassian/confluence_taxonomy_id_map.md` — present
- [ ] `projects/project-2/atlassian/confluence_taxonomy_ids.json` — present
- [ ] `projects/project-3/Project3_TopicIntelligenceDatabase_Scope_Risepoint.docx` — present
- [ ] `projects/project-3/Project3_ExecutiveSummary_Risepoint.docx` — present
- [ ] `CHANGELOG.md` — updated with March 25 entry
- [ ] `DEPENDENCY_MAP.md` — updated with automation projects section
- [ ] `README.md` — updated with projects table and known issues

**If Content_Orchestration_Schema_v2_1.sql is missing:** Do not push. Locate or reconstruct the schema first. See note in Step 2 above.

---

*Document generated March 25, 2026. Run these commands from the workflow-designs repo root.*
