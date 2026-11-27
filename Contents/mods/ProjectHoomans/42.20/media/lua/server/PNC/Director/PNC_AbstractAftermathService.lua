-- Server-authoritative off-camera aftermath/loot site adapter and radio
-- broadcast publisher backed by the canonical PsychopatzCore.SurvivorWorld.Events
-- ledger (persisted in Store.Registry.survivorWorldEvents for reload durability).

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.AbstractAftermathService = PNC.AbstractAftermathService or {}

local Aftermath = PNC.AbstractAftermathService
local Store = PNC.HoomansWorldView
local WorldEvents = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldEvents"
local TownCatalog = require
    "PNC/ConvoEngine/Dialogue/WorldMapTownCatalog"

Aftermath.Sites = Aftermath.Sites or {}
Aftermath.RecentBroadcasts = Aftermath.RecentBroadcasts or {}
Aftermath.MAX_SITES = 16
Aftermath.MAX_BROADCASTS = 24
Aftermath.DEFAULT_TTL_HOURS = 48

local function nowHours(at)
    if tonumber(at) then return tonumber(at) end
    if Store and type(Store.WorldAgeHours) == "function" then
        return tonumber(Store.WorldAgeHours()) or 0
    end
    return 0
end

local function syncSitesCache()
    local events = WorldEvents.List({ ownerMod = "ProjectHoomans" })
    local list = {}
    for i = 1, #events do
        local ev = events[i]
        local p = type(ev.payload) == "table" and ev.payload or {}
        list[#list + 1] = {
            id = ev.id,
            kind = ev.kind,
            x = ev.x,
            y = ev.y,
            z = ev.z or 0,
            npcId = p.npcId,
            npcName = p.npcName,
            refugeKind = p.refugeKind,
            cause = p.cause or "off_camera_encounter",
            lootTier = p.lootTier or "standard",
            lootClaimed = p.lootClaimed == true,
            createdAt = ev.createdAt,
            expiresAt = ev.expiresAt,
            summary = ev.summary,
        }
    end
    while #list > Aftermath.MAX_SITES do
        table.remove(list, 1)
    end
    Aftermath.Sites = list
    return list
end

function Aftermath.SyncToStore()
    if Store and type(Store.Registry) == "table" then
        Store.Registry.survivorWorldEvents = WorldEvents.ExportSnapshot()
        if type(Store.Touch) == "function" then
            Store.Touch("survivor_world_events_updated")
        end
        return true
    end
    return false
end

function Aftermath.RestoreFromStore(at)
    local now = nowHours(at)
    if Store and type(Store.Registry) == "table"
        and type(Store.Registry.survivorWorldEvents) == "table"
    then
        WorldEvents.RestoreSnapshot(Store.Registry.survivorWorldEvents, now)
    end
    syncSitesCache()
    return #Aftermath.Sites
end

local function cardinalDirection(dx, dy)
    local angle = math.atan2(dy, dx)
    local deg = angle * (180 / math.pi)
    if deg < 0 then deg = deg + 360 end
    -- PZ world coords: +x = east, +y = south, -y = north, -x = west.
    if deg >= 337.5 or deg < 22.5 then return "east" end
    if deg < 67.5 then return "southeast" end
    if deg < 112.5 then return "south" end
    if deg < 157.5 then return "southwest" end
    if deg < 202.5 then return "west" end
    if deg < 247.5 then return "northwest" end
    if deg < 292.5 then return "north" end
    return "northeast"
end

local function describeLocation(x, y)
    x = tonumber(x) or 0
    y = tonumber(y) or 0
    if TownCatalog and type(TownCatalog.ResolveTownAt) == "function" then
        local exact = TownCatalog.ResolveTownAt(x, y)
        if exact and exact ~= "" then
            return "in " .. tostring(exact)
        end
    end
    if TownCatalog and type(TownCatalog.GetTowns) == "function" then
        local towns = TownCatalog.GetTowns() or {}
        local bestTown, bestDistSq = nil, 3500 * 3500
        local bestCx, bestCy = 0, 0
        for i = 1, #towns do
            local t = towns[i]
            if t and t.x1 and t.x2 and t.y1 and t.y2 and t.name then
                local cx = (t.x1 + t.x2) * 0.5
                local cy = (t.y1 + t.y2) * 0.5
                local dx, dy = x - cx, y - cy
                local d2 = dx * dx + dy * dy
                if d2 < bestDistSq then
                    bestDistSq = d2
                    bestTown = t.name
                    bestCx, bestCy = cx, cy
                end
            end
        end
        if bestTown then
            return cardinalDirection(x - bestCx, y - bestCy) .. " of " .. tostring(bestTown)
        end
    end
    local gx = math.floor(x / 100) * 100
    local gy = math.floor(y / 100) * 100
    return string.format("near sector %d, %d", gx, gy)
