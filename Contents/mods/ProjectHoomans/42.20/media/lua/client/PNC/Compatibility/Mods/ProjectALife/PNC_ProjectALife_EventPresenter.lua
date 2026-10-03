-- Nearby Hoomans speakers for normalized Project A-Life world events.

require "PNC/Compatibility/Mods/ProjectALife/PNC_ProjectALife_FlavorDefinitions"

local Client = PNC.Compatibility.ProjectALifeEvents.Client

local function flavorFor(event)
    if event.category == "meta" then
        if event.metaKind == "gunfire" then
            return "projectalife.meta_gunfire"
        elseif event.metaKind == "heli" or event.metaKind == "military" then
            return "projectalife.meta_aircraft"
        elseif event.metaKind == "crash" then
            return "projectalife.meta_crash"
        elseif event.metaKind == "ambience" then
            return "projectalife.meta_ambience"
        end
    elseif event.category == "encounter" then
        if event.stance == "friendly" then
            return "projectalife.encounter_friendly"
        elseif event.stance == "hostile" or event.stance == "careful" then
            return "projectalife.encounter_hostile"
        end
        return "projectalife.encounter_unknown"
    elseif event.category == "faction_stance"
        and (event.stance == "hostile" or event.stance == "careful")
    then
        return "projectalife.faction_hostile"
    elseif event.category == "faction_conflict" then
        if event.direction == "outgoing" then
            return "projectalife.faction_conflict_outgoing"
        end
        return "projectalife.faction_conflict_incoming"
    end
    return nil
end

local function eventRadius(event)
    if event.category == "meta" then
        if event.metaKind == "heli" or event.metaKind == "military" then
            return 120
        elseif event.metaKind == "ambience" then
            return 60
        end
        return 100
    elseif event.category == "encounter" then
        return 48
    elseif event.category == "faction_conflict" then
        return 48
    end
    return 36
end

local function distanceWithin(first, second, radius)
    if not first or not second
        or math.abs(first.z - second.z) > 2
    then
        return false
    end
    local dx = first.x - second.x
    local dy = first.y - second.y
    return (dx * dx) + (dy * dy) <= radius * radius
end

local function playerPosition(player)
    return {
        x = Client.Coordinate(player:getX()),
        y = Client.Coordinate(player:getY()),
        z = Client.Coordinate(player:getZ()),
    }
end

local function chooseSpeaker(player, event, radius)
    local resolver = PNC.CompanionTargetResolver
    if not resolver or type(resolver.CollectNearbyCompanions) ~= "function" then
        return nil
    end
    local candidates = resolver.CollectNearbyCompanions(player, 24)
    local eventPoint = { x = event.x, y = event.y, z = event.z }
    for index = 1, #candidates do
        local target = candidates[index]
        local source = target and target.source or nil
        local point = source and {
            x = Client.Coordinate(source.x),
            y = Client.Coordinate(source.y),
            z = Client.Coordinate(source.z),
        } or nil
        if point and point.x ~= nil and point.y ~= nil
            and point.z ~= nil and distanceWithin(point, eventPoint, radius)
        then
            return target
        end
    end
    return nil
end

local function pruneSeen(now)
    local count = 0
    for eventID, at in pairs(Client.seen) do
        if now - (tonumber(at) or 0) > 180000 then
            Client.seen[eventID] = nil
        else
            count = count + 1
        end
    end
    if count < 96 then return end
    local removed = 0
    for eventID in pairs(Client.seen) do
        Client.seen[eventID] = nil
        removed = removed + 1
        if removed >= 32 then break end
    end
end

local function receive(event)
    local presentation = PNC.SocialFlavorPresentation
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local point = player and playerPosition(player) or nil
    local radius = eventRadius(event)
    local flavorID = flavorFor(event)
    if not presentation or type(presentation.Receive) ~= "function"
        or not point or not flavorID
        or not distanceWithin(point,
            { x = event.x, y = event.y, z = event.z }, radius)
    then
        return false
    end

    local now = Client.NowMs()
    pruneSeen(now)
    if Client.seen[event.eventID] then return false end

    local cooldown = event.category == "faction_stance" and 60000
        or event.category == "encounter" and 25000 or 18000
    local last = tonumber(Client.lastAccepted[event.category]) or 0
    if last > 0 and now - last < cooldown then return false end

    local target = chooseSpeaker(player, event, radius)
    local speakerID = Client.CleanText(target and target.id, 96)
    if not speakerID then return false end

    local accepted = presentation.Receive({
        npcID = speakerID,
        eventID = "projectalife:" .. event.eventID .. ":" .. speakerID,
        flavorID = flavorID,
        family = "projectalife_world_event",
        eventType = "projectalife_" .. event.category,
        socialRole = target.source and (
            target.source.socialRole or target.source.npcType) or "colonist",
        priority = 38,
        llmEligible = false,
        memoryEligible = false,
        context = {
            eventType = "projectalife_" .. event.category,
            projectALifeKind = event.metaKind or event.category,
            projectALifeStance = event.stance,
            projectALifeConflictDirection = event.direction,
            projectALifeConflictDamage = event.damage,
            factionName = event.factionName or "that faction",
        },
        source = {
            kind = "social_flavor",
            channel = "projectalife",
            eventType = "projectalife_" .. event.category,
            contextEligible = false,
        },
        cooldowns = {
            ambientMs = 12000,
            familyMs = cooldown,
            speakerMs = 45000,
            mergeWindowMs = 12000,
        },
    })
    if accepted == true then
        Client.seen[event.eventID] = now
        Client.lastAccepted[event.category] = now
        return true
    end
    return false
end

function Client.HandleAdapterEvent(eventContext)
    if type(eventContext) ~= "table" then return false end
    local event
    if eventContext.event == "projectalife_meta_event" then
        event = Client.NormalizeMeta(eventContext.context)
    elseif eventContext.event == "projectalife_client_flavor" then
        event = Client.NormalizeServer(eventContext.context)
    else
        return false
    end
    return event and receive(event) or false
end

return Client
