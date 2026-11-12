local Offers = require "PNC/Semantics/PNC_SemanticDialogueBranchOffers"
local ResponsePlan = require "PNC/Semantics/PNC_SemanticDialogueResponsePlan"
local TextBinding = require "PsychopatzCore/Semantics/PsychopatzSemanticTextBinding"

local function truthy(value, label)
    if not value then error(label or "expected truthy") end
end

local offer = {
    id = "ask.direction",
    labelKey = "psdl.social.location.ask.offer.label",
    labelFallback = "Ask for directions",
    utteranceKey = "psdl.social.location.ask.offer.utterance",
    utteranceFallback = "Which way?",
    frame = {intent = "QUESTION", subject = "LOCATION_DIRECTION"},
    consumers = {"participant", "player", "npc"},
    constraints = {
        path = "speaker.traits",
        op = "contains",
        value = "brave",
    },
}
local normalizedOffer, offerReason = Offers.Normalize(offer)
truthy(normalizedOffer, offerReason)
truthy(normalizedOffer.consumers[3] == "npc", "NPC offer consumer")

local built, planOrReason = ResponsePlan.Build({
    dialogueAct = "ANSWER_LOCATION",
    sourcePoolID = "social.location.ask",
    turns = {
        {
            id = "answer",
            segments = {
                {
                    kind = "translation",
                    templateID = "psdl.social.location.ask.answer",
                    fallback = "{target.name} is north of here.",
                    args = {},
                },
            },
            offers = {offer},
        },
        {
            id = "detail",
            segments = {
                {
                    kind = "translation",
                    templateID = "psdl.social.location.ask.detail",
                    fallback = "Ask me if you need the route.",
                    args = {},
                },
            },
        },
    },
})
local plan = built and planOrReason or nil
local planReason = built and nil or planOrReason
truthy(plan, planReason)
truthy(ResponsePlan.Validate(plan), "Core-compatible ResponsePlan")
truthy(plan.turns[1].offers[1].frame.intent == "QUESTION",
    "semantic offer frame preserved without text reparsing")

local rendered, renderReason = TextBinding.Render(
    "{speaker.name} tells {addressee.name} about {target.name}.",
    {
        speaker = {name = "Alice"},
        addressee = {name = "One"},
        target = {name = "the old mill"},
    }
)
truthy(rendered, renderReason)
truthy(rendered == "Alice tells One about the old mill.",
    "actor-neutral presentation bindings")

print("pnc_psdl_core_response_offer_smoke: PASS")
