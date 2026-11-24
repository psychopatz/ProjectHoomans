-- Overhead dialogue prompt indicator drawn above NPCs waiting for a player reply.
-- Mirrors PNC_NameplateStealthIndicator's exact world-to-screen projection using
-- the vanilla media/ui/emotes/insult.png speech-bubble texture so the player
-- knows pressing V will reveal embedded reply choices inside TYPE TO TALK.

PNC = PNC or {}
PNC.NameplateDialoguePromptIndicator = PNC.NameplateDialoguePromptIndicator or {}

local Indicator = PNC.NameplateDialoguePromptIndicator
local PROMPT_TEXTURE_PATH = "media/ui/emotes/insult.png"
local PROMPT_TEXTURE = getTexture and getTexture(PROMPT_TEXTURE_PATH) or nil

local function resolveTexture()
    if not PROMPT_TEXTURE and getTexture then
        PROMPT_TEXTURE = getTexture(PROMPT_TEXTURE_PATH)
    end
    return PROMPT_TEXTURE
end

local function isFullConversationOpen()
    local conv = PsychopatzCore and PsychopatzCore.Conversation or nil
    local view = conv and conv.instance or nil
    return view ~= nil and view.closed ~= true and view.closing ~= true
end

local function resolveActivePrompt()
    local surface = PNC.ConvoEngine and PNC.ConvoEngine.CombatResponseSurface or nil
    local active = surface and surface.active or nil
    if type(active) == "table" and type(active.rows) == "table" and #active.rows > 0 then
        local npcID = tostring(active.npcID or "")
        if npcID ~= "" then return npcID, active end
    end
    local inline = PNC.Conversation and PNC.Conversation.InlineChat and PNC.Conversation.InlineChat.State or nil
    if type(inline) == "table"
        and inline.hasUserSubmitted == true
        and type(inline.activeQuickReplies) == "table"
        and #inline.activeQuickReplies > 0
        and tostring(inline.targetID or "") ~= ""
    then
        return tostring(inline.targetID), inline.activeQuickReplies
    end
    return nil
end

local function resolveNPCBody(manager, npcID)
    if PNC.Registry and type(PNC.Registry.GetLiveZombie) == "function" then
        local live = PNC.Registry.GetLiveZombie(npcID)
        if live and (not live.isDead or live:isDead() ~= true) then
            return live
        end
    end
    for _, entry in ipairs(manager and manager.entries or {}) do
        if entry and tostring(entry.id or "") == npcID then
            local body = entry.zombie or entry.body
            if body and (not body.isDead or body:isDead() ~= true) then
                return body
            end
        end
    end
    return nil
end

function Indicator.Render(manager)
    if not manager or not isoToScreenX or not isoToScreenY then
        return false
    end
    if isFullConversationOpen() then return false end
    local npcID = resolveActivePrompt()
    if not npcID then return false end
    local body = resolveNPCBody(manager, npcID)
    if not body or not body.getX or not body.getY or not body.getZ then
        return false
    end
    local texture = resolveTexture()
    if not texture or not texture.getWidth or not texture.getHeight then
        return false
    end
    local width = texture:getWidth()
    local height = texture:getHeight()
    local playerIndex = manager.playerIndex or 0
    local screenX = isoToScreenX(
        playerIndex, body:getX(), body:getY(), body:getZ()
    ) - (manager.x or 0)
    local screenY = isoToScreenY(
        playerIndex, body:getX(), body:getY(), body:getZ()
    ) - (manager.y or 0)
    local zoom = 1
    local core = getCore and getCore() or nil
    if core and core.getZoom then
        zoom = tonumber(core:getZoom(playerIndex)) or 1
        if zoom <= 0 then zoom = 1 end
    end
    local alpha = body.getAlpha and body:getAlpha(playerIndex) or 1
    manager:drawTextureScaled(
        texture,
        screenX - (width / 2),
        screenY - (140 / zoom) - height,
        width,
        height,
        alpha,
        1,
        1,
        1
    )
    return true
end

Indicator.TEXTURE_PATH = PROMPT_TEXTURE_PATH

return Indicator
