# Dialogue Content Registry & Phrase Variation

**Status: REQUIRED extension of the Semantic Observatory parent goal.** This is the durable content-authoring contract for reducing repetitive semantic dialogue without turning Studio into a semantic-logic editor.

## Product intent

Project Hoomans semantic logic is increasingly implemented by agents and validated through the real Lua worker. Human-facing Studio should therefore specialize in **dialogue content** rather than asking the user to manually wire flows, block contracts or interaction graphs.

The desired split is:

```text
semantic/context logic            agent-authored Lua / reviewed CodeBuilder structure
        ↓
semantic response selection       what the NPC means in this context
        ↓
speech style                     neutral / warm / terse / guarded / future styles
        ↓
phrase selection                 which equivalent wording is used this time
        ↓
normal translation resolution    EN/TL string keys through PsychopatzCore
        ↓
rendered conversation
```

Phrase variation must never become a second semantic selector or gameplay-authority path.

## Verified baseline that motivates the design

Current production code already has the required foundations:

- `PNC_SemanticDialogueResponseCatalog_Selection.lua` deterministically selects eligible semantic variants and avoids immediate repetition among tied highest-scoring variants.
- `PNC_SpeechRealization.lua` applies style after semantic selection, currently choosing one phrase for `neutral`, `warm`, `terse` or `guarded`.
- `PNC_ConversationToolReplies.lua` and Social Flavor provide a proven legacy pattern for arrays of equivalent wording plus deterministic anti-repeat selection.
- CodeBuilder canonical datasets already model response pools and can emit Lua plus EN/TL translation artifacts.
- PsychopatzCore translation resolution accepts **string values**. Current Project Hoomans EN/TL translation JSON catalogs are string-valued; translation arrays are not the runtime contract.

Therefore the new system should reuse the proven phrase-pool behavior while preserving the modern semantic/realization/translation architecture.

## Non-negotiable separation: semantic variant vs phrase variant

A **semantic variant** changes why/when a response is appropriate:

```text
semantic.flow.greeting.opening.rain
semantic.flow.greeting.opening.friendly
semantic.question.whats_up.weather
semantic.question.whats_up.busy
```

It may own `when`, priority, response plan, grounded facts or authority-related metadata and remains in the production ResponseCatalog.

A **phrase variant** is alternate wording with the **same semantic meaning, conditions, plan and gameplay effects**:

```text
friendly/warm
  - "Hey! Really good to see you."
  - "There you are. Glad you're okay."
  - "Good to see a familiar face."
```

Phrase variants must not consume ResponseCatalog semantic-variant slots merely to add synonyms. The current `MAX_VARIANTS = 16` response-pool bound remains for semantic/context alternatives unless separately justified by measured evidence.

## Canonical authoring source

Create or adapt one reviewed CodeBuilder-owned canonical content source for content-only phrase families. Preferred shape/name unless the implementation audit proves an existing canonical dataset can own this without ambiguity:

`tools/semantic_harness/codebuilder/sources/semantic_dialogue_content.json`

This is an **authoring source**, not a runtime database and not ModData.

Conceptual record:

```json
{
  "id": "semantic.flow.greeting.opening.friendly",
  "kind": "npc_response",
  "styles": {
    "neutral": [
      {
        "id": "good_to_see_you",
        "en": "Hey! Good to see you.",
        "tl": "Uy! Mabuti at nakita kita."
      },
      {
        "id": "familiar_face",
        "en": "Good to see a familiar face.",
        "tl": "Mabuting makakita ng pamilyar na mukha."
      }
    ]
  }
}
```

The exact schema may be refined by CodeBuilder conventions, but it must keep stable phrase IDs, paired EN/TL content, bounded style groups and verified linkage to the actual semantic/template owner.

### Canonical ownership rules

- Semantic Lua/CodeBuilder structure owns pool ID, semantic variant ID, `when`, priority, response plan, grounded-fact references, actions and authority metadata.
- Dialogue Content Registry owns content-only phrase IDs, EN/TL wording, enabled/disabled state if supported, and content-level style grouping.
- Generated Lua/translation artifacts are derived output and are not hand-edited after migration.
- Existing hand-authored Lua text remains authoritative until that family is explicitly migrated; do not create silent duplicate ownership.
- Provenance must state `AUTHORED_LUA`, canonical content source, generated artifact, translation source, or `UNKNOWN` honestly.

## Generated runtime artifacts

Do **not** place arrays directly into `Responses.json`, `Suggestions.json` or other PsychopatzCore translation catalogs.

CodeBuilder should compile each logical phrase to normal string-valued translation keys, for example:

```text
UI_PNC_Conversation_Semantic_FlowGreetingOpeningFriendly__good_to_see_you
UI_PNC_Conversation_Semantic_FlowGreetingOpeningFriendly__familiar_face
```

with ordinary EN/TL string entries and the existing manifest path.

The compiled Lua side should expose a bounded phrase-family registry that maps the logical semantic/style family to those physical phrase IDs/translation keys. It may extend SpeechRealization or a tightly owned companion module; it must not create a second translation manager or semantic response catalog.

## Runtime phrase selection contract

Phrase selection occurs **after semantic selection and style resolution**.

Requirements:

- deterministic for the same controlled salt/context where required by harness tests;
- immediate-repeat avoidance within the same NPC + logical phrase family/style;
- bounded in-memory history only; no per-NPC ModData phrase history and no save bloat;
- no `math.random`-only behavior that makes harness replay unexplained/non-reproducible;
- selection metadata observable by Simulation/CLI: semantic variant, style, phrase ID, phrase-pool size and anti-repeat reason;
- reset/isolation behavior explicit for worker/scenario tests;
- initial phrase count is bounded (prefer a conservative cap such as 16 per style/family until benchmark evidence justifies more).

