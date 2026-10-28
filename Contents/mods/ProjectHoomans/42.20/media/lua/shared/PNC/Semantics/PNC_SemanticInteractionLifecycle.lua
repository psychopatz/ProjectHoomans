-- Composition hub for the bounded semantic interaction lifecycle.
--
-- The public entrypoint and namespace remain stable. Envelope construction is
-- loaded before the mutable lifecycle state owner so all existing callers keep
-- their public API and load-order contract.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Lifecycle = PNC.Semantics.InteractionLifecycle or {}
PNC.Semantics.InteractionLifecycle = Lifecycle

Lifecycle.VERSION = 1
Lifecycle.SCHEMA = "semantic.interaction.lifecycle.v1"
Lifecycle.ENVELOPE_SCHEMA = "semantic.interaction.envelope.v1"
-- Stable provenance names are kept on the composition hub so inspectors and
-- read-only callers can discover the contract without loading mutable state.
Lifecycle.PROVENANCE_FIELDS = {
    "realizationFamily",
    "realizationID",
}
Lifecycle.LIMITS = {
    factRefs = 8,
    modifiers = 12,
    topicStack = 4,
    turns = 12,
    openQuestions = 8,
    commitments = 8,
    eventRefs = 16,
    realizations = 8,
    sharedEvents = 64,
    pairs = 4096,
}

Lifecycle.Internal = Lifecycle.Internal or {}

require "PNC/Semantics/PNC_SemanticInteractionLifecycle_Envelope"
require "PNC/Semantics/PNC_SemanticInteractionLifecycle_State"

return Lifecycle
