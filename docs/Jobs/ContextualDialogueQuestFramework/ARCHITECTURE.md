# Architecture — Semantic Lab is the Authoring/Testing Control Center

## Canonical ownership

```text
Semantic Lab visual CodeBlocks / InteractionSpec
    -> existing SemanticLabAuthoringService
    -> canonical reviewed semantic/dialogue definitions
    -> existing CodeBuilder validator/compiler/writer
         -> generated Project Hoomans Lua catalog/flow shards in actual mod media
         -> registered EN/TL Conversation translation shards + manifest
    -> existing production PsychopatzCore parser and Hoomans Lua response/flow owners
    -> real Core+Hoomans worker inside existing Semantic Lab
    -> visual transcript + meaning/fact/disclosure/translation/effect inspector
    -> fix authoring/hooks and repeat
```

**No second parser/compiler/flow engine/GUI.** The existing GUI workflow (`tools/semantic_harness/workflow.py`), CodeBuilder (`tools/semantic_harness/codebuilder/{blocks,compiler,build,service}.py`), Flow editor, `conversation_inspector.py`, worker modules and versioned protocol are canonical. CodeBlocks are **declarative**; Python never evaluates Knowledge rules, game permissions or actions.

## Runtime and generated content boundaries

- Reusable authored blocks: language trigger / `NPC_BACKSTORY` typed kind; personal fact reference; player-scoped knowledge reference; tri-state disclosure gate; known/suspected/refusal/ambiguous response pool; bounded topic/follow-up; typed translation key/args. Extend existing registry and schema only as necessary, with validation and diagnostics.
- Authored canonical source is the reviewed input; approved generated Lua, EN/TL catalogs and manifest are the actual runtime assets under `Contents/mods/ProjectHoomans/**/media/`. Generated output byte-stable and source-linked; no unrelated scratch JSON/copy of generated assets.
- Existing Hoomans `PNC.Semantics.DialogueFacts` reads NPC personal truth through Conversation Memory/identity-seeded backstory. Existing `PNC.NPCKnowledge` controls what a given player has actually learned and may see; familiarity is only eligibility, never auto-discovery. Server alone commits authoritative disclosure and sends client-scoped dossier snapshots.
- `BACKSTORY_FACT` is a privileged harness diagnostic path and cannot count as player-conversation acceptance; never use `authoritativeBackstoryAccess = true` in non-admin player-facing dialogue, client, dossier or PBrainZ.
- A suspected player fact is *not* licensed to promote to the canonical selected seed-derived fact. If suspected, use its authorized observed value with uncertainty or withhold. Verified/confirmed history may resolve a localized canonical value only with an appropriate disclosure/evidence provenance.
- Hoomans translation facade `PNC.Translation` wraps **PsychopatzCore CustomTranslationManager**: registered system catalogs, active EN/TL locale, key registration, fallback diagnostics and formatter. Do not add a Tagalog switch or new manual translation dictionary in Lua. Existing backstory `PNC.Conversation.TextLoader` is a legacy consumer; migrate the backstory question/response authoring path through existing registered catalogs with compatible legacy behavior.
- The **dialogue template is not the localized fact noun**: complete sentences must use registered response keys and typed arguments, such as `kind` and `content`, and worker trace must show real key, args, resolved value and fallback status. Literal English fallback is permitted only as a safe missing-key fallback, never as the normal TL realization path.
- Stable identity seed + version-stable backstory selections + sparse stable-ID overrides remain the NPC truth owner. Player Knowledge is sparse per player-character/NPC pair; dossier and PBrainZ are authorized projections, not secondary sources of truth. Do not generate/update biography each tick or persist full dialogue history.

## Safety and integration

Protect existing STAY, inventory, compliments, gift, quest and companion gameplay admission: generated dialogue never directly executes unregistered effects. Preserve native SP/MP and Workshop for user-owned live testing. No new Git branches; new changes target existing main after safe in-place integration review. Existing B0–B6 code is still on the preexisting divergent branch at audited source HEAD `47556220`, not on main. No full prompt in checked-in docs.

## Final codeblock composition and localization closure (2026-10-20)

The generated static grounded-dialogue catalog now exists and is loaded by the production Lua catalog. The **remaining architectural seam** is the path from selected *parameterized and connected* CodeBlocks in the existing Tk `SemanticLabWorkflowPane` to the typed canonical `InteractionSpec`/authored dialogue source actually passed into `SemanticLabAuthoringService.generate_workflow`. Merely validating `block_ids` and subsequently compiling an unchanged dataset is not genuine composition. Reuse the current `InteractionSpec` compiler, existing flow graph schema and registered typed provider references; no second DSL, translator, parser or gameplay dispatcher.

Translation is two typed stages: authorized stable personal fact ID → properly localized displayed value (Core-backed existing registered translation seam; proper nouns remain intact) → existing `PNC.Translation.TrFormat` response template with typed `content`. Current H3 TL output showed `farmer` although existing TL lexicon has `occupation.farmer=magsasaka`; fix the source-to-presentation translation gap without rewriting persisted canonical identity or upgrading suspected private observations.

Knowledge descriptor disclosure policy needs configurable graduated familiarity/approval/privacy classes on the **server**; thresholds permit disclosure but never create discovered evidence. Dossier and optional PBrainZ project only existing per-character Knowledge; no per-player matrix/whole-profile ModData bloat. The final full-goal acceptance includes the real Tk GUI→approved generated files→fresh Lua worker path and comparable bytes for 0/1/10 actual player discoveries; the older synthetic metrics remain historical evidence.

## V1–V5 extension (2026-10-20): one reusable visual composition pipeline

Former structured F1–F4 work provides a fixed four-block `NPC_BACKSTORY` UI with real typed InteractionSpec, generated production Lua+EN/TL, and worker acceptance. The approved broader V goal reuses these exact owners but permits editing the block graph itself (add/remove/parameterize/connect with validated typed ports), not merely changing the prewired form. One existing CodeBuilder compiler/writer, one `SemanticLabAuthoringService` GUI/CLI path. Keep `semantic.interaction_spec.v1` as canonical typed interaction representation and preserve existing `semantic.codeblocks.v1` action-flow document behavior via adapter. No arbitrary game-side policy/commands in generated templates.

For newly authored semantic fact values, use stable IDs and existing `PNC.Translation` registered Core-backed catalog lookup; preserve legacy `Memory.GetBackstoryText` consumers until compatibility tests permit migration. Never leak canonical seed truth via client/PBrainZ when only suspected/unknown player evidence exists. Graduated familiarity 25/50/75 already exists; add willingness/approval/context through existing server-owned relationships and consent, not another persistent subsystem. Persisted storage metrics must label actor bytes and per-player Knowledge bytes separately under the same serializer, with 0/1/10 observations and actual worker evidence. See `V1_V5_VISUAL_AUTHORING_AND_RUNTIME_CONSOLIDATION.md` and current `PROGRESS.md`.

The earlier statements about PR #4 being unmerged or H0/F1 as future work in archived docs are historically superseded. Main is the only allowed development ref; no checked-in prompt MD.
