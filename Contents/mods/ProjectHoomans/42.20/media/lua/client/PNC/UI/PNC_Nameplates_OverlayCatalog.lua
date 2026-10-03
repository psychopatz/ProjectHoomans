local Nameplates = PNC.Nameplates
local Settings = Nameplates.Settings

local overlayDefinitions = {
    { id = "nameplate_debug", setting = "showNameplateDebug",
        labelKey = "UI_PNC_Settings_ShowNameplateDebug" },
    { id = "camp", setting = "showCampDebug", label = "Camp" },
    { id = "path", setting = "showPathDebug", label = "Paths" },
    { id = "combat", setting = "showCombatDebug", label = "Combat" },
    { id = "zombie", setting = "showZombieDebug", label = "",
        labelKey = "UI_PNC_Settings_ShowZombieDebug" },
    { id = "animation", setting = "showAnimationDebug", label = "Animation" },
    { id = "scenes", setting = "showAnimationSceneDebug", label = "Scenes" },
    { id = "faction", setting = "showFactionDebug", label = "Faction" },
    { id = "community", setting = "showCommunityDebug", label = "Community" },
}
local overlayDefinitionByID = {}
for _, definition in ipairs(overlayDefinitions) do
    overlayDefinitionByID[definition.id] = definition
end
overlayDefinitionByID.ai = overlayDefinitionByID.nameplate_debug

function Nameplates.GetOverlayDefinitions()
    return overlayDefinitions
end

function Nameplates.IsOverlayEnabled(id)
    local definition = overlayDefinitionByID[tostring(id or "")]
    return definition ~= nil and Settings[definition.setting] == true
end

function Nameplates.GetOverlayLabel(id)
    local definition = overlayDefinitionByID[tostring(id or "")]
    if definition and definition.labelKey then
        return PNC.Translation.GetKey(definition.labelKey)
    end
    return definition and definition.label or tostring(id or "Overlay")
end

function Nameplates.GetOverlaySummary()
    local active = {}
    for _, definition in ipairs(overlayDefinitions) do
        if Settings[definition.setting] == true then
            active[#active + 1] = Nameplates.GetOverlayLabel(definition.id)
        end
    end
    return #active > 0 and ("ON: " .. table.concat(active, ", ")) or "ON: none"
end
