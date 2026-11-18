-- Shared filename/library choice for both creator hosts.
PNC.NPCAuthoringSaveDialog = PNC.NPCAuthoringSaveDialog or {}
local Dialog = PNC.NPCAuthoringSaveDialog
function Dialog.Open(owner, name, library, callback, options)
    require "ISUI/ISTextBox"
    require "ISUI/ISTickBox"
    local tr = PNC.Translation.GetKey
    local collection = require "PNC/Core/Definitions/PNC_LocalNPCCollection"
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local canPublish = collection.CanPublish(player)
    options = options or {}
    local invalidName = tr("UI_PNC_Authoring_InvalidFilename", "Enter a filename containing letters or numbers")
    local popup
    popup = ISTextBox:new(0, 0, 500, 170,
        options.title or tr("UI_PNC_UniqueNPCEditor_Save", "Save NPC preset..."), tostring(name or ""), owner,
        function(target, button)
            if button.internal ~= "OK" then popup:showErrorMessage(false); return end
            local label = popup.entry:getText()
            local fileName = PNC.DefinitionDatabase.FileName(label)
            if not fileName then popup:showErrorMessage(true, invalidName); return end
            popup:showErrorMessage(false)
            local currentPlayer = getSpecificPlayer and getSpecificPlayer(0) or nil
            callback(label, fileName, popup.library ~= nil and popup.library:isSelected(1)
                and collection.CanPublish(currentPlayer) == true)
        end)
    popup:initialise()
    popup.entry.tooltip = options.help or tr("UI_PNC_Authoring_SaveName", "Save filename")
    popup:setValidateFunction(owner, function(_, value) return PNC.DefinitionDatabase.FileName(value) ~= nil end)
    popup:setValidateTooltipText(invalidName)
    popup.yes:setTitle(tr("UI_PNC_Authoring_SavePresetAction", "Save preset"))
    local buttonWidth = math.max(popup.yes.width, getTextManager():MeasureStringX(UIFont.Small, popup.yes.title) + 24)
    popup.yes:setWidth(buttonWidth)
    popup.yes:setX((popup.width - 10) / 2 - buttonWidth)
    if library ~= nil then
        local y = popup.yes.y
        local height = getTextManager():getFontHeight(UIFont.Small) + 12
        local check = ISTickBox:new(12, y, popup.width - 24, height, "", popup, function() end)
        check:initialise(); check:instantiate()
        local option = tr("UI_PNC_Authoring_WorldLibrary", "Also make this NPC available in world encounters")
        check:addOption(option)
        check:setSelected(1, library == true and canPublish)
        -- Native ISTickBox disables named options; it has no setEnable method.
        -- disableOption also blocks joypad forceClick, unlike enable alone.
        check:disableOption(option, not canPublish)
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
