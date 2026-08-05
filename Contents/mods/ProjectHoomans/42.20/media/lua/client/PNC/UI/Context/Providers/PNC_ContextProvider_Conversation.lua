-- Build 42.20 world-context integration for conversations.
PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}

local Provider = {
    id = "conversation",
}

local SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/system/shared/{language}/categories.json",
    domain = "pnc.system.shared.categories",
}

local function tr(key)
    if PNC.Conversation and PNC.Conversation.TextLoader then
        PNC.Conversation.TextLoader.EnsureSource(SOURCE, { key })
    end
    local text = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text
    return text and text.Resolve({ key = key, domain = SOURCE.domain }) or key
end

function Provider.isEnabled(entry)
    return entry and entry.id ~= nil
end

function Provider.addOptions(menu, entry, player)
    local option = menu:addOption(
        tr("context.talk"),
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
