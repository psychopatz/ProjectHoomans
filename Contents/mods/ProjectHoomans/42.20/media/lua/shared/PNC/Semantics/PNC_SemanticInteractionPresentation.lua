-- Presentation adapters for an already-selected InteractionPlan.
-- This module never selects behavior, content identity, or gameplay authority.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local ConversationRegistry = require
    "PNC/Semantics/Generated/Conversation/Registry"
local ResponsePlan = require
    "PNC/Semantics/PNC_SemanticDialogueResponsePlan"
local SpeechRealization = require "PNC/Semantics/PNC_SpeechRealization"
local ValueBounds = require "PNC/Semantics/PNC_SemanticValueBounds"
local TacticalLanguage = require
    "PNC/Semantics/PNC_SemanticTacticalSpatialLanguage"

local Presentation = PNC.Semantics.InteractionPresentation or {}
PNC.Semantics.InteractionPresentation = Presentation

Presentation.VERSION = 1

local function copy(value)
    return ValueBounds.Copy(value)
end

local function styleContext(projection, actorID)
    projection = type(projection) == "table" and projection or {}
    local actor = type(projection.actor) == "table"
        and projection.actor or {}
    local disposition = type(actor.disposition) == "table"
        and actor.disposition or {}
    local relationship = type(projection.relationship) == "table"
        and projection.relationship or {}
    local world = type(projection.world) == "table"
        and projection.world or {}
    return {
        actorID = actorID or actor.id,
        npcID = actorID or actor.id,
        actorConversationContext = {
            personality = {
                aggression = disposition.aggression,
                sociability = disposition.sociability,
                forgiveness = disposition.forgiveness,
                compassion = disposition.empathy,
                bravery = disposition.confidence,
            },
            relationship = {
                state = relationship.state,
                approval = relationship.approval,
                respect = relationship.respect,
                familiarity = relationship.familiarity,
            },
            traits = copy(actor.traits) or {},
            roles = {},
            situation = {
                inCombat = world.immediateDanger == true,
            },
            bond = {},
        },
        phraseSalt = tostring(actorID or actor.id or "interaction-actor"),
    }
end

local function initialFallback(templateID)
    local family, phrases = ConversationRegistry.FamilyFor(
        templateID, "neutral"
    )
    if type(family) ~= "table"
        or type(phrases) ~= "table"
        or type(phrases[1]) ~= "table"
    then
        return nil, "dialogue_content_family_unavailable"
    end
    return tostring(phrases[1].fallback or "")
end

local function decorateTacticalSpeech(realized, plan, projection)
    if type(realized) ~= "table" or type(plan) ~= "table"
        or tostring(plan.behaviorID or "") ~= "behavior.scene_horde_prompt"
    then
        return realized
    end
    local world = type(projection) == "table"
        and type(projection.world) == "table" and projection.world or {}
    local danger = type(world.danger) == "table" and world.danger or {}
    local spatial = type(danger.spatial) == "table" and danger.spatial or nil
    if not spatial then
        realized.tacticalSpatialSuppressionReason = "spatial_unavailable"
        return realized
    end
    local text, reason, metadata = TacticalLanguage.Decorate(
        realized.fallback,
        "zombie_group",
        spatial,
        spatial.presentationMode
    )
    if metadata then
        realized.fallback = text
        realized.tacticalSpatialPresentation = metadata
    else
        realized.tacticalSpatialSuppressionReason = reason
    end
    return realized
end

local function realizeContent(
    templateID, dialogueAct, projection, actorID, selectionPrefix
)
    if type(templateID) ~= "string" or templateID == "" then
        return nil, "content_template_missing"
    end
    local fallback, reason = initialFallback(templateID)
    if fallback == nil then return nil, reason end
    local response = {
        templateID = templateID,
        fallback = fallback,
        args = {},
        selectionID = tostring(selectionPrefix or "interaction")
            .. ":" .. templateID,
        selectionSource = "interaction_presentation",
    }
    local plan, planReason = ResponsePlan.Attach(
        response, dialogueAct or "ACKNOWLEDGE", nil
    )
    if type(plan) ~= "table" then
        return nil, planReason or "response_plan_unavailable"
    end
    local realized = SpeechRealization.Apply(
        response,
        styleContext(projection, actorID)
    )
    return realized
end

function Presentation.Build(plan, policy, projection, actorID)
    plan = type(plan) == "table" and plan or {}
    policy = type(policy) == "table" and policy or {}
    projection = type(projection) == "table" and projection or {}
    local actor = type(projection.actor) == "table"
        and projection.actor or {}
    local capabilities = type(actor.capabilities) == "table"
        and actor.capabilities or {}
    local outputs = type(plan.outputs) == "table" and plan.outputs or {}
    local result = {
        schemaVersion = Presentation.VERSION,
        behaviorID = plan.behaviorID,
        behaviorAct = plan.behaviorAct,
        semanticOnly = policy.semanticOnly == true,
        speech = nil,
        emote = nil,
        flavor = nil,
        gameplayIntent = nil,
        suppressed = {},
    }

    local speech = outputs.speech
    if type(speech) == "table" then
        if policy.speech == true and capabilities.speech == true then
            local realized, reason = realizeContent(
                speech.contentTemplateID,
                speech.dialogueAct,
                projection,
                actorID,
                "interaction.speech"
            )
            if realized then
                result.speech = decorateTacticalSpeech(
                    realized, plan, projection
                )
            else
                result.suppressed[#result.suppressed + 1] = {
                    output = "speech",
                    reason = reason,
                }
            end
        else
            result.suppressed[#result.suppressed + 1] = {
                output = "speech",
                reason = policy.speech ~= true
                    and "lod_suppressed"
                    or capabilities.speech == false
                        and "capability_unavailable"
                        or "capability_unknown",
            }
        end
    end

    local emote = outputs.emote
    if type(emote) == "table" then
        if policy.emote == true and capabilities.emote == true then
            result.emote = {
                id = emote.id,
                actorID = actorID or actor.id,
                targetActorIDs = copy(plan.targetActorIDs) or {},
            }
        else
            result.suppressed[#result.suppressed + 1] = {
                output = "emote",
                reason = policy.emote ~= true
                    and "lod_suppressed"
                    or capabilities.emote == false
                        and "capability_unavailable"
                        or "capability_unknown",
            }
        end
    end

    local flavor = outputs.flavor
    if type(flavor) == "table" then
        if policy.flavor == true then
            local realized, reason = realizeContent(
                flavor.contentTemplateID,
                flavor.presentationAct or "AMBIENT_FLAVOR",
                projection,
                actorID,
                "interaction.flavor"
            )
            if realized then
                result.flavor = realized
            else
                result.suppressed[#result.suppressed + 1] = {
                    output = "flavor",
                    reason = reason,
                }
            end
        else
            result.suppressed[#result.suppressed + 1] = {
                output = "flavor",
                reason = "lod_suppressed",
            }
        end
    end

    if type(outputs.gameplayIntent) == "table" then
        result.gameplayIntent = {
            id = outputs.gameplayIntent.id,
            authorized = false,
            status = "intent_only",
        }
    end

    return result
end

return Presentation