end

local function buildRadioText(event)
    local kind = tostring(event and event.kind or "SKIRMISH")
    local loc = describeLocation(event and event.x, event and event.y)
    if kind == "COLONIST_SOS" then
        local name = tostring(event.npcName or event.npcId or "A survivor")
        local refuge = tostring(event.refugeKind or "area")
        return name .. " broadcast an SOS from a " .. refuge .. " " .. loc .. "."
    elseif kind == "COLONIST_DEAD" then
        local name = tostring(event.npcName or event.npcId or "A survivor")
        return "Radio silence from " .. name .. " " .. loc .. " — gear may still be out there."
    elseif kind == "HAZARD_OVERWHELMED" then
        return "Heavy gunfire and screams heard " .. loc .. " before the signal cut out."
    elseif kind == "CARAVAN_SIGHTING" then
        return "Trader caravan spotted moving " .. loc .. "."
    elseif kind == "LOOTER_ACTIVITY" then
        return "Armed looters reported moving " .. loc .. "."
    end
    return "Skirmish reported along the road " .. loc .. "."
end

function Aftermath.PruneExpired(at)
    local now = nowHours(at)
    local removed = WorldEvents.PruneExpired(now)
    syncSitesCache()
    if removed > 0 then
        Aftermath.SyncToStore()
    end
    return removed
end

function Aftermath.RegisterSite(spec, at)
    if type(spec) ~= "table" then return nil, "spec_required" end
    local x = tonumber(spec.x)
    local y = tonumber(spec.y)
    if x == nil or y == nil then return nil, "coords_required" end
    local now = nowHours(at)
    local ttl = math.max(1, tonumber(spec.ttlHours) or Aftermath.DEFAULT_TTL_HOURS)
    local ev, err = WorldEvents.Publish({
        kind = tostring(spec.kind or "SKIRMISH"),
        ownerMod = "ProjectHoomans",
        x = x,
        y = y,
        z = tonumber(spec.z) or 0,
        radius = tonumber(spec.radius) or 48,
        ttlHours = ttl,
        summary = tostring(spec.summary or buildRadioText(spec)),
        tags = {
            aftermath = true,
            refugeKind = spec.refugeKind,
        },
        payload = {
            npcId = spec.npcId,
            npcName = spec.npcName,
            refugeKind = spec.refugeKind,
            cause = tostring(spec.cause or "off_camera_encounter"),
            lootTier = tostring(spec.lootTier or "standard"),
            lootClaimed = false,
        },
    }, now)
    if not ev then return nil, err end
    syncSitesCache()
    Aftermath.SyncToStore()
    return ev
end

function Aftermath.BroadcastOutcome(event, at)
    if type(event) ~= "table" then return false, "event_required" end
    local now = nowHours(at)
    local text = buildRadioText(event)
    local channelID = PNC.RadioDiscoveryChannel and PNC.RadioDiscoveryChannel.ID
        or "projecthoomans.survivor_net"
    local context = {
        kind = tostring(event.kind or "SKIRMISH"),
        text = text,
        x = tonumber(event.x) or 0,
        y = tonumber(event.y) or 0,
        z = tonumber(event.z) or 0,
        npcId = event.npcId,
        npcName = event.npcName,
        refugeKind = event.refugeKind,
        at = now,
    }
    local aired = false
    local reason = "recorded_only"
    local broadcasts = PsychopatzCore and PsychopatzCore.RadioBroadcasts or nil
    local customRadio = PsychopatzCore and PsychopatzCore.CustomRadio or nil
    if broadcasts and type(broadcasts.Air) == "function" then
        local providerID = PNC.WorldDiscovery and PNC.WorldDiscovery.RADIO_BROADCAST_PROVIDER_ID
            or "projecthoomans.world_discovery"
        local ok, res, resReason = pcall(broadcasts.Air, providerID, {
            channelID = channelID,
            eventType = "off_camera_outcome",
            context = context,
        })
        if ok and res == true then
            aired = true
            reason = "radio_broadcasts"
        elseif ok then
            reason = tostring(resReason or "radio_skipped")
        end
    elseif customRadio and type(customRadio.AirEvent) == "function" then
        local ok, res, resReason = pcall(customRadio.AirEvent, channelID, "off_camera_outcome", context)
        if ok and res == true then
            aired = true
            reason = "custom_radio"
        elseif ok then
            reason = tostring(resReason or "radio_skipped")
        end
    end

    Aftermath.RecentBroadcasts[#Aftermath.RecentBroadcasts + 1] = {
        kind = context.kind,
        text = text,
        x = context.x,
        y = context.y,
        at = now,
        aired = aired,
        reason = reason,
    }
    while #Aftermath.RecentBroadcasts > Aftermath.MAX_BROADCASTS do
        table.remove(Aftermath.RecentBroadcasts, 1)
    end
    return aired, reason, context
