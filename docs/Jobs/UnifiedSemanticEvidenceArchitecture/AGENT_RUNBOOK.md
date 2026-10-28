# Agent Runbook — Unified Semantic Evidence Architecture

## Read order

Read root AGENTS.md, then:

1. README.md;
2. ARCHITECTURE.md;
3. this runbook;
4. ROADMAP.md;
5. PROGRESS.md last.

Open AUDIT.md for revision-specific baseline evidence. Open HARNESS_ACCEPTANCE.md when implementing or verifying a gate. Do not recursively read older semantic jobs unless a concrete ownership question requires them.

## Ownership

- PsychopatzCore: generic text normalization/candidates/DialogueTurn only.
- Project Hoomans Semantics: evidence normalization, discourse/pragmatic interpretation, InteractionProviders/Context and Director integration.
- Social/Relationship/Conduct/Knowledge/domain systems: authoritative facts, effects, durable state and policies.
- Conversation Memory: compact bounded episodic/durable projection, not gameplay truth.
- Dialogue Content/CodeBuilder: wording, constructions, affordance/content data and deterministic generated artifacts.
- Semantic Lab: observe/test production Lua; Python is not semantic authority.

## Implementation discipline

Prefer extension of existing modules/contracts over new top-level managers.

Before adding a module, prove an existing owner cannot safely host the responsibility. Never create feature-specific apology/gratitude/promise memory/context engines.

All persistent changes require a storage-delta test. A new ModData root or transcript-like payload is outside scope unless the user explicitly approves a redesigned storage architecture.

Keep queries bounded and targeted. Do not copy full relationship memory, full conduct evidence, interaction journal or arbitrary ModData into each semantic turn.

## Salience discipline

Use salience to mean retention importance only.

Do not silently reuse it for NLU confidence, contextual relevance, behavior relevance, memory strength, decay or priority.

When combining signals for contextual relevance, expose contributing evidence in diagnostics and keep the derived score ephemeral.

## Canonical source discipline

When semantic/event metadata is declarative/generated:

1. edit canonical owning source;
2. regenerate through CodeBuilder/owning compiler when applicable;
3. inspect generated changes;
4. run focused validation;
5. regenerate again and prove byte identity;
6. commit source + generated result together.

Do not hand-edit generated Lua/JSON as a parallel authority.

## Git/runtime safety

Use existing main. Preserve unrelated work. No blind pull/reset/rebase/stash/discard. Do not publish Workshop content. Do not launch native PZ. Never write source SAVE data; use fixture/working-copy replay only.

Commit coherent validated slices locally. Do not push unless explicitly authorized.

## Continuous execution

Under the parent /goal, start at the exact Next Chunk in PROGRESS.md. After each accepted chunk, update PROGRESS and continue through the next mandatory roadmap phase automatically.

Stop only for a real blocker, repository ownership conflict, unsafe concurrent modification, missing required tooling with no accepted fallback, or user-owned native acceptance after all developer-side gates pass.
