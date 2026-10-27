# P11B — Needs wording-domain characterization

This document records the bounded Needs wording slice migrated after P11B0. It
does not move need eligibility, need values, gameplay effects, follow-up state,
or proposal commitment authority.

## Live ownership before migration

The semantic route is split across stable production boundaries:

- `PNC_SemanticDialogueLocalResponse_Questions.lua` dispatches Needs questions
  to the observation spoke. `resolveNeeds` chooses the quantity pool or the
  offer pool; it does not author wording or evaluate gameplay effects.
- `PNC_SemanticDialogueLocalResponse_Core.lua` calls the response catalog and
  builds the bounded response plan.
- `PNC_SemanticDialogueResponseCatalog_Questions_Needs.lua` owns the ten
  fixed response variants, their `needType`/`needUrgency` predicates, grounded
  fact references, dialogue acts, and continuation plans. Those records remain
  runtime selection authority.
- `PNC_SemanticDialogueFlow_Needs.lua` owns quantity/proposal follow-up state,
  required slots, interruption, and resume behavior. It remains unchanged.
- The Question Needs static translation map owned ten semantic IDs. Its
  entries redirected to ten `Responses.json` keys.
- `SpeechRealization/Families/Status.lua` owned the four style variants for
  `semantic.question.needs.offer.hunger`, redirected to four
  `Realizations.json` keys. No other Needs ID had a style family.

The response-catalog dataset variants
`semantic.question.needs.proposal.dataset.thirst` and
`semantic.question.needs.quantity.dataset.clarify_thirst` remain in the
manifest-backed response-pool shard as separate dataset records. Their plan
metadata and generated runtime ownership are not part of this fixed wording
slice.

## Migrated cohesive domain

`content/needs.json` now owns all ten fixed `semantic.question.needs.*` IDs:

- offer: hunger, thirst, fatigue, and unknown;
- quantity: hunger, thirst, and unknown;
- proposal: hunger, thirst, and unknown.

The canonical shard preserves the live EN/TL response wording. Hunger offer
also preserves its neutral, warm, terse, and guarded wording as one family:
the neutral phrase uses the former `Responses.json` text, while the other
styles use the former `Realizations.json` text. The other nine families are
neutral-only because they had no production style family.

No migrated family has placeholders or translation arguments. The old static
map entries and the ten old response keys are retired. The four old hunger
realization keys and their `Status.lua` family are retired. No alias table was
introduced.

## Dynamic boundary and acceptance evidence

Need urgency/type predicates, grounded references, response plans, flow state,
and any gameplay eligibility/effects remain outside canonical Conversation
content. The real worker continues to return semantic IDs and generated
Conversation translation keys; EN/TL hunger offer → quantity → proposal probes
retain empty transport/tool-call lists and report no side effects.

The shard/compiler contract verifies ownership of all ten IDs, exact generated
EN/TL output, retired legacy keys, and real-worker semantic identity. The
existing contextual C3-B/C3-C/C3-D contracts continue to cover quantity,
proposal, interruption, and resume behavior.
