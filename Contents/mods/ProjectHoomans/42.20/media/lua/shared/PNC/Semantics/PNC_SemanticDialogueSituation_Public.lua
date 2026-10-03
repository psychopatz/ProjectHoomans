-- Semantic situation public projection and rule registration provider.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Situation = PNC.Semantics.DialogueSituation
local Internal = Situation.Internal or {}
Situation.Internal = Internal
local bounded = Internal.Bounded
local fromSource = Internal.FromSource
local activity = Internal.Activity
local needs = Internal.Needs
local emotionalState = Internal.EmotionalState
local healthState = Internal.HealthState
local attitude = Internal.Attitude
local socialStyle = Internal.SocialStyle
local normalizeActivityRule = Internal.NormalizeActivityRule

function Situation.Build(context)
    context = type(context) == "table" and context or {}
    local relationship = type(context.relationship) == "table"
        and context.relationship or {}
    local state = type(context.semanticDialogueState) == "table"
        and context.semanticDialogueState or {}
    local activityValue = activity(context)
    local needValue = needs(context)
    local emotionalValue = emotionalState(context)
    return {
        schemaVersion = Situation.VERSION,
        npc = {
            activity = activityValue,
            needs = needValue,
            emotion = emotionalValue,
            healthState = healthState(context),
            inCombat = fromSource(context, "inCombat") == true,
        },
        social = {
            relationshipState = context.relationshipState,
            attitude = attitude(context, relationship),
            style = socialStyle(context),
            familiarity = bounded(relationship.familiarity, 0, 1),
        },
        conversation = {
            currentTopic = state.currentTopic or context.currentTopic,
            previousTopic = state.previousTopic or context.previousTopic,
            lastIntent = state.lastIntent or context.lastIntent,
            lastAction = state.lastAction or context.lastAction,
            hasPendingQuestion = state.pendingQuestion ~= nil
                or context.pendingQuestion ~= nil,
            hasPendingRequest = state.pendingRequest ~= nil
                or context.pendingRequest ~= nil,
        },
        world = {
            timeBand = context.worldContext
                and context.worldContext.timeBand or nil,
            raining = context.worldContext
                and context.worldContext.weather
                and context.worldContext.weather.raining or nil,
            foggy = context.worldContext
                and context.worldContext.weather
                and context.worldContext.weather.foggy or nil,
            indoors = context.worldContext
                and context.worldContext.environment
                and context.worldContext.environment.indoors or nil,
        },
    }
end

function Situation.RegisterActivityRule(rule)
    local normalized, reason = normalizeActivityRule(rule)
    if not normalized then return false, reason end
    local index
    for index = 1, #Situation.ACTIVITY_RULES do
        if Situation.ACTIVITY_RULES[index].id == normalized.id then
            Situation.ACTIVITY_RULES[index] = normalized
            return true, normalized
        end
    end
    if #Situation.ACTIVITY_RULES >= Situation.MAX_ACTIVITY_RULES then
        return false, "activity_rule_limit"
    end
    Situation.ACTIVITY_RULES[#Situation.ACTIVITY_RULES + 1] = normalized
    return true, normalized
end

return Situation
