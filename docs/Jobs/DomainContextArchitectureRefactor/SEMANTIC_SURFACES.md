# Conversation and semantic public surfaces

Start with the operation below. `client`, `server` and `shared` select runtime
availability; they do not create competing business owners. Paths are relative
to the current runtime's `media/lua/`. The machine-readable supported paths are
in `DOMAIN_CONTRACTS.json`; provider filenames are implementation details.

| Operation | Public entry | Owner and stopping boundary |
| --- | --- | --- |
| Open/update/close a client session | `client/PNC/Conversation/PNC_ConversationLifecycle` | `Lifecycle.Create` callbacks; `Lifecycle.Finish` delivers close outcome and clears working state. Start/heartbeat helpers remain a separate slice. |
| Authorize scene mutations | `shared/PNC/Conversation/PNC_ConversationScene`, `server/PNC/Conversation/PNC_ConversationServer` | Server/SP scene lease owner. MP client submits requests with the same token; transport cannot grant authority. |
| Persist conversation memory | `shared/PNC/Conversation/Memory/PNC_ConversationMemoryRepository` | Bounded portable schema. Persistence coordinates timing; it does not load UI or response realization. |
| Interpret typed/structured input | `client/PNC/Semantics/PNC_SemanticDialogueInput` | `DialogueInput.Submit` / `SubmitSemanticFrame` coordinate parsing, policy and existing adapters. Core supplies reusable parser/IR mechanisms. |
| Register Hoomans language definitions | `shared/PNC/Semantics/PNC_SemanticCatalog` | `Catalog.Register`; useful phrase/concept catalogs stay fine-grained. No gameplay mutation. |
| Select dialogue policy and flow | `shared/PNC/Semantics/PNC_SemanticDialoguePolicy` | Policy decisions/candidates; `CommitFlow` changes bounded dialogue working context, not inventory/orders. |
| Obtain generated suggestions | `shared/PNC/Semantics/PNC_SemanticDialogueSuggestions` | Candidate/frame projection. Typed and clicked input converge on existing submission/authority contracts. |
| Release/query semantic working state | `client/PNC/Semantics/PNC_SemanticDialogueSession` | `ClearWorkingState`, `ReleaseView`, `GetActiveView`; no parser/UI bootstrap. Conversation retains its history, queue and scene-close flags. |
| Observe accepted interaction facts | `shared/PNC/Semantics/PNC_SemanticInteractionLifecycle` | Canonical bounded interaction state/envelope. The existing server handler validates facts and hands off; facts do not replace gameplay commands. |
| Query social evidence | `shared/PNC/Semantics/PNC_SemanticInteractionEvidence`, `PNC_SemanticInteractionRelations` | Read bounded accepted facts; Social services own relationship/conduct mutations. |
| Realize response wording | `shared/PNC/Semantics/PNC_SemanticDialogueRealizationAuthority` | `Resolve` / `AttachProvenance`; preserve response-plan provenance and existing queue/TTS delivery. No hidden action dispatch. |
| Inspect semantic diagnostics | `shared/PNC/Semantics/PNC_SemanticDiagnostics` | Bounded optional `Record`; diagnostic enablement remains centrally configured. |

Specialist public contracts (camp shapes, address selection, combat utterances,
world observations, transport adapters, optional LLM validation) are listed in
the manifest. A currently foreign caller does not make a private provider a
public API. The reviewed specialist paths expose existing top-level operations;
foreign imports into their implementation providers are rejected by the guard.

## Authority and state

Semantic IR remains the common meaning contract. Deterministic interpretation
and policy work without an LLM. Optional providers return validated meaning or
wording; they do not bypass authoritative task admission, queues or receipts.

Each mutable state keeps its current owner: scene leases, interaction facts,
working dialogue context, relationship/conduct state and compact memory are
separate responsibilities. No facade reconstructs duplicate authoritative state.
Keep direct calls within an owner. Public specialist queries are preferable to
loading a full dialogue application merely to read one bounded contract.

## Tooling evidence contract

The Semantic Lab worker retains **all** wire events in `transport` and keeps
`sideEffects.none` / `transportCount` as complete-traffic observations. Added
`dispatchTransport` and `factTransport` views distinguish the existing
`SemanticInteractionLifecycle` fact protocol from executable dispatch evidence.
Unknown commands stay in dispatch evidence. `noGameplayEffects`,
`dispatchTransportCount` and `factTransportCount` make assertions explicit.

This is reporting only: the production transport still executes, validates and
records lifecycle facts. The new views neither suppress events nor create a
second state store. Snapshot/no-change comparisons and explicit fact checks
retain complete-wire assertions. Gameplay-dispatch tests use the new view.

Authoring and presentation IDs have distinct contracts: `semanticTemplateID`
identifies meaning; an emitted `key` may be a generated locale key; compiler
`locations` uses `phrase.<semanticTemplateID>` for wording-family source ownership.
Do not substitute one ID space for another in fixtures or diagnostic consumers.

## Current migration scope

The P5A close working set was 6 files / 1,151 lines / 40,190 bytes, versus
P0's 7 / 1,311 / 46,385. P5C adds the small semantic-session owner seam;
that extra file removes foreign working-state writes and supports independent
retrieval/testing. Handoffs remain 2 rather than P0's 3. Begin/heartbeat implementation
is outside that coherent slice. The factory returns the public Finish callback
directly; obsolete private factory/finish files have no retained shim.

The 44 supported semantic paths and 66 foreign literal-import edges are reviewed
in `P5B_MCP_TRACES.json`, plus the typed identity transport entry owned by Networking, with graph coverage and statement-form import
limitations recorded. This establishes subdomain navigation/public boundaries;
it does not claim P5's remaining cycle and legacy-fixture work is complete.
