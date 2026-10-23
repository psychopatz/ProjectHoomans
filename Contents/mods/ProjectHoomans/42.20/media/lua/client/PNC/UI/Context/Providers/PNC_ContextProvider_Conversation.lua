-- Build 42.20 world-context integration for conversations.
PNC = PNC or {}
PNC.ContextHub = PNC.ContextHub or {}
local DialogueRuntime = PNC.Semantics
    and PNC.Semantics.SemanticDialogueRuntime
    or require "PNC/Semantics/PNC_SemanticDialogueRuntime"

local Provider = {
    id = "conversation",
}

local SOURCE = {
    modID = "ProjectHoomans",
    pathPattern = "media/conversation/system/shared/{language}/categories.json",
    domain = "pnc.system.shared.categories",
}

local function auditTalk(eventName, data)
    local diagnostics = PNC.Semantics
        and PNC.Semantics.SemanticDiagnostics or nil
    if diagnostics and type(diagnostics.Record) == "function" then
        return diagnostics.Record(eventName, data)
    end
    return false
end

local function tr(key)
    if PNC.Conversation and PNC.Conversation.TextLoader then
        PNC.Conversation.TextLoader.EnsureSource(SOURCE, { key })
    end
    local text = PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.Text
    return text and text.Resolve({ key = key, domain = SOURCE.domain }) or key
end

function Provider.isEnabled(entry)
    return DialogueRuntime.IsEnabled() and entry and entry.id ~= nil
end

function Provider.addOptions(menu, entry, player)
    local option = menu:addOption(
        tr("context.talk"),
        nil,
        function()
            if PNC.Conversation and PNC.Conversation.Open then
                auditTalk("native.talk.context_click", {
                    entryID = entry and entry.id,
                    playerName = player and type(player.getDisplayName)
                        == "function" and player:getDisplayName() or nil,
                })
                local view = PNC.Conversation.Open(entry, player)
                auditTalk("native.talk.context_result", {
                    entryID = entry and entry.id,
                    opened = view ~= nil,
                    conversationID = view and view.session
                        and view.session.conversationID or nil,
                    route = view and view.spec and view.spec.context
                        and (view.spec.context.talkStartRoute
                            or view.spec.context.talkStartProjection
                            and view.spec.context.talkStartProjection.route)
                        or nil,
                })
            end
        end
    )
    if option and getTexture then
        option.iconTexture = getTexture("media/ui/emotes/insult.png")
    end
end

PNC.ContextHub.RegisterProvider(Provider)
return Provider
