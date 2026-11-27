-- Server-authoritative off-camera zombie hazard zone evaluator and
-- Sandbox-configurable colonist SOS / permadeath policy.
-- Uses O(1) IsoMetaChunk:getZombieIntensity() plus a pluggable threat-provider
-- seam for future roaming hordes, with deterministic save-file seeded rolls.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.AbstractHazardResolver = PNC.AbstractHazardResolver or {}

local Hazard = PNC.AbstractHazardResolver
local Store = PNC.HoomansWorldView
local Groups = PNC.AbstractGroups
local Profiles = PNC.AbstractCombatProfile
local Config = PNC.DirectorConfig

Hazard.ThreatProviders = Hazard.ThreatProviders or {}
Hazard.RecentEvents = Hazard.RecentEvents or {}
Hazard.Cooldowns = Hazard.Cooldowns or {}

Hazard.MAX_RECENT_EVENTS = 32
Hazard.CHECK_COOLDOWN_HOURS = 1.0
Hazard.THREAT_THRESHOLD = 45

local function getWorldSeed()
    local cg = PsychopatzCore and PsychopatzCore.SurvivorWorld
        and PsychopatzCore.SurvivorWorld.CorridorGraph or nil
    if cg and type(cg.GetWorldSeed) == "function" then
        return tonumber(cg.GetWorldSeed()) or 0
    end
    if Store and type(Store.WorldSeed) == "function" then
        return tonumber(Store.WorldSeed()) or 0
    end
    return 0
end

local function seededUnit(salt)
    local cg = PsychopatzCore and PsychopatzCore.SurvivorWorld
        and PsychopatzCore.SurvivorWorld.CorridorGraph or nil
    if cg and type(cg.UnitRoll) == "function" then
        return cg.UnitRoll(getWorldSeed(), salt)
    end
    local hash = (2166136261 + math.floor(getWorldSeed())) % 2147483647
    local text = tostring(salt or "")
    for i = 1, #text do
        hash = (hash * 16777619 + string.byte(text, i)) % 2147483647
    end
    return (hash % 1000000) / 1000000
end

