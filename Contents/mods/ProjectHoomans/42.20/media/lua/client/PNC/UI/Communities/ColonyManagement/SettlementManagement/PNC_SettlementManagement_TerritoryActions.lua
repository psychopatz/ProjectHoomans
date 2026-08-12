local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Support = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"

local Territory = {}

function Territory.Begin(window, operation)
    local snapshot = window.snapshot or {}
    local settlement = snapshot.settlement
    local current = Support.BaseRegion(window)
    local currentCount = GridRegion.countTiles(current)
    local territory = settlement and settlement.territory or {}
    local maximum = operation == "create"
        and (PNC.SettlementDefinitions.STARTING_TERRITORY or 270)
        or tonumber(territory.territoryCapacity) or 0
    local titles = {
        create = Support.Tr("UI_PNC_Base_SelectCreate", "SELECT AREA: BASE TERRITORY"),
        expand = Support.Tr("UI_PNC_Base_SelectExpand", "SELECT AREA TO ADD"),
        shrink = Support.Tr("UI_PNC_Base_SelectShrink", "SELECT AREA TO REMOVE"),
    }
    local options = {
        title = titles[operation],
        instruction = Support.Tr("UI_PNC_Base_SelectHelp",
            "Drag a rectangle; use Add or Erase to shape an irregular connected area."),
        initialRegion = Support.EmptyRegion(),
        guideRegion = operation == "create" and nil or current,
        guideRenderZ = math.floor(getSpecificPlayer(0):getZ()),
        maxTiles = operation == "create" and maximum or nil,
        highlightColor = operation == "shrink"
            and { r = 1, g = 0.25, b = 0.2, a = 0.42 }
            or { r = 0.15, g = 0.7, b = 1, a = 0.44 },
    }
    options.validate = function(region, stats)
        local candidate = operation == "create" and Support.Footprint(region)
            or operation == "expand"
                and GridRegion.union(current, Support.Footprint(region))
            or GridRegion.subtract(current, Support.Footprint(region))
        local ok, reason = Support.ValidateConnected(candidate)
        local claimed = GridRegion.countTiles(candidate)
        if ok and claimed > maximum then ok, reason = false, "BASE_CAPACITY_EXCEEDED" end
        if ok and operation == "expand" and claimed <= currentCount then
            ok, reason = false, "NO_NEW_TERRITORY"
        end
        if ok and operation == "shrink" and claimed >= currentCount then
            ok, reason = false, "NO_TERRITORY_REMOVED"
        end
        return ok, ok and nil or Shared.SettlementReason(reason), {
            claimed = claimed, capacity = maximum, selected = stats.tileCount,
        }
    end
    options.onConfirm = function(region)
        local colony = snapshot.colony or {}
        if operation == "create" then
            PNC.Client.RequestCreateBase({ colonyId = colony.id,
                factionId = colony.factionID or colony.factionId, region = region })
        elseif operation == "expand" then
            PNC.Client.RequestExpandBase({ baseId = settlement.id,
                expectedRevision = settlement.revision, regionDelta = region })
        else
            PNC.Client.RequestShrinkBase({ baseId = settlement.id,
                expectedRevision = settlement.revision, regionDelta = region })
        end
        Support.ApplyLocalResult(window)
    end
    Support.OpenSelector(window, options)
end

return Territory
