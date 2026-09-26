-- Observe public A-Life encounter and reputation APIs on the server.

require "PNC/Compatibility/Mods/ProjectALife/PNC_ProjectALife_EventServer"

local Server = PNC.Compatibility.ProjectALifeEvents.Server
Server.hooks = Server.hooks or {}
Server.installAttempts = tonumber(Server.installAttempts) or 0

local function factionData(actorOrFaction)
    local id
    local data
    local actor
    if type(actorOrFaction) == "string" then
        id = Server.CleanText(actorOrFaction, 64)
    elseif type(actorOrFaction) == "table"
        and type(actorOrFaction.factionId) == "string"
    then
        id = Server.CleanText(actorOrFaction.factionId, 64)
    else
        pcall(function()
            if actorOrFaction and actorOrFaction.getModData then
                data = actorOrFaction:getModData()
            end
        end)
        if type(data) == "table" then
            id = Server.CleanText(data.ProjectALifeFactionId, 64)
            local registry = ProjectALife and ProjectALife.ActorRegistry
            local uid = data.ProjectALifeUID
            if not id and type(uid) == "string" and registry
                and type(registry.read) == "function"
            then
                local ok, value = pcall(registry.read, uid)
                if ok then actor = value end
                id = actor and Server.CleanText(actor.factionId, 64) or nil
            end
        end
    end

    local catalog = ProjectALife and ProjectALife.Catalog
    local faction
    if id and catalog and type(catalog.faction) == "function" then
        local ok, value = pcall(catalog.faction, id)
        if ok then faction = value end
    end
    local general = faction and faction.general
    return id, Server.CleanText(general and general.name, 64)
        or "that faction"
end

local function observeEncounter(definition, point, count)
    if type(definition) ~= "table" then return false end
    local position = Server.EventPosition(point)
    local total = tonumber(count) or 0
    if not position or total < 1 then return false end
    local id = Server.CleanText(definition.id, 56) or "encounter"
    return Server.Emit("projectalife_encounter", {
        eventID = Server.NextEventID("encounter", id),
        x = position.x,
        y = position.y,
        z = position.z,
        atMs = Server.NowMs(),
        stance = Server.NormalizeStance(definition.stance),
        count = total,
    })
end

local function observeReputation(player, actorOrFaction, deed)
    local point = Server.PlayerPosition(player)
    local id, name = factionData(actorOrFaction)
    if not point or not id then return false end
    return Server.Emit("projectalife_faction_stance", {
        eventID = Server.NextEventID("faction", id),
        x = point.x,
        y = point.y,
        z = point.z,
        atMs = Server.NowMs(),
        stance = "hostile",
        factionName = name,
        recipientUsername = Server.PlayerName(player),
        cause = Server.CleanText(deed, 24),
    })
end

local function installEncounterHook()
    local log = ProjectALife and ProjectALife.EncounterLog
    local installed = Server.hooks.encounter
    if type(log) ~= "table" or type(log.record) ~= "function" then
        return false
    end
    if installed and installed.owner == log
        and log.record == installed.wrapper
    then
        return true
    end

    local original = log.record
    local wrapper = function(definition, point, count, reason, groupId)
        local result = original(definition, point, count, reason, groupId)
        if result == true then
            pcall(observeEncounter, definition, point, count)
        end
        return result
    end
    log.record = wrapper
    Server.hooks.encounter = {
        owner = log,
        original = original,
        wrapper = wrapper,
    }
    return true
end

local function installReputationHook()
    local reputation = ProjectALife and ProjectALife.Reputation
    local installed = Server.hooks.reputation
    if type(reputation) ~= "table"
        or type(reputation.escalate) ~= "function"
    then
        return false
    end
    if installed and installed.owner == reputation
        and reputation.escalate == installed.wrapper
    then
        return true
    end

    local original = reputation.escalate
    local wrapper = function(player, actorOrFaction, deed)
        local changed, reason = original(player, actorOrFaction, deed)
        if changed == true then
            pcall(observeReputation, player, actorOrFaction, deed)
        end
        return changed, reason
    end
    reputation.escalate = wrapper
    Server.hooks.reputation = {
        owner = reputation,
        original = original,
        wrapper = wrapper,
    }
    return true
end

function Server.Install()
    local encounter = installEncounterHook()
    local reputation = installReputationHook()
    return encounter and reputation
end

local function removeRetry()
    if Server.retry and Events and Events.OnTick
        and Events.OnTick.Remove
    then
        Events.OnTick.Remove(Server.retry)
    end
    Server.retry = nil
end

local function retryInstall()
    Server.installAttempts = Server.installAttempts + 1
    if Server.Install() or Server.installAttempts >= 1200 then
        removeRetry()
    end
end

if Events and Events.OnTick and Events.OnTick.Add then
    Server.retry = retryInstall
    Events.OnTick.Add(retryInstall)
end
retryInstall()

return Server
