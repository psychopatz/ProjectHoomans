-- Translation and static text contracts for the Puppet Opera window.

PNC = PNC or {}

local Internal = PNC.PuppetOperaDebugWindow.Internal

local function tr(key, fallback)
    if PNC.Translation and PNC.Translation.GetKey then
        local value = PNC.Translation.GetKey(key)
        if value and value ~= key then return value end
    end
    return fallback or key
end

Internal.tr = tr
Internal.TEXT_TITLE = tr(
    "UI_PNC_PuppetOpera_Title", "Puppet Opera Scene Builder")
Internal.TEXT_DESCRIPTION = tr(
    "UI_PNC_PuppetOpera_Description",
    "Build a multi-actor scene from existing player and NPC animation routes"
)
Internal.TEXT_NO_ACTOR = tr(
    "UI_PNC_PuppetOpera_SelectActorSlot", "Select actor slot")

return Internal
