# Agent Runbook — Coherent Emergent Conversation

Use this runbook only for this job.

## Read order

Read root `AGENTS.md`, then `README.md`, `ARCHITECTURE.md`, this runbook, `ROADMAP.md`, `HARNESS_ACCEPTANCE.md`, and `PROGRESS.md` last.

Read `AUDIT.md` only when you need the evidence behind the current failure taxonomy.

## Operating goal

Complete C0–C10 so human text, semantic candidates, discourse context, dynamic choices, runtime utterance realization, pragmatic interaction, behavior selection and social effects behave as one coherent conversation system.

The Next Chunk is a starting point, not a stop condition. After each accepted chunk, update `PROGRESS.md` concisely and continue automatically to the next mandatory phase.

## Authority rules

Never create a second:

- human-text parser/tokenizer in ProjectHoomans;
- conversation/discourse authority;
- pragmatic interaction director;
- ResponsePlan/Dialogue Content path;
- translation system;
- gameplay-effect authority.

PsychopatzCore owns generic human-text surface recovery and semantic candidates.

ProjectHoomans owns conversation-specific contextual interpretation and downstream interaction behavior.

NPC-generated semantic acts are never rendered to English and reparsed internally.

## Surface-recovery rules

Recovery is fallback, bounded and explainable.

- exact matches win;
- derive compact aliases from registered vocabulary instead of manually hardcoding malformed copies;
- preserve original text;
- expose recovered surface and recovery kind;
- penalize uncertain recovery;
- keep ambiguous recoveries as candidates;
- never use unrestricted substring matching;
- never let recovery weaken mutating-action safety.

## Discourse rules

The Contextual Discourse Resolver consumes semantic candidates plus existing bounded interaction context. It does not tokenize raw text.

Use existing pending questions, flows, topics, recent semantic acts, references, actor/relationship/world/knowledge projections and beat/scene state.

Prefer semantic composition and context over sentence-by-sentence phrase branches.

## Risk rules

Conversation recall and gameplay safety have different thresholds.

A moderate-confidence social act may be accepted when contextual evidence is strong and there is no dangerous mutation.

Inventory/world/task/gameplay mutation remains conservative and requires the existing exact/high-confidence/confirmation protections.

Do not globally lower thresholds to make conversation examples pass.

## Dynamic choice and realization rules

Dynamic buttons are semantic affordances, not generated strings with hidden behavior.

Internally separate:

- origin: authored vs generated;
- stance: positive / negative / neutral;
- strategy: apologize, challenge, dismiss, follow up, agree, disagree, repair, etc.;
- contextual modifiers: traits, relationship, topic, beat, world state and capabilities.

The user-facing surface may group generated choices into positive-leading, negative-leading and contextual/trait-driven lanes, but trait-driven choices may themselves be positive or negative. Do not encode trait as a mutually exclusive sentiment class.

Generated button clicks carry their typed semantic frame through the existing suggestion/click pipeline. Do not render text and send it back through NLU.

Dynamic NPC/player wording must use a bounded UtterancePlan / compositional realization path inside the existing SpeechRealization authority. Reuse canonical semantic lexemes and locale-specific construction rules; never echo arbitrary raw player text as generated dialogue. Always retain an ordinary Dialogue Content fallback when a composition is unavailable or unsafe.

## Social-memory rules

Immediate conversation understanding/reaction is not the same as durable conduct persistence.

If evidence is coalesced or pruned, expose that persistence result without converting the semantic interaction into a rejection.

Keep durable state bounded and do not persist full transcripts.

## Harness discipline

All acceptance uses the real production Lua worker and real providers.

Python may display, compare, edit canonical source and schedule scenarios. It must not implement semantic decisions.

Every understanding trace should stay bounded and lazy; do not replace observability with monolithic JSON dumps or routine screenshots.

## Cross-repository discipline

Before changing PsychopatzCore:

- inspect its `AGENTS.md`, branch/status/HEAD and concurrent work;
- change only generic NLU-owned behavior there;
- add Core-local tests for generic behavior;
- then verify ProjectHoomans against the paired checkout.

Before changing ProjectHoomans, recheck its worktree as well.

Never reset, rebase, stash or discard uncertain work.

## Compiler/content discipline

Generated files are never hand-authored.

If a semantic/catalog/content source changes, use the existing CodeBuilder and prove deterministic second generation.

Do not add sentence lists to generated runtime files to bypass the canonical source model.

## Validation cadence

For each chunk:

- focused Core tests when Core changes;
- focused ProjectHoomans Lua/Python tests;
- real-worker corpus cases;
- negative/ambiguous controls;
- action-safety controls;
- generation/idempotence checks when sources change;
- bounded performance evidence where relevant;
- `git diff --check`;
- no source-save mutation.

C10 performs broad final regression.

## Documentation hygiene

Keep `PROGRESS.md` as current truth only: current phase, accepted evidence, immediate Next Chunk, remaining mandatory work and real blockers.

Do not append completed-phase diaries. Git history is the archive.

Do not put active job state in root `AGENTS.md`.
