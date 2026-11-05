# Test Suite Rationalization

**Parent objective:** Audit and rationalize the complete Project Hoomans developer test estate so every maintained test has a defensible current purpose, redundant or superseded coverage is removed or consolidated, repetitive test infrastructure is reduced, expensive coverage is routed appropriately, and no meaningful regression/authority protection is lost.

This is **not** a target-count exercise. Falling below 1,000 tests is neither required nor sufficient. The result is accepted only when the maintained suite is smaller/simpler where evidence supports it, faster or better routed where measurable, and at least as trustworthy for current production behavior.

Read:
1. root `AGENTS.md`;
2. this README;
3. `ARCHITECTURE.md`;
4. `AUDIT.md`;
5. `ACCEPTANCE.md`;
6. `ROADMAP.md`;
7. `AGENT_RUNBOOK.md`;
8. **`PROGRESS.md` last**.

Scope includes root Lua tests, Python tests, Semantic Lab/Harness tests, architecture/refactor checks, test runners/helpers, fixtures, and suite selection/routing. Native Project Zomboid SP/MP acceptance remains user-owned unless explicitly assigned.

No checked-in `GOAL_PROMPT.md`. The executable `/goal` is delivered in chat.
