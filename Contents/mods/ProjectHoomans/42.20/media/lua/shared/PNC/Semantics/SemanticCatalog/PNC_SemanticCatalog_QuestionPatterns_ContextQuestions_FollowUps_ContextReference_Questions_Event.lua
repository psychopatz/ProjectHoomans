-- Typed event follow-up questions. These intentionally do not require a
-- captured pronoun: the active lifecycle beat supplies the event reference.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic event follow-up spoke requires Catalog.Internal")
end

if type(Internal.RegisterContextReferenceQuestion) ~= "function" then
    error("semantic event follow-up spoke requires question core")
end

function Internal.RegisterContextReferenceEventQuestions()
    local register = Internal.RegisterContextReferenceQuestion
    register(
        "pnc.question.context_reference.event_what_happened",
        { { kind = "literal", value = "what" },
          { kind = "literal", value = "happened" } },
        0.99, 140, "EVENT_WHAT_HAPPENED", false,
        { requiresEventFollowUp = true,
          eventOfferID = "semantic.followup.event.happened" }
    )
    register(
        "pnc.question.context_reference.event_location",
        { { kind = "literal", value = "where" },
          { kind = "literal", value = "are" },
          { kind = "literal", value = "they" } },
        0.99, 140, "EVENT_LOCATION", false,
        { requiresEventFollowUp = true,
          eventOfferID = "semantic.followup.event.location" }
    )
    register(
        "pnc.question.context_reference.event_quantity",
        { { kind = "literal", value = "how" },
          { kind = "literal", value = "many" } },
        0.99, 140, "EVENT_QUANTITY", false,
        { requiresEventFollowUp = true,
          eventOfferID = "semantic.followup.event.quantity" }
    )
    register(
        "pnc.question.context_reference.event_attacker",
        { { kind = "literal", value = "who" },
          { kind = "literal", value = "hurt" },
          { kind = "literal", value = "you" } },
        0.99, 140, "EVENT_ATTACKER", false,
        { requiresEventFollowUp = true,
          eventOfferID = "semantic.followup.event.attacker" }
    )
    register(
        "pnc.question.context_reference.event_need",
        { { kind = "literal", value = "what" },
          { kind = "literal", value = "do" },
          { kind = "literal", value = "you" },
          { kind = "literal", value = "need" } },
        0.99, 140, "EVENT_NEED", false,
        { requiresEventFollowUp = true,
          eventOfferID = "semantic.followup.event.need" }
    )
    register(
        "pnc.question.context_reference.event_deceased",
        { { kind = "literal", value = "who" },
          { kind = "literal", value = "died" } },
        0.99, 140, "EVENT_DECEASED", false,
        { requiresEventFollowUp = true,
          eventOfferID = "semantic.followup.event.deceased" }
    )
    register(
        "pnc.question.context_reference.event_next",
        { { kind = "literal", value = "what" },
          { kind = "literal", value = "do" },
          { kind = "literal", value = "we" },
          { kind = "literal", value = "now" } },
        0.99, 140, "EVENT_NEXT", false,
        { requiresEventFollowUp = true,
          eventOfferID = "semantic.followup.event.next" }
    )
    register(
        "pnc.question.context_reference.event_now",
        { { kind = "literal", value = "what" },
          { kind = "literal", value = "now" } },
        0.99, 139, "EVENT_NEXT", false,
        { requiresEventFollowUp = true,
          eventOfferID = "semantic.followup.event.next" }
    )
    register(
        "pnc.question.context_reference.event_health",
        { { kind = "literal", value = "are" },
          { kind = "literal", value = "you" },
          { kind = "literal", value = "hurt" } },
        0.99, 140, "EVENT_HEALTH", false,
        { requiresEventFollowUp = true,
          eventOfferID = "semantic.followup.event.health" }
    )
    register(
        "pnc.question.context_reference.event_pursuer",
        { { kind = "literal", value = "who" },
          { kind = "literal", value = "was" },
          { kind = "literal", value = "after" },
          { kind = "literal", value = "you" } },
        0.99, 140, "EVENT_PURSUER", false,
        { requiresEventFollowUp = true,
          eventOfferID = "semantic.followup.event.pursuer" }
    )
    register(
        "pnc.question.context_reference.event_what",
        { { kind = "literal", value = "what" },
          { kind = "literal", value = "is" },
          { kind = "literal", value = "it" } },
        0.99, 139, "EVENT_WHAT", false,
        { requiresEventFollowUp = true,
          eventOfferID = "semantic.followup.event.what" }
    )
end

return Internal
