# Semantic Dialogue Refinement & Variation Expansion

## Parent objective

Use the now-working Semantic Quality Sweep to systematically identify weak NPC dialogue, refine it at the **canonical authoring source**, and expand in-scope conversational dialogue so every active phrase style has **at least 10 meaningful phrase variants** while preserving semantic meaning, gameplay authority, personality/relationship fit, EN/TL parity, deterministic anti-repeat behavior, and grounded Project Zomboid/post-apocalyptic tone.

This is a content-quality goal, not a new semantic architecture goal.

The Quality Sweep, Response Observatory, Conversation Inspector, Dialogue Content Registry, CodeBuilder, and production Lua selector/realizer are accepted dependencies.

## Core user outcome

The user should be able to:

1. generate broad sentence coverage with Quality Sweep;
2. immediately see awkward/bland/robotic lines and the contexts that caused them;
3. trace each weak line back to its canonical phrase family;
4. improve that canonical family rather than patching generated Lua;
5. provide at least 10 strong phrase variants for every active style in the in-scope family;
6. regenerate CodeBuilder outputs;
7. rerun affected cases through real Lua;
8. confirm that meaning/authority is unchanged while wording is more natural, varied, contextual and setting-appropriate.

## Minimum-10 rule

For this job, an **in-scope active style bucket** means one NPC phrase family/style combination that is actually used for human-facing spoken dialogue and owned by the canonical conversation content system.

Each such active style bucket must contain **at least 10 phrase variants** after refinement.

Examples:

- `semantic.question.wellbeing.default / neutral` → >=10
- `semantic.question.wellbeing.default / warm` → >=10
- `semantic.flow.greeting.opening.default / guarded` → >=10

Do not satisfy the requirement by creating 10 semantic ResponseCatalog variants. The variation belongs in the post-semantic phrase layer.

## Scope

### In scope

- NPC spoken dialogue owned by canonical `phraseFamilies`;
- greeting / farewell;
- wellbeing / needs / health;
- identity / first contact;
- What's Up / general social conversation;
- social tool replies and reactions;
- companion commands / task acknowledgements;
- combat/event reactions and banter;
- quest/knowledge/navigation dialogue where it is normal spoken NPC text;
- other canonical conversational phrase families discovered by the corpus inventory.

### Explicitly classify before expansion

Some corpus records may be:

- atomic/system-like;
- compatibility fallback;
- intentionally fixed protocol text;
- mechanically constrained placeholders;
- third-party compatibility lines;
- non-NPC player UI wording.

Do not silently exempt them. Inventory them and record one of:

- `EXPAND_TO_10`
- `ATOMIC_EXEMPT`
- `STRUCTURAL_NOT_PHRASE`
- `THIRD_PARTY_COMPAT_DEFERRED`
- `PLAYER_UI_OUT_OF_SCOPE`

Any exemption needs a documented reason and must not be used merely to reduce workload.

## Accepted dependency

Current Quality Sweep baseline is accepted at repository HEAD `b3836b2c`:

- sentence-first review UX;
- balanced production-backed sentence generation;
- variant-guided sentence expansion;
- real-worker quality evidence;
- full response registry pagination;
- actual trigger/context/provenance display.

Do not redesign or bloat that subsystem unless a small extension is required for phrase-refinement acceptance.

## Documents

Read after root `AGENTS.md`:

1. `AGENT_RUNBOOK.md`
2. `ARCHITECTURE.md`
3. `STYLE_GUIDE.md`
4. `HARNESS_ACCEPTANCE.md`
5. `ROADMAP.md`
6. `AUDIT.md`
7. `PROGRESS.md` **last**

## Non-goals

- No runtime LLM dependency.
- No hand edits to generated Lua/translation outputs.
- No semantic/gameplay behavior changes simply to improve prose.
- No synonym spam to hit a numeric quota.
- No mandatory profanity.
- No flattening every NPC into the same “gritty survivor” voice.
- No English-only expansion with fake/English TL placeholders.
- No giant monolithic dialogue source.
- No native PZ/Workshop publication required for developer-side acceptance.
