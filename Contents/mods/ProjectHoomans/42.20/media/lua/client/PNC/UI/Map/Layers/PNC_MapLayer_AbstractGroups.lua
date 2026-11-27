-- Admin/debug world-map markers for persistent abstract survivor groups.

require "ISUI/Maps/ISWorldMap"
require "PNC/UI/Mobile/PNC_MobileGroupDebugModel"
require "PNC/UI/Mobile/PNC_MobileGroupTrackModel"
local MarkerDiagnostics = require
    "PsychopatzCore/UI/Map/PsychopatzMapMarkerDiagnostics"

PNC = PNC or {}
PNC.AbstractGroupMapLayer = PNC.AbstractGroupMapLayer or {}

local GroupLayer = PNC.AbstractGroupMapLayer
local Layers = PNC.MapLayers
local ClientState = PNC.Network.ClientState
local MobileModel = PNC.MobileGroupDebugModel
local TrackModel = PNC.MobileGroupTrackModel

GroupLayer.lastRequestAt = GroupLayer.lastRequestAt or 0
-- Per-group interpolation state, keyed by group id and rebuilt only when a new
-- director snapshot arrives. Bounded by the snapshot's own group list.
GroupLayer.Tracks = GroupLayer.Tracks or {}
GroupLayer.TrackCount = GroupLayer.TrackCount or 0
GroupLayer.SnapshotToken = GroupLayer.SnapshotToken
GroupLayer.positionScratch = GroupLayer.positionScratch or {}

local COLORS = {
    LOOTER = { r = 1.00, g = 0.22, b = 0.16 },
    RAIDER = { r = 1.00, g = 0.22, b = 0.16 },
    TRADER = { r = 1.00, g = 0.78, b = 0.18 },
    CARAVAN = { r = 1.00, g = 0.78, b = 0.18 },
    SCAVENGER = { r = 0.95, g = 0.55, b = 0.15 },
    REFUGEE = { r = 0.25, g = 0.75, b = 1.00 },
    WANDERER = { r = 0.72, g = 0.72, b = 0.72 },
}

local function markerColor(group)
    local gType = string.upper(tostring(group and group.groupType or ""))
    if COLORS[gType] then return COLORS[gType] end
    local arch = string.upper(tostring(group and group.mobile and group.mobile.archetypeID or ""))
    if string.find(arch, "LOOTER", 1, true) or string.find(arch, "RAIDER", 1, true)
        or string.find(arch, "BANDIT", 1, true)
    then
        return COLORS.LOOTER
    end
    if string.find(arch, "TRADER", 1, true) or string.find(arch, "CARAVAN", 1, true) then
        return COLORS.TRADER
    end
    if string.find(arch, "SCAV", 1, true) then return COLORS.SCAVENGER end
    if string.find(arch, "REFUGEE", 1, true) then return COLORS.REFUGEE end
    return COLORS.WANDERER
end

local function isVisible()
    return PNC.MapDisplay and PNC.MapDisplay.AreBasesVisible
        and PNC.MapDisplay.AreBasesVisible()
        and PNC.MapRawEntityDebug
        and (PNC.MapRawEntityDebug.IsEnabled and PNC.MapRawEntityDebug.IsEnabled()
            or not PNC.MapRawEntityDebug.IsEnabled and PNC.MapRawEntityDebug.ShowRawEntities == true)
        and PNC.Client and PNC.Client.CanUseDebug
        and PNC.Client.CanUseDebug()
end

function GroupLayer.Update(force)
    if not isVisible() then return false end
    local now = PNC.Core.Now()
    if force ~= true
        and now - (tonumber(GroupLayer.lastRequestAt) or 0) < 1500
    then return false end
    GroupLayer.lastRequestAt = now
    local snapshot = ClientState.directorDebug or {}
    return PNC.Client.RequestDirectorDebug(
        snapshot.selectedGroupId, snapshot.selectedLocationId,
        snapshot.population and snapshot.population.selectedSectorId)
end

-- Route polylines are owned exclusively by PsychopatzCore.SurvivorWorldActorMap.
-- This layer renders only abstract group dots and the combat-math hover box.

