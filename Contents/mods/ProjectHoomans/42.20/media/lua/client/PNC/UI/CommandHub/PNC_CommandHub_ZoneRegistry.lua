-- Data-driven zone editor catalog. The window only renders these definitions;
-- adding a new colony zone should not require another UI branch.

require "PsychopatzCore/UI/World/PsychopatzGridRegionSelector"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}
PNC.CommandHub.ZoneRegistry = PNC.CommandHub.ZoneRegistry or {}

local Registry = PNC.CommandHub.ZoneRegistry
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Selector = require "PsychopatzCore/UI/World/PsychopatzGridRegionSelector"
local FishingActions = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_FishingActions"
local CorpseHaulUI = PNC.CommandHub.CorpseHaulUI

Registry.Definitions = Registry.Definitions or {}
Registry.Ordered = Registry.Ordered or {}
Registry.Revision = tonumber(Registry.Revision) or 0

local function rebuild()
    local output = {}
    for _, definition in pairs(Registry.Definitions) do
        output[#output + 1] = definition
    end
    table.sort(output, function(left, right)
        local a, b = tonumber(left.order) or 100, tonumber(right.order) or 100
        if a == b then return tostring(left.id) < tostring(right.id) end
        return a < b
    end)
    Registry.Ordered = output
end

function Registry.Register(definition)
    if type(definition) ~= "table" then return nil end
    local id = tostring(definition.id or "")
    if id == "" then return nil end
    definition.id = id
    Registry.Definitions[id] = definition
    Registry.Revision = Registry.Revision + 1
    rebuild()
    return definition
end

function Registry.Get(id)
    return Registry.Definitions[tostring(id or "")]
end

function Registry.All() return Registry.Ordered end

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function emptyRegion()
    return { levels = {} }
end

local function connected(region)
    if GridRegion.countTiles(region) <= 0 then
        return false, tr("UI_PNC_CommandHub_Zone_Empty",
            "Select at least one tile.")
    end
    if not GridRegion.isConnected(region, 4) then
        return false, tr("UI_PNC_CommandHub_Zone_Disconnected",
            "Selection must be one connected area.")
    end
    return true
end

local function treeCount(region)
    local cell = getCell and getCell() or nil
    if not cell or type(cell.getGridSquare) ~= "function" then return nil end
    local count = 0
    for z, level in pairs(region and region.levels or {}) do
        for y, spans in pairs(level.rows or {}) do
            for index = 1, #spans, 2 do
                for x = spans[index], spans[index + 1] do
                    local ok, square = pcall(cell.getGridSquare, cell, x, y, z)
                    local tree
                    if ok and square and type(square.getTree) == "function" then
                        ok, tree = pcall(square.getTree, square)
                        if ok and tree then count = count + 1 end
                    end
                end
            end
        end
    end
    return count
end

local function validateLumber(region, stats)
    local valid, reason = connected(region)
    if not valid then return false, reason end
    local count = treeCount(region)
    if stats then stats.treeCount = count or 0 end
    if count and count <= 0 then
        return false, tr("UI_PNC_CommandHub_Zone_NoTrees",
            "Selection must include at least one tree.")
    end
    return true, nil, { treeCount = count or 0 }
end

local function validateFishing(region, stats, selector)
    if FishingActions and FishingActions.ValidateRegion then
        return FishingActions.ValidateRegion(region, stats, selector)
    end
    return connected(region)
end

local function stateFor(snapshot, id)
    if id == "corpse_haul" then
        return snapshot and snapshot.settlement
            and snapshot.settlement.corpseHaul or nil
    end
    return snapshot and snapshot.zoneState
        and snapshot.zoneState[id] or nil
end

local function regionSummary(region)
    local count = GridRegion.countTiles(region or emptyRegion())
    return tostring(count) .. " " .. tr("UI_PNC_CommandHub_Zone_Tiles", "TILES")
end

local function zoneSummary(zone, kind)
    if not zone then return tr("UI_PNC_CommandHub_Zone_NotConfigured",
        "NOT CONFIGURED") end
    if kind == "lumber" then
        return tostring(zone.available or 0) .. " "
            .. tr("UI_PNC_CommandHub_Zone_TreesReady", "TREES READY")
    end
    if kind == "fishing" then
        return tostring(zone.spotCount or 0) .. " "
            .. tr("UI_PNC_CommandHub_Zone_FishingSpots", "FISHING SPOTS")
    end
    return tr("UI_PNC_CommandHub_Zone_Configured", "CONFIGURED")
end

local function openRegion(window, definition, section)
    local zone = window:getZoneState()
    local initial = section.initialRegion and section.initialRegion(zone)
        or zone and zone.geometry or emptyRegion()
    local options = {
        title = tr(section.selectorTitleKey, section.selectorTitleFallback),
        instruction = tr(section.selectorHelpKey, section.selectorHelpFallback),
        initialRegion = initial,
        selectionKind = "region",
        maxTiles = tonumber(PNC.Const and PNC.Const[definition.maxTilesKey])
            or definition.maxTiles or 10000,
        highlightColor = section.highlightColor,
        previewColor = section.previewColor,
        validate = section.validate,
        ownerWindow = window,
        player = getSpecificPlayer and getSpecificPlayer(0) or nil,
        playerNum = 0,
        onConfirm = function(region)
            local options = { region = region }
            local existing = window:getZoneState()
            if existing and existing.id then options.zoneId = existing.id end
            local ok, reason
            if PNC.Client and PNC.Client.RequestColonyAction then
                ok, reason = PNC.Client.RequestColonyAction(
                    definition.setAction, options)
            else
                ok, reason = false, "CLIENT_UNAVAILABLE"
            end
            if ok == false then
                window:setStatus(tostring(reason or "ZONE_CREATE_FAILED"))
                return false
            end
            window:setStatus(tr("UI_PNC_CommandHub_Zone_RequestSent",
                "ZONE REQUEST SENT"))
            return true
        end,
    }
    return Selector.Open(options)
end

local function openCorpse(window, sectionID)
    if not CorpseHaulUI or not CorpseHaulUI.Open then return false end
    local result, reason = CorpseHaulUI.Open(window, sectionID)
    if result then
        window:setStatus(tr("UI_PNC_CommandHub_Zone_RequestSent",
            "ZONE REQUEST SENT"))
    end
    if reason == "CORPSE_SOURCE_REQUIRED" then
        reason = tr("UI_PNC_CommandHub_Zone_CorpseSourceRequired",
            "CREATE CORPSE COLLECT FIRST")
    end
    return result, reason
end

local function clearCorpse(window)
    local current = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.colonyManagement or {}
    local settlement = current.settlement or nil
    local ok, reason
    if PNC.Client and PNC.Client.RequestColonyAction then
        ok, reason = PNC.Client.RequestColonyAction(
            "corpse_haul_zones_clear", { baseId = settlement and settlement.id })
    else
        ok, reason = false, "CLIENT_UNAVAILABLE"
    end
    if ok == false then window:setStatus(tostring(reason or "CLEAR_FAILED")) end
    return ok
end

Registry.Register({
    id = "lumber", order = 10,
    titleKey = "UI_PNC_CommandHub_Zone_ChopWood",
    titleFallback = "Chop wood",
    helpKey = "UI_PNC_CommandHub_Zone_ChopWoodHelp",
    helpFallback = "Select the trees colonists may cut.",
    setAction = "lumber_zone_set", clearAction = "lumber_zone_clear",
    maxTilesKey = "LUMBER_MAX_ZONE_TILES", maxTiles = 10000,
    getState = function(snapshot) return stateFor(snapshot, "lumber") end,
    sections = {
        {
            id = "lumber", titleKey = "UI_PNC_CommandHub_Zone_LumberArea",
            titleFallback = "DESIGNATED CHOPPING AREA",
            selectorTitleKey = "UI_PNC_CommandHub_Zone_LumberSelectTitle",
            selectorTitleFallback = "SELECT TREES TO CHOP",
            selectorHelpKey = "UI_PNC_CommandHub_Zone_LumberSelectHelp",
            selectorHelpFallback = "Drag over connected trees to designate them.",
            validate = validateLumber,
            highlightColor = { r = 0.20, g = 1.00, b = 0.28, a = 0.45 },
            previewColor = { r = 0.35, g = 1.00, b = 0.40, a = 0.25 },
            summary = function(zone) return zoneSummary(zone, "lumber") end,
        },
    },
})

Registry.Register({
    id = "corpse_haul", order = 20,
    titleKey = "UI_PNC_CommandHub_Zone_GrabCorpse",
    titleFallback = "Grab corpse",
    helpKey = "UI_PNC_CommandHub_Zone_GrabCorpseHelp",
    helpFallback = "Designate where corpses are collected and dumped.",
    getState = function(snapshot) return stateFor(snapshot, "corpse_haul") end,
    sections = {
        {
            id = "source", titleKey = "UI_PNC_CommandHub_Zone_CorpseCollect",
            titleFallback = "CORPSE COLLECT",
            summary = function(zone)
                return zone and zone.sourceRegion
                    and regionSummary(zone.sourceRegion)
                    or tr("UI_PNC_CommandHub_Zone_NotConfigured", "NOT CONFIGURED")
            end,
            open = function(window)
                return openCorpse(window, "source")
            end,
            clear = clearCorpse,
        },
        {
            id = "destination", titleKey = "UI_PNC_CommandHub_Zone_CorpseDump",
            titleFallback = "CORPSE DUMP",
            summary = function(zone)
                return zone and zone.destinationRegion
                    and regionSummary(zone.destinationRegion)
                    or tr("UI_PNC_CommandHub_Zone_NotConfigured", "NOT CONFIGURED")
            end,
            open = function(window)
                return openCorpse(window, "destination")
            end,
            clear = clearCorpse,
        },
    },
})

Registry.Register({
    id = "fishing", order = 30,
    titleKey = "UI_PNC_CommandHub_Zone_Fishing",
    titleFallback = "Fishing",
    helpKey = "UI_PNC_CommandHub_Zone_FishingHelp",
    helpFallback = "Select connected land and water for fishing.",
    setAction = "fishing_zone_set", clearAction = "fishing_zone_clear",
    maxTilesKey = "FISHING_MAX_ZONE_TILES", maxTiles = 10000,
    getState = function(snapshot) return stateFor(snapshot, "fishing") end,
    sections = {
        {
            id = "fishing", titleKey = "UI_PNC_CommandHub_Zone_FishingArea",
            titleFallback = "DESIGNATED FISHING AREA",
            selectorTitleKey = "UI_PNC_CommandHub_Zone_FishingSelectTitle",
            selectorTitleFallback = "SELECT FISHING AREA",
            selectorHelpKey = "UI_PNC_CommandHub_Zone_FishingSelectHelp",
            selectorHelpFallback = "Select connected land and water; shoreline land becomes fishing spots.",
            validate = validateFishing,
            highlightColor = { r = 0.15, g = 1.00, b = 0.38, a = 0.42 },
            previewColor = { r = 0.30, g = 1.00, b = 0.45, a = 0.28 },
            summary = function(zone) return zoneSummary(zone, "fishing") end,
        },
    },
})

function Registry.OpenSelector(window, definition, section)
    return openRegion(window, definition, section)
end

return Registry
