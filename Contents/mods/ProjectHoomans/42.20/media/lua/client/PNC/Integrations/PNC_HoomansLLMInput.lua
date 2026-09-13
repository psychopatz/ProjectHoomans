-- Hoomans adapter for the reusable Core LLM input. The same component is
-- mounted in the full conversation and in the closed-UI NPC overlay.
require "PsychopatzCore/Input/PsychopatzKeybinds"
require "PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"
require "PNC/Commands/PNC_CompanionTargetResolver"

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}
PNC.HoomansLLM = PNC.HoomansLLM or {}

local Integration = PNC.HoomansLLM
local Conversation = PNC.Conversation
local Text = PsychopatzCore.Conversation.Text
local Keybinds = PsychopatzCore.Keybinds
local Targets = PNC.CompanionTargetResolver
local LLMInput = PsychopatzConversationLLMInput

local function inlineDiagnosticsEnabled()
    local trace = PsychopatzCore and PsychopatzCore.DebugTrace
    return trace and trace.IsEnabled
        and trace.IsEnabled() == true
end

local MAX_INPUT_LENGTH = 4000
local INLINE_WIDTH = 320
local INLINE_HEIGHT = 108
local INLINE_PLAYER_Y_OFFSET = 36
local INLINE_LIFECYCLE_INTERVAL_MS = 100
local INLINE_CONTEXT_REFRESH_INTERVAL_MS = 500
local INLINE_CONTROLS_REFRESH_INTERVAL_MS = 250
local INLINE_RECOVERY_INTERVAL_MS = 250
local INLINE_RECOVERY_GRACE_MS = 4000
local INLINE_MODE_NEAREST = "nearest"
local INLINE_MODE_NEARBY = "nearby"
local INLINE_SCOPE_COLONISTS = "colonists"
local INLINE_SCOPE_OTHER = "other"
local INLINE_SCOPE_SOCIAL = "social"
local INLINE_HIGHLIGHT_COLOR = {
    r = 0.0,
    g = 1.0,
    b = 1.0,
    a = 0.85,
}
local INLINE_TITLE = {
    key = "panel.llm_inline_input",
    domain = "pnc.system.shared.categories",
    fallback = "TALK TO",
}
local INLINE_MODE_BUTTONS = {
    {
        id = INLINE_MODE_NEAREST,
        mode = INLINE_MODE_NEAREST,
        title = {
            key = "llm.mode.nearest",
            fallback = "SINGLE NPC",
        },
        image = "media/ui/MP/mp_ui_emptyServer.png",
    },
    {
        id = INLINE_MODE_NEARBY,
        mode = INLINE_MODE_NEARBY,
        title = {
            key = "llm.mode.nearby",
            fallback = "NEARBY NPCS",
        },
        image = "media/ui/MP/mp_ui_playerCount.png",
    },
}
local INLINE_SCOPE_TOGGLE = {
    id = "npcScope",
    title = {
        key = "llm.scope.colonists",
        fallback = "COLONISTS",
    },
    alternateTitle = {
        key = "llm.scope.other",
        fallback = "OTHER NPCS",
    },
}

local function label(key, fallback)
    return Text.Resolve({
        key = key,
        domain = "pnc.system.shared.categories",
        fallback = fallback,
    }, fallback)
end

local describeInlineButtons

local function logInlineMode(event, requested, committed, reason)
    if not inlineDiagnosticsEnabled() then return end
    if not PNC.Core or not PNC.Core.LogInfo then return end
    PNC.Core.LogInfo(
        "inline_mode event=" .. tostring(event or "unknown")
            .. " requested=" .. tostring(requested or "nil")
            .. " committed=" .. tostring(committed or "nil")
            .. " ui=" .. tostring(Integration.Inline
                and Integration.Inline.part
                and Integration.Inline.part.inputMode or "nil")
            .. " target=" .. tostring(Integration.Inline
                and Integration.Inline.targetID or "nil")
            .. " reason=" .. tostring(reason or "nil")
            .. " " .. tostring(describeInlineButtons
                and describeInlineButtons() or "buttons=unavailable")
    )
end

local function logSubmitRejection(view, reason)
    if not print then return end
    local spec = view and view.spec or {}
    local interactive = view and view.isConversationInteractive
        and view:isConversationInteractive() == true
        or false
    local pending = Integration.GetPending
        and Integration.GetPending() ~= nil or false
    print(
        "[PNC][LLM] chat_submit_rejected "
            .. "npc=" .. tostring(spec.npcID or "unknown")
            .. " reason=" .. tostring(reason or "rejected")
            .. " interactive=" .. tostring(interactive)
            .. " pending=" .. tostring(pending)
    )
end

local function stateFor(view)
    local status = label("llm.status.off", "LLM BRIDGE OFF")
    local enabled = false
    local visible = false
    if Integration.IsBridgeEnabled and Integration.IsBridgeEnabled() then
        visible = true
        if not view or not view.session then
            status = label("llm.status.open", "OPEN A CONVERSATION")
        elseif view.session.llmPending
            or Integration.GetPending and Integration.GetPending()
        then
            status = label("llm.status.waiting", "WAITING FOR NPC RESPONSE...")
        elseif not view:isConversationInteractive() then
            status = label("llm.status.speaking", "NPC IS SPEAKING...")
        else
            enabled = true
            -- The controls and input field already communicate readiness;
            -- avoid spending a second line on a generic status banner.
            status = ""
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
    options.submitOnEnter = options.submitOnEnter ~= false
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

local function nativeColorDescription(color)
    if not color then return "nil" end
    return table.concat({
        tostring(color.r), tostring(color.g), tostring(color.b),
        tostring(color.a),
    }, ",")
end