end

function Aftermath.OnOffCameraOutcome(event, at)
    if type(event) ~= "table" then return nil end
    local now = nowHours(at)
    local kind = tostring(event.kind or "SKIRMISH")
    local site = nil
    if kind == "COLONIST_SOS" or kind == "COLONIST_DEAD" or kind == "HAZARD_OVERWHELMED" then
        site = Aftermath.RegisterSite({
            kind = kind,
            x = event.x,
            y = event.y,
            z = event.z,
            npcId = event.npcId,
            npcName = event.npcName,
            refugeKind = event.refugeKind,
            cause = event.cause,
            lootTier = kind == "COLONIST_DEAD" and "high" or "standard",
        }, now)
    end
    Aftermath.BroadcastOutcome(event, now)
    return site
end

Aftermath.SIGHTING_GROUP_COOLDOWN_HOURS = 12
Aftermath.SIGHTING_GLOBAL_COOLDOWN_HOURS = 6
Aftermath._lastSightingGlobalAt = Aftermath._lastSightingGlobalAt or -100
Aftermath._sightingGroupCooldowns = Aftermath._sightingGroupCooldowns or {}

-- Lightweight, cooldown-gated radio sightings for passing traders and looters.
function Aftermath.MaybePublishSighting(group, at)
    if type(group) ~= "table" or group.state ~= "TRAVELING"
        or type(group.journey) ~= "table" or group.journey.state ~= "en_route"
    then
        return false, "not_traveling"
    end
    local gType = string.upper(tostring(group.groupType or ""))
    local kind = nil
    if gType == "TRADER" or gType == "CARAVAN" then
        kind = "CARAVAN_SIGHTING"
    elseif gType == "LOOTER" or gType == "RAIDER" then
        kind = "LOOTER_ACTIVITY"
    else
        return false, "unsupported_type"
    end
    local now = nowHours(at)
    if (now - (tonumber(Aftermath._lastSightingGlobalAt) or -100)) < Aftermath.SIGHTING_GLOBAL_COOLDOWN_HOURS then
        return false, "global_cooldown"
    end
    local gid = tostring(group.id or "")
    local nextAllowed = tonumber(Aftermath._sightingGroupCooldowns[gid]) or 0
    if now < nextAllowed then
        return false, "group_cooldown"
    end
    local gx = tonumber(group.journey.x) or (group.location and tonumber(group.location.x))
    local gy = tonumber(group.journey.y) or (group.location and tonumber(group.location.y))
    if not gx or not gy then return false, "no_coords" end

    Aftermath._lastSightingGlobalAt = now
    Aftermath._sightingGroupCooldowns[gid] = now + Aftermath.SIGHTING_GROUP_COOLDOWN_HOURS

    local ev = {
        kind = kind,
        x = gx,
        y = gy,
        z = 0,
        groupId = gid,
        groupType = gType,
        at = now,
    }
    WorldEvents.Publish({
        kind = kind,
        ownerMod = "ProjectHoomans",
        x = gx,
        y = gy,
        z = 0,
        radius = 40,
        ttlHours = 6,
        summary = buildRadioText(ev),
        tags = { sighting = true, groupType = gType },
        payload = { groupId = gid, groupType = gType, materialized = true },
    }, now)
    Aftermath.BroadcastOutcome(ev, now)
    return true, kind
end

function Aftermath.GetDebugSnapshot()
    local sites = syncSitesCache()
    local copySites = {}
    for i = 1, #sites do copySites[i] = sites[i] end
    local broadcasts = {}
    for i = 1, #Aftermath.RecentBroadcasts do
        broadcasts[i] = Aftermath.RecentBroadcasts[i]
    end
    return {
        sites = copySites,
        recentBroadcasts = broadcasts,
    }
end

return Aftermath
