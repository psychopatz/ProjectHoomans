-- Command hub category definitions and UI action adapters.
--
-- The registry root owns gating and open/close policy. This provider owns
-- the declarative category and zone-action presentation contract.

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}

local CommandHub = PNC.CommandHub
local Internal = CommandHub.RegistryInternal or {}
local Registry = Internal.Registry or CommandHub.Registry
local Gates = Internal.Gates or CommandHub.Gates
local isOpen = Internal.IsOpen
local isZoneActionOpen = Internal.IsZoneActionOpen
local toggleChild = Internal.ToggleChild
local openWork = Internal.OpenWork
local openZone = Internal.OpenZone
local toggleEvents = Internal.ToggleEvents
local isJournalOpen = Internal.IsJournalOpen
local openColonist = Internal.OpenColonist
local openStorage = Internal.OpenStorage
local openResearch = Internal.OpenResearch
local scavengeAvailable = Internal.ScavengeAvailable
local openScavenge = Internal.OpenScavenge
local isScavengeOpen = Internal.IsScavengeOpen
local stockpileBootstrapVisible = Internal.StockpileBootstrapVisible
local stockpileBootstrapEnabled = Internal.StockpileBootstrapEnabled
local stockpileBootstrapDisabledTooltip = Internal.StockpileBootstrapDisabledTooltip
local buildStockpile = Internal.BuildStockpile
local openBase = Internal.OpenBase

if type(Registry) ~= "table" or type(Gates) ~= "table"
    or type(isOpen) ~= "function" or type(toggleChild) ~= "function"
then
    return Registry
end

Registry.SetCategoryOrder({ "work", "workshop", "zone", "scavenge", "colony", "events", "colonist", "storage",
    "research", "stockpile", "base" })

Registry.RegisterCategory({
    id = "work",
    source = "ProjectHoomans",
    order = 10,
    childID = "work",
    useChildren = false,
    titleKey = "UI_PNC_CommandHub_Category_Work",
    titleFallback = "Work",
    tooltipKey = "UI_PNC_CommandHub_WorkHelp",
    tooltipFallback = "Authorize colonists for automatic work",
    enabled = Gates.HasBaseAndStockpile,
    disabledTooltip = Gates.BaseAndStockpileDisabledTooltip,
    onClick = toggleChild("work", openWork),
    selected = function() return isOpen("work") end,
    closeHub = false,
})

Registry.RegisterCategory({
    id = "zone",
    source = "ProjectHoomans",
    order = 20,
    childID = "zone",
    useChildren = false,
    titleKey = "UI_PNC_CommandHub_Category_Zone",
    titleFallback = "Zone",
    tooltipKey = "UI_PNC_CommandHub_ZoneHelp",
    tooltipFallback = "Assign work areas for colony activities",
    enabled = Gates.HasColony,
    disabledTooltip = Gates.BaseDisabledTooltip,
    onClick = toggleChild("zone"),
    selected = function() return isOpen("zone") end,
    closeHub = false,
    actions = {
        {
            id = "base_zone",
            source = "ProjectHoomans",
            order = 5,
            titleKey = "UI_PNC_CommandHub_Zone_Base",
            titleFallback = "Base Zone",
            tooltipKey = "UI_PNC_CommandHub_Zone_BaseHelp",
            tooltipFallback = "Edit the territory that anchors your facilities and storage",
            visible = true,
            enabled = Gates.HasColony,
            disabledTooltip = Gates.BaseDisabledTooltip,
            onClick = openZone("base_zone"),
            selected = function() return isZoneActionOpen("base_zone") end,
            closeHub = false,
        },
        {
            id = "lumber",
            source = "ProjectHoomans",
            order = 10,
            titleKey = "UI_PNC_CommandHub_Zone_ChopWood",
            titleFallback = "Chop wood",
            tooltipKey = "UI_PNC_CommandHub_Zone_ChopWoodHelp",
            tooltipFallback = "Set a tree-cutting zone",
            enabled = Gates.HasBaseAndStockpile,
            disabledTooltip = Gates.BaseAndStockpileDisabledTooltip,
            onClick = openZone("lumber"),
            selected = function() return isZoneActionOpen("lumber") end,
            closeHub = false,
        },
        {
            id = "corpse_haul",
            source = "ProjectHoomans",
            order = 20,
            titleKey = "UI_PNC_CommandHub_Zone_GrabCorpse",
            titleFallback = "Grab corpse",
            tooltipKey = "UI_PNC_CommandHub_Zone_GrabCorpseHelp",
            tooltipFallback = "Choose a corpse source and destination area",
            enabled = Gates.HasBaseAndStockpile,
            disabledTooltip = Gates.BaseAndStockpileDisabledTooltip,
            onClick = openZone("corpse_haul"),
            selected = function() return isZoneActionOpen("corpse_haul") end,
            closeHub = false,
        },
        {
            id = "fishing",
            source = "ProjectHoomans",
            order = 30,
            titleKey = "UI_PNC_CommandHub_Zone_Fishing",
            titleFallback = "Fishing",
            tooltipKey = "UI_PNC_CommandHub_Zone_FishingHelp",
            tooltipFallback = "Set a shoreline fishing zone",
            enabled = Gates.HasBaseAndStockpile,
            disabledTooltip = Gates.BaseAndStockpileDisabledTooltip,
            onClick = openZone("fishing"),
            selected = function() return isZoneActionOpen("fishing") end,
            closeHub = false,
        },
    },
})

