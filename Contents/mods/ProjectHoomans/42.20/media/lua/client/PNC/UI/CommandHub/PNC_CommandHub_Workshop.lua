PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}
PNC.CommandHub.Workshop = PNC.CommandHub.Workshop or {}

local Hub = PNC.CommandHub
local Registry = require "PNC/UI/CommandHub/PNC_CommandHub_Registry"
local Gates = Hub.Gates

local function openWorkshop(_, owner)
    local workshop = PNC.WorkshopUI
    if not workshop then
        workshop = require "PNC/UI/Workshop/PNC_WorkshopWindow"
    end
    if workshop and workshop.Open then return workshop.Open(owner) end
    return false
end

local function toggleWorkshop(_, owner)
    local controller = Hub.ChildController
    if controller and controller.Toggle then
        return controller.Toggle("workshop", owner)
    end
    return openWorkshop(_, owner)
end

Registry.RegisterCategory({
    id = "workshop",
    source = "ProjectHoomans",
    order = 15,
    childID = "workshop",
    useChildren = false,
    titleKey = "UI_PNC_CommandHub_Category_Workshop",
    titleFallback = "Workshop",
    tooltipKey = "UI_PNC_CommandHub_WorkshopHelp",
    tooltipFallback = "Open crafting and salvaging production",
    enabled = Gates.HasBaseAndStockpile,
    disabledTooltip = Gates.BaseAndStockpileDisabledTooltip,
    onClick = toggleWorkshop,
    selected = function()
        local controller = Hub.ChildController
        return controller and controller.IsOpen
            and controller.IsOpen("workshop") or false
    end,
    closeHub = false,
})

return PNC.CommandHub.Workshop
