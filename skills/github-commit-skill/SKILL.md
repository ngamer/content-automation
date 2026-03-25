---
name: github-commit-skill
description: >
  Use this skill whenever committing, staging, or organizing files into the
  content-automation GitHub repository (github.com/ngamer/content-automation).
  Triggers on: "commit this to GitHub", "add this to the repo", "push to
  GitHub", "stage these files", "update the repo", "what needs to be committed",
  "let's do a GitHub commit", "push what we built today", or any end-of-session
  request to save artifacts to version control. Also triggers proactively
  whenever a session produces a versioned artifact (a new .md, .sql, .docx,
  or prompt file) that should be filed — do not wait for the user to ask.
  Always use this skill rather than improvising commit instructions.
---

# GitHub Commit Skill — content-automation Repo

## How This Works

Every commit session follows the same pattern regardless of which computer
you're on:

1. **Download** the repo fresh from GitHub to a temporary folder
2. **Copy** your new files into the right places
3. **Commit** the changes with a descriptive message
4. **Push** the changes back up to GitHub
5. **Delete** the temporary folder — you're done

The repo on GitHub is always the source of truth. There is no persistent
local copy to maintain. Each session starts clean.

---

## Repo

**GitHub URL:** https://github.com/ngamer/content-automation  
**Default branch:** main

---

## Step 1 — Set Up a Working Folder

Open PowerShell. Run these commands to download a fresh copy of the repo:

```powershell
# Go to your Desktop
cd "$env:USERPROFILE\Desktop"

# Download the repo from GitHub
# This creates a folder called "content-automation" on your Desktop
git clone https://github.com/ngamer/content-automation

# Enter that folder
cd content-automation
```

**What this does:** `git clone` downloads the entire repo from GitHub.
You now have a complete, up-to-date copy to work with.

**First time on a new machine?** Git may ask for your GitHub username and
password. Use your GitHub username and a Personal Access Token (not your
GitHub password) — see the Troubleshooting section at the bottom if you
hit this.

---

## Step 2 — Identify Where Each File Goes

Files downloaded from Claude land in your Downloads folder by default.
Use this table to determine the target folder inside the repo:

| Artifact Type | Target Folder in Repo |
|---|---|
| Prompt file (WorkflowConfig, CCA1, ARV20, etc.) | `content/` |
| Prompt version summary doc | `content/` |
| Project status or registry doc | `projects/` |
| Deliverable Completion Protocol | `projects/` |
| Session Log | `projects/Session_Log.md` — append only, never replace |
| Project 1 design docs | `projects/project-1/` |
| Project 2 architecture or research | `projects/project-2/` |
| Project 2 n8n / integration research | `projects/project-2/research/` |
| Project 2 Atlassian taxonomy files | `projects/project-2/atlassian/` |
| Project 3 scoping or exec summary | `projects/project-3/` |
| SQL schema or database file | `projects/project-3/database/` |
| README update | repo root — rename to `README.md` |

If an artifact doesn't fit any row, ask before assigning a path.

---

## Repo Folder Structure

```
content-automation/
├── content/              ← Prompt files, WorkflowConfig, OperatorChecklist
├── seo/                  ← SEO analysis workflow specs
├── brand/                ← Brand compliance specs
├── analytics/            ← Analytics workflow specs
├── paid-media/           ← Paid media specs
├── outreach/             ← Outreach specs
├── projects/
│   ├── Project_Status_Current_v1.md
│   ├── Open_Issues_Registry_v1.md
│   ├── Deliverable_Completion_Protocol_v1.md
│   ├── Session_Log.md
│   ├── project-1/
│   │   └── Project1_EditorialInterface_Risepoint.docx
│   ├── project-2/
│   │   ├── Project2_FullAutomation_Architecture_Risepoint.docx
│   │   ├── Project2_Addendum_ToolServicesLayer_DRAFT_Risepoint.docx
│   │   ├── Architecture_Reconciliation_v1.md
│   │   ├── Human_Checkpoint_Analysis_v1.md
│   │   ├── Workflow_Risk_Assessment_v1.md
│   │   ├── research/
│   │   └── atlassian/
│   └── project-3/
│       ├── Project3_TopicIntelligenceDatabase_Scope_Risepoint.docx
│       ├── Project3_ExecutiveSummary_Risepoint.docx
│       └── database/
│           └── Content_Orchestration_Schema_v2_1.sql
├── CHANGELOG.md          ← Always update on every commit
├── DEPENDENCY_MAP.md     ← Update when prompt versions or project deps change
└── README.md             ← Update when structure or known issues change
```

