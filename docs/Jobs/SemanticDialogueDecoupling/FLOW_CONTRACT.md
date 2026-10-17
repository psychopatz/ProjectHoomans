# Flow ownership and registered-module contract

Status: **registry/kernel implemented; production behavioral ownership still incomplete.** Preserve existing `PNC_SemanticDialogueFlowRegistry` and `...FlowKernel` rather than replacing them.

## Verified current behavior
- Identity and wellbeing definition modules register via `PNC_SemanticDialogueFlowCatalog.lua`.
- Definitions contain triggers, nodes, typed captures, accepts, `responsePool`, and `onMatch`/`onRefuse`/`onUnrelated` controls.
- Registry rejects duplicate IDs, unsupported frame fields, conflicting slot owners, missing nodes and unreachable transitions; kernel has bounded active/suspended sessions and preview vs commit.
- Current `Policy.Decide` attaches `flowPreview` but chooses response branch via `resolveIntentBranch`; actual pool selection remains in `LocalResponse.Resolve` based on that branch.

## Target behavioral contract
1. **Safe eligibility first:** only valid IR and authorized intents can activate a flow; fuzzy or ambiguous mutating input must clarify and must not dispatch effects. Flow participation may not bypass entity/authority checks.
2. **Flow controls reaction:** after preview eligibility, an appropriate flow response pool/plan is selected by the production responder. A flow may ask a follow-up, give a contextual response, clarify or return to a suspended topic without a new `elseif` in central `resolveIntentBranch`.
3. **Legacy fallback:** unmigrated branches continue to work; there is a single deterministic winner and one response, not both a flow and legacy policy responding.
4. **Single commit:** `Preview` is idempotent and effect-free; only accepted user turns advance the active/suspended session exactly once. A gameplay effect requires existing server authorization. An NPC reply must not be misinterpreted as player input.
5. **Stable state:** bounded flow/node/slots/speaker/addressee, stack max and expiry. Multiple NPCs cannot share one pending obligation. Explicit refusal is scoped to the currently addressed question; the original `im fine thanks` identity regression remains protected.
6. **Extension demonstration:** introduce one harmless third pilot flow (e.g. smalltalk / player asks about NPC activity) using a separate Lua definition and authored response pool, optionally an EN/TL shard entry. No central intent/resolver special-casing; compare before/after real PZ traces.
7. **Single source of truth:** the flow declares semantic meaning and response references; translation files contain localized prose only; the semantic GUI previews/edits definitions using the validated production registry. Do not create a second JSON executor.
8. **Diagnostics:** report candidate eligibility, flow selection/transition, chosen response pool/template, fallbacks and authoritative effects. Check native SP/MP first, then add focused worker tests only for a demonstrated gap.

## Implementation sequence
- After deployed Core handshake and native baseline, integrate response selection at the existing policy/response boundary with a small compatibility adapter. Avoid rewriting all social/command branches.
- Migrate identity and wellbeing behavior while keeping their real game decisions and keys unchanged.
- Add a third simple flow proving future extensibility.
- Only then expand graphical authoring and multi-act response realization.
