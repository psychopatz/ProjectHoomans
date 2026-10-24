-- Social-event bridge for the Necroa exposure adapter.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.Necroa = PNC.Compatibility.Necroa or {}

local Social = {}
local EntityRef = PNC.EntityRef
local Network = PNC.Network
local Hooks = PNC.SocialEventHooks
local SocialReactions = PNC.Semantics
    and PNC.Semantics.SocialReactions or nil
if type(SocialReactions) ~= "table" then
    local ok, loaded = pcall(
        require,
        "PNC/Semantics/PNC_SemanticSocialReaction"
    )
    SocialReactions = ok and loaded or nil
end
local ContextProviders = PNC.Semantics
    and PNC.Semantics.ContextProviders or nil
if type(ContextProviders) ~= "table" then
    local ok, loaded = pcall(
        require,
        "PNC/Core/Social/PNC_FlavorTextResolver"
    )
    ContextProviders = ok and loaded or nil
end

local function worldAgeHours()
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return tonumber(getGameTime():getWorldAgeHours()) or 0
    end
    return 0
end

function Social.WorldAgeHours()
    return worldAgeHours()
end

local function relationshipDelta(before, after)
    return {
        approval = (tonumber(after and after.approval) or 0)
            - (tonumber(before and before.approval) or 0),
        respect = (tonumber(after and after.respect) or 0)
            - (tonumber(before and before.respect) or 0),
        familiarity = (tonumber(after and after.familiarity) or 0)
            - (tonumber(before and before.familiarity) or 0),
    }
end

function Social.Role(record)
    if ContextProviders and ContextProviders.ResolveNPCType then
        local ok, role = pcall(ContextProviders.ResolveNPCType, record)
        if ok and role then return tostring(role) end
    end
    return "neutral"
end

function Social.PlayerKey(player)
    if Hooks and Hooks.ResolvePlayerKey then
        local ok, key = pcall(Hooks.ResolvePlayerKey, player)
        if ok and key then return key end
    end
    return nil
end

function Social.Emit(observerRecord, actorKey, eventType, eventID,
    position, ambient, player)
    local targetKey = EntityRef and EntityRef.ForNPC
        and EntityRef.ForNPC(observerRecord.id) or nil
    local event
    local ok
    local processed
    local detail
    local semantic
    local semanticContext
    local semanticAmbient
    if not targetKey or not actorKey or not PNC.SocialEvents
        or not PNC.SocialEvents.Emit
    then
        return false
    end
    event = {
        id = eventID,
        type = eventType,
        actorKey = actorKey,
        targetKey = targetKey,
        occurredAt = worldAgeHours(),
        sourceSystem = "necroa",
        x = position and position.x or nil,
        y = position and position.y or nil,
        z = position and position.z or nil,
        context = {
            observerNPCID = tostring(observerRecord.id),
            source = "necroa_airborne_exposure",
        },
    }
    ok, processed = pcall(PNC.SocialEvents.Emit, event)
    if not ok or not processed or processed.ok ~= true then return false end
    semanticContext = type(ambient) == "table"
        and type(ambient.context) == "table" and ambient.context or {}
    semanticContext.eventType = eventType
    semanticContext.source = "necroa_airborne_exposure"
    semantic = SocialReactions and SocialReactions.Resolve and
        SocialReactions.Resolve({
            eventType = eventType,
            eventID = processed.eventID,
            npcID = observerRecord.id,
            context = semanticContext,
        }) or nil
    if semantic then
        semanticAmbient = {}
        for key, value in pairs(ambient or {}) do
            semanticAmbient[key] = value
        end
        semanticAmbient.resolvedText = semantic.fallback
        semanticAmbient.responsePlanID = semantic.responsePlanID
        semanticAmbient.realizationFamily = semantic.realizationFamily
        semanticAmbient.realizationID = semantic.realizationID
        semanticAmbient.factRefs = semantic.groundedFactRefs
        semanticAmbient.context = semanticContext
    else
        semanticAmbient = ambient
    end
    if player and Network and Network.SendConversationRelationshipForNPC then
        detail = processed.details and processed.details[1] or nil
        Network.SendConversationRelationshipForNPC(
            player,
            observerRecord.id,
            eventType,
            {
                source = eventType,
                eventID = processed.eventID,
                relationshipBefore = detail and detail.relationshipBefore or nil,
                relationshipAfter = detail and detail.relationshipAfter or nil,
                relationshipDelta = relationshipDelta(
                    detail and detail.relationshipBefore or nil,
                    detail and detail.relationshipAfter or nil
                ),
                ambientFlavor = semanticAmbient,
            }
        )
    end
    return true
end

return Social
