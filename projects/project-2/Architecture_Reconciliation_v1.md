# Architecture Reconciliation
## Project 2 Full Automation Spec vs. n8n Implementation Guide

**Version:** 1.0  
**Date:** March 25, 2026  
**Owner:** Noah Gamer, AI Enablement for Digital Experience  
**Purpose:** Resolve apparent conflicts between the Project 2 architecture specification (which references Claude Code as the execution environment) and the n8n implementation guide (which describes n8n as the orchestration layer). This document establishes the canonical architecture for the AI Engineer hire.

---

## The Apparent Conflict

The Project 2 Full Automation Architecture specification states:

> "Layer 3: Orchestration — Orchestrator agent reads Jira work queue, routes articles to appropriate subagents, monitors completion. Runs in: Claude Code (CLI agentic execution environment)."
> "Layer 2: Execution Agents — Specialized subagents — one per workflow stage. Runs in: Claude Code with Opus 4.6 model."

The n8n Implementation Guide describes:

> "A master orchestration workflow calling six standalone sub-workflows via Execute Sub-workflow nodes, each wired with dual triggers for zero-coupling, MCP Client Tool nodes for external data, and Wait nodes for human decision gates."

These appear to describe two different orchestration architectures. They are not mutually exclusive. This document explains the relationship.

---

## Resolution: These Are Two Layers of the Same Architecture

n8n and Claude Code serve different roles in the system. They are not competing options — they operate at different levels.

**n8n is the workflow orchestration and scheduling layer.** It handles: scheduling (polling Jira every 30 minutes), triggering sub-workflows on status changes, managing Wait nodes for human-in-the-loop handoffs, routing between workflow stages via Switch nodes, and writing completion results back to Jira and Confluence.

**Claude Code (Anthropic API calls) is the AI execution layer.** It handles: executing the actual content workflow prompts (CCA1, GAP17, ARID14, ARV20, CCW68, M6SWA1), making MCP tool calls to Ahrefs, GSC, SERP API, and Atlassian, and producing the artifact outputs that get written to Confluence.

**The correct mental model:**

```
n8n (orchestration layer)
  → reads Jira work queue
  → triggers the right sub-workflow
  → Sub-workflow calls Claude API (via HTTP Request node)
    → Claude executes the prompt with MCP tools
    → Claude returns structured artifact output
  → n8n writes output to Confluence via Atlassian MCP
  → n8n transitions Jira status
  → n8n waits for next trigger or human input
```

The "agents" described in Project 2 Section 4 are Claude API sessions invoked by n8n sub-workflows — not standalone Claude Code processes running independently on a server. CLAUDE.md (Section 1.1 of the Project 2 spec) is the system prompt passed to Claude at the start of each API call, not a file read by a running Claude Code CLI process.

---

## What This Means for the Build

### What n8n Owns

| Responsibility | n8n Mechanism |
|---|---|
| Jira work queue polling | Schedule trigger (every 30 min) or Webhook trigger |
| Sub-workflow routing | Execute Sub-workflow node + Switch node |
| Human-in-the-loop approval gates | Wait node (resume on form submission or webhook) |
| Parallel fan-out (CCA1 → GAP17 + ARID14 + CCW68 simultaneously) | Execute Sub-workflow with Wait OFF + callback webhook pattern |
| Rate limit queuing (prevent simultaneous Ahrefs calls) | Queue Mode + worker distribution |
| Artifact writing to Confluence | Atlassian MCP node or HTTP Request to Confluence REST API |
| Jira status transitions | Atlassian MCP node |
| Error handling and retry logic | Retry on Fail settings per node + Error Workflow |

### What Claude API Calls Own

| Responsibility | Claude Mechanism |
|---|---|
| Executing workflow prompts | HTTP Request node → Anthropic Messages API |
| MCP tool calls (Ahrefs, GSC, SERP) | AI Agent node with MCP Client Tool sub-nodes (for steps requiring real-time tool calls) |
| Artifact generation (SEO specs, briefs, article drafts) | Claude completion response → parsed by n8n Code node |
| Gate logic execution | Embedded in prompt system instructions (WorkflowConfig v1.8) |
| Session context management | Managed via messages array in API call |

### The Hybrid Node Pattern (Critical Design Decision)

The n8n guide recommends a hybrid approach that must be applied consistently:

**Use AI Agent node (with MCP Client Tool sub-nodes) for:** GAP17 (Step 2), ARID14 (Step 3), ARV20 (Step 5a) — steps that require real-time MCP tool calls to Ahrefs and GSC as part of Claude's reasoning process.

**Use HTTP Request node (direct Anthropic API) for:** CCA1 (Step 1), CCW68 (Step 5b), M6SWA1 (Step 6) — steps where prompt fidelity matters most and MCP tool calls can be pre-fetched and injected as context rather than called live during the session.

The reason for the split: the AI Agent node makes MCP integration easy but normalizes prompts through a LangChain abstraction layer, which can degrade output quality for steps with complex, carefully engineered system prompts. The HTTP Request node preserves exact prompt control but requires the AI Engineer to handle MCP data retrieval separately (via pre-fetch HTTP calls before the Claude API call).

---

