# Contextual Dialogue & Quest Framework — Grounded NPC Conversation

**Active product goal (2026-10-20): Harness-first CodeBuilder and translation recovery on top of previously implemented B0–B6. PARENT STATUS: IN PROGRESS.**

The user wants an NPC conversation AUTHORING and DEBUGGING tool, not a large collection of handwritten Lua phrase handlers or JSON-only tests. The existing Semantic Lab is the control center: visually compose reusable blocks → preview canonical source and generated files → approve → generate real Hoomans Lua and EN/TL translation assets in the proper mod paths → restart the real Core+Hoomans Lua worker → visually inspect the conversation, evidence, translation lookups and side effects. The agent must use this workflow to implement and accept new personal/backstory dialogue.

**Known corrections:** CodeBuilder currently lacks authored `NPC_BACKSTORY` subject support, backstory response IDs lack translation-key mappings and registered EN/TL full-sentence entries, the legacy seed-fact JSON loader coexists with the Core-backed custom manager, player `suspected` backstory projections can be replaced by authoritative truth, and prior Python full-suite logs disagree with the accepted progress claim.

**Source locations:** On existing `main`, this directory is the canonical documentation target. The old B0–B6 source and progress ledger remain in the preexisting `docs/contextual-dialogue-quest-framework-20261018` branch at inspected HEAD `4755622022f244f9cd890039b705c0badf0cf57a`; **not integrated into main** at this checkpoint. Existing PR #4 is open/unmerged and reported nonmergeable. Safely reconcile into existing `main` without creating any branch or overwriting files. Core paired source snapshot: `2179ee19307a993e186e6da661ad4212e984e0b4`.

## Canonical read order

Root `AGENTS.md`; job `README.md`, `AGENT_RUNBOOK.md`, `ARCHITECTURE.md`, **`HARNESS_FIRST_CODEBUILDER_TRANSLATION_RECOVERY.md`**, `GIT_INTEGRATION_AND_NO_NEW_BRANCHES.md`, `ROADMAP.md`, `CONVERSATION_ACCEPTANCE.md`; read **`PROGRESS.md` LAST** for the ONE current chunk. Review historic B0–B6 source and ledger on the preexisting branch when auditing rather than erasing evidence. Inspect actual source and matching Core runtime before editing.

**No checked-in /goal bootstrap:** The complete `/goal` prompt is delivered to the user in chat only, not stored in an MD file. Native Project Zomboid SP/MP and Workshop operations remain user-owned.