local function nativeButtonValue(button, getter, field)
    if not button then return nil end
    if getter and button[getter] then return button[getter](button) end
    return button[field]
end

local function nativeButtonDescription(definition, part)
    local button = definition and definition.button
    if not button then return "mode=" .. tostring(definition and definition.mode) .. ":nil" end
    local x = nativeButtonValue(button, "getX", "x")
    local y = nativeButtonValue(button, "getY", "y")
    local width = nativeButtonValue(button, "getWidth", "width")
    local height = nativeButtonValue(button, "getHeight", "height")
    return table.concat({
        "mode=" .. tostring(definition.mode),
        "xywh=" .. tostring(x) .. "," .. tostring(y) .. ","
            .. tostring(width) .. "," .. tostring(height),
        "enable=" .. tostring(button.enable),
        "variant=" .. tostring(button.psychopatzVariant),
        "bg=" .. nativeColorDescription(button.backgroundColor),
        "bgHover=" .. nativeColorDescription(button.backgroundColorMouseOver),
        "border=" .. nativeColorDescription(button.borderColor),
        "text=" .. nativeColorDescription(button.textColor),
        "bgEnabled=" .. nativeColorDescription(button.backgroundColorEnabled),
        "borderEnabled=" .. nativeColorDescription(button.borderColorEnabled),
        "image=" .. tostring(button.image),
        "tooltip=" .. tostring(button.tooltip),
        "targetIsPart=" .. tostring(button.target == part),
    }, " ")
end

