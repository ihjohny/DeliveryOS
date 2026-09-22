# Autonomous AI Agents & Coding Assistants Guide

Welcome! If you are an AI coding assistant or developer working on **DeliveryOS**:

⚡ **TOKEN-SAVING FAST ENTRY**:  
Before loading large documentation files, inspect the **Context Router** to identify the exact 1–2 files needed for your specific task:  
👉 **[`context_docs/QUICK_REFERENCE.md`](./context_docs/QUICK_REFERENCE.md)**

---

## 📚 Master Engineering Specifications & Index

All authoritative system rules, business workflows, technical specifications, and architecture decisions are maintained in `context_docs/`:

1. **[Master AI Agent Rules & Invariants](./context_docs/AGENT_RULES.md)** — Authoritative engineering standards, DoD, and governance.
2. **[Master Work Breakdown Structure (WBS)](./WORK_BREAKDOWN.md)** — Step-by-step engineering roadmap and implementation milestones.
3. **[Quick Reference & Context Router](./context_docs/QUICK_REFERENCE.md)** — Token-efficient task-to-document routing table.
4. **[Business Requirements Documents (BRD)](./context_docs/business-requirements-documents/README.md)** — Core business rules, user journeys, and personas.
5. **[Technical Implementation Documents (TID)](./context_docs/technical-implementation-documents/README.md)** — System architecture, schemas, APIs, and devops.
6. **[Architecture Decision Records (ADR)](./context_docs/architecture-decision-records/README.md)** — Permanent architectural contracts and state machines.

---

## ⚡ Core Operational Invariants Matrix

To prevent command misinterpretation or skipped instructions, every AI agent must adhere to the invariants below. For complete technical rationale and enforcement procedures, follow the linked sections in **[`AGENT_RULES.md`](./context_docs/AGENT_RULES.md)**:

| Invariant | Direct Rule Command | Authoritative Section in `AGENT_RULES.md` |
| :--- | :--- | :--- |
| **Commit Authority** | **NO AUTO-COMMITS**: Never run `git commit` autonomously. Run `git commit` **only** when explicitly commanded (e.g. `"make a commit"`). | [Git Protocol (§ 6.1)](./context_docs/AGENT_RULES.md#6-git--version-control-protocol) |
| **Push Authority** | **NO AUTO-PUSH**: When commanded to commit, execute **ONLY the local commit**. Never run `git push` without an explicit, distinct push command (e.g. `"push to remote"` or `"git push"`). | [Git Protocol (§ 6.1)](./context_docs/AGENT_RULES.md#6-git--version-control-protocol) |
| **Type Safety** | **ZERO RAW `any`**: Maintain strict typing (`"strict": true`). Declare explicit DTOs, interfaces, or Prisma types; never cast to `any`. | [Backend & Frontend Standards (§ 3)](./context_docs/AGENT_RULES.md#3-technology-stack--architectural-standards) & [ADR-010](./context_docs/architecture-decision-records/ADR-010-ai-driven-engineering-governance-and-no-auto-commits.md) |
| **Production Realism** | **ZERO PLACEHOLDER SHORTCUTS**: Implement real production code without mock fallbacks, empty `TODO`s, or deleted failing tests. | [Definition of Done (§ 5)](./context_docs/AGENT_RULES.md#5-definition-of-done-dod) |
| **Architectural Sync** | **ADR SYNCHRONIZATION**: Any modification to dependencies, state machines, storage, or ingress requires an ADR update or creation. | [Pattern Consistency (§ 8.4)](./context_docs/AGENT_RULES.md#8-pattern-consistency--living-documentation-protocol) & [ADR Index](./context_docs/architecture-decision-records/README.md) |
| **Lean Documentation** | **CONCISE & USEFUL ONLY**: Keep all documentation clear, concise, and understandable. Do not over-populate with verbose prose or speculative filler. | [Living Docs Standard (§ 8.5)](./context_docs/AGENT_RULES.md#8-pattern-consistency--living-documentation-protocol) |
| **Active Clarification** | **ZERO ASSUMPTIONS**: If a requirement or user prompt is ambiguous, pause and ask structured questions with recommended options before executing. | [Active Interview Protocol (§ 7)](./context_docs/AGENT_RULES.md#7-zero-assumption--active-interview-protocol) |
