-- Registers the colony-settings command-hub branch.
-- Future colony settings should register sibling actions through this module.

PNC = PNC or {}
PNC.CommandHub = PNC.CommandHub or {}
PNC.CommandHub.Colony = PNC.CommandHub.Colony or {}

local Hub = PNC.CommandHub
local Colony = Hub.Colony
local Registry = Hub.Registry
    or require "PNC/UI/CommandHub/PNC_CommandHub_Registry"
local Gates = Hub.Gates

local function colonyDisabledTooltip()
    if Gates.HasColony() then return nil end
    return {
        key = "UI_PNC_CommandHub_Disabled_ColonySettings",
        fallback = "Requires colony data before Colony settings can be opened.",
    }
end

local function toggleColony(_, owner)
    local controller = Hub.ChildController
    if controller and controller.Toggle then
        return controller.Toggle("colony", owner)
    end
    return false
end

local function openProvision(_, owner)
    local provision = PNC.ProvisionSettingsUI
    if not provision then
        provision = require "PNC/UI/Provision/PNC_ProvisionSettingsWindow"
    end
    if provision and provision.Open then
        return provision.Open(owner)
    end
    return false
end

local function colonySnapshot()
    local client = PNC.ColonyManagementClient
    if client and type(client.ReadSnapshot) == "function" then
        local update = client.ReadSnapshot()
        if type(update) == "table" then return update.snapshot or {} end
    end
    return {}
end

local function hasFaction()
    return type(colonySnapshot().faction) == "table"
end

local function factionRequiredTooltip(key)
    if hasFaction() then return nil end
    return {
        key = key,
        fallback = "Requires an established faction.",
    }
end

local function changeNameDisabledTooltip()
    return factionRequiredTooltip("UI_PNC_CommandHub_Disabled_ColonyName")
end

local function changeEmblemDisabledTooltip()
    return factionRequiredTooltip("UI_PNC_CommandHub_Disabled_ColonyEmblem")
end

local function openChangeName()
    local snapshot = colonySnapshot()
    if type(snapshot.faction) ~= "table" then return false end
    local prompt = PNC.ColonyNamePrompt
    if not prompt then
        prompt = require "PNC/UI/Communities/PNC_ColonyNamePrompt"
    end
    if prompt and prompt.Open then
        return prompt.Open({ snapshot = snapshot, mode = "rename" })
    end
    return false
end

local function openChangeEmblem()
    local snapshot = colonySnapshot()
    local faction = snapshot.faction
    if type(faction) ~= "table" then return false end
    local editor = PNC.FactionEmblemEditor
    if not editor then
        editor = require "PNC/UI/Factions/PNC_FactionEmblemEditor"
    end
    if not editor or not editor.Open then return false end
    return editor.Open({
        archetypeID = faction.archetypeID or "settler",
        emblem = faction.emblem,
        seed = faction.id or "player_faction",
        onSave = function(emblem)
            if PNC.Client and PNC.Client.SetFactionEmblem then
                return PNC.Client.SetFactionEmblem(emblem)
            end
            return false, "faction_emblem_unavailable"
        end,
    })
end

Registry.RegisterCategory({
    id = "colony",
    source = "ProjectHoomans",
    order = 30,
    childID = "colony",
    useChildren = false,
    titleKey = "UI_PNC_CommandHub_Category_Colony",
    titleFallback = "Colony",
    tooltipKey = "UI_PNC_CommandHub_ColonyHelp",
    tooltipFallback = "Manage colony policies and identity",
    enabled = Gates.HasColony,
    disabledTooltip = colonyDisabledTooltip,
    onClick = toggleColony,
    selected = function()
        local controller = Hub.ChildController
        return controller and controller.IsOpen
            and controller.IsOpen("colony") or false
    end,
    closeHub = false,
})

function Colony.Register(definition)
    return Registry.RegisterAction("colony", definition)
end

Colony.Register({
    id = "provision_settings",
    source = "ProjectHoomans",
    order = 10,
    titleKey = "UI_PNC_CommandHub_Colony_ProvisionSettings",
    titleFallback = "Provision Settings",
    tooltipKey = "UI_PNC_CommandHub_Colony_ProvisionSettingsHelp",
    tooltipFallback = "Configure food, hydration, and medical reserves",
    onClick = openProvision,
    closePanel = true,
})

Colony.Register({
    id = "change_name",
    source = "ProjectHoomans",
    order = 20,
    titleKey = "UI_PNC_CommandHub_Colony_ChangeName",
    titleFallback = "Change Name",
    tooltipKey = "UI_PNC_CommandHub_Colony_ChangeNameHelp",
    tooltipFallback = "Rename your faction",
    enabled = hasFaction,
    disabledTooltip = changeNameDisabledTooltip,
    onClick = openChangeName,
    closePanel = true,
})

Colony.Register({
    id = "change_emblem",
    source = "ProjectHoomans",
    order = 30,
    titleKey = "UI_PNC_CommandHub_Colony_ChangeEmblem",
    titleFallback = "Change Emblem",
    tooltipKey = "UI_PNC_CommandHub_Colony_ChangeEmblemHelp",
    tooltipFallback = "Edit your faction emblem",
    enabled = hasFaction,
    disabledTooltip = changeEmblemDisabledTooltip,
    onClick = openChangeEmblem,
    closePanel = true,
})

return Colony