local function recordEvent(event)
    local list = Hazard.RecentEvents
    list[#list + 1] = event
    while #list > Hazard.MAX_RECENT_EVENTS do
        table.remove(list, 1)
    end
    return event
end

function Hazard.RegisterThreatProvider(id, providerFn)
    id = tostring(id or "")
    if id == "" or type(providerFn) ~= "function" then return false end
    Hazard.ThreatProviders[id] = providerFn
    return true
end

function Hazard.UnregisterThreatProvider(id)
    id = tostring(id or "")
    if id == "" or Hazard.ThreatProviders[id] == nil then return false end
    Hazard.ThreatProviders[id] = nil
    return true
end

-- O(1) in-memory IsoMetaChunk zombie intensity lookup (0..255). Never loads chunks.
function Hazard.SampleMetaZombieIntensity(x, y)
    x = tonumber(x)
    y = tonumber(y)
    if x == nil or y == nil then return 0 end
    local world = getWorld and getWorld() or nil
    local metaGrid = world and world.getMetaGrid and world:getMetaGrid() or nil
    if not metaGrid then return 0 end
    local chunkX = math.floor(x / 10)
    local chunkY = math.floor(y / 10)
    local ok, chunkData
    if type(metaGrid.getChunkData) == "function" then
        ok, chunkData = pcall(metaGrid.getChunkData, metaGrid, chunkX, chunkY)
    end
    if not ok or not chunkData then return 0 end
    if type(chunkData.getZombieIntensity) == "function" then
        local okI, val = pcall(chunkData.getZombieIntensity, chunkData)
        if okI and tonumber(val) then
            return math.max(0, tonumber(val))
        end
    end
    return 0
end

function Hazard.EvaluateThreatAt(x, y, at)
    local metaIntensity = Hazard.SampleMetaZombieIntensity(x, y)
    local providerTotal = 0
    local sources = {}
    if metaIntensity > 0 then
        sources[#sources + 1] = { id = "metagrid_zombies", intensity = metaIntensity }
    end
    local ids = {}
    for id in pairs(Hazard.ThreatProviders) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    for i = 1, #ids do
        local id = ids[i]
        local fn = Hazard.ThreatProviders[id]
        local ok, val = pcall(fn, x, y, at)
        local num = ok and math.max(0, tonumber(val) or 0) or 0
        if num > 0 then
            providerTotal = providerTotal + num
            sources[#sources + 1] = { id = id, intensity = num }
        end
    end
    return {
        totalThreat = metaIntensity + providerTotal,
        metaIntensity = metaIntensity,
        providerThreat = providerTotal,
        sources = sources,
    }
end

local function findNearbyShelterBuilding(x, y)
    x = tonumber(x) or 0
    y = tonumber(y) or 0
    local world = getWorld and getWorld() or nil
    local metaGrid = world and world.getMetaGrid and world:getMetaGrid() or nil
    if metaGrid and type(metaGrid.getBuildingsIntersecting) == "function" then
        local ok, list = pcall(
            metaGrid.getBuildingsIntersecting,
            metaGrid,
            math.floor(x - 60),
            math.floor(y - 60),
            120,
            120
        )
        if ok and list and type(list.size) == "function" and list:size() > 0 then
            local bestX, bestY, bestDistSq = nil, nil, math.huge
            local count = math.min(list:size(), 16)
            for i = 0, count - 1 do
                local b = list:get(i)
                if b and type(b.getX) == "function" and type(b.getY) == "function" then
                    local bx = tonumber(b:getX()) or x
                    local by = tonumber(b:getY()) or y
                    local bw = type(b.getW) == "function" and (tonumber(b:getW()) or 4) or 4
                    local bh = type(b.getH) == "function" and (tonumber(b:getH()) or 4) or 4
                    local cx = math.floor(bx + bw * 0.5)
                    local cy = math.floor(by + bh * 0.5)
                    local dx, dy = cx - x, cy - y
                    local dSq = dx * dx + dy * dy
                    if dSq < bestDistSq then
                        bestDistSq = dSq
                        bestX, bestY = cx, cy
                    end
                end
            end
            if bestX and bestY then
                return { x = bestX, y = bestY, z = 0, shelteredInBuilding = true }
            end
        end
    end
    return { x = math.floor(x + 0.5), y = math.floor(y + 0.5), z = 0, shelteredInBuilding = false }
end

local function applyItemLoss(record, lossPct, saltPrefix)
    lossPct = math.max(0, math.min(100, tonumber(lossPct) or 0))
    if lossPct <= 0 or type(record) ~= "table" then return 0 end
    local inv = type(record.inventory) == "table" and record.inventory or nil
    local items = inv and (type(inv.items) == "table" and inv.items or inv) or nil
    if type(items) ~= "table" or #items == 0 then return 0 end
    local removed = 0
    local kept = {}
    for i = 1, #items do
        local roll = seededUnit(tostring(saltPrefix) .. ":item:" .. tostring(i)) * 100
        if roll < lossPct then
            removed = removed + 1
        else
            kept[#kept + 1] = items[i]
        end
    end
    if type(inv.items) == "table" then
        inv.items = kept
    else
        record.inventory = kept
    end
    return removed
end

-- Sandbox-configurable colonist loss policy: deterministic SOS shelter roll vs permadeath.
function Hazard.ApplyColonistLossPolicy(record, x, y, at, cause, salt)
    if type(record) ~= "table" then return nil, "record_required" end
    at = tonumber(at) or (Store and Store.WorldAgeHours and Store.WorldAgeHours() or 0)
    cause = tostring(cause or "zombie_hazard")
    local sosChance = PNC.Sandbox and PNC.Sandbox.OffCameraColonistSOSChance
        and PNC.Sandbox.OffCameraColonistSOSChance() or 70.0
    local itemLossPct = PNC.Sandbox and PNC.Sandbox.OffCameraColonistSOSItemLossPercent
        and PNC.Sandbox.OffCameraColonistSOSItemLossPercent() or 50.0
    local roll = seededUnit(tostring(salt or record.id) .. ":sos:" .. tostring(math.floor(at * 60 + 0.5))) * 100

    if PNC.Travel and PNC.Travel.Service and PNC.Travel.Service.Cancel then
        pcall(PNC.Travel.Service.Cancel, record, "off_camera_hazard")
    else
        record.travel = nil
    end

    if roll < sosChance then
        local shelter = findNearbyShelterBuilding(x, y)
        record.x = shelter.x
        record.y = shelter.y
        record.z = shelter.z or 0
        record.health = type(record.health) == "table" and record.health or { max = 100 }
        local maxHp = math.max(1, tonumber(record.health.max) or 100)
        record.health.current = math.max(10, math.floor(maxHp * 0.25))
        local itemsLost = applyItemLoss(record, itemLossPct, tostring(record.id) .. ":" .. tostring(math.floor(at * 60)))
        record.sosState = {
            active = true,
            x = shelter.x,
            y = shelter.y,
            z = shelter.z or 0,
            shelteredInBuilding = shelter.shelteredInBuilding == true,
            at = at,
            cause = cause,
            itemsLost = itemsLost,
        }
        local ev = recordEvent({
            kind = "COLONIST_SOS",
            npcId = record.id,
            npcName = record.name or record.id,
            x = shelter.x,
            y = shelter.y,
            z = shelter.z or 0,
            at = at,
            cause = cause,
            itemsLost = itemsLost,
            shelteredInBuilding = shelter.shelteredInBuilding == true,
        })
        if Store and Store.Emit then
            Store.Emit("ABSTRACT_COLONIST_SOS", ev)
        end
        if PNC.AbstractAftermathService and PNC.AbstractAftermathService.OnOffCameraOutcome then
            PNC.AbstractAftermathService.OnOffCameraOutcome(ev, at)
        end
        return "SOS", ev
    end

    record.alive = false
    record.health = type(record.health) == "table" and record.health or { max = 100 }
    record.health.current = 0
    record.health.state = "dead"
    record.x = math.floor((tonumber(x) or tonumber(record.x) or 0) + 0.5)
    record.y = math.floor((tonumber(y) or tonumber(record.y) or 0) + 0.5)
    local ev = recordEvent({
        kind = "COLONIST_DEAD",
        npcId = record.id,
        npcName = record.name or record.id,
        x = record.x,
        y = record.y,
        z = record.z or 0,
        at = at,
        cause = cause,
    })
    if Store and Store.Emit then
        Store.Emit("ABSTRACT_COLONIST_DEAD", ev)
    end
    if PNC.AbstractAftermathService and PNC.AbstractAftermathService.OnOffCameraOutcome then
        PNC.AbstractAftermathService.OnOffCameraOutcome(ev, at)
    end
    return "DEAD", ev
end

function Hazard.ResolveForParticipants(participants, x, y, at, opts)
    opts = type(opts) == "table" and opts or {}
    at = tonumber(at) or (Store and Store.WorldAgeHours and Store.WorldAgeHours() or 0)
    local threat = opts.threatOverride or Hazard.EvaluateThreatAt(x, y, at)
    local totalThreat = tonumber(threat and threat.totalThreat) or 0
    if totalThreat < (tonumber(opts.threshold) or Hazard.THREAT_THRESHOLD) then
        return { outcome = "CLEAR", threat = totalThreat }
    end
    local profile = Profiles and Profiles.BuildForParticipants
        and Profiles.BuildForParticipants(participants, opts.resources, opts)
        or { overallPower = 1, defense = 1, mobility = 1, memberCount = #participants }

    local actorScore = math.max(0.25, (tonumber(profile.overallPower) or 1) * 18
        + (tonumber(profile.defense) or 0.5) * 12
        + (tonumber(profile.mobility) or 0.5) * 10)
    local salt = tostring(opts.entityId or "hazard") .. ":" .. tostring(math.floor(x / 10))
        .. ":" .. tostring(math.floor(y / 10)) .. ":" .. tostring(math.floor(at * 10))
    local variance = 0.8 + seededUnit(salt .. ":var") * 0.4
    local ratio = (actorScore * variance) / math.max(1, totalThreat)

    if ratio >= 1.15 then
        local ev = recordEvent({
            kind = "HAZARD_CLEARED",
            entityId = opts.entityId,
            x = x, y = y, z = 0, at = at,
            threat = totalThreat,
            ratio = ratio,
        })
        return { outcome = "CLEARED", threat = totalThreat, ratio = ratio, event = ev }
    elseif ratio >= 0.65 then
        local ev = recordEvent({
            kind = "HAZARD_WOUNDED",
            entityId = opts.entityId,
            x = x, y = y, z = 0, at = at,
            threat = totalThreat,
            ratio = ratio,
        })
        if Store and Store.Emit then
            Store.Emit("ABSTRACT_HAZARD_SKIRMISH", ev)
        end
        return { outcome = "WOUNDED", threat = totalThreat, ratio = ratio, event = ev }
    end

    -- Overwhelmed!
    local details = {}
    if opts.isPlayerColonist == true and type(participants[1]) == "table" then
        local policyOutcome, policyEv = Hazard.ApplyColonistLossPolicy(
            participants[1], x, y, at, "zombie_hazard", salt
        )
        details.policyOutcome = policyOutcome
        details.event = policyEv
    else
        local ev = recordEvent({
            kind = "HAZARD_OVERWHELMED",
            entityId = opts.entityId,
            x = x, y = y, z = 0, at = at,
            threat = totalThreat,
            ratio = ratio,
        })
        details.event = ev
        if Store and Store.Emit then
            Store.Emit("ABSTRACT_HAZARD_OVERWHELMED", ev)
        end
        if PNC.AbstractAftermathService and PNC.AbstractAftermathService.OnOffCameraOutcome then
            PNC.AbstractAftermathService.OnOffCameraOutcome(ev, at)
        end
    end
    return {
        outcome = "OVERWHELMED",
        threat = totalThreat,
        ratio = ratio,
        policyOutcome = details.policyOutcome,
        event = details.event,
    }
end

function Hazard.Tick(at, budget)
    at = tonumber(at) or (Store and Store.WorldAgeHours and Store.WorldAgeHours() or 0)
    budget = math.max(1, math.floor(tonumber(budget) or 8))
    local checked = 0
    local encounters = PNC.AbstractEncounters

    -- 1. Check abstracted traveling player colonists.
    if PNC.Registry and type(PNC.Registry.List) == "function" then
        for _, record in ipairs(PNC.Registry.List()) do
            if checked >= budget then break end
            if type(record) == "table"
                and record.alive ~= false
                and record.recruited == true
                and record.presenceState ~= (PNC.Const and PNC.Const.PRESENCE_LIVE)
                and type(record.travel) == "table"
                and record.travel.state == "en_route"
            then
                local key = "npc:" .. tostring(record.id)
                local cd = tonumber(Hazard.Cooldowns[key]) or 0
                if at >= cd then
                    local nearby = encounters and encounters.IsPlayerNearby
                        and encounters.IsPlayerNearby({ x = record.x, y = record.y })
                    if not nearby then
                        Hazard.Cooldowns[key] = at + Hazard.CHECK_COOLDOWN_HOURS
                        Hazard.ResolveForParticipants(
                            { record },
                            record.x,
                            record.y,
                            at,
                            { entityId = key, isPlayerColonist = true }
                        )
                        checked = checked + 1
                    end
                end
            end
        end
    end

    -- 2. Check abstracted traveling AI groups.
    if Groups and type(Groups.List) == "function" then
        for _, group in ipairs(Groups.List()) do
            if checked >= budget then break end
            if type(group) == "table" and group.state == "TRAVELING" and type(group.journey) == "table" then
                local key = "group:" .. tostring(group.id)
                local cd = tonumber(Hazard.Cooldowns[key]) or 0
                if at >= cd then
                    local gx = tonumber(group.journey.x) or (group.location and group.location.x)
                    local gy = tonumber(group.journey.y) or (group.location and group.location.y)
                    if gx and gy then
                        local nearby = encounters and encounters.IsPlayerNearby
                            and encounters.IsPlayerNearby({ x = gx, y = gy })
                        if not nearby then
                            Hazard.Cooldowns[key] = at + Hazard.CHECK_COOLDOWN_HOURS
                            Hazard.ResolveForParticipants(
                                group.memberIds or group.memberActorIDs or {},
                                gx,
                                gy,
                                at,
                                { entityId = key, resources = group.resources, isPlayerColonist = false }
                            )
                            checked = checked + 1
                        end
                    end
                end
            end
        end
    end

    return checked
end

function Hazard.GetDebugSnapshot()
    local copy = {}
    for i = 1, #Hazard.RecentEvents do
        copy[i] = Hazard.RecentEvents[i]
    end
    return {
        recentEvents = copy,
        threatProviderCount = (function()
            local n = 0
            for _ in pairs(Hazard.ThreatProviders) do n = n + 1 end
            return n
        end)(),
    }
end

return Hazard