function GroupLayer.FormatHoverLines(group)
    local members = #(group.memberIds or {})
    local lines = {
        tostring(group.groupType or "SURVIVOR GROUP")
            .. " [" .. tostring(group.id or "?") .. "]",
        "Members: " .. tostring(members),
        tostring(group.mission or "IDLE") .. " / "
            .. tostring(group.state or "IDLE"),
        "Faction: " .. tostring(group.factionId or "independent"),
    }
    if group.mobile then
        lines[#lines + 1] = "Mobile: "
            .. MobileModel.StateText(group.mobile, group)
            .. " / " .. tostring(MobileModel.Presence(
                group.mobile, group))
        lines[#lines + 1] = "Destination: "
            .. MobileModel.TargetText(group.mobile, group)
    end
    local cp = type(group.combatProfile) == "table" and group.combatProfile or nil
    if cp then
        lines[#lines + 1] = string.format(
            "Power: %.2f (Man:%.2f Mor:%.2f Cond:%d%%)",
            tonumber(cp.overallPower) or 0,
            tonumber(cp.manpower) or 0,
            tonumber(cp.morale) or 0,
            math.floor((tonumber(cp.condition) or 0) * 100 + 0.5)
        )
        lines[#lines + 1] = string.format(
            "Offense: Melee %.2f | Ranged %.2f (Ammo:%d %s)",
            tonumber(cp.meleePower) or 0,
            tonumber(cp.rangedPower) or 0,
            math.floor(tonumber(cp.ammoState) or 0),
            tostring(cp.ammoLabel or "EMPTY")
        )
        lines[#lines + 1] = string.format(
            "Defense: %.2f (Armor:%.2f) | Mob:%.2f | Med:%.2f",
            tonumber(cp.defense) or 0,
            tonumber(cp.armorRating) or 0,
            tonumber(cp.mobility) or 0,
            tonumber(cp.medical) or 0
        )
    else
        lines[#lines + 1] = "Power: (uncomputed)"
    end
    local j = type(group.journey) == "table" and group.journey or nil
    if j and j.state == "en_route" then
        local pts = type(j.route) == "table" and type(j.route.points) == "table"
            and #j.route.points or 0
        local prov = type(j.route) == "table" and tostring(j.route.provider or "corridor") or "direct"
        lines[#lines + 1] = string.format(
            "Route: %s (%d pts) %d%% | ETA %.1fh (%.0ft)",
            prov,
            pts,
            math.floor((tonumber(j.progress) or 0) * 100 + 0.5),
            tonumber(j.eta) or 0,
            tonumber(j.distanceTotal) or 0
        )
    end
    return lines
end

local function drawHover(map, group, x, y, color)
    local lines = GroupLayer.FormatHoverLines(group)
    local width = 345
    local height = 12 + (#lines * 16)
    x = math.min((map.width or 0) - width - 5, x + 12)
    y = math.min((map.height or 0) - height - 5, y + 12)
    x, y = math.max(5, x), math.max(5, y)
    map:drawRect(x, y, width, height, 0.94, 0.04, 0.04, 0.04)
    map:drawRectBorder(x, y, width, height, 1,
        color.r, color.g, color.b)
    for index, line in ipairs(lines) do
        local r, g, b = 0.88, 0.88, 0.88
        if index == 1 then
            r, g, b = color.r, color.g, color.b
        elseif string.sub(line, 1, 6) == "Power:" then
            r, g, b = 1.0, 0.88, 0.35
        elseif string.sub(line, 1, 6) == "Route:" then
            r, g, b = 0.45, 0.90, 1.0
        end
        map:drawText(line, x + 8, y + 5 + (index - 1) * 16,
            r, g, b, 1, UIFont.Small)
    end
end

local function worldAgeHours()
    local gameTime = getGameTime and getGameTime() or nil
    return gameTime and gameTime.getWorldAgeHours
        and tonumber(gameTime:getWorldAgeHours()) or nil
end

-- Rebuilds the glide tracks for one snapshot. Cheap by construction: one pass
-- over the snapshot's groups, no allocation for groups that already have a
-- track, and the reused table set is recycled rather than discarded.
local function rebuildTracks(snapshot)
    local received = ClientState.lastDirectorDebugReceiveAt
    if received == GroupLayer.SnapshotToken then return end
    GroupLayer.SnapshotToken = received
    local tracks = GroupLayer.Tracks
    local pool = GroupLayer.TrackPool or {}
    GroupLayer.TrackPool = pool
    local at = worldAgeHours()
    local used, groupID
    local kept = {}
    for _, group in ipairs(snapshot.groups or {}) do
        groupID = tostring(group.id or "")
        if groupID ~= "" then
            local existing = tracks[groupID]
            local track = TrackModel.Begin(group, at, existing)
            if track then
                kept[groupID] = track
            elseif existing then
                -- Group left transit: return its table to the pool.
                pool[#pool + 1] = existing
            end
        end
    end
    -- Retire tracks for groups that vanished or stopped travelling.
    for groupID, existing in pairs(tracks) do
        if not kept[groupID] then pool[#pool + 1] = existing end
    end
    GroupLayer.Tracks = kept
    GroupLayer.TrackCount = 0
    for _ in pairs(kept) do
        GroupLayer.TrackCount = GroupLayer.TrackCount + 1
    end
end

local function clearTracks()
    local tracks = GroupLayer.Tracks
    local hasTrack = false
    for _ in pairs(tracks) do
        hasTrack = true
        break
    end
    if GroupLayer.SnapshotToken == nil and not hasTrack then
        return
    end
    local pool = GroupLayer.TrackPool or {}
    for _, existing in pairs(tracks) do
        pool[#pool + 1] = existing
    end
    GroupLayer.TrackPool = pool
    GroupLayer.Tracks = {}
    GroupLayer.TrackCount = 0
    GroupLayer.SnapshotToken = nil
end

-- Marker position for one group: the server's confirmed location for groups
-- that are not in transit, otherwise the interpolated in-between point.
local function markerPosition(group, at)
    local location = group.location
    if not location or not location.x or not location.y then return nil end
    local track = GroupLayer.Tracks[tostring(group.id or "")]
    if not track or not at then return location.x, location.y end
    local projected = TrackModel.Position(track, at, GroupLayer.positionScratch)
    if not projected then return location.x, location.y end
    return projected.x, projected.y
end

function GroupLayer.Render(map)
    if not isVisible() or not map or not map.mapAPI then
        if GroupLayer.TrackCount > 0 then clearTracks() end
        return
    end
    GroupLayer.Update(false)
    if ClientState.directorDebugAuthorized ~= true then
        if GroupLayer.TrackCount > 0 then clearTracks() end
        return
    end
    local snapshot = ClientState.directorDebug or {}
    rebuildTracks(snapshot)
    local at = GroupLayer.TrackCount > 0 and worldAgeHours() or nil
    local mouseX, mouseY = map:getMouseX(), map:getMouseY()
    local hovered, hoveredX, hoveredY, hoveredColor
    local showNames = PNC.MapDisplay.AreNamesVisible
        and PNC.MapDisplay.AreNamesVisible()
    for _, group in ipairs(snapshot.groups or {}) do
        local px, py = markerPosition(group, at)
        if px then
            local x = map.mapAPI:worldToUIX(px, py)
            local y = map.mapAPI:worldToUIY(px, py)
            local color = markerColor(group)
            local dx, dy = mouseX - x, mouseY - y
            local isHovered = dx * dx + dy * dy <= 64
            local size = isHovered and 10 or 7
            map:drawRect(x - size / 2, y - size / 2, size, size, 1,
                color.r, color.g, color.b)
            map:drawRectBorder(x - size / 2, y - size / 2, size, size, 1,
                0.05, 0.05, 0.05)
            if showNames or isHovered then
                local label = group.mobile
                    and MobileModel.StateText(group.mobile, group)
                    or tostring(group.groupType or "GROUP")
                map:drawTextCentre(label, x,
                    y - 18, color.r, color.g, color.b, 1, UIFont.Small)
            end
            if isHovered then
                hovered, hoveredX, hoveredY, hoveredColor = group, mouseX,
                    mouseY, color
            end
        end
    end
    if hovered then
        drawHover(map, hovered, hoveredX, hoveredY, hoveredColor)
    end
end

-- Test/diagnostic seam: the marker coordinate a snapshot group is drawn at,
-- after track interpolation. Does not mutate layer state.
function GroupLayer.MarkerPosition(group)
    return markerPosition(group, worldAgeHours())
end

function GroupLayer.ListDiagnostics()
    local snapshot = ClientState.directorDebug or {}
    rebuildTracks(snapshot)
    local at = GroupLayer.TrackCount > 0 and worldAgeHours() or nil
    local output = {}
    for _, group in ipairs(snapshot.groups or {}) do
        local groupID = tostring(group.id or "")
        local x, y = markerPosition(group, at)
        if groupID ~= "" and x and y then
            output[#output + 1] = {
                kind = "abstract_group",
                source = "ProjectHoomans:AbstractGroups",
                id = groupID,
                groupID = groupID,
                label = tostring(group.groupType or "GROUP"),
                position = {
                    x = tonumber(x), y = tonumber(y),
                    z = tonumber(group.location.z) or 0,
                },
                presence = "abstract",
                physicalPresence = "not_materialized",
                mobile = group.mobile ~= nil,
                state = group.state,
                factionID = group.factionId,
                rendered = isVisible() and
                    ClientState.directorDebugAuthorized == true,
            }
        end
    end
    return output
end

function GroupLayer.ClearTracks()
    clearTracks()
end

if Layers and Layers.Register then
    Layers.Register("pnc_abstract_groups", {
        order = 105,
        isVisible = isVisible,
        render = GroupLayer.Render,
    })
end

MarkerDiagnostics.RegisterSource("ProjectHoomans:AbstractGroups", {
    kind = "abstract_group",
    priority = 80,
    list = GroupLayer.ListDiagnostics,
})

return GroupLayer
