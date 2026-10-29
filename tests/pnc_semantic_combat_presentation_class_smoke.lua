local T = require "tests/support/test"
T.addPackagePaths()

PNC = { Semantics = {} }
require "PsychopatzCore/Semantics/PsychopatzSemantic"
local Plan = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponsePlan.lua"
)
local Catalog = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueResponseCatalog.lua"
)
T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Identity/PNC_Identity.lua"
)
local Suggestions = T.load(
    "ProjectHoomans", "shared",
    "PNC/Semantics/PNC_SemanticDialogueSuggestions.lua"
)

local allowed = {
    BARK = true,
    TACTICAL_PROMPT = true,
    TERMINAL = true,
}
local pools, variants = 0, 0
local sawPrompt, sawBark = false, false

for poolID, pool in pairs(Catalog.POOLS or {}) do
    if string.sub(tostring(poolID), 1, 16) == "semantic.combat." then
        pools = pools + 1
        for _, variant in ipairs(pool.variants or {}) do
            variants = variants + 1
            local plan = variant.plan
            T.truthy(type(plan) == "table",
                poolID .. " variant has a response plan")
            local class = tostring(plan.presentationClass or "")
            T.truthy(allowed[class] == true,
                poolID .. " variant explicitly declares presentation class")
            if class == "TACTICAL_PROMPT" then
                sawPrompt = true
                local offers = plan.turns
                    and plan.turns[1] and plan.turns[1].offers or {}
                T.truthy(#offers > 0,
                    poolID .. " tactical prompt requires executable offers")
                for _, offer in ipairs(offers) do
                    T.truthy(
                        type(offer.frame) == "table"
                            and tostring(offer.frame.action or "") ~= "",
                        poolID .. " tactical offer has a typed gameplay action"
                    )
                end
            elseif class == "BARK" then
                sawBark = true
                -- Barks may offer optional contextual continuation, but those
                -- are not required response actions.
                for _, turn in ipairs(plan.turns or {}) do
                    for _, offer in ipairs(turn.offers or {}) do
                        T.falsy(
                            type(offer.frame) == "table"
                                and tostring(offer.frame.action or ""):match(
                                    "^COMBAT_"
                                ),
                            poolID
                                .. " bark cannot require a tactical combat action"
                        )
                    end
                end
            end
        end
    end
end

T.truthy(pools >= 5, "dynamic combat pool audit found expected semantic pools")
T.truthy(variants > 20, "dynamic combat pool audit covers generated variants")
T.truthy(sawPrompt, "combat catalog contains tactical prompt classification")
T.truthy(sawBark, "combat catalog contains autonomous bark classification")

local prompt = T.truthy(Catalog.Get("semantic.combat.horde.prompt"),
    "horde prompt pool exists")
for _, variant in ipairs(prompt.variants or {}) do
    T.equal(variant.plan.presentationClass, "TACTICAL_PROMPT",
        "every horde prompt variant is response-required")
end

local ack = T.truthy(Catalog.Get("semantic.combat.horde.ack"),
    "horde acknowledgement pool exists")
for _, variant in ipairs(ack.variants or {}) do
    T.equal(variant.plan.presentationClass, "BARK",
        "post-decision acknowledgement is autonomous bark")
    T.equal(#(variant.plan.turns[1].offers or {}), 0,
        "acknowledgement does not ask for another response")
end

local kill = T.truthy(Catalog.Get(
    "semantic.combat.kill.killer.aggressive"
), "killer combat pool exists")
local hasOptionalOffers = false
for _, variant in ipairs(kill.variants or {}) do
    T.equal(variant.plan.presentationClass, "BARK",
        "kill commentary is autonomous even when follow-ups exist")
    if #(variant.plan.turns[1].offers or {}) > 0 then
        hasOptionalOffers = true
    end
end
T.truthy(hasOptionalOffers,
    "bark classification permits optional contextual continuations")

