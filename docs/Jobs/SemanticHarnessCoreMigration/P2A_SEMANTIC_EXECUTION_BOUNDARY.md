# P2-A semantic execution boundary

## Audit result

Core already owns the provider-neutral semantic engine and actor services:
parser/IR, conversation service, identity, social, knowledge, journey, and
conversation landing. Hoomans' harness worker is an adapter around PNC
production services, not a clean second engine.

The following Hoomans files are mixed and are not safe wholesale moves:

- `Conversation_Context_Builder.lua`: generic actor/world context shape plus
  PNC health, faction, relationship, knowledge, and companion policy;
- `Conversation_Turn.lua`: generic turn/delta bookkeeping plus PNC dialogue
  submission, local authority pumping, and Hoomans response projection;
- `OutputProjection.lua`: bounded output shaping plus Hoomans command labels,
  translation, and PNC tool-result realization;
- `CommandRouter_InteractionLifecycle.lua`: generic envelope/default routing
  plus the PNC lifecycle store, social reactions, and view mutation.

`SemanticAdapters_Core*.lua` installs PNC compatibility globals and scenario
fixtures; it is an adopter adapter, not Core engine code.

## Plan

1. Add a Core typed semantic-execution contract for context, text/frame
   submission, snapshots, bounded result projection, interaction operations,
   and materialization metadata.
2. Implement the contract in Hoomans through explicit callbacks over its
   existing PNC services.
3. Add a DTCommon adapter that can operate abstractly and a DTHoomans adapter
   that can request physical materialization, without duplicating the worker.
4. Move only generic turn/result and interaction-envelope orchestration after
   both adapters pass the contract tests.
5. Delete Hoomans copies only after import-zero and provider parity gates pass.

The first code chunk is the Core contract plus Hoomans adapter wiring; no
provider policy or merchant/health/faction data belongs in Core.
