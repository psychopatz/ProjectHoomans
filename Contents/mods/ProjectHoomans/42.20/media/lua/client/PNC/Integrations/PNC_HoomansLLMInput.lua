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

local MAX_INPUT_LENGTH = 4000
local INLINE_WIDTH = 320
local INLINE_HEIGHT = 108
local INLINE_PLAYER_Y_OFFSET = 36
local INLINE_LIFECYCLE_INTERVAL_MS = 100
local INLINE_CONTEXT_REFRESH_INTERVAL_MS = 500
local INLINE_CONTROLS_REFRESH_INTERVAL_MS = 250
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
            fallback = "NEAREST NPC",
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
    if entry and entry.zombie then return entry.zombie end
    local registry = PNC.Registry
    local id = tostring(entry and entry.id or "")
    if id ~= "" and registry and registry.GetLiveZombie then
        return registry.GetLiveZombie(id)
    end
    return nil
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
    Inline.focusAfterTriggerRelease = false
    Inline.triggerBinding = nil
    return true
end

local function clearPendingInlineFallback()
    Inline.pendingTargetEntry = nil
    Inline.pendingFallbackReason = nil
    Inline.pendingFallbackDeadline = nil
    Inline.pendingFallbackNextAttemptAt = nil
end

local function queueInlineFallback(entry, reason)
    local id = tostring(entry and entry.id or "")
    if id == "" then return false end
    Inline.pendingTargetEntry = entry
    Inline.targetID = id
    Inline.directTarget = entry
    Inline.mode = INLINE_MODE_NEAREST
    Inline.scope = INLINE_SCOPE_OTHER
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
    Inline.mode = INLINE_MODE_NEAREST
    Inline.scope = INLINE_SCOPE_OTHER
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

local function resolveInlineRecipients(player)
    if not player or not Targets then return nil end
    Inline.mode = Targets.NormalizeMode(Inline.mode or INLINE_MODE_NEAREST)
    Inline.scope = Targets.NormalizeScope(
        Inline.scope or INLINE_SCOPE_COLONISTS
    )
    local resolved = Targets.ResolveRecipients(
        player,
        Inline.mode,
        nil,
        Inline.scope
    )
    if not resolved then return nil end
    -- The closed key entry point cannot be switched to OTHER NPCS until it
    -- has opened once.  In multiplayer the nearby NPC is commonly a
    -- replicated social target rather than a player-owned companion, so fall
    -- through to the resolver's social scope when the companion scope is
    -- empty.  Keep Inline.scope as the user's requested scope so the existing
    -- colonist/other toggle remains stable after the window opens.
    if not resolved.target
        and Inline.scope == INLINE_SCOPE_COLONISTS
        and Targets.SCOPE_SOCIAL
    then
        local social = Targets.ResolveRecipients(
            player,
            Inline.mode,
            nil,
            INLINE_SCOPE_SOCIAL
        )
        if social and social.target then resolved = social end
    end
    local primary = resolved.target
    if Inline.targetID then
        local candidates = resolved.targets
        if Inline.mode == INLINE_MODE_NEAREST and #candidates == 0 then
            candidates = Targets.CollectNearbyTargets(
                player,
                nil,
                Inline.scope
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
    if Inline.mode == INLINE_MODE_NEAREST then
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
    host.spec.context = context
    host.spec.character = entry and entry.zombie or nil
end

local function rebuildInlineHosts(player, resolved)
    local oldHosts = {}
    local newHosts = {}
    local createdHosts = {}
    local entries = {}
    local old
    local entry
    local host
    local id
    local primaryTarget = resolved.primary or resolved.target
    if not primaryTarget then return false end
    for _, old in ipairs(Inline.hosts or {}) do
        id = tostring(old.spec and old.spec.npcID or "")
        if id ~= "" then oldHosts[id] = old end
    end
    for _, candidate in ipairs(resolved.targets) do
        entry = Targets.BuildConversationEntry(candidate)
        id = tostring(entry.id)
        host = oldHosts[id]
        if host and host.closed then host = nil end
        if not host then
            host = buildInlineHost(entry, player)
            if host then createdHosts[#createdHosts + 1] = host end
        end
        if not host then
            for _, created in ipairs(createdHosts) do
                if created and created.close then
                    created:close("inline_target_build_failed")
                end
            end
            return false
        end
        refreshInlineHostContext(host, entry, player)
        oldHosts[id] = nil
        entries[#entries + 1] = entry
        newHosts[#newHosts + 1] = host
    end
    -- A mode switch is only available while no request is pending, so unused
    -- hosts have no in-flight bridge work and can be retired safely.
    for _, unused in pairs(oldHosts) do
        if unused and unused.close then unused:close("inline_retargeted") end
    end
    local primaryID = tostring(primaryTarget.id or "")
    local primaryIndex = 1
    for index, candidate in ipairs(entries) do
        if tostring(candidate.id) == primaryID then
            primaryIndex = index
            break
        end
    end
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

function Integration.SetInlineMode(_, mode, part)
    if part and part ~= Inline.part then return false end
    if not Inline.part then return false end
    if Integration.GetPending and Integration.GetPending() then return false end
    local previousMode = Inline.mode
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    Inline.mode = Targets.NormalizeMode(mode)
    local resolved = resolveInlineRecipients(player)
    if not resolved or #resolved.targets == 0 then
        Inline.mode = previousMode
        return false
    end
    if not rebuildInlineHosts(player, resolved) then
        Inline.mode = previousMode
        return false
    end
    Inline.nextLifecycleAt = 0
    Inline.nextContextRefreshAt = 0
    Inline.nextControlsRefreshAt = 0
    refreshInlineHighlights(0)
    Inline.part.owner = Inline.host
    Inline.part:refreshControls()
    positionInline(0, player)
    return true
end

function Integration.SetInlineScope(_, value, part)
    if part and part ~= Inline.part then return false end
    if not Inline.part then return false end
    if Integration.GetPending and Integration.GetPending() then return false end
    local previousScope = Inline.scope
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    Inline.scope = value == true
        and INLINE_SCOPE_OTHER or INLINE_SCOPE_COLONISTS
    local resolved = resolveInlineRecipients(player)
    if not resolved or #resolved.targets == 0 then
        Inline.scope = previousScope
        return false
    end
    if not rebuildInlineHosts(player, resolved) then
        Inline.scope = previousScope
        return false
    end
    Inline.nextLifecycleAt = 0
    Inline.nextContextRefreshAt = 0
    Inline.nextControlsRefreshAt = 0
    refreshInlineHighlights(0)
    Inline.part.owner = Inline.host
    Inline.part:refreshControls()
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
    if now >= (tonumber(Inline.nextLifecycleAt) or 0) then
        for _, host in ipairs(Inline.hosts or {}) do
            if host and host.updateLifecycle then
                local interruption = host:updateLifecycle()
                if interruption or host.closed then
                    Integration.CloseInline(
                        interruption or "conversation_interrupted"
                    )
                    return
                end
            end
        end
        Inline.nextLifecycleAt = now + INLINE_LIFECYCLE_INTERVAL_MS
    end
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or getPlayer and getPlayer() or nil
    if now >= (tonumber(Inline.nextContextRefreshAt) or 0) then
        refreshLockedInlineEntries(player)
        Inline.nextContextRefreshAt = now
            + INLINE_CONTEXT_REFRESH_INTERVAL_MS
    end
    refreshInlineHighlights(0)
    Inline.part.owner = Inline.host
    Inline.part.title = INLINE_TITLE
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
