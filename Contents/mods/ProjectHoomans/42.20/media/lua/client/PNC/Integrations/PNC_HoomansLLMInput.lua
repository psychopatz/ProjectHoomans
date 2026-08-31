-- Hoomans adapter for the reusable Core LLM input. The same component is
-- mounted in the full conversation and in the closed-UI NPC overlay.
require "PsychopatzCore/Input/PsychopatzKeybinds"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"
require "PNC/Commands/PNC_CompanionCommandEmotes"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}

local Integration = PNC.HoomansLLM
local Conversation = PNC.Conversation
local Text = PsychopatzCore.Conversation.Text
local Keybinds = PsychopatzCore.Keybinds
local Emotes = PNC.CompanionCommandEmotes
local LLMInput = PsychopatzConversationLLMInput

local MAX_INPUT_LENGTH = 4000
local INLINE_WIDTH = 320
local INLINE_HEIGHT = 88
local INLINE_Y_OFFSET = 220
local INLINE_TITLE = {
    key = "panel.llm_inline_input",
    domain = "pnc.system.shared.categories",
    fallback = "TALK TO",
}

local function label(key, fallback)
    return Text.Resolve({
        key = key,
        domain = "pnc.system.shared.categories",
        fallback = fallback,
    }, fallback)
end

local function stateFor(view)
    local status = label("llm.status.off", "LLM BRIDGE OFF")
    local enabled = false
    local visible = false
    if Integration.IsBridgeEnabled and Integration.IsBridgeEnabled() then
        visible = true
        if not view or not view.session then
            status = label("llm.status.open", "OPEN A CONVERSATION")
        elseif view.session.llmPending then
            status = label("llm.status.waiting", "WAITING FOR NPC RESPONSE...")
        elseif not view:isConversationInteractive() then
            status = label("llm.status.speaking", "NPC IS SPEAKING...")
        else
            enabled = true
            status = label("llm.status.ready", "LLM CHAT READY")
        end
    end
    return {
        visible = visible,
        enabled = enabled,
        statusText = status,
        sendKey = "llm.send",
    }
end

function Integration.CreateInputPart(bounds, options)
    options = options or {}
    options.partID = options.partID or "llmInput"
    options.minimumWidth = options.minimumWidth or 280
    options.minimumHeight = options.minimumHeight or 82
    options.title = options.title or {
        key = "panel.llm_input",
        domain = "pnc.system.shared.categories",
        fallback = "TYPE TO TALK",
    }
    options.submit = options.submit or Integration.Submit
    options.getState = options.getState or stateFor
    options.resolveText = options.resolveText or label
    options.maxInputLength = options.maxInputLength or MAX_INPUT_LENGTH
    options.tooltipKey = options.tooltipKey or "llm.input_tooltip"
    options.sendKey = options.sendKey or "llm.send"
    options.sendTitle = options.sendTitle or "SEND"
    return LLMInput:new(
        bounds.x,
        bounds.y,
        bounds.width,
        bounds.height,
        options
    )
end

-- Compatibility name for integrations that referred to the old adapter class.
ISPNCHoomansLLMInput = LLMInput
Conversation.CreateHoomansLLMInput = Integration.CreateInputPart

local Inline = Integration.Inline or {}
Integration.Inline = Inline

local function currentConversationView()
    return PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
end

local function closePart(part)
    if not part then return end
    if part.setVisible then part:setVisible(false) end
    if part.removeFromUIManager then part:removeFromUIManager() end
end

function Integration.CloseInline(reason)
    local part = Inline.part
    local host = Inline.host
    closePart(part)
    if host and host.close then host:close(reason or "inline_closed") end
    Inline.part = nil
    Inline.host = nil
    Inline.target = nil
    Inline.targetID = nil
    return true
end

local function screenBounds(playerIndex)
    local core = getCore and getCore() or nil
    local width = core and core.getScreenWidth and core:getScreenWidth()
        or 1920
    local height = core and core.getScreenHeight and core:getScreenHeight()
        or 1080
    local left = getPlayerScreenLeft and getPlayerScreenLeft(playerIndex) or 0
    local top = getPlayerScreenTop and getPlayerScreenTop(playerIndex) or 0
    local playerWidth = getPlayerScreenWidth
        and getPlayerScreenWidth(playerIndex) or width
    local playerHeight = getPlayerScreenHeight
        and getPlayerScreenHeight(playerIndex) or height
    local right = left + playerWidth
    local bottom = top + playerHeight
    return left, top, right, bottom
end

local function worldPosition(entry)
    local zombie = entry and entry.zombie
    if zombie and zombie.getX and zombie.getY and zombie.getZ then
        return zombie:getX(), zombie:getY(), zombie:getZ()
    end
    local source = entry and (entry.snapshot or entry.record) or {}
    return tonumber(source.x), tonumber(source.y), tonumber(source.z)
end

