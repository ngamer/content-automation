---
name: session-handoff-skill
description: >
  Use this skill at the end of any working session on the Risepoint Content
  Automation Program (Projects 1, 2, or 3) to produce a structured handoff
  summary. Triggers on: "wrap up this session", "end of session summary",
  "what did we accomplish today", "session handoff", "summarize what we built",
  "let's close out", "what should I carry forward", or any signal that a
  working session is concluding. Also triggers proactively when a session has
  produced one or more artifacts and the conversation appears to be winding
  down — do not wait for the user to ask. Output goes to Session_Log.md
  (appended, not replaced) and optionally to Project_Status_Current_v1.md
  if open issues changed.
---

# Session Handoff Skill — Risepoint Content Automation Program

## What This Skill Does

Produces a concise, structured end-of-session summary in a consistent format.
The summary captures what was produced, what decisions were made, what issues
changed status, and what the next session should pick up first. It is appended
to `Session_Log.md` in the repo and eliminates the need for archaeology across
chat history to reconstruct project state.

---

## Output Format

Produce the following block. Every field is required. If a section has nothing
to report, write "None" — do not omit the section.

```markdown
---
## Session: [YYYY-MM-DD]

**Focus:** [One sentence — what this session was primarily about]

### Produced
<!-- List every artifact created or significantly updated this session -->
- `[filename or artifact name]` — [one-line description of what it is]

### Decisions Made
<!-- Explicit choices that affect future work — architecture, scope, approach -->
- [Decision]: [what was decided and why, one sentence]

### Issues Updated
<!-- Any known issue opened, resolved, or changed status -->
- [KI-XX or Q-XX]: [status change — e.g., "opened", "resolved", "superseded by..."]

### Pending Commits
<!-- Files produced this session that are NOT yet in GitHub -->
- `[filename]` → `[target repo path]`

### Next Session — Pick Up Here
<!-- The single most important thing to do first in the next session -->
**First action:** [specific action, not a vague goal]

<!-- Additional queued items in priority order -->
- [item 2]
- [item 3]

### Context for Next Session
<!-- Anything that would otherwise require re-reading chat history -->
[2–4 sentences max. Include: any unresolved ambiguity, a mid-flight artifact,
or a decision that was almost-but-not-quite made.]
---
```

---

## How to Fill Each Field

**Focus:** Derive from the dominant activity of the session. One of:
- Architecture / design work
- Artifact production (name the artifact type)
- Issue resolution
- Research / evaluation
- GitHub organization
- Skill building

**Produced:** Include every file downloaded, every doc created, every skill
drafted. If the session produced zero artifacts (pure analysis), write
"No file artifacts — analysis session."

**Decisions Made:** Only record decisions that will affect future build work.
Exclude "we decided to continue as planned" type non-decisions. If nothing
was decided, write "None."

**Issues Updated:** Cross-reference against the Open Issues Registry. Record
only actual status changes — not re-statements of issues that were already
open before this session.

**Pending Commits:** Everything in Produced that is not yet in GitHub. This
is the commit queue. If everything was committed this session, write "None —
all artifacts committed."

**Next Session — Pick Up Here:** The first action should be specific enough
that you could start executing it immediately without re-reading anything.
Bad: "Continue with Project 3." Good: "Resolve KI-01 — paste CCA1 v3.2
prompt file and run field verification against C1/C2/C5 connection maps."

**Context for Next Session:** Write this for a Claude instance that has
access to project files but not this chat history. What would it miss?
Typical things to include: a half-finished artifact, an almost-resolved
issue, a constraint that was discovered mid-session, or a scope change.

---

## Append to Session_Log.md

The output block goes at the top of `Session_Log.md` (newest first).
If `Session_Log.md` does not exist yet, create it with this header:

```markdown
# Session Log — Risepoint Content Automation Program

Append new sessions at the top. Newest first.
Keep all entries — do not archive or delete.

---
```

Then append the session block immediately after the header.

The file lives at:
```
projects/Session_Log.md
```
in the `content-automation` repo (https://github.com/ngamer/content-automation).

---

## When to Also Update Project_Status_Current_v1.md

Update `Project_Status_Current_v1.md` (not just Session_Log) when:
- An issue in the Open Issues Registry changed status (opened / resolved / superseded)
- A new artifact was added to the artifact inventory
- A key decision was made that changes project-level status

When updating, change only the affected section — do not regenerate the
entire document.

---

## Active Project State Reference

Use this to populate the handoff accurately. Cross-check against what
changed this session.

**Projects:**
- Project 1 (Editorial Interface): Scoped, not started
- Project 2 (Full Pipeline Automation): Scoped, not started
- Project 2 Addendum (Tool Services Layer): Draft, awaiting Q8
- Project 3 (Topic Intelligence Database): Concept scoping complete

**Blocking issues (as of March 25, 2026):**
- KI-01: CCA1 v3.2 field names unverified — Open
- KI-02: ARV20 version mismatch in config registry — Open
- Q8: Execution environment decision — Open (Option C recommended)
- Schema A/B: Scope boundary not formally accepted — Open

**Active prompt versions:**
WorkflowConfig v1.8 · CCW68 v6.8 · ARV20 v2.5 · ARID14 v1.6 ·
GAP17 v1.8 · CCA1 v3.2 · OperatorChecklist v1.4

**Source file locations on this machine:**
- Project docs: `C:\Users\noahg\OneDrive\Documents\Content Automation documents\`
- Skill files: `C:\Users\noahg\OneDrive\Documents\Content Automation documents\Content Automation Skills\`
- Prompt files: `C:\Users\noahg\OneDrive\Documents\Prompt Design\Content\`

---

## Failure Modes

| Problem | Fix |
|---|---|
| "Next Session" first action is vague | Make it executable: name the file, the tool call, or the specific step |
| Issues Updated lists things that didn't change | Only record actual status changes from this session |
| Pending Commits is empty but artifacts were produced | Re-check Produced list — if any file isn't in GitHub, it belongs here |
| Context section is too long | Cap at 4 sentences. If more context is needed, it belongs in a doc, not a log entry |
| Session_Log.md grows too large | Never archive or delete entries — the log is the record |
