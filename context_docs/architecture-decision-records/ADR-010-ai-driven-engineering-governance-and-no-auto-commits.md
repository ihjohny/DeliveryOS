# ADR-010: AI-Driven Engineering Governance, Deterministic Quality Standards, and No-Auto-Commits Rule

## Status
**Accepted** (2026-09-22)

---

## Context
DeliveryOS is developed and maintained via an AI-assisted engineering methodology where autonomous coding assistants (such as Google Antigravity, Claude, or Cursor) collaborate directly with human systems engineers. While AI acceleration dramatically shortens iteration cycles, unconstrained AI code generation introduces well-documented systemic risks:
1. **Premature & Polluting Git Commits**: AI agents executing automated `git commit` loops without human verification contaminate git histories with broken intermediate states, hallucinated files, and untested patches.
2. **Type Degradation & Technical Debt Accumulation**: Under time or token pressure, AI models frequently take shortcuts—casting difficult typings to `any`, creating mock implementations, using `TODO` placeholders, or silently deleting tests instead of fixing the root cause.
3. **Architectural Drift**: In a micro-monorepo with 5 distributed applications (NestJS API, 2 Vite SPAs, 2 Flutter apps), an agent fixing a single bug in isolation might violate cross-cutting architectural invariants (e.g., bypassing PostGIS, storing auth tokens in shared localStorage, or changing state machine transitions without updating both portals).
4. **Context Window Exhaustion**: Loading entire codebases into agent context windows burns tokens exponentially and leads to loss of instruction adherence.

To make AI-driven development predictable, resilient, and enterprise-grade, clear engineering governance rules must be formalized as architectural invariants and enforced continuously.

---

## Decision
We enforce a strict, mandatory **AI Engineering Governance Protocol** across all agents, prompts, and contributors in DeliveryOS:

### 1. The "No-Auto-Commits" Invariant (Strict Rule 6)
- **AI agents are strictly forbidden from executing `git commit` or `git push` autonomously.**
- AI assistants may stage changes (`git add`), run diffs (`git status`, `git diff`), run unit/e2e tests, and execute linters.
- Every commit must be explicitly authorized and requested by the human operator (e.g., user explicitly prompting `"make a commit"`).
- Commit messages must follow Conventional Commits standard (`feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`).

### 2. Zero-Tolerance Code Quality Standards
- **Zero Raw `any`**: In TypeScript (NestJS, React SPAs), the use of `any` or `as any` is strictly forbidden. Developers and agents must declare strict interfaces, Zod schemas, or Prisma generated types.
- **Zero Mock / Placeholder Shortcuts**: In production code, no `// TODO: implement later`, stubbed returns (`return true; /* temp */`), or mock data fallbacks in live services are permitted. Features must be fully implemented, tested, and integrated.
- **Zero Test Deletion**: Agents are never allowed to delete or comment out failing tests to achieve a "green" build. Failing tests must be debugged and resolved at the implementation level.

### 3. Architecture Decision Record (ADR) Mandatory Lifecycle
- Any proposed architectural pivot, new third-party dependency, change to order state machines, storage engine modification, or API contract alteration **must be accompanied by an ADR** or an update to an existing ADR.
- ADRs reside in `context_docs/architecture-decision-records/` and must follow the standardized format: Context, Decision, State Machine / Schema / Architecture Diagram, Consequences, and Alternatives Considered.
- Before generating code for major features, agents must inspect `context_docs/QUICK_REFERENCE.md` and the relevant ADRs to ensure zero architectural regression.

### 4. Context Router Token-Saving Architecture
- To prevent prompt drift and token waste, agents must not ingest the entire documentation tree.
- Agents must enter through `context_docs/QUICK_REFERENCE.md` (Context Router) to read only the specific 1–2 BRDs, TIDs, or ADRs relevant to their current task.

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
             |   Explicit Human-Ordered Commit  |
             +----------------------------------+
```

---

## Consequences

### Positive
- **Rock-Solid Git History**: Git history remains pristine, atomic, bisectable, and free of noisy AI trial-and-error artifacts.
- **Architectural Cohesion**: Cross-app contracts (WebSockets, REST endpoints, JSONB structures) cannot be casually broken by agents unaware of global invariants.
- **Rapid Onboarding for Future Agents**: Any future AI model (GPT-5, Gemini 2.0, Claude 3.5 Sonnet) starting in this repository immediately reads `AGENTS.md` and adheres to system invariants without human hand-holding.
- **High Code Confidence**: Production codebases maintain strict typing, real implementations, and 100% test passing rates across all 5 applications.

### Negative
- **Slight Velocity Friction**: Agents cannot run completely unattended "fire-and-forget" continuous commits; the human engineer remains in the verification loop.
- **Documentation Overhead**: Modifying core patterns requires updating ADRs and keeping documentation synchronized with code.

---

## Alternatives Considered
- **Full Autonomous CI/CD Self-Commit**: Allowing the agent to commit and push whenever tests pass.
  - *Rejected*: Flaky tests, missed edge cases, or hallucinated logic can still slip into remote branches, breaking downstream environments.
- **Unstructured Memory / Scratchpads**: Relying on conversation history rather than formal ADRs.
  - *Rejected*: Agent context windows are ephemeral; conversation history is lost across sessions or when context truncates. File-based ADRs in the repository are permanent and version-controlled.
