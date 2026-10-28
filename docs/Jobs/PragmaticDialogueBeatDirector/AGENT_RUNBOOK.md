# Agent Runbook — Coherent Emergent Conversation

Use this runbook only when a reproduced live regression requires reopening this completed job.

**Completion guard:** C0–C11 and L0–L5 are developer-accepted. Do not execute either roadmap wholesale without new runtime evidence.

## Read order

Normal post-completion work reads root `AGENTS.md`, then `README.md` and `PROGRESS.md` only.

If a regression requires this runbook, load only its owning support document: `DYNAMIC_CONVERSATION.md` for generated-choice/UtterancePlan behavior, `HARNESS_ACCEPTANCE.md` for acceptance evidence, `ARCHITECTURE.md` for authority disputes, or `STORAGE_TOPOLOGY.md` for compiler/storage behavior.

## Operating goal

Preserve the accepted coherent-conversation architecture and repair only reproduced regressions through the owning authority. Do not reopen adjacent completed phases merely because one live case fails.

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

Immediate conversation understanding/reaction is not the same as durable relationship-memory or conduct-evidence retention.

If bounded relationship memory or conduct evidence is coalesced, pruned or dropped, expose that persistence outcome independently. Storage capacity alone must not convert an already-understood/selected social interaction into a rejection.

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

## Compiler/storage/content discipline

Generated files are never hand-authored.

Canonical conversation source should stay atomic and semantically named. Generated output should stay semantically sharded and context-bounded.

Do not create or preserve numeric overflow shards such as `Part02`, `Part03`, or opaque generated conversation filenames whose semantic ownership cannot be inferred from path/name.

If a generated shard exceeds budget, split by semantic subdomain. Do not solve size by adding another numbered part.

Generated indexes point to owning shards; they do not become another full-definition registry.

The root manifest remains compiler/source-root configuration, not a growing list of every record.

CodeBuilder must expose context-health checks for source/shard size, definitions per shard, oversized indexes, orphan/collision/reference failures, and forbidden numeric/opaque shard names. Budget values may be tuned from measured data but the guardrail itself is mandatory.

Use lightweight ID→source→generated/dependency indexes for agent/tool discovery. Avoid duplicating definitions into discovery metadata.

Dynamic candidates, UtterancePlans, realized sentences and runtime combinations are ephemeral; never pre-expand or persist their combinatorial products.

If a semantic/catalog/content source changes, use the existing CodeBuilder and prove deterministic second generation. Full build idempotence remains mandatory even if targeted affected-closure compilation is added for developer speed.

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

C11 performs broad final regression.

## Documentation hygiene

Keep `PROGRESS.md` as current truth only: current phase, accepted evidence, immediate Next Chunk, remaining mandatory work and real blockers.

Do not append completed-phase diaries. Git history is the archive.

Do not put active job state in root `AGENTS.md`.
