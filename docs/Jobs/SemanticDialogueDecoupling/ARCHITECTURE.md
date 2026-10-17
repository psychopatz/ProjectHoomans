# Unified semantic dialogue architecture — stable design

## Event-driven pipeline (target, not a claim of existing code)

    player utterance
        -> existing PsychopatzCore normalize/grammar/IR
        -> bounded candidate capture with typed slots and provenance
        -> Project Hoomans contextual eligibility and active flow
        -> policy/flow transition with safety/authority gates
        -> existing contextual reaction/response catalog
        -> optional typed dialogue-act composition
        -> stable translation key + localized Core-backed text
        -> NPC display / optional PBrainZ verbalization
        -> explicit gameplay request ONLY via existing authoritative service

Only add an intermediate module when a concrete Phase test proves current hooks insufficient. Avoid a parallel interpreter, redundant text catalog or Jess port.

## Ownership
- **PsychopatzCore:** normalizer/parser/concepts/confidence/IR, optional generic bounded candidate/typed-capture API, and optional generic custom translation manifest loader. Any Core code change is a separate authorized commit in the Core repo; **one job PROGRESS** tracks both repos.
- **Project Hoomans:** NPC context facts, references, active dialogue flows, candidate eligibility, reaction selection, response composition, translation registration, existing client presentation/server command boundary.
- **MarketSense:** item classification, never semantic lexicon overrides.
- **PBrainZ:** optional provider phrasing/retrieval, never needed for deterministic offline operation nor allowed to bypass server action policy.
- **Authoritative game domains:** identity, relationships, tasks, inventory, leases, MP validation, saves. No parser/flow performs gameplay mutations directly.
- **Existing authored conversation data:** `common/media/conversation/` stays distinct from custom UI/semantic translation bundles and native PZ `Translate`.

## Non-negotiable invariants
1. A matched pattern is not permission to interpret as a validated identity, activate a flow or schedule any gameplay action. Unsupported or ambiguous input clarifies without relationship penalty.
2. `Parser.Parse`, IR v1, response catalog IDs, public `PNC.Translation.GetKey/Get/TrFormat`, network schemas and server validations remain compatible absent an explicitly tested migration.
3. Name, need and wellbeing semantics must be resolved by typed facts and flow eligibility, not endless stop words or artificial global-priority inflation.
4. Context/flow state is bounded per speaker+addressee+conversation; pending identity may suspend on an interrupt and resume without leaking into other NPCs.
5. PREVIEW is side-effect-free, repeated PREVIEW is equivalent, a committed turn transitions once, and server outcomes alone authorize game effects.
6. Event-driven on utterance/state change; no per-NPC OnTick scans, full WordNet runtime loading, repetitive disk reads, or unbounded history ModData.
7. Build 42 media watcher safety: never stage/delete a transient temporary **directory** under a watched live `media/` tree.
8. Each phase has real production-Lua Semantic Lab assertions; native SP/MP acceptance separately established.

## Extensibility result
A new dialogue type should ideally require: (a) one small registered Lua flow with typed frames and states, (b) existing contextual response IDs/plans, (c) EN/TL bundle references only where new text is needed, (d) focused real-worker scenario and regression assertions. The core policy should not gain an `elseif` per new type.

This goal owns one ROADMAP and PROGRESS even when changes span Hoomans+Core. Avoid a second translation or dialogue agent ledger.