A phrase-choice failure falls back to the canonical semantic/template phrase and never changes gameplay behavior.

## SpeechRealization integration

Existing SpeechRealization already owns style selection. Extend that seam rather than adding a parallel post-processor.

Target conceptual behavior:

```text
ResponseCatalog selected: semantic.flow.greeting.opening.friendly
SpeechStyle selected: warm
Phrase family: semantic.flow.greeting.opening.friendly / warm
Phrase selected: familiar_face
Translation key: ...FriendlyWarm__familiar_face
```

Diagnostics must preserve both semantic identity and rendered phrase identity. A wording change must not obscure why the underlying semantic response was selected.

## Player landing-page / choice content

Studio Dialogue Content also owns **surface wording** for player-facing semantic choices such as:

- `conversation.landing:whats_up`
- What's Up group/landing labels
- Back / Talk again about / similar semantic navigation labels where ownership is verified

Structural fields remain locked/read-only:

```text
candidate ID
route
hub ID
canonical concept
eligibility/predicates
frame/action metadata
```

Only the content fields are editable.

### Stability rule for player choices

NPC response wording may rotate dynamically with anti-repeat behavior. Player navigation labels should remain **stable by default** so the menu does not visually reroll on every refresh.

If player utterance variants are added later, the chosen phrase must remain stable for the relevant conversation/menu lifetime and preserve the exact semantic frame/route. Display-label variation is opt-in, not the default.

## Studio target: Explore | Dialogue Content | Review

Studio's primary tabs become:

### Explore

Read-only discovery of registered responses/interactions/flows/sources and verified ownership. No runtime scenario execution.

### Dialogue Content

The normal content-editing surface. It should let the user/agent:

- search/browse NPC response families and player landing/choice content;
- see semantic ID, context/condition, priority, plan and gameplay metadata as **locked** structural context;
- inspect phrase count by style and language;
- add, duplicate, edit, disable/remove (subject to source policy) content-only phrase variants;
- edit paired EN/TL text with placeholder parity validation;
- identify under-varied families (for example one warm phrase only);
- validate duplicates/equivalent wording, mixed-language bleed, placeholders and bounded lengths;
- preview the selected phrase family in the single Simulation workbench;
- submit the canonical content diff to Review rather than writing production/generated artifacts blindly.

The editor works against the verified canonical source with stale fingerprint/SHA guards. Raw JSON editing is not the default workflow.

### Review

Review continues to own before/after candidate approval evidence: source owner, EN/TL changes, phrase IDs, invariants, isolated real-Lua replay and gameplay/effect parity.

## Developer Tools, not primary Studio workflow

The following structural tools are for agents/maintainers and should not remain a peer everyday Studio tab after the content workflow is established:

- Flow editor/mutator;
- raw canonical JSON editor;
- Block contracts/palette;
- Interaction Composer;
- legacy Build Workflow.

Expose them under a bounded `Developer Tools…` entry/menu/toggle if still needed. Flow visualization may remain reachable from Explore, but structural mutation is not the normal human workflow. Retire legacy Build Workflow once unique capability/caller analysis proves it redundant.

## Migration sequence

Do not migrate the entire dialogue corpus in one change.

1. Establish schema/compiler/registry with no behavior change.
2. Migrate one verified low-risk family such as `semantic.flow.greeting.opening.default` and prove generated outputs equal the accepted current phrase before adding variety.
3. Add multiple EN/TL phrases and verify deterministic anti-repeat + style behavior through the real worker.
4. Migrate greeting opening/follow-up families.
5. Migrate high-value repetitive semantic question families such as What's Up, wellbeing/activity/weather where ownership is clear.
6. Add player landing/choice content editing while keeping routing/eligibility locked and labels stable.
7. Audit legacy ToolReplies/SocialFlavor families for later content-source consolidation; do not delete or wholesale migrate them until ownership/parity is proven.
8. Expand only with coverage/repetition evidence from Simulation/CLI.

Each migrated family must have exactly one canonical content owner after cutover.

## Performance and persistence

- Compile phrase data once; do not parse authoring JSON per frame or per NPC.
- No runtime network/LLM dependency.
- No phrase text persisted per NPC/save.
- Keep phrase registry metadata bounded and lazily inspectable.
- Benchmark worker startup, registry size, phrase selection and rendered-output size against the existing P0/P7 baselines before raising caps.

## Acceptance

The Dialogue Content Registry slice is accepted only when all are true:

1. A canonical reviewed content source compiles deterministically through existing CodeBuilder infrastructure.
2. Translation outputs remain ordinary string-valued EN/TL entries and existing PsychopatzCore translation APIs require no array semantics.
3. ResponseCatalog still selects semantic/context variants; phrase variety does not consume semantic variant slots simply for synonyms.
4. SpeechRealization/owned phrase seam selects among at least three equivalent phrases for one migrated family with deterministic immediate-repeat avoidance.
5. Worker/Simulation/CLI expose semantic variant + style + phrase ID separately.
6. Real-Lua EN/TL replay proves multiple phrases can occur while `when`, priority, plan, actions, transport, authority and effect deltas remain unchanged.
7. Studio `Dialogue Content` can inspect/edit that migrated family through its canonical source, validate EN/TL and preview in Simulation without exposing structural mutation as the default action.
8. Studio can edit one verified player landing/choice text pair while route/hub/concept/eligibility fields remain locked and behavior-parity tests pass.
9. Stale-source guards reject edits against changed canonical inputs; rejected review leaves production/generated artifacts unchanged.
10. CodeBuilder regeneration is idempotent, Kahlua/translation manifest verification passes, save hashes remain unchanged, and no watched-media staging/runtime ModData text is introduced.
