-- Shared filename/library choice for both creator hosts.
PNC.NPCAuthoringSaveDialog = PNC.NPCAuthoringSaveDialog or {}
local Dialog = PNC.NPCAuthoringSaveDialog
function Dialog.Open(owner, name, library, callback)
    require "ISUI/ISTextBox"
    require "ISUI/ISTickBox"
    local tr = PNC.Translation.GetKey
    local collection = require "PNC/Core/Definitions/PNC_LocalNPCCollection"
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local canPublish = collection.CanPublish(player)
    local popup
    popup = ISTextBox:new(0, 0, 500, 170,
        tr("UI_PNC_Authoring_SaveName", "Save filename"), tostring(name or ""), owner,
        function(target, button)
            if button.internal ~= "OK" then return end
            local label = popup.entry:getText()
            local fileName = PNC.DefinitionDatabase.FileName(label)
            if not fileName then target:setStatus(tr("UI_PNC_Authoring_InvalidFilename", "Enter a filename containing letters or numbers")); return end
            callback(label, fileName, popup.library and popup.library:isSelected(1) == true)
        end)
    popup:initialise()
    if library ~= nil then
        local y = popup.yes.y
        local height = getTextManager():getFontHeight(UIFont.Small) + 12
        local check = ISTickBox:new(12, y, popup.width - 24, height, "", popup, function() end)
        check:initialise(); check:instantiate()
        check:addOption(tr("UI_PNC_Authoring_WorldLibrary", "Also make this NPC available in world encounters"))
        check:setSelected(1, library == true and canPublish)
        check:setEnable(canPublish)
        check.tooltip = tr(canPublish and "UI_PNC_Authoring_WorldLibraryHelp" or "UI_PNC_Authoring_AdminLibrary",
            canPublish and "Reusable in other worlds. Death is permanent within each world." or "Only a multiplayer administrator can publish encounter characters.")
        popup.library = check; popup:addChild(check)
        popup.yes:setY(y + height + 8); popup.no:setY(y + height + 8)
        popup:setHeight(popup.height + height + 8)
    end
    popup:addToUIManager(); popup:bringToTop()
    popup.entry:focus()
    return popup
end
return Dialog
