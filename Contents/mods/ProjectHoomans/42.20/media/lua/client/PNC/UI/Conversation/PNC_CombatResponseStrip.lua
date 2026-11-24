-- Unified headless dialogue prompt adapter.
--
-- Retires the standalone floating bottom-center strip: active NPC prompts now
-- signal the player via the overhead media/ui/emotes/insult.png indicator
-- (PNC_NameplateDialoguePromptIndicator) and render their clickable reply
-- choices directly inside the headless TYPE TO TALK inputbox when pressing V.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Surface = PNC.ConvoEngine.CombatResponseSurface
    or require "PNC/ConvoEngine/CombatResponseSurface"
local Strip = PNC.CombatResponseStrip or {}
PNC.CombatResponseStrip = Strip

local function refreshInlineInput()
    local inlineChat = PNC.Conversation and PNC.Conversation.InlineChat or nil
    local part = inlineChat and inlineChat.State and inlineChat.State.part or nil
    if part and type(part.refreshControls) == "function" then
        pcall(part.refreshControls, part)
    end
end

function Strip.Show(model)
    model = type(model) == "table" and model or nil
    if not model or type(model.rows) ~= "table" or #model.rows == 0 then
        Strip.Hide("empty")
        return false
    end
    Strip.activeModel = model
    refreshInlineInput()
    return true
end

function Strip.Sync(model)
    if type(model) ~= "table" or type(model.rows) ~= "table" or #model.rows == 0 then
        return Strip.Hide("empty")
    end
    Strip.activeModel = model
    refreshInlineInput()
    return true
end

function Strip.Hide()
    Strip.activeModel = nil
    refreshInlineInput()
    return true
end

Surface.SetUIAdapter(Strip)

return Strip