describeInlineButtons = function()
    local part = Inline.part
    if not part then return "panel=nil modeButtons=0" end
    local descriptions = {}
    local seen = {}
    local uniqueCount = 0
    local duplicateCount = 0
    local targetMismatchCount = 0
    for _, definition in ipairs(part.modeButtons or {}) do
        local button = definition and definition.button
        if button and seen[button] then duplicateCount = duplicateCount + 1 end
        if button and not seen[button] then
            seen[button] = true
            uniqueCount = uniqueCount + 1
        end
        if button and button.target ~= nil and button.target ~= part then
            targetMismatchCount = targetMismatchCount + 1
        end
        descriptions[#descriptions + 1] = nativeButtonDescription(definition, part)
    end
    local children = part.getChildren and part:getChildren() or part.children
    local childCount = 0
    local modeChildCount = 0
    if type(children) == "table" then
        for _, child in ipairs(children) do
            childCount = childCount + 1
            if seen[child] then modeChildCount = modeChildCount + 1 end
        end
    end
    return "panel=" .. tostring(part)
        .. " modeButtons=" .. tostring(#(part.modeButtons or {}))
        .. " uniqueButtons=" .. tostring(uniqueCount)
        .. " duplicateButtons=" .. tostring(duplicateCount)
        .. " targetMismatches=" .. tostring(targetMismatchCount)
        .. " children=" .. tostring(childCount)
        .. " modeChildren=" .. tostring(modeChildCount)
        .. " buttons=[" .. table.concat(descriptions, " || ") .. "]"
end

local function colorsEqual(left, right)
    if not left or not right then return false end
    return math.abs((tonumber(left.r) or 0) - (tonumber(right.r) or 0)) < 0.0001
        and math.abs((tonumber(left.g) or 0) - (tonumber(right.g) or 0)) < 0.0001
        and math.abs((tonumber(left.b) or 0) - (tonumber(right.b) or 0)) < 0.0001
        and math.abs((tonumber(left.a) or 0) - (tonumber(right.a) or 0)) < 0.0001
end

local function nativeButtonIsSelected(button)
    local theme = PsychopatzCore and PsychopatzCore.UI
        and PsychopatzCore.UI.Theme
    if theme and theme.Color then
        return colorsEqual(button.backgroundColor, theme.Color("accentDark"))
            and colorsEqual(button.borderColor, theme.Color("accent"))
    end
    return button.psychopatzVariant == "selected"
end

local function inlineModeConsistency(event)
    if not inlineDiagnosticsEnabled() then return true end
    local part = Inline.part
    if not part or not Targets then return true end
    local committed = Targets.NormalizeMode(
        Inline.mode or INLINE_MODE_NEAREST
    )
    local uiMode = part.inputMode and Targets.NormalizeMode(part.inputMode)
        or nil
    local selectedMode
    local selectedCount = 0
    local buttonsOK = true
    local modeButtonCount = 0
    local allModeButtonsEnabled = true
    for _, definition in ipairs(part.modeButtons or {}) do
        local button = definition and definition.button
        if button then
            modeButtonCount = modeButtonCount + 1
            local isEnabled = button.enable ~= false
            if not isEnabled then allModeButtonsEnabled = false end
            local isSelected = isEnabled and nativeButtonIsSelected(button)
                or false
            if isSelected then
                selectedCount = selectedCount + 1
                selectedMode = definition.mode
            end
            local expectedSelected = definition.mode == committed
            if button.psychopatzVariant
                ~= (expectedSelected and "selected" or "quiet")
            then
                buttonsOK = false
            end
        end
    end
    -- Disabled native buttons are deliberately painted by ISButton:setEnable
    -- with its disabled colors, so there is no selected color to assert in
    -- that state.  Keep checking the logical marker, and resume the native
    -- color assertion as soon as both mode controls are enabled again.
    local nativeSelectionOK = not allModeButtonsEnabled
        or (modeButtonCount == 2
            and selectedCount == 1
            and selectedMode == committed)

    local expectedRecipients = {}
    for _, entry in ipairs(Inline.entries or {}) do
        local id = tostring(entry and entry.id or "")
        if id ~= "" then expectedRecipients[id] = true end
    end
    local outlinedRecipients = Inline.highlightedZombies or {}
    local outlinedCount = 0
    local recipientsOK = true
    for id in pairs(expectedRecipients) do
        if outlinedRecipients[id] == nil then recipientsOK = false end
    end
    for id in pairs(outlinedRecipients) do
        outlinedCount = outlinedCount + 1
        if not expectedRecipients[id] then recipientsOK = false end
    end
    if uiMode ~= committed
        or not nativeSelectionOK
        or not buttonsOK
        or not recipientsOK
    then
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn(
                "inline_mode_assertion_failed event=" .. tostring(event)
                    .. " committed=" .. tostring(committed)
                    .. " ui=" .. tostring(uiMode)
                    .. " selected=" .. tostring(selectedMode)
                    .. " selectedCount=" .. tostring(selectedCount)
                    .. " nativeSelectionCheck=" .. tostring(
                        allModeButtonsEnabled and "enabled" or "disabled")
                    .. " outlined=" .. tostring(outlinedCount)
                    .. " expectedOutlined=" .. tostring(#(Inline.entries or {}))
                    .. " buttonsOK=" .. tostring(buttonsOK)
                    .. " recipientsOK=" .. tostring(recipientsOK)
            )
        end
        return false
    end
    return true
end

Integration.AssertInlineModeState = inlineModeConsistency

local function onInlineVisualRefresh(_, part, event)
    if not inlineDiagnosticsEnabled() then return end
    if part ~= Inline.part then return end
    logInlineMode("visual_refresh_" .. tostring(event or "unknown"),
        Inline.mode, Inline.mode, nil)
    inlineModeConsistency(event or "visual_refresh")
end

local function onInlineModeCommitted(_, mode, part)
    if not inlineDiagnosticsEnabled() then return end
    if part ~= Inline.part then return end
    logInlineMode("mode_committed", mode, Inline.mode, nil)
    inlineModeConsistency("mode_committed")
end

local function onInlineNativeControlState(_, part, event, button)
    if not inlineDiagnosticsEnabled() then return end
    if part ~= Inline.part then return end
    logInlineMode(
        "native_" .. tostring(event or "unknown"),
        Inline.mode,
        Inline.mode,
        "button=" .. tostring(button and button.internal or "unknown")
    )
end

local function isLongPressBinding(binding)
    local longPressType = Keybinds and Keybinds.TYPE_LONG_PRESS
        or "longpress"
    return type(binding) == "table"
        and tostring(binding.type or "") == tostring(longPressType)
end

local function focusInlineInputWhenReady()
    if not Inline.part or not Inline.focusAfterTriggerRelease then
        return false
    end
    local binding = Inline.triggerBinding
    if binding and Keybinds and Keybinds.IsDown
        and Keybinds.IsDown(binding)
    then
        return false
    end
    Inline.focusAfterTriggerRelease = false
    Inline.triggerBinding = nil
    if Inline.part.focusInput then
        Inline.part:focusInput()
        return true
    end
    return false
end

Integration.FocusInlineInputWhenReady = focusInlineInputWhenReady

local function prepareInlineInputFocus(binding)
    Inline.triggerBinding = isLongPressBinding(binding) and binding or nil
    Inline.focusAfterTriggerRelease = Inline.triggerBinding ~= nil
    if Inline.focusAfterTriggerRelease then
        return focusInlineInputWhenReady()
    end
    if Inline.part and Inline.part.focusInput then
        Inline.part:focusInput()
        return true
    end
    return false
end

local function resolveInlineZombie(entry)
    local registry = PNC.Registry
    local id = tostring(entry and entry.id or "")
    if id ~= "" and registry and registry.GetLiveZombie then
        local live = registry.GetLiveZombie(id)
        if live and (not live.isDead or live:isDead() ~= true) then
            return live
        end
        local sync = PNC.ClientPresenceSync
        local presenceBody = sync and sync.ResolveBodyForNPC
            and sync.ResolveBodyForNPC(id, entry and entry.snapshot)
        if presenceBody
            and (not presenceBody.isDead or presenceBody:isDead() ~= true)
        then
            return presenceBody
        end
        return nil
    end
    if entry and entry.zombie
        and (not entry.zombie.isDead or entry.zombie:isDead() ~= true)
    then
        return entry.zombie
    end
    return nil
end

local function refreshClientPresenceBodies()
    local sync = PNC.ClientPresenceSync
    local internal = sync and sync.Internal
    if internal and internal.RefreshBodyMap then
        internal.RefreshBodyMap(getTimeInMillis and getTimeInMillis() or 0)
    end
end

local function clearInlineHighlights(playerIndex)
    local active = Inline.highlightedZombies or {}
    for _, zombie in pairs(active) do
        if zombie and zombie.setOutlineHighlight then
            zombie:setOutlineHighlight(playerIndex, false)
        end
    end
    Inline.highlightedZombies = {}
end

local function refreshInlineHighlights(playerIndex)
    local previous = Inline.highlightedZombies or {}
    local current = {}
    refreshClientPresenceBodies()
    for _, entry in ipairs(Inline.entries or {}) do
        local id = tostring(entry and entry.id or "")
        local zombie = resolveInlineZombie(entry)
        if id ~= "" and zombie and zombie.setOutlineHighlight then
            current[id] = zombie
            -- IsoMovingObject.renderlast clears this native outline after the
            -- frame, so reapply it while the inline conversation is active.
            zombie:setOutlineHighlight(playerIndex, true)
            if zombie.setOutlineHighlightCol then
                zombie:setOutlineHighlightCol(
                    playerIndex,
                    INLINE_HIGHLIGHT_COLOR.r,
                    INLINE_HIGHLIGHT_COLOR.g,
                    INLINE_HIGHLIGHT_COLOR.b,
                    INLINE_HIGHLIGHT_COLOR.a
                )
            end
        end
    end
    for id, zombie in pairs(previous) do
        if current[id] ~= zombie
            and zombie
            and zombie.setOutlineHighlight
        then
            zombie:setOutlineHighlight(playerIndex, false)
        end
    end
    Inline.highlightedZombies = current
    return current
end

Integration.RefreshInlineHighlights = function()
    return refreshInlineHighlights(0)
end

Integration.ClearInlineHighlights = function()
    clearInlineHighlights(0)
end

local function currentConversationView()
    return PsychopatzCore and PsychopatzCore.Conversation
        and PsychopatzCore.Conversation.instance or nil
end

local function currentTime()
    return getTimeInMillis and getTimeInMillis() or 0
end

local function directTargetFromEntry(entry, player)
    local source = entry and (entry.source or entry.record or entry.snapshot)
        or nil
    local zombie = entry and entry.zombie or source and source.zombie or nil
    local id = tostring(entry and entry.id or source and source.id or "")
    local x = zombie and zombie.getX and zombie:getX()
        or tonumber(entry and entry.x)
        or tonumber(source and source.x)
    local y = zombie and zombie.getY and zombie:getY()
        or tonumber(entry and entry.y)
        or tonumber(source and source.y)
    local z = zombie and zombie.getZ and zombie:getZ()
        or tonumber(entry and entry.z)
        or tonumber(source and source.z)
    local dx
    local dy
    if id == "" or not player or x == nil or y == nil or z == nil then
        return nil
    end
    if zombie and zombie.isDead and zombie:isDead() then return nil end
    if math.floor(z) ~= math.floor(tonumber(player:getZ()) or 0) then
        return nil
    end
    dx = x - player:getX()
    dy = y - player:getY()
    if (dx * dx) + (dy * dy) > 20 * 20 then return nil end
    return {
        id = id,
        name = entry.name or source and source.name or "NPC",
        distSq = (dx * dx) + (dy * dy),
        source = entry,
        zombie = zombie,
        record = entry.record,
        snapshot = entry.snapshot,
    }
end

local function closePart(part)
    if not part then return end
    if part.blurInput then
        part:blurInput()
    elseif part.entry and part.entry.unfocus then
        part.entry:unfocus()
    end
    if part.setVisible then part:setVisible(false) end
    if part.removeFromUIManager then part:removeFromUIManager() end
end

function Integration.CloseInline(reason)
    local part = Inline.part
    local hosts = Inline.hosts or {}
    local closed = {}
    clearInlineHighlights(0)
    closePart(part)
    for _, host in ipairs(hosts) do
        if host and not closed[host] and host.close then
            host:close(reason or "inline_closed")
            closed[host] = true
        end
    end
    if Inline.host and not closed[Inline.host] and Inline.host.close then
        Inline.host:close(reason or "inline_closed")
    end
    Inline.part = nil
    Inline.host = nil
    Inline.hosts = nil
    Inline.targets = nil
    Inline.entries = nil
    Inline.target = nil
    Inline.targetID = nil
    Inline.directTarget = nil
    Inline.nextLifecycleAt = nil
    Inline.nextContextRefreshAt = nil
    Inline.nextControlsRefreshAt = nil
    Inline.recoveryStartedAt = nil
    Inline.recoveryDeadlineAt = nil
    Inline.nextRecoveryAt = nil
    Inline.focusAfterTriggerRelease = false
    Inline.triggerBinding = nil
    return true
end

local function clearPendingInlineFallback()
    Inline.pendingTargetEntry = nil
    Inline.pendingFallbackMode = nil
    Inline.pendingFallbackScope = nil
    Inline.pendingFallbackReason = nil
    Inline.pendingFallbackDeadline = nil
    Inline.pendingFallbackNextAttemptAt = nil
end

local function queueInlineFallback(entry, reason)
    local id = tostring(entry and entry.id or "")
    if id == "" then return false end
    Inline.pendingTargetEntry = entry
    -- A fallback request may arrive while the compact input is already open
    -- (for example, while a closing full conversation is still finishing).
    -- Keep the player's committed mode/scope untouched until the fallback is
    -- actually opened; otherwise the next inline tick silently changes the
    -- mode button from nearby back to nearest.
    Inline.pendingFallbackMode = INLINE_MODE_NEAREST
    Inline.pendingFallbackScope = INLINE_SCOPE_OTHER
    if not Inline.part then
        Inline.targetID = id
        Inline.directTarget = entry
        Inline.mode = INLINE_MODE_NEAREST
        Inline.scope = INLINE_SCOPE_OTHER
        logInlineMode(
            "fallback_queued",
            INLINE_MODE_NEAREST,
            Inline.mode,
            reason
        )
    else
        logInlineMode(
            "fallback_deferred",
            INLINE_MODE_NEAREST,
            Inline.mode,
            reason
        )
    end
    Inline.pendingFallbackReason = tostring(reason or "conversation_handoff")
    Inline.pendingFallbackDeadline = currentTime() + 5000
    Inline.pendingFallbackNextAttemptAt = 0
    return true
end

local function openQueuedInlineFallback(binding)
    local entry = Inline.pendingTargetEntry
    if not entry then return false end
    local now = currentTime()
    if now > (tonumber(Inline.pendingFallbackDeadline) or 0) then
        clearPendingInlineFallback()
        return false
    end
    if now < (tonumber(Inline.pendingFallbackNextAttemptAt) or 0) then
        return false
    end
    Inline.pendingFallbackNextAttemptAt = now + 250
    Inline.targetID = tostring(entry.id)
    Inline.directTarget = entry
    Inline.mode = Inline.pendingFallbackMode or INLINE_MODE_NEAREST
    Inline.scope = Inline.pendingFallbackScope or INLINE_SCOPE_OTHER
    if Integration.OpenInline(binding) then
        clearPendingInlineFallback()
        return true
    end
    return false
end

function Integration.OpenInlineForTarget(entry, binding)
    if not Integration.IsBridgeEnabled
        or not Integration.IsBridgeEnabled()
        or Integration.GetPending and Integration.GetPending()
    then
        return false
    end
    if not queueInlineFallback(entry, "conversation_handoff") then
        return false
    end
    local view = currentConversationView()
    if view then
        if view.close then view:close("nameplate_fallback") end
        return true
    end
    return openQueuedInlineFallback(binding)
end

function Integration.RequestInlineFallback(entry, reason, view)
    if not Integration.IsBridgeEnabled
        or not Integration.IsBridgeEnabled()
    then
        return false
    end
    if not queueInlineFallback(entry, reason) then return false end
    local current = currentConversationView()
    if current and (not view or current == view) and current.close then
        current:close("nameplate_fallback")
    end
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

local function positionInline(playerIndex, player)
    local part = Inline.part
    if not part or not player or not isoToScreenX or not isoToScreenY then
        return false
    end
    if not player.getX or not player.getY or not player.getZ then
        return false
    end
    local x, y, z = player:getX(), player:getY(), player:getZ()
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
    -- The closed-T input belongs to the player interaction, not to the NPC's
    -- nameplate. Keep it under the player's feet while the NPC response is
    -- rendered independently by the shared detached speech lane.
    local targetY = screenY + INLINE_PLAYER_Y_OFFSET
    part:setX(math.max(minX, math.min(maxX, targetX)))
    part:setY(math.max(minY, math.min(maxY, targetY)))
    return true
end

local function resolveNearestCycle(player, currentID, scope)
    if Targets.ResolveNearestCycle then
        return Targets.ResolveNearestCycle(player, currentID, nil, scope)
    end

    -- Compatibility fallback for older resolver implementations used by
    -- focused tests or partially updated multiplayer clients.
    local candidates = Targets.CollectNearbyTargets
        and Targets.CollectNearbyTargets(player, nil, scope) or {}
    local nextIndex = 1
    local current = currentID ~= nil and tostring(currentID) or nil
    if current and current ~= "" then
        for index, candidate in ipairs(candidates) do
            if tostring(candidate.id) == current then
                nextIndex = (index % #candidates) + 1
                break
            end
        end
    end
    local target = candidates[nextIndex]
    return {
        mode = INLINE_MODE_NEAREST,
        scope = scope,
        target = target,
        targets = target and { target } or {},
    }
end

local function resolveInlineRecipients(player, options)
    options = options or {}
    if not player or not Targets then return nil end
    local mode = Targets.NormalizeMode(
        options.mode or Inline.mode or INLINE_MODE_NEAREST
    )
    local scope = Targets.NormalizeScope(
        options.scope or Inline.scope or INLINE_SCOPE_COLONISTS
    )
    local resolved
    if options.cycleNearest and mode == INLINE_MODE_NEAREST then
        resolved = resolveNearestCycle(
            player,
            Inline.targetID,
            scope
        )
    else
        resolved = Targets.ResolveRecipients(
            player,
            mode,
            nil,
            scope
        )
    end
    if not resolved then return nil end
    -- The closed key entry point cannot be switched to OTHER NPCS until it
    -- has opened once.  In multiplayer the nearby NPC is commonly a
    -- replicated social target rather than a player-owned companion, so fall
    -- through to the resolver's social scope when the companion scope is
    -- empty.  Keep Inline.scope as the user's requested scope so the existing
    -- colonist/other toggle remains stable after the window opens.
    if not resolved.target
        and scope == INLINE_SCOPE_COLONISTS
        and Targets.SCOPE_SOCIAL
    then
        local social
        if options.cycleNearest and mode == INLINE_MODE_NEAREST then
            social = resolveNearestCycle(
                player,
                Inline.targetID,
                INLINE_SCOPE_SOCIAL
            )
        else
            social = Targets.ResolveRecipients(
                player,
                mode,
                nil,
                INLINE_SCOPE_SOCIAL
            )
        end
        if social and social.target then resolved = social end
    end
    local primary = resolved.target
    if Inline.targetID
        and not options.cycleNearest
        and not options.selectClosest
    then
        local candidates = resolved.targets
        if mode == INLINE_MODE_NEAREST and #candidates == 0 then
            candidates = Targets.CollectNearbyTargets(
                player,
                nil,
                scope
            )
        end
        local found = false
        for _, candidate in ipairs(candidates) do
            if tostring(candidate.id) == tostring(Inline.targetID) then
                primary = candidate
                found = true
                break
            end
        end
        if not found and Inline.directTarget then
            primary = directTargetFromEntry(Inline.directTarget, player)
            found = primary ~= nil
            if found then resolved.targets = { primary } end
        end
        if not found then return nil end
    end
    if not primary then return nil end
    if mode == INLINE_MODE_NEAREST then
        resolved.targets = { primary }
    end
    return {
        primary = primary,
        targets = resolved.targets,
        scope = resolved.scope,
    }
end

-- Kept public for diagnostics and focused tests. The keybind and mode/scope
-- controls all use this same recipient path.
Integration.ResolveInlineRecipients = resolveInlineRecipients

local function buildInlineHost(entry, player)
    if not Conversation.BuildDefinition
        or not PsychopatzCore.Conversation.CreateHeadless
    then
        return nil
    end
    local definition = Conversation.BuildDefinition(entry, player)
    definition.context = definition.context or {}
    definition.context.nameplateConversation = true
    definition.context.guardThreats = false
    local host = PsychopatzCore.Conversation.CreateHeadless(definition)
    if not host then
        if print then
            print("[PNC][LLM] inline_host_failed reason=create_headless")
        end
        return nil
    end
    if host.lifecycleError then
        if print then
            print(
                "[PNC][LLM] inline_host_failed reason=lifecycle "
                    .. tostring(host.lifecycleError)
            )
        end
        return nil
    end
    host.hoomansLLM = true
    return host
end

local function refreshInlineHostContext(host, entry, player)
    if not host or not host.spec then return end
    local context = host.spec.context or {}
    context.entry = entry
    context.player = player
    context.nameplateConversation = true
    context.guardThreats = false
    host.spec.context = context
    host.spec.character = entry and entry.zombie or nil
end

local function rebuildInlineHosts(player, resolved, requestedMode)
    local oldHosts = {}
    local newHosts = {}
    local createdHosts = {}
    local entries = {}
    local targets = resolved and resolved.targets or {}
    local old
    local entry
    local host
    local id
    local primaryTarget = resolved
        and (resolved.primary or resolved.target) or nil
    local mode = Targets.NormalizeMode(
        requestedMode or Inline.mode or INLINE_MODE_NEAREST
    )
    local primaryID = tostring(primaryTarget and primaryTarget.id or "")
    local primaryIndex
    if not primaryTarget then return false end
    for _, old in ipairs(Inline.hosts or {}) do
        id = tostring(old and old.spec and old.spec.npcID or "")
        if id ~= "" then oldHosts[id] = old end
    end
    for _, candidate in ipairs(targets) do
        entry = Targets.BuildConversationEntry(candidate)
        id = tostring(entry and entry.id or "")
        if id ~= "" then
            host = oldHosts[id]
            if host and host.closed then
                host = nil
                oldHosts[id] = nil
            end
            if not host then
                host = buildInlineHost(entry, player)
                if host then createdHosts[#createdHosts + 1] = host end
            end
            if host then
                refreshInlineHostContext(host, entry, player)
                oldHosts[id] = nil
                entries[#entries + 1] = entry
                newHosts[#newHosts + 1] = host
                if id == primaryID then
                    primaryIndex = #entries
                end
            elseif mode ~= INLINE_MODE_NEARBY then
                for _, created in ipairs(createdHosts) do
                    if created and created.close then
                        created:close("inline_target_build_failed")
                    end
                end
                return false
            end
        end
    end
    if #newHosts == 0 then
        for _, created in ipairs(createdHosts) do
            if created and created.close then
                created:close("inline_target_build_failed")
            end
        end
        return false
    end
    -- A mode switch is only available while no request is pending, so unused
    -- hosts have no in-flight bridge work and can be retired safely.
    for _, unused in pairs(oldHosts) do
        if unused and unused.close then unused:close("inline_retargeted") end
    end
    primaryIndex = primaryIndex or 1
    Inline.entries = entries
    Inline.hosts = newHosts
    Inline.target = entries[primaryIndex]
    Inline.targetID = tostring(Inline.target.id)
    Inline.host = newHosts[primaryIndex]
    return true
end

-- Keep the selected target/host stable while the compact UI is open. Refresh
-- live body and snapshot references opportunistically, but never re-run the
-- acquisition radius gate or rebuild headless hosts just because the NPC
-- moved.
local function refreshLockedInlineEntries(player)
    local entries = Inline.entries or {}
    local hosts = Inline.hosts or {}
    for index, entry in ipairs(entries) do
        local refreshed = Targets.BuildConversationEntry({
            id = entry.id,
            source = entry.source,
            record = entry.record,
            snapshot = entry.snapshot,
            zombie = entry.zombie,
        })
        if refreshed and tostring(refreshed.id or "") ~= "" then
            refreshed.name = refreshed.name or entry.name
            entries[index] = refreshed
            refreshInlineHostContext(hosts[index], refreshed, player)
            if Inline.targetID
                and tostring(Inline.targetID) == tostring(refreshed.id)
            then
                Inline.target = refreshed
            end
        end
    end
end

local function syncInlineModeButton()
    local part = Inline.part
    if not part then return end
    local mode = Targets.NormalizeMode(
        Inline.mode or INLINE_MODE_NEAREST
    )
    if part.inputMode
        and Targets.NormalizeMode(part.inputMode) ~= mode
    then
        logInlineMode("mode_desync", part.inputMode, mode, "adapter_sync")
    end
    -- The Core input owns the UI projection and commits it after this
    -- integration's recipient transaction returns true. This reconciliation
    -- point is diagnostic-only; writing inputMode here creates a second mode
    -- authority and can race the native button lifecycle.
end

local function resetInlineRecovery()
    Inline.recoveryStartedAt = nil
    Inline.recoveryDeadlineAt = nil
    Inline.nextRecoveryAt = nil
end

function Integration.SetInlineMode(_, mode, part)
    local previousMode = Targets.NormalizeMode(
        Inline.mode or INLINE_MODE_NEAREST
    )
    local requestedMode = Targets.NormalizeMode(mode)
    logInlineMode("mode_click", requestedMode, previousMode, "callback_begin")
    if part and part ~= Inline.part then
        logInlineMode("mode_rejected", requestedMode, previousMode,
            "stale_part")
        return false
    end
    if not Inline.part then
        logInlineMode("mode_rejected", requestedMode, previousMode,
            "panel_closed")
        return false
    end
    if Integration.GetPending and Integration.GetPending() then
        logInlineMode("mode_rejected", requestedMode, previousMode,
            "llm_pending")
        return false
    end
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    local cycleNearest = previousMode == INLINE_MODE_NEAREST
        and requestedMode == INLINE_MODE_NEAREST
    local selectClosest = previousMode == INLINE_MODE_NEARBY
        and requestedMode == INLINE_MODE_NEAREST
    refreshClientPresenceBodies()
    local resolved = resolveInlineRecipients(player, {
        mode = requestedMode,
        cycleNearest = cycleNearest,
        selectClosest = selectClosest,
    })
    if not resolved or #resolved.targets == 0 then
        logInlineMode("mode_rejected", requestedMode, previousMode,
            "recipient_unavailable")
        return false
    end
    if not rebuildInlineHosts(player, resolved, requestedMode) then
        logInlineMode("mode_rejected", requestedMode, previousMode,
            "host_build_failed")
        return false
    end
    -- Commit the adapter mode only after recipients and headless hosts have
    -- been rebuilt successfully.  The Core widget commits its own visual
    -- state immediately after this callback returns, so changing or
    -- repainting the button here creates a one-frame disagreement.
    Inline.mode = requestedMode
    Inline.nextLifecycleAt = 0
    Inline.nextContextRefreshAt = 0
    Inline.nextControlsRefreshAt = 0
    resetInlineRecovery()
    refreshInlineHighlights(0)
    Inline.part.owner = Inline.host
    positionInline(0, player)
    -- The Core widget commits inputMode and paints the native buttons after
    -- this callback returns. Do not write either UI field from the adapter.
    logInlineMode("mode_transaction_accepted", requestedMode, Inline.mode, nil)
    return true
end

function Integration.SetInlineScope(_, value, part)
    if part and part ~= Inline.part then return false end
    if not Inline.part then return false end
    if Integration.GetPending and Integration.GetPending() then return false end
    local previousScope = Targets.NormalizeScope(
        Inline.scope or INLINE_SCOPE_COLONISTS
    )
    local requestedScope = value == true
        and INLINE_SCOPE_OTHER or INLINE_SCOPE_COLONISTS
    local selectClosest = requestedScope ~= previousScope
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    refreshClientPresenceBodies()
    local resolved = resolveInlineRecipients(player, {
        scope = requestedScope,
        selectClosest = selectClosest,
    })
    if not resolved or #resolved.targets == 0 then
        return false
    end
    if not rebuildInlineHosts(player, resolved, Inline.mode) then
        return false
    end
    Inline.scope = requestedScope
    Inline.nextLifecycleAt = 0
    Inline.nextContextRefreshAt = 0
    Inline.nextControlsRefreshAt = 0
    resetInlineRecovery()
    refreshInlineHighlights(0)
    Inline.part.owner = Inline.host
    positionInline(0, player)
    return true
end

function Integration.SubmitInline(view, value, part)
    local accepted, reason = Integration.Submit(view, value, part)
    if accepted == true then
        Integration.CloseInline("message_submitted")
    else
        logSubmitRejection(view, reason)
    end
    return accepted, reason
end

function Integration.OpenInline(binding)
    if not Integration.IsBridgeEnabled
        or not Integration.IsBridgeEnabled()
        or Integration.GetPending and Integration.GetPending()
    then
        return false
    end
    if currentConversationView() then return false end
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if not player or not Targets then return false end
    refreshClientPresenceBodies()
    Inline.mode = Targets.NormalizeMode(Inline.mode or INLINE_MODE_NEAREST)
    Inline.scope = Targets.NormalizeScope(
        Inline.scope or INLINE_SCOPE_COLONISTS
    )
    local resolved = resolveInlineRecipients(player)
    local candidate = resolved and resolved.primary
    if not candidate then return false end
    if Inline.part and tostring(Inline.targetID) == tostring(candidate.id)
        and Inline.mode == (Inline.part.inputMode or Inline.mode)
    then
        refreshInlineHighlights(0)
        if Inline.part.bringToTop then Inline.part:bringToTop() end
        prepareInlineInputFocus(binding)
        return true
    end
    if Inline.part then Integration.CloseInline("retargeted") end
    if not rebuildInlineHosts(player, resolved) then return false end
    Inline.nextLifecycleAt = 0
    Inline.nextContextRefreshAt = 0
    Inline.nextControlsRefreshAt = 0
    local part = LLMInput:new(0, 0, INLINE_WIDTH, INLINE_HEIGHT, {
        owner = Inline.host,
        partID = "llmInlineInput",
        title = INLINE_TITLE,
        submit = Integration.SubmitInline,
        getState = stateFor,
        resolveText = label,
        maxInputLength = MAX_INPUT_LENGTH,
        submitOnEnter = true,
        tooltipKey = "llm.input_tooltip",
        sendKey = "llm.send",
        sendTitle = "SEND",
        modeButtons = INLINE_MODE_BUTTONS,
        initialMode = Inline.mode,
        onModeChanged = Integration.SetInlineMode,
        onModeCommitted = onInlineModeCommitted,
        onVisualRefresh = onInlineVisualRefresh,
        onNativeControlState = onInlineNativeControlState,
        toggleButton = INLINE_SCOPE_TOGGLE,
        initialToggleValue = Inline.scope == INLINE_SCOPE_OTHER,
        onToggleChanged = Integration.SetInlineScope,
        maxInputLines = 6,
        maxInputHeight = 122,
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
    part:refreshControls()
    refreshInlineHighlights(0)
    positionInline(0, player)
    if part.bringToTop then part:bringToTop() end
    prepareInlineInputFocus(binding)
    return true
end

local function updateInlineHostLifecycles()
    local hosts = Inline.hosts or {}
    local entries = Inline.entries or {}
    local activeHosts = {}
    local activeEntries = {}
    local primaryHost = Inline.host
    local primaryPresent = false
    local primaryFailed = false
    local primaryFailureReason
    local failureReason

    for index, host in ipairs(hosts) do
        local interruption
        if host and host.updateLifecycle then
            interruption = host:updateLifecycle()
        end
        if interruption or host and host.closed then
            failureReason = failureReason
                or interruption or "conversation_interrupted"
            -- Nearby mode is a batch of independent headless conversations.
            -- A secondary NPC can disappear while the selected conversation is
            -- still valid; remove only that recipient instead of destroying
            -- the compact input for everyone.
            if host == primaryHost then
                primaryFailed = true
                primaryFailureReason = interruption
                    or "conversation_interrupted"
            end
        elseif host then
            activeHosts[#activeHosts + 1] = host
            activeEntries[#activeEntries + 1] = entries[index]
            if host == primaryHost then primaryPresent = true end
        end
    end

    if #activeHosts == 0 then
        Inline.hosts = {}
        Inline.entries = {}
        Inline.host = nil
        Inline.target = nil
        clearInlineHighlights(0)
        return false, failureReason or "conversation_interrupted"
    end
    if primaryFailed then
        if Inline.mode ~= INLINE_MODE_NEARBY
            or (primaryFailureReason ~= "npc_unavailable"
                and primaryFailureReason ~= "conversation_interrupted")
        then
            return false, primaryFailureReason or "conversation_interrupted"
        end
        Inline.host = activeHosts[1]
        Inline.target = activeEntries[1]
        Inline.targetID = Inline.target
            and tostring(Inline.target.id or "") or nil
    elseif not primaryPresent then
        return false, "conversation_interrupted"
    end
    Inline.hosts = activeHosts
    Inline.entries = activeEntries
    return true
end

local function recoverInlineHosts(player, now)
    if not Inline.part or not player then return false end
    if now < (tonumber(Inline.nextRecoveryAt) or 0) then return false end
    if now > (tonumber(Inline.recoveryDeadlineAt) or 0) then
        return false
    end
    Inline.nextRecoveryAt = now + INLINE_RECOVERY_INTERVAL_MS
    local resolved = resolveInlineRecipients(player, {
        selectClosest = true,
    })
    if not resolved or #resolved.targets == 0 then return false end
    if not rebuildInlineHosts(player, resolved) then return false end
    resetInlineRecovery()
    Inline.nextLifecycleAt = now + INLINE_LIFECYCLE_INTERVAL_MS
    Inline.nextContextRefreshAt = now
    Inline.nextControlsRefreshAt = now
    refreshInlineHighlights(0)
    Inline.part.owner = Inline.host
    Inline.part:refreshControls()
    positionInline(0, player)
    return true
end

function Integration.UpdateInline()
    if currentConversationView() then
        if Inline.part then Integration.CloseInline("conversation_opened") end
        return
    end
    if Inline.pendingTargetEntry then
        openQueuedInlineFallback("conversation_handoff")
    end
    if not Inline.part then return end
    if not Integration.IsBridgeEnabled
        or not Integration.IsBridgeEnabled()
    then
        Integration.CloseInline("bridge_disabled")
        return
    end
    local now = currentTime()
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if now >= (tonumber(Inline.nextLifecycleAt) or 0) then
        local lifecycleActive, lifecycleReason = updateInlineHostLifecycles()
        if not lifecycleActive then
            if lifecycleReason == "npc_unavailable"
                or lifecycleReason == "conversation_interrupted"
            then
                if not Inline.recoveryStartedAt then
                    Inline.recoveryStartedAt = now
                    Inline.recoveryDeadlineAt = now
                        + INLINE_RECOVERY_GRACE_MS
                    Inline.nextRecoveryAt = now
                end
                lifecycleActive = recoverInlineHosts(player, now)
                if not lifecycleActive
                    and now < (tonumber(Inline.recoveryDeadlineAt) or 0)
                then
                    refreshInlineHighlights(0)
                    Inline.part.owner = nil
                    Inline.nextLifecycleAt = now
                        + INLINE_LIFECYCLE_INTERVAL_MS
                    if now >= (tonumber(Inline.nextControlsRefreshAt) or 0)
                        and Inline.part.refreshControls
                    then
                        Inline.part:refreshControls()
                        Inline.nextControlsRefreshAt = now
                            + INLINE_CONTROLS_REFRESH_INTERVAL_MS
                    end
                    positionInline(0, player)
                    return
                end
            end
            if not lifecycleActive then
                Integration.CloseInline(lifecycleReason)
                return
            end
        end
        resetInlineRecovery()
        Inline.nextLifecycleAt = now + INLINE_LIFECYCLE_INTERVAL_MS
    end
    if now >= (tonumber(Inline.nextContextRefreshAt) or 0) then
        refreshLockedInlineEntries(player)
        Inline.nextContextRefreshAt = now
            + INLINE_CONTEXT_REFRESH_INTERVAL_MS
    end
    refreshInlineHighlights(0)
    Inline.part.owner = Inline.host
    Inline.part.title = INLINE_TITLE
    syncInlineModeButton()
    if now >= (tonumber(Inline.nextControlsRefreshAt) or 0) then
        Inline.part:refreshControls()
        Inline.nextControlsRefreshAt = now
            + INLINE_CONTROLS_REFRESH_INTERVAL_MS
    end
    positionInline(0, player)
    focusInlineInputWhenReady()
end

local function closeOnEscape(key)
    if Inline.part and Keyboard and key == Keyboard.KEY_ESCAPE then
        Integration.CloseInline("escape")
    end
end

if Keybinds and Keybinds.RegisterPress then
    Keybinds.RegisterPress({
        id = "ProjectHoomans.LLMChat",
        label = "UI_PNC_HoomansLLM_TalkKey",
        tooltip = "UI_PNC_HoomansLLM_TalkTooltip",
        defaultKey = getKeyCode and (tonumber(getKeyCode("V")) or 47)
            or 47,
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