local function positionInline(playerIndex)
    local part = Inline.part
    local entry = Inline.target
    if not part or not entry or not isoToScreenX or not isoToScreenY then
        return false
    end
    local x, y, z = worldPosition(entry)
    if x == nil or y == nil or z == nil then return false end
    local screenX = isoToScreenX(playerIndex, x, y, z)
    local screenY = isoToScreenY(playerIndex, x, y, z)
    local left, top, right, bottom = screenBounds(playerIndex)
    local width = part:getWidth()
    local height = part:getHeight()
    local minX = left
    local maxX = math.max(left, right - width)
    local minY = top
    local maxY = math.max(top, bottom - height)
    local targetX = screenX - (width / 2)
    local targetY = screenY - INLINE_Y_OFFSET
    part:setX(math.max(minX, math.min(maxX, targetX)))
    part:setY(math.max(minY, math.min(maxY, targetY)))
    return true
end

local function targetStillNearby(player)
    if not player or not Inline.targetID or not Emotes then return nil end
    local candidates = Emotes.CollectNearbyCompanions(player)
    for _, candidate in ipairs(candidates) do
        if tostring(candidate.id) == tostring(Inline.targetID) then
            return Emotes.BuildConversationEntry(candidate)
        end
    end
    return nil
end

function Integration.OpenInline()
    if not Integration.IsBridgeEnabled
        or not Integration.IsBridgeEnabled()
        or Integration.GetPending and Integration.GetPending()
    then
        return false
    end
    if currentConversationView() then return false end
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if not player or not Emotes then return false end
    local candidates = Emotes.CollectNearbyCompanions(player)
    local candidate = candidates[1]
    if not candidate then return false end
    if Inline.part and tostring(Inline.targetID) == tostring(candidate.id) then
        if Inline.part.bringToTop then Inline.part:bringToTop() end
        if Inline.part.focusInput then Inline.part:focusInput() end
        return true
    end
    if Inline.part then Integration.CloseInline("retargeted") end
    if not Conversation.BuildDefinition
        or not PsychopatzCore.Conversation.CreateHeadless
    then
        return false
    end
    local entry = Emotes.BuildConversationEntry(candidate)
    local definition = Conversation.BuildDefinition(entry, player)
    local host = PsychopatzCore.Conversation.CreateHeadless(definition)
    if not host or host.lifecycleError then return false end
    host.hoomansLLM = true
    local part = LLMInput:new(0, 0, INLINE_WIDTH, INLINE_HEIGHT, {
        owner = host,
        partID = "llmInlineInput",
        title = INLINE_TITLE,
        submit = Integration.Submit,
        getState = stateFor,
        resolveText = label,
        maxInputLength = MAX_INPUT_LENGTH,
        tooltipKey = "llm.input_tooltip",
        sendKey = "llm.send",
        sendTitle = "SEND",
        showClose = true,
        onClose = function()
            Integration.CloseInline("user_closed")
        end,
        closeTitle = "X",
    })
    part:initialise()
    part:instantiate()
    part:addToUIManager()
    part:setReveal(1)
    if part.setAlwaysOnTop then part:setAlwaysOnTop(true) end
    Inline.part = part
    Inline.host = host
    Inline.target = entry
    Inline.targetID = tostring(entry.id)
    part:refreshControls()
    positionInline(0)
    if part.bringToTop then part:bringToTop() end
    if part.focusInput then part:focusInput() end
    return true
end

function Integration.UpdateInline()
    if not Inline.part then return end
    if currentConversationView() then
        Integration.CloseInline("conversation_opened")
        return
    end
    if not Integration.IsBridgeEnabled
        or not Integration.IsBridgeEnabled()
    then
        Integration.CloseInline("bridge_disabled")
        return
    end
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    local entry = targetStillNearby(player)
    if not entry then
        Integration.CloseInline("target_unavailable")
        return
    end
    Inline.target = entry
    Inline.part.title = INLINE_TITLE
    Inline.part:refreshControls()
    positionInline(0)
end

local function closeOnEscape(key)
    if Inline.part and Keyboard and key == Keyboard.KEY_ESCAPE then
        Integration.CloseInline("escape")
    end
end

if Keybinds and Keybinds.RegisterLongPress then
    Keybinds.RegisterLongPress({
        id = "ProjectHoomans.LLMChat",
        label = "UI_PNC_HoomansLLM_LongPressKey",
        tooltip = "UI_PNC_HoomansLLM_LongPressTooltip",
        defaultKey = getKeyCode and getKeyCode("T") or 20,
        longPressMs = 600,
        isEnabled = function()
            return Integration.IsBridgeEnabled
                and Integration.IsBridgeEnabled()
                and not (Integration.GetPending and Integration.GetPending())
                and not currentConversationView()
        end,
        onTrigger = Integration.OpenInline,
    })
end

if Events and Events.OnTick and not Integration._inlineTickHookRegistered then
    Events.OnTick.Add(Integration.UpdateInline)
    Integration._inlineTickHookRegistered = true
end

if Events and Events.OnKeyPressed and not Integration._inlineEscapeHookRegistered then
    Events.OnKeyPressed.Add(closeOnEscape)
    Integration._inlineEscapeHookRegistered = true
end

return LLMInput