## CLAUDE.md — Clarification on Its Role

The Project 2 spec describes CLAUDE.md as a file that agents "read at session start." This is accurate in the Claude Code CLI sense, where CLAUDE.md is loaded from the filesystem before execution begins.

In the n8n + Anthropic API architecture, CLAUDE.md content is the **system prompt** passed in every API call's `system` field. It is not read from disk at runtime — it is stored in n8n as a credential or workflow variable and injected into each API call's system message.

**Practical implication:** CLAUDE.md still needs to be version-controlled in the GitHub repository (as specified in the Project 2 spec). But the mechanism for "reading" it is n8n injecting it as a system prompt, not a Claude Code process reading a file.

---

## Execution Environment Decision (Q8) — Impact on This Architecture

The unresolved Q8 decision affects one layer of this architecture: where n8n runs and how it invokes Claude.

| Option | n8n Runs On | Claude Invoked By |
|---|---|---|
| Option A: Claude Code on VM | n8n on same VM, or separate n8n instance | HTTP Request → Anthropic API, OR Claude Code sub-processes |
| Option B: Databricks + Anthropic API | n8n on VM/cloud, Databricks jobs as workers | Databricks jobs → Anthropic API directly (n8n triggers Databricks jobs) |
| Option C: Hybrid (recommended) | n8n on VM for pilot | HTTP Request → Anthropic API during pilot; Databricks jobs → Anthropic API in production |

**For the pilot (Weeks 1–20):** n8n Enterprise on a VM, calling the Anthropic API directly via HTTP Request nodes. This is the simplest path and requires no Databricks integration during the build/validation phase.

**For production (post-pilot):** The Claude API calls can be ported to Databricks jobs with minimal changes to the workflow logic — only the invocation layer changes, not the prompts, WorkflowConfig, or CLAUDE.md content.

---

## Build Sequence Reconciliation

The Project 2 spec defines a 20-week build sequence starting with Phase 1 (Foundation). The n8n guide describes the same sequence from an n8n perspective. They are compatible. The reconciled sequence is:

**Phase 0 (Week 0 — pre-build, from Tool Services Layer addendum):**
- Confirm Q8 execution environment decision
- Provision n8n Enterprise instance
- Install Playwright (server-side) for URL Verification Service
- Validate all MCP connections in n8n (Ahrefs, Atlassian, GSC, SERP API)
- Build and test URL Verification Service in isolation
- Build and test Document Generation Service in isolation

**Phase 1 (Weeks 1–2, from Project 2 spec):**
- Create CLAUDE.md (system prompt content — stored as n8n credential/variable)
- Set up GitHub repository structure
- Create Jira project schema for FIT pilot
- Create Confluence space for FIT pilot
- Build Orchestrator workflow in n8n (read-only first — Jira queries only)
- Validate Orchestrator reads Jira and maps issues to correct sub-workflow triggers

**Phases 2–7:** Follow Project 2 spec Section 6 unchanged. Each "agent" described there maps to an n8n sub-workflow containing an HTTP Request node or AI Agent node invoking the Anthropic API.

---

## What the AI Engineer Needs to Know — Summary

1. **n8n is the orchestrator. Claude API is the executor.** Not competing architectures — different layers.

2. **CLAUDE.md is a system prompt, not a file read at runtime.** Store it as an n8n credential or environment variable. Version-control it in GitHub.

3. **Use the hybrid node pattern.** AI Agent node for MCP-heavy steps (GAP17, ARID14, ARV20). HTTP Request node for prompt-sensitive steps (CCA1, CCW68, M6SWA1).

4. **WorkflowConfig v1.8 is still the source of truth.** Its routing logic, field maps, and gate definitions are injected into the Claude system prompt (CLAUDE.md). When the workflow changes, update WorkflowConfig and CLAUDE.md. Never hardcode workflow logic in n8n node configurations.

5. **The Tool Services Layer addendum defines three services** that n8n sub-workflows call rather than invoking tools directly. Read it before designing the Source Agent (Phase 4, Week 9) and Refresh Draft Agent (Phase 6, Week 15).

6. **Phase 0 is not optional.** URL Verification and Document Generation services must be built and validated before any agent that depends on them is written. The earliest hard blocker is Week 9 (Source Agent).

---

## Open Questions Specific to This Reconciliation

These questions need answers before the n8n pilot build can begin:

| # | Question | Owner |
|---|---|---|
| R-1 | Which n8n plan tier is currently active? Enterprise features (Queue Mode, Git Sync, execution history, HITL approval) are required for this architecture. | Noah Gamer |
| R-2 | Where will the n8n instance be hosted? Self-hosted on a VM (recommended for pilot) or n8n Cloud? | Noah Gamer + IT/Systems |
| R-3 | Are all nine MCP server SSE endpoints accessible from the n8n instance's network? Some enterprise networks block outbound SSE connections. | IT/Systems |
| R-4 | Is the Anthropic API key provisioned as an n8n credential? What rate tier is it on? | Noah Gamer |

---

*Document generated March 25, 2026. To be committed to `/projects/project-2/` in github.com/ngamer/workflow-designs. This document supersedes any interpretation that n8n and Claude Code are competing architectures.*