---

## Step 3 — Copy Your Files Into the Repo

```powershell
# Copy a file from Downloads into a repo folder
Copy-Item "$env:USERPROFILE\Downloads\[filename]" "projects\"

# Copy into a subfolder
Copy-Item "$env:USERPROFILE\Downloads\[filename]" "projects\project-2\"

# Confirm the file landed — you should see it listed
Get-Item "projects\[filename]"
```

Produce one `Copy-Item` line per file. Always verify with `Get-Item` after
copying. If a file is missing, do not proceed to the commit step.

**If a subfolder doesn't exist yet**, create it first:
```powershell
New-Item -ItemType Directory -Path "projects\project-2\research"
```

---

## Step 4 — Update CHANGELOG.md

Open `CHANGELOG.md` in Notepad (or any text editor) and add a new entry
at the very top of the file, just below the file header. Format:

```markdown
## [YYYY-MM-DD] — [Short description of what changed]

### Added
- `path/to/file` — [one-line description of what it is]

### Updated
- `path/to/file` — [what changed and why, one line]

### Known Issues (active)
- KI-01: [open / resolved]
- KI-02: [open / resolved]
```

Rules:
- Date is always today's date
- Only include sections that apply — leave out `### Updated` if nothing updated
- Known Issues: only include if a known issue changed status this session
- Keep it factual — one line per file

---

## Step 5 — Check DEPENDENCY_MAP.md

Update `DEPENDENCY_MAP.md` only when one of these is true:
- A prompt file version changed (e.g., ARV20 bumped to v2.6)
- A new dependency between project components was established
- KI-01 or KI-02 was resolved, or a new known issue was added

If none apply, skip it and add "No dependency changes this session" to
the CHANGELOG entry so it's clear this was intentional.

---

## Step 6 — Stage, Commit, and Push

```powershell
# Mark each file to include in this commit
# List files explicitly — do not use "git add ." which stages everything
git add projects/[filename]
git add projects/project-2/[filename]
git add CHANGELOG.md

# Review what's about to be committed
# You should only see the files you just added
git status

# Save a snapshot with a descriptive message
git commit -m "[Verb] [what was done]

- [file 1]: [one-line description]
- [file 2]: [one-line description]"

# Upload to GitHub
git push origin main
```

**What each command does:**
- `git add` — marks a file as "include this in the next commit"
- `git status` — shows what's staged; always review before committing
- `git commit -m` — saves a labeled snapshot of the changes
- `git push origin main` — sends your commit up to GitHub

**Commit message verb:** Add / Update / Fix / Document  
**Subject line:** keep under 72 characters  
**Body:** one bullet per file, max 6; group by folder if more than 6

---

## Step 7 — Verify on GitHub

Open https://github.com/ngamer/content-automation in a browser and confirm:
- Your files appear in the correct folders
- The commit message shows in the commit history
- No error messages appeared in PowerShell

If something looks wrong, do not delete the local folder yet.

---

## Step 8 — Clean Up

Once everything looks right on GitHub, delete the local folder. You don't
need it — GitHub has the authoritative copy.

```powershell
cd "$env:USERPROFILE\Desktop"
Remove-Item -Recurse -Force content-automation
```