-- A typed equivalent of an active tactical button must bind back to that
-- current authoritative click frame, rather than become a second parser/action
-- implementation.
local eventRef = "combat:horde:typed-parity"
local promptOffers = Catalog.OffersForSelection(
    "semantic.combat.horde.prompt",
    "semantic.combat.horde.prompt.default"
)
local promptOfferIDs = {}
for index, offer in ipairs(promptOffers or {}) do
    promptOfferIDs[index] = offer.id
end
local lifecycle = {
    schema = "semantic.interaction.lifecycle.v1",
    status = "ACTIVE",
    topic = "combat",
    activeBeat = {
        id = "beat:horde:typed-parity",
        topic = "combat",
        act = "QUESTION",
        eventRef = eventRef,
        eventType = "zombie_horde_encounter",
        responsePlanID = "semantic.combat.horde.prompt",
        realizationID = "semantic.combat.horde.prompt.default",
        factRefs = { eventRef },
        offerIDs = promptOfferIDs,
    },
}
local tacticalContext = {
    npcID = "npc-typed-parity",
    presentationClass = "TACTICAL_PROMPT",
    interactionLifecycle = lifecycle,
    actorAuthority = { owned = true, companion = true },
    npcState = { activeBehavior = "FollowOwner" },
}
local tacticalProjection = Suggestions.Build({
    sequence = 9,
    accepted = true,
    ir = {},
    decision = {},
}, tacticalContext, {})
local tacticalView = {
    semanticSuggestions = tacticalProjection,
    session = { semanticInteractionLifecycle = lifecycle },
    spec = {
        npcID = "npc-typed-parity",
        context = tacticalContext,
    },
}
PNC.Semantics.DialogueInput = {
    Internal = {
        Suggestions = Suggestions,
        audit = function() end,
        attachInteractionEnvelope = function() end,
    },
}
local Input = PNC.Semantics.DialogueInput
T.load(
    "ProjectHoomans", "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Lifecycle_Submission_Single_Interpretation.lua"
)
local typedFrame = T.truthy(Input.Internal.TacticalFrameForTyped(
    tacticalView, "Take them!", tacticalContext
), "typed tactical utterance resolves to the active canonical offer frame")
T.equal(typedFrame.action, "COMBAT_ENGAGE",
    "typed equivalent converges on the same combat engage action")
T.equal(typedFrame.origin.eventRef, eventRef,
    "typed equivalent remains guarded by the current encounter event")
local barkContext = {}
for key, value in pairs(tacticalContext) do barkContext[key] = value end
barkContext.presentationClass = "BARK"
T.equal(Input.Internal.TacticalFrameForTyped(
    tacticalView, "Take them.", barkContext
), nil, "ordinary bark context cannot reinterpret text as tactical command")

local ok, reason = Plan.Build({
    dialogueAct = "REACT",
    sourcePoolID = "semantic.combat.invalid",
    presentationClass = "CHATBOT",
    segments = {
        { kind = "literal", text = "bad class" },
    },
})
T.falsy(ok, "unknown presentation class is rejected by plan authority")
T.equal(reason, "response_plan_presentation_class_invalid",
    "invalid class has stable validation reason")

-- Equal-priority named-firearm variants must rotate rather than repeat the
-- exact boast every eligible kill.
Catalog.ResetSelections()
local context = {
    npcID = "npc-antirepeat",
    combatWeaponFamily = "firearm",
    combatSkillBand = "high",
    combatWeaponNamed = true,
}
local first = T.truthy(Catalog.Select(
    "semantic.combat.kill.killer.aggressive",
    context,
    "antirepeat-seed"
), "first named firearm variant selects")
local second = T.truthy(Catalog.Select(
    "semantic.combat.kill.killer.aggressive",
    context,
    "antirepeat-seed"
), "second named firearm variant selects")
T.truthy(first.id ~= second.id,
    "equal-priority combat variants rotate instead of repeating")
T.contains(first.id, "firearm_high_named_",
    "first anti-repeat selection stays in grounded firearm family")
T.contains(second.id, "firearm_high_named_",
    "second anti-repeat selection stays in grounded firearm family")

T.finish("pnc_semantic_combat_presentation_class_smoke")
