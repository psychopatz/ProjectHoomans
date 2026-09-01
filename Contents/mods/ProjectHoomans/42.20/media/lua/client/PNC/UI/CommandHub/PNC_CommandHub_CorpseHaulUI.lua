require "PsychopatzCore/UI/World/PsychopatzGridRegionSelector"

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}
PNC.CommandHub.CorpseHaulUI = PNC.CommandHub.CorpseHaulUI or {}

local CorpseHaulUI = PNC.CommandHub.CorpseHaulUI
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Selector = require "PsychopatzCore/UI/World/PsychopatzGridRegionSelector"

CorpseHaulUI.MAX_TILES = 100000

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function emptyRegion()
    return { levels = {} }
end

local function clientState()
    return PNC.Network and PNC.Network.ClientState or {}
end

local function currentSettlement()
    local snapshot = clientState().colonyManagement or {}
    return snapshot.settlement or {}
end

local function currentConfiguration()
    local settlement = currentSettlement()
    return settlement.corpseHaul or {}, settlement.id
end

local function validateRegion(region)
    if GridRegion.countTiles(region) <= 0 then
        return false, "EMPTY_REGION"
    end
    if not GridRegion.isConnected(region, 4) then
        return false, tr("UI_PNC_CommandHub_CorpseHaul_Disconnected",
            "Selection must be one connected area.")
    end
    return true
end

local function openDestination(sourceRegion, baseId, configuration,
    ownerWindow)
    return Selector.Open({
        title = tr("UI_PNC_CommandHub_CorpseHaul_DestinationTitle",
            "SELECT CORPSE DESTINATION AREA"),
        instruction = tr("UI_PNC_CommandHub_CorpseHaul_DestinationHelp",
            "Drag across the area where collected corpses should be dropped."),
        initialRegion = configuration.destinationRegion or emptyRegion(),
        selectionKind = "region",
        maxTiles = CorpseHaulUI.MAX_TILES,
        guideLayers = {
            {
                region = sourceRegion,
                color = { r = 1, g = 0.62, b = 0.12, a = 0.30 },
            },
        },
        highlightColor = { r = 0.18, g = 0.82, b = 1, a = 0.48 },
        previewColor = { r = 0.35, g = 0.9, b = 1, a = 0.28 },
        validate = validateRegion,
        ownerWindow = ownerWindow,
        player = getSpecificPlayer and getSpecificPlayer(0) or nil,
        playerNum = 0,
        onConfirm = function(destinationRegion)
            local ok, reason
            if PNC.Client and PNC.Client.RequestColonyAction then
                ok, reason = PNC.Client.RequestColonyAction(
                    "corpse_haul_zones_set", {
                        baseId = baseId,
                        sourceRegion = sourceRegion,
                        destinationRegion = destinationRegion,
                    })
            else
                ok, reason = false, "CLIENT_UNAVAILABLE"
            end
            CorpseHaulUI.lastResult = ok
            CorpseHaulUI.lastError = ok and nil or reason
            return ok ~= false
        end,
    })
end

local function openSource(baseId, configuration, ownerWindow)
    return Selector.Open({
        title = tr("UI_PNC_CommandHub_CorpseHaul_SourceTitle",
            "SELECT CORPSE SOURCE AREA"),
        instruction = tr("UI_PNC_CommandHub_CorpseHaul_SourceHelp",
            "Drag across the area where eligible corpses may be collected."),
        initialRegion = configuration.sourceRegion or emptyRegion(),
        selectionKind = "region",
        maxTiles = CorpseHaulUI.MAX_TILES,
        highlightColor = { r = 1, g = 0.62, b = 0.12, a = 0.48 },
        previewColor = { r = 1, g = 0.78, b = 0.25, a = 0.28 },
        validate = validateRegion,
        ownerWindow = ownerWindow,
        player = getSpecificPlayer and getSpecificPlayer(0) or nil,
        playerNum = 0,
        onConfirm = function(sourceRegion)
            return openDestination(sourceRegion, baseId, configuration,
                ownerWindow)
        end,
    })
end

function CorpseHaulUI.Open(ownerWindow, sectionID)
    local configuration, baseId = currentConfiguration()
    CorpseHaulUI.lastError = nil
    if not baseId or tostring(baseId) == "" then
        CorpseHaulUI.lastResult = false
        CorpseHaulUI.lastError = "BASE_NOT_FOUND"
        return false
    end
    if sectionID == "destination" then
        if not configuration.sourceRegion then
            CorpseHaulUI.lastResult = false
            CorpseHaulUI.lastError = "CORPSE_SOURCE_REQUIRED"
            return false, CorpseHaulUI.lastError
        end
        CorpseHaulUI.lastResult = openDestination(
            configuration.sourceRegion, baseId, configuration, ownerWindow)
    else
        CorpseHaulUI.lastResult = openSource(baseId, configuration, ownerWindow)
    end
    return CorpseHaulUI.lastResult ~= nil
end

return CorpseHaulUI