Registry.RegisterCategory({
    id = "events",
    source = "ProjectHoomans",
    order = 40,
    childID = "events",
    titleKey = "UI_PNC_CommandHub_Category_Events",
    titleFallback = "Events",
    tooltipKey = "UI_PNC_CommandHub_EventsHelp",
    tooltipFallback = "Open the colony journal",
    onClick = toggleChild("events", toggleEvents),
    selected = isJournalOpen,
    closeHub = false,
})

Registry.RegisterCategory({
    id = "scavenge",
    source = "ProjectHoomans",
    order = 30,
    useChildren = false,
    titleKey = "UI_PNC_CommandHub_Category_Scavenge",
    titleFallback = "Scavenge",
    tooltipKey = "UI_PNC_CommandHub_ScavengeHelp",
    tooltipFallback = "Assign a scavenging team and search nearby loot",
    visible = scavengeAvailable,
    enabled = scavengeAvailable,
    onClick = openScavenge,
    selected = isScavengeOpen,
    closeHub = false,
})

Registry.RegisterCategory({
    id = "colonist",
    source = "ProjectHoomans",
    order = 50,
    childID = "colonist",
    useChildren = false,
    titleKey = "UI_PNC_CommandHub_Category_Colonist",
    titleFallback = "Colonist",
    tooltipKey = "UI_PNC_CommandHub_ColonistHelp",
    tooltipFallback = "Inspect colonist needs and details",
    onClick = toggleChild("colonist", openColonist),
    selected = function() return isOpen("colonist") end,
    closeHub = false,
})

Registry.RegisterCategory({
    id = "storage",
    source = "ProjectHoomans",
    order = 60,
    childID = "storage",
    useChildren = false,
    titleKey = "UI_PNC_CommandHub_Category_Storage",
    titleFallback = "Storage",
    tooltipKey = "UI_PNC_CommandHub_StorageHelp",
    tooltipFallback = "Open colony storage",
    enabled = Gates.HasBaseAndStockpile,
    disabledTooltip = Gates.BaseAndStockpileDisabledTooltip,
    onClick = toggleChild("storage", openStorage),
    selected = function() return isOpen("storage") end,
    closeHub = false,
})

Registry.RegisterCategory({
    id = "research",
    source = "ProjectHoomans",
    order = 70,
    childID = "research",
    useChildren = false,
    titleKey = "UI_PNC_CommandHub_Category_Research",
    titleFallback = "Research",
    tooltipKey = "UI_PNC_CommandHub_ResearchHelp",
    tooltipFallback = "Plan colony upgrades and study research sources",
    onClick = toggleChild("research", openResearch),
    selected = function() return isOpen("research") end,
    closeHub = false,
})

Registry.RegisterCategory({
    id = "stockpile",
    source = "ProjectHoomans",
    order = 75,
    useChildren = false,
    titleKey = "UI_PNC_CommandHub_Category_Stockpile",
    titleFallback = "BUILD STOCKPILE",
    tooltipKey = "UI_PNC_CommandHub_StockpileHelp",
    tooltipFallback = "Create the colony's first stockpile",
    visible = stockpileBootstrapVisible,
    enabled = stockpileBootstrapEnabled,
    disabledTooltip = stockpileBootstrapDisabledTooltip,
    onClick = buildStockpile,
    closeHub = false,
})

Registry.RegisterCategory({
    id = "base",
    source = "ProjectHoomans",
    order = 80,
    childID = "base",
    useChildren = false,
    titleKey = "UI_PNC_CommandHub_Category_Base",
    titleFallback = "Base",
    tooltipKey = "UI_PNC_CommandHub_BaseHelp",
    tooltipFallback = "Plan and place colony buildings",
    enabled = Gates.HasColony,
    disabledTooltip = Gates.BaseDisabledTooltip,
    onClick = toggleChild("base", openBase),
    selected = function() return isOpen("base") end,
    closeHub = false,
})


return Registry
