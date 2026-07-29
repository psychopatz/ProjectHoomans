PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

local Provider = {
    id = "conversation",
}

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    if not value or value == "" or value == key then return fallback end
    return value
end

function Provider.isEnabled(entry)
    return entry and entry.id ~= nil
end

function Provider.addOptions(menu, entry, player)
    local option = menu:addOption(
        tr("UI_PNC_Conversation_Talk", "Talk"),
        nil,
        function()
            if PNC.Conversation and PNC.Conversation.Open then
                PNC.Conversation.Open(entry, player)
            end
        end
    )
    if option and getTexture then
        option.iconTexture = getTexture("media/ui/emotes/insult.png")
    end
end

PNC.ContextHub.RegisterProvider(Provider)
return Provider
