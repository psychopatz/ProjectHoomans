-- Companion Dogs compatibility: one canonical flavor and bark presentation.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
local Bridge = PNC.Compatibility.CompanionDogs or {}
local Internal = Bridge.Internal or {}
Bridge.Internal = Internal
PNC.Compatibility.CompanionDogs = Bridge

local FLAVORS = {
    {
        id = "companion_dogs_good_boy",
        lines = {
            { key = "UI_PNC_CompanionDogs_GoodBoy_1",
                fallback = "Who's a good boy?" },
            { key = "UI_PNC_CompanionDogs_GoodBoy_2",
                fallback = "Good boy. That's a good boy." },
        },
    },
    {
        id = "companion_dogs_good_girl",
        lines = {
            { key = "UI_PNC_CompanionDogs_GoodGirl_1",
                fallback = "Who's a good girl?" },
            { key = "UI_PNC_CompanionDogs_GoodGirl_2",
                fallback = "Good girl. That's a good girl." },
        },
    },
    {
        id = "companion_dogs_good_dog",
        lines = {
            { key = "UI_PNC_CompanionDogs_GoodDog_1",
                fallback = "Who's a good dog?" },
            { key = "UI_PNC_CompanionDogs_GoodDog_2",
                fallback = "Good dog. You look well cared for." },
        },
    },
    {
        id = "companion_dogs_feed_boy",
        lines = {
            { key = "UI_PNC_CompanionDogs_FeedBoy_1",
                fallback = "Here you go, good boy." },
            { key = "UI_PNC_CompanionDogs_FeedBoy_2",
                fallback = "There you go, boy. Eat up." },
        },
    },
    {
        id = "companion_dogs_feed_girl",
        lines = {
            { key = "UI_PNC_CompanionDogs_FeedGirl_1",
                fallback = "Here you go, good girl." },
            { key = "UI_PNC_CompanionDogs_FeedGirl_2",
                fallback = "There you go, girl. Eat up." },
        },
    },
    {
        id = "companion_dogs_feed_dog",
        lines = {
            { key = "UI_PNC_CompanionDogs_FeedDog_1",
                fallback = "Here you go, good dog." },
            { key = "UI_PNC_CompanionDogs_FeedDog_2",
                fallback = "There you go. Eat up." },
        },
    },
}

function Bridge.RegisterFlavors()
    local flavor = PNC.CompanionCommandFlavor
    local index
    local definition
    if not flavor then
        pcall(require, "PNC/Core/Commands/PNC_CompanionCommandFlavor")
        flavor = PNC.CompanionCommandFlavor
    end
    if not flavor or type(flavor.Register) ~= "function" then
        return false
    end
    for index = 1, #FLAVORS do
        definition = FLAVORS[index]
        if type(flavor.Get) ~= "function" or not flavor.Get(definition.id) then
            flavor.Register(definition.id, { npc = definition.lines })
        end
    end
    Bridge._flavorsRegistered = true
    return true
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
    flavorID, eventID, dogSex, fed)
    local core = PNC.Core
    local network = PNC.Network
    local sent = 0
    local payload
    if not network or type(network.SendSocialGreeting) ~= "function" then
        Bridge._lastPresentationReason = "social_transport_unavailable"
        return 0
    end
    Bridge.RegisterFlavors()
    payload = {
        eventID = eventID,
        npcID = tostring(npcID),
        flavorID = flavorID,
        eventType = "companion_dog",
        interactionType = fed and "companion_dog_feed"
            or "companion_dog_greeting",
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