---

## Full Command Block Template

Produce this as a single copyable block for every commit session,
with placeholders filled in:

```powershell
# ── SETUP ──────────────────────────────────────────────────────────
cd "$env:USERPROFILE\Desktop"
git clone https://github.com/ngamer/content-automation
cd content-automation

# ── COPY FILES IN ──────────────────────────────────────────────────
Copy-Item "$env:USERPROFILE\Downloads\[file1]" "[target folder]\"
Copy-Item "$env:USERPROFILE\Downloads\[file2]" "[target folder]\"

# ── VERIFY FILES LANDED ────────────────────────────────────────────
Get-Item "[target folder]\[file1]"
Get-Item "[target folder]\[file2]"

# ── STAGE ──────────────────────────────────────────────────────────
git add [target folder]/[file1]
git add [target folder]/[file2]
git add CHANGELOG.md

# ── REVIEW — confirm only expected files are listed ─────────────────
git status

# ── COMMIT ─────────────────────────────────────────────────────────
git commit -m "[Verb] [description]

- [file1]: [description]
- [file2]: [description]"

# ── PUSH TO GITHUB ─────────────────────────────────────────────────
git push origin main

# ── VERIFY on GitHub before cleaning up ────────────────────────────
# https://github.com/ngamer/content-automation

# ── CLEANUP ────────────────────────────────────────────────────────
cd "$env:USERPROFILE\Desktop"
Remove-Item -Recurse -Force content-automation
```

---

## Verification Checklist

Append this after every command block:

```
Before git push:
□ All files copied and confirmed with Get-Item — nothing missing
□ CHANGELOG.md updated with today's date entry
□ DEPENDENCY_MAP.md updated or confirmed no changes needed
□ git status shows only the expected files — nothing extra staged
□ Commit message subject line is under 72 characters

After git push — check GitHub:
□ Files appear in the correct folders
□ Commit message is correct in the commit history
□ No error messages in PowerShell output
```

---

## Active Prompt Version Reference

If a commit includes a prompt file with a version that doesn't match
this table, flag it before producing instructions — may be a KI-02 issue.

| Prompt | ID | Current Version |
|---|---|---|
| WorkflowConfig | — | v1.8 |
| Content Creation Workflow | CCW68 | v6.8 |
| Article Refresh Workflow | ARV20 | v2.5 |
| Article Refresh Identification | ARID14 | v1.6 |
| Content Gap Analysis | GAP17 | v1.8 |
| Content Cluster Analysis | CCA1 | v3.2 |
| Operator Checklist | — | v1.4 |

---

## Known Issues — Current State

| ID | Issue | Status |
|---|---|---|
| KI-01 | CCA1 v3.2 output field names unverified against C1/C2/C5 connection maps | Open |
| KI-02 | ARV20 listed as v2.0/v2.1 in config registry; live file is v2.5 | Open |

---

## Troubleshooting

| Problem | What it means | Fix |
|---|---|---|
| `git clone` asks for username/password | GitHub auth not configured on this machine | Enter your GitHub username; use a Personal Access Token as the password (not your GitHub account password). Generate one at github.com → Settings → Developer Settings → Personal Access Tokens. |
| `git push` says "rejected" | The repo changed since your clone | Run `git pull origin main` then try `git push` again |
| `git status` shows unexpected files | Something extra got staged | Run `git restore --staged [filename]` to unstage it |
| `Copy-Item` says path not found | Target subfolder doesn't exist | Create it: `New-Item -ItemType Directory -Path "[folder path]"` |
| File path has spaces and command fails | PowerShell splits on spaces | Wrap the entire path in double quotes |
| `Remove-Item` says access denied | A file in the folder is open | Close any open files in that folder, then retry |
| `git commit` opens a text editor unexpectedly | Commit message was missing or malformed | Close the editor (type `:q!` if it's vim), then rerun with `-m "your message"` in quotes |
