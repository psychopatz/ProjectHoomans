-- Companion Dogs compatibility: one canonical flavor and bark presentation.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
local Bridge = PNC.Compatibility.CompanionDogs or {}
local Internal = Bridge.Internal or {}
Bridge.Internal = Internal
PNC.Compatibility.CompanionDogs = Bridge
local SocialReactions = PNC.Semantics
    and PNC.Semantics.SocialReactions or nil
if type(SocialReactions) ~= "table" then
    local ok, loaded = pcall(
        require,
        "PNC/Semantics/PNC_SemanticSocialReaction"
    )
    SocialReactions = ok and loaded or nil
end

local function countNearbyPlayers(body, dog)
    local core = PNC.Core
    local count = 0
    local function inspect(player)
        if player and (Internal.Near(player, body, Bridge.PRESENTATION_RADIUS)
            or Internal.Near(player, dog, Bridge.PRESENTATION_RADIUS))
        then
            count = count + 1
        end
    end
    if core and type(core.ForEachPlayer) == "function" then
        core.ForEachPlayer(inspect)
        return count
    end
    return 1
end

function Internal.HasNearbyPlayer(body, dog)
    return countNearbyPlayers(body, dog) > 0
end

function Internal.SendFlavorToNearbyPlayers(body, dog, npcID, dogKey,
    eventID, dogSex, fed)
    local core = PNC.Core
    local network = PNC.Network
    local sent = 0
    local payload
    local eventType = fed and "companion_dog_feed"
        or "companion_dog_greeting"
    local semanticContext = {
        eventType = eventType,
        eventRef = eventID,
        eventID = eventID,
        npcID = tostring(npcID),
        companionDogSex = dogSex or "unknown",
        companionDogFed = fed == true,
        factRefs = { eventID },
        semanticEventFacts = {
            [tostring(eventID)] = {
                eventRef = eventID,
                authoritative = true,
                disclosure = "player",
                summary = fed and "the companion dog was fed"
                    or "the companion dog greeted the survivor",
                happened = fed and "the companion dog was fed"
                    or "the companion dog greeted the survivor",
                dogSex = dogSex or "unknown",
                fed = fed == true,
            },
        },
    }
    local semantic = SocialReactions
        and type(SocialReactions.Resolve) == "function"
        and SocialReactions.Resolve({
            eventType = eventType,
            eventID = eventID,
            npcID = tostring(npcID),
            act = "ACK",
            topic = "companion_dog",
            context = semanticContext,
        }) or nil
    if not network or type(network.SendSocialGreeting) ~= "function" then
        Bridge._lastPresentationReason = "social_transport_unavailable"
        return 0
    end
    if not semantic or type(semantic.fallback) ~= "string"
        or semantic.fallback == ""
    then
        Bridge._lastPresentationReason = "semantic_realization_unavailable"
        return 0
    end
    payload = {
        eventID = eventID,
        npcID = tostring(npcID),
        eventType = eventType,
        interactionType = eventType,
        text = semantic.fallback,
        resolvedText = semantic.fallback,
        semanticOwned = true,
        responsePlanID = semantic.responsePlanID,
        poolID = semantic.realizationFamily,
        realizationFamily = semantic.realizationFamily,
        realizationID = semantic.realizationID,
        contentOwner = semantic.contentOwner,
        factRefs = semantic.groundedFactRefs,
        offerIDs = semantic.offerIDs,
        context = semanticContext,
        source = {
            kind = "semantic_speech",
            channel = "companion_dogs",
            eventType = eventType,
            semanticOwned = true,
            contextEligible = false,
        },
        dogKey = dogKey,
        dogSex = dogSex,
        dogX = dog:getX(),
        dogY = dog:getY(),
        dogZ = dog:getZ(),
    }
    local function send(player)
        local close = player and (
            Internal.Near(player, body, Bridge.PRESENTATION_RADIUS)
            or Internal.Near(player, dog, Bridge.PRESENTATION_RADIUS)
        )
        if close then
            local ok, accepted = Internal.SafeCall(
                network.SendSocialGreeting, player, payload)
            if ok and accepted == true then sent = sent + 1 end
        end
    end
    if core and type(core.ForEachPlayer) == "function" then
        core.ForEachPlayer(send)
    else
        local ok, accepted = Internal.SafeCall(
            network.SendSocialGreeting, nil, payload)
        if ok and accepted == true then sent = 1 end
    end
    Bridge._lastPresentationEventID = eventID
    Bridge._lastPresentationSent = sent
    Bridge._lastPresentationReason = sent > 0 and "delivered" or "no_recipient"
    return sent
end

function Internal.Bark(dog)
    local cd = Internal.CompanionDogs()
    if not cd then return false end
    if type(cd.barkOnce) == "function" then
        local ok, result = Internal.SafeCall(cd.barkOnce, dog)
        return ok and result ~= false
    end
    if type(cd.bark) == "function" then
        local ok, result = Internal.SafeCall(cd.bark, dog)
        return ok and result ~= false
    end
    return false
end

return Bridge
