# ADR-010: AI-Driven Engineering Governance, Quality Standards & Version Control Boundaries

## Status
**Accepted** (2026-09-22)

---

## Context & Problem Statement
Autonomous AI coding assistants accelerate development but introduce systemic risks if left unconstrained:
1. **Unchecked Commits & Pushes**: Automated commits pollute git history; automated pushing ships unverified states to remote branches.
2. **Type Degradation & Shortcuts**: Casting types to `any`, using mock `TODO` fallbacks, or deleting tests causes rapid technical debt.
3. **Architectural Drift**: Agents working on isolated files risk violating cross-cutting monorepo invariants without centralized guidance.
4. **Documentation Overpopulation**: Verbose, bloated documentation exhausts agent context windows and degrades prompt adherence.

---

## Decision
We enforce a mandatory **AI Engineering Governance Protocol** across all contributors and AI agents:

### 1. Strict Separation of Commit and Push Authority
- **NO Autonomous Git Commits**: AI agents are strictly forbidden from running `git commit` autonomously.
- **Commit Isolation**: When commanded to commit (e.g. `"make a commit"`), the agent performs **ONLY the local commit**. It must **NEVER** run `git push`.
- **Push Isolation**: `git push` is executed **only** upon receiving an explicit, distinct push command (e.g. `"push to remote"` or `"git push"`).
- Commit messages must strictly follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`).

### 2. Zero-Tolerance Code Quality Standards
- **Zero Raw `any`**: In TypeScript (NestJS, React SPAs), `any` or `as any` is strictly prohibited. Use strong interfaces, DTOs, or Prisma generated types.
- **Zero Mock / Placeholder Shortcuts**: In production code, no `// TODO: implement later` or dummy returns. All features must be fully implemented and integrated.
- **Zero Test Deletion**: Failing tests must be fixed at the root cause, never commented out or deleted.

### 3. Living ADR Lifecycle
- Any modification to dependencies, order state machines, storage engines, or API contracts requires an ADR update or new ADR in `context_docs/architecture-decision-records/`.
- Agents must cross-reference existing ADRs before proposing architectural changes.

### 4. Lean, High-Density Documentation Standard
- Keep all documentation clear, concise, and easily understandable.
- **Do not over-populate** documents with narrative filler, duplicate sections, or speculative prose.
- Prioritize structured tables, Mermaid diagrams, and copy-paste-ready snippets over paragraphs of text.

### 5. Token-Efficient Context Routing
- Agents must enter through [`context_docs/QUICK_REFERENCE.md`](../QUICK_REFERENCE.md) to load only the 1–2 files relevant to the active task, preventing prompt dilution.

```
       +---------------------------------------------+
       |             Human Operator                  |
       +---------------------------------------------+
                              |
                     Prompt & Task Scope
                              v
       +---------------------------------------------+
       |          Autonomous AI Agent                |
       |  (Consults QUICK_REFERENCE & ADR Index)     |
       +---------------------------------------------+
                              |
            +-----------------+-----------------+
            |                                   |
            v                                   v
  [Code Modification]                 [Verification Suites]
  - Strict TypeScript (no `any`)      - `npm run test` (NestJS)
  - Strict Dart / Riverpod            - `npm run test:run` (SPAs)
  - PostGIS & Redis Invariants        - `flutter test` (Apps)
  - Synchronize ADRs if modified      - Clean lint & typecheck
            |                                   |
            +-----------------+-----------------+
                              |
                              v
             +----------------------------------+
             |   Git Staging (`git status/add`) |
             +----------------------------------+
                              |
                        [HALT & REPORT]
                              |
                              v
             +----------------------------------+
             |   Human Operator Review & Signoff|
             +----------------------------------+
                              |
                      "make a commit"
                              v
             +----------------------------------+
             |   Local Git Commit (ONLY)        |
             |   (git commit -m "...")          |
             +----------------------------------+
                              |
                     "push to remote"
                              v
             +----------------------------------+
             |   Remote Push Execution (ONLY)   |
             |   (git push origin <branch>)     |
             +----------------------------------+
```

---

## Consequences

### Positive
- **Clean, Bisectable Git History**: Local commits remain reviewable; remote branches stay deployable.
- **Architectural Cohesion**: Shared invariants across all 5 apps remain protected from regression.
- **Context Efficiency**: Lean documentation conserves LLM tokens and prevents instruction drift.

### Negative
- **Interactive Verification**: AI cannot execute end-to-end "fire-and-forget" push loops without human oversight.

---

## Alternatives Considered
- **Autonomous Auto-Commit on Test Pass**: Rejected to prevent unreviewed intermediate states in git history.
- **Unstructured Scratchpad Memory**: Rejected because conversational context is lost across sessions; repository ADRs provide permanent version-controlled contracts.
