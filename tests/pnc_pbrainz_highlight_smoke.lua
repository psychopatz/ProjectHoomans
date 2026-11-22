local T = require "tests/support/test"
T.addPackagePaths()

local LLMInput = {}
local keyDown = true
local registeredPress
local keybinds = {
    TYPE_PRESS = "press",
    TYPE_LONG_PRESS = "longpress",
    RegisterPress = function(definition)
        definition.type = "press"
        registeredPress = definition
        return definition
    end,
    IsDown = function() return keyDown end,
}
PsychopatzCore = {
    Conversation = {
        Text = {
            Resolve = function(value, fallback)
                return type(value) == "table" and (value.fallback or fallback)
                    or tostring(value or fallback or "")
            end,
        },
    },
    Keybinds = keybinds,
}
PNC = {
    Conversation = {},
    CompanionTargetResolver = { SCOPE_SOCIAL = "social" },
}
UIFont = { Small = "Small", Medium = "Medium" }
getKeyCode = function(name) return name == "V" and 47 or 0 end

package.preload["PsychopatzCore/Input/PsychopatzKeybinds"] = function() return keybinds end
package.preload["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"] = function()
    PsychopatzConversationLLMInput = LLMInput
    return LLMInput
end
package.preload["PNC/Commands/PNC_CompanionTargetResolver"] = function()
    return PNC.CompanionTargetResolver
end

T.load("ProjectHoomans", "client", "PNC/Conversation/InlineChat/PNC_InlineChat.lua")
local InlineChat = PNC.Conversation.InlineChat

function LLMInput:new(_, _, _, _, options) return options end

T.equal(registeredPress.type, keybinds.TYPE_PRESS, "inline talk action uses a single press")
T.equal(registeredPress.defaultKey, 47, "inline talk key defaults to V")

local targetPlayer = {
    getX = function() return 100 end,
    getY = function() return 100 end,
    getZ = function() return 0 end,
}
local requestedScopes = {}
PNC.CompanionTargetResolver.NormalizeMode = function(mode) return mode or "nearest" end
PNC.CompanionTargetResolver.NormalizeScope = function(scope) return scope or "colonists" end
PNC.CompanionTargetResolver.ResolveRecipients = function(_, _, _, scope)
    requestedScopes[#requestedScopes + 1] = scope
    if scope == "social" then
        local target = { id = "network-npc", name = "Network NPC" }
        return { scope = scope, target = target, targets = { target } }
    end
    return { scope = scope, target = nil, targets = {} }
end
getSpecificPlayer = function() return targetPlayer end
local inlineResolved = InlineChat.ResolveRecipients(targetPlayer)
T.truthy(inlineResolved and inlineResolved.primary, "keybind recipient resolver falls back to social MP NPCs")
T.equal(inlineResolved.primary.id, "network-npc", "social fallback selected the network NPC")
T.equal(requestedScopes[1], "colonists", "companion scope remains first")
T.equal(requestedScopes[2], "social", "social scope is used as fallback")

local first, second = { highlights = {}, colors = {} }, { highlights = {}, colors = {} }
for _, obj in ipairs({ first, second }) do
    function obj:setOutlineHighlight(playerIndex, enabled)
        self.highlights[#self.highlights + 1] = { playerIndex = playerIndex, enabled = enabled }
    end
    function obj:setOutlineHighlightCol(playerIndex, r, g, b, a)
        self.colors[#self.colors + 1] = { playerIndex = playerIndex, r = r, g = g, b = b, a = a }
    end
end

InlineChat.State.entries = { { id = "npc-one", zombie = first }, { id = "npc-two", zombie = second } }
InlineChat.RefreshHighlights()
T.equal(first.highlights[1].enabled, true, "nearby selection enables the native outline")
T.equal(second.highlights[1].enabled, true, "nearby selection enables every recipient outline")
T.equal(first.colors[1].r, 0, "selection outline is cyan")
T.equal(first.colors[1].g, 1, "selection outline is cyan")
T.equal(first.colors[1].b, 1, "selection outline is cyan")
T.equal(first.colors[1].a, 0.85, "selection outline has visible alpha")

InlineChat.State.entries = { { id = "npc-one", zombie = first } }
InlineChat.RefreshHighlights()
T.equal(second.highlights[2].enabled, false, "removed nearby recipient loses the native outline")
InlineChat.ClearHighlights()
T.equal(first.highlights[3].enabled, false, "closing the inline chat clears the selected outline")

local focusPart = { focusCount = 0 }
function focusPart:focusInput() self.focusCount = self.focusCount + 1 end
InlineChat.State.part = focusPart
InlineChat.State.triggerBinding = { type = keybinds.TYPE_LONG_PRESS }
InlineChat.State.focusAfterTriggerRelease = true
T.falsy(InlineChat.FocusInputWhenReady(), "long-press input stays unfocused while the trigger is held")
T.equal(focusPart.focusCount, 0, "the held trigger cannot send its key into the text field")
keyDown = false
T.truthy(InlineChat.FocusInputWhenReady(), "long-press input focuses after the trigger is released")
T.equal(focusPart.focusCount, 1, "released trigger focuses the input once")

local inputOptions = InlineChat.CreateInputPart({ x = 0, y = 0, width = 320, height = 108 })
local readyState = inputOptions.getState({
    session = {},
    isConversationInteractive = function() return true end,
}, inputOptions)
T.equal(readyState.statusText, "", "ready inline input does not render a generic status footer")

-- Fail closed when DialogueInput is genuinely unloaded; route cleanly through PNC.ConvoEngine.DialogueInput when present.
local semanticRequire = require
local legacyCalled = false
PNC.ConvoEngine = nil
PNC.PBrainZ = { Submit = function() legacyCalled = true; return true end }
require = function(name)
    if name == "PNC/ConvoEngine/RuntimeFacade" or name == "PNC/ConvoEngine/Dialogue/Input" then return true end
    return semanticRequire(name)
end
local unavailAccepted, unavailReason = inputOptions.submit({}, "hello there", inputOptions)
T.equal(unavailAccepted, false, "missing ConvoEngine input rejects submission")
T.equal(unavailReason, "semantic_input_unavailable", "missing ConvoEngine input returns stable reason")
T.falsy(legacyCalled, "missing semantic input never bypasses into PBrainZ")

local submitCalls = {}
PNC.ConvoEngine = {
    DialogueInput = {
        Submit = function(view, val)
            submitCalls[#submitCalls + 1] = val
            if val == "bye" then
                view.lastSemanticDialogueResult = {
                    decision = { route = "deterministic", branch = "FAREWELL_ACKNOWLEDGED", closeConversation = true },
                }
            else
                view.lastSemanticDialogueResult = {
                    decision = { route = "deterministic", branch = "GREET_ACKNOWLEDGED" },
                }
            end
            return true, "accepted"
        end,
    },
}
local testHostClosedReason
local submitView = { close = function(_, r) testHostClosedReason = r end }
local okSub, okReason = InlineChat.Submit(submitView, "hello", {})
T.equal(okSub, true, "InlineChat.Submit routes cleanly through PNC.ConvoEngine.DialogueInput")
T.equal(okReason, "accepted", "InlineChat.Submit returns accepted")
T.equal(submitCalls[1], "hello", "InlineChat.Submit passes submitted utterance")
InlineChat.State.part = { inputMode = "nearest" }
InlineChat.State.host = submitView
InlineChat.State.hosts = { submitView }
local byeSub = InlineChat.Submit(submitView, "bye", InlineChat.State.part)
T.equal(byeSub, true, "InlineChat.Submit accepts semantic farewell")
T.equal(testHostClosedReason, "semantic_farewell", "semantic farewell closes InlineChat cleanly")
T.falsy(InlineChat.IsActive(), "InlineChat closes after semantic farewell")
require = semanticRequire

-- Verify group silent-close & single-primary farewell reason dedup.
local closeReasons = {}
local h1 = { close = function(_, r) closeReasons[1] = r end }
local h2 = { close = function(_, r) closeReasons[2] = r end }
InlineChat.State.part = { inputMode = "nearby" }
InlineChat.State.host = h1
InlineChat.State.hosts = { h1, h2 }
InlineChat.State.hasUserSubmitted = false
InlineChat.Close("user_closed")
T.equal(closeReasons[1], "inline_silent_close", "untouched inline open/close uses silent close reason")
T.equal(closeReasons[2], "inline_silent_close", "untouched inline group uses silent close reason")

InlineChat.State.part = { inputMode = "nearby" }
InlineChat.State.host = h1
InlineChat.State.hosts = { h1, h2 }
InlineChat.State.hasUserSubmitted = true
InlineChat.Close("user_closed")
T.equal(closeReasons[1], "user_closed", "interacted inline close fires farewell only for primary host")
T.equal(closeReasons[2], "inline_group_silent_close", "interacted inline group suppresses duplicate farewells on secondary hosts")

local inlineSource = T.read("ProjectHoomans", "client", "PNC/Conversation/InlineChat/PNC_InlineChatConfig.lua")
T.contains(inlineSource, 'image = "media/ui/MP/mp_ui_emptyServer.png"', "inline single-target control keeps its person icon")
T.contains(inlineSource, 'fallback = "SINGLE NPC"', "inline single-target control has a distinct hover name")
T.contains(inlineSource, 'image = "media/ui/MP/mp_ui_playerCount.png"', "inline multi-target control keeps its group icon")
T.contains(inlineSource, 'fallback = "NEARBY NPCS"', "inline multi-target control has a distinct hover name")

local firstTarget = { id = "npc-one", name = "First NPC", zombie = first }
local secondTarget = { id = "npc-two", name = "Second NPC", zombie = second }
local otherTarget = { id = "npc-other", name = "Other NPC" }
local failHostID
local failAllHosts = false
PNC.CompanionTargetResolver.ResolveNearestCycle = function(_, currentID, _, scope)
    local target = tostring(currentID or "") == firstTarget.id and secondTarget or firstTarget
    return { scope = scope, target = target, targets = { target } }
end
PNC.CompanionTargetResolver.ResolveRecipients = function(_, mode, _, scope)
    if scope == "other" then
        return { scope = scope, target = otherTarget, targets = { otherTarget } }
    end
    if mode == "nearby" then
        return { scope = scope, target = firstTarget, targets = { firstTarget, secondTarget } }
    end
    return { scope = scope, target = firstTarget, targets = { firstTarget } }
end
PNC.CompanionTargetResolver.BuildConversationEntry = function(target)
    return { id = target.id, name = target.name, source = target, zombie = target.zombie }
end
PNC.Conversation.BuildDefinition = function(entry)
    return { npcID = entry.id, context = {} }
end
PsychopatzCore.Conversation = {
    CreateHeadless = function(definition)
        if failAllHosts or failHostID == definition.npcID then
            return { spec = definition, closed = true, lifecycleError = "npc_unavailable" }
        end
        local host = { spec = definition, closed = false }
        function host:close() self.closed = true end
        return host
    end,
}
local modePart = {
    inputMode = "nearest",
    refreshControls = function() end,
    updateModeButtonStyles = function(self) self.visualMode = self.inputMode end,
}
local function commitModeForTest(mode)
    modePart.inputMode = mode
    modePart:updateModeButtonStyles()
end
InlineChat.State.part = modePart
InlineChat.State.mode = "nearest"
InlineChat.State.scope = "social"
InlineChat.State.targetID = firstTarget.id
InlineChat.State.hosts = {}
InlineChat.State.entries = {}
InlineChat.State.host = nil
getSpecificPlayer = function() return targetPlayer end

T.truthy(InlineChat.SetMode(modePart, "nearest", modePart), "repeated nearest mode click retargets immediately")
commitModeForTest("nearest")
T.equal(InlineChat.State.targetID, secondTarget.id, "nearest mode cycles to the next NPC without reopening")
T.equal(#InlineChat.State.hosts, 1, "nearest mode keeps one active conversation host")
T.equal(InlineChat.State.host.spec.context.nameplateConversation, true, "compact host uses headless context")
T.equal(InlineChat.State.host.spec.context.guardThreats, false, "compact host disables threat interruption")

T.truthy(InlineChat.SetMode(modePart, "nearby", modePart), "nearby mode switches immediately")
commitModeForTest("nearby")
T.equal(modePart.inputMode, "nearby", "nearby mode updates the selected mode button state")
T.equal(modePart.visualMode, "nearby", "nearby mode refreshes the selected mode styling")
T.equal(#InlineChat.State.hosts, 2, "nearby mode creates a host for every nearby NPC")
T.equal(InlineChat.State.targetID, secondTarget.id, "nearby mode preserves the selected target")

T.truthy(InlineChat.SetMode(modePart, "nearest", modePart), "nearest mode switches back immediately")
commitModeForTest("nearest")
T.equal(InlineChat.State.targetID, firstTarget.id, "switching back to nearest selects the closest NPC")
T.equal(#InlineChat.State.hosts, 1, "switching back to nearest retires the extra host")
T.equal(second.highlights[#second.highlights].enabled, false, "switching back clears unselected outline")

T.truthy(InlineChat.SetScope(modePart, true, modePart), "scope toggle switches to other NPCs immediately")
T.equal(InlineChat.State.scope, "other", "scope toggle commits the other-NPC scope")
T.equal(InlineChat.State.targetID, otherTarget.id, "scope toggle selects a target in the new scope")

InlineChat.State.mode = "nearby"
InlineChat.State.scope = "social"
InlineChat.State.part = modePart
local activeTargetID = InlineChat.State.targetID
T.truthy(InlineChat.RequestFallback({ id = "fallback-npc" }, "test_fallback"), "fallback request is accepted")
T.equal(InlineChat.State.mode, "nearby", "fallback request preserves active nearby mode")
T.equal(InlineChat.State.targetID, activeTargetID, "fallback request preserves active target")
T.equal(InlineChat.State.pendingFallbackMode, "nearest", "fallback mode is deferred until fallback open")
InlineChat.State.pendingTargetEntry = nil
InlineChat.State.pendingFallbackMode = nil
InlineChat.State.pendingFallbackScope = nil
InlineChat.State.pendingFallbackReason = nil
InlineChat.State.pendingFallbackDeadline = nil
InlineChat.State.pendingFallbackNextAttemptAt = nil

failHostID = secondTarget.id
modePart.inputMode = "nearest"
InlineChat.State.mode = "nearest"
InlineChat.State.scope = "social"
InlineChat.State.targetID = firstTarget.id
T.truthy(InlineChat.SetMode(modePart, "nearby", modePart), "nearby mode accepts healthy hosts when one is unavailable")
T.equal(#InlineChat.State.hosts, 1, "nearby mode prunes unavailable host")
T.equal(InlineChat.State.targetID, firstTarget.id, "nearby mode preserves healthy primary host")
failHostID = nil

failAllHosts = true
modePart.inputMode = "nearest"
InlineChat.State.mode = "nearest"
InlineChat.State.scope = "social"
InlineChat.State.targetID = firstTarget.id
InlineChat.State.hosts = {}
InlineChat.State.entries = {}
T.falsy(InlineChat.SetMode(modePart, "nearby", modePart), "mode switch rejects when no host can be built")
T.equal(InlineChat.State.mode, "nearest", "rejected mode switch preserves committed mode")
T.equal(modePart.inputMode, "nearest", "rejected mode switch preserves widget mode")
failAllHosts = false

local replacement = { highlights = {}, colors = {} }
function replacement:setOutlineHighlight(playerIndex, enabled)
    self.highlights[#self.highlights + 1] = { playerIndex = playerIndex, enabled = enabled }
end
function replacement:setOutlineHighlightCol(playerIndex, r, g, b, a)
    self.colors[#self.colors + 1] = { playerIndex = playerIndex, r = r, g = g, b = b, a = a }
end
PNC.Registry = { GetLiveZombie = function(id) return tostring(id) == "npc-one" and replacement or nil end }
InlineChat.State.entries = { { id = "npc-one", zombie = first } }
InlineChat.State.highlightedZombies = { ["npc-one"] = first }
InlineChat.RefreshHighlights()
T.equal(first.highlights[#first.highlights].enabled, false, "stale body loses native outline after replacement")
T.equal(replacement.highlights[1].enabled, true, "current body receives native outline after replacement")
InlineChat.ClearHighlights()

InlineChat.State.part = nil
local closedReason
PsychopatzCore.Conversation.instance = { close = function(_, reason) closedReason = reason end }
local selectedEntry = { id = "hostile-selected", name = "Hostile Selected", x = 2, y = 0, z = 0 }
T.truthy(InlineChat.OpenForTarget(selectedEntry), "hostile conversation requests nameplate handoff")
T.equal(InlineChat.State.pendingTargetEntry, selectedEntry, "handoff keeps selected target entry")
T.equal(InlineChat.State.scope, "other", "hostile handoff selects non-colonist scope")
T.equal(closedReason, "nameplate_fallback", "handoff closes full conversation view")
PsychopatzCore.Conversation.instance = nil
InlineChat.State.pendingTargetEntry = nil
InlineChat.State.pendingFallbackReason = nil
InlineChat.State.pendingFallbackDeadline = nil
InlineChat.State.pendingFallbackNextAttemptAt = nil
InlineChat.Close("test_cleanup")

local lifecyclePart = { inputMode = "nearby", refreshControls = function() end, updateModeButtonStyles = function() end }
local lifecyclePrimary = { closed = false, session = { updates = 0 } }
function lifecyclePrimary.session:update() self.updates = self.updates + 1 end
function lifecyclePrimary:updateLifecycle() return nil end
local lifecycleSecondary = { closed = false }
function lifecycleSecondary:updateLifecycle() self.closed = true; return "npc_unavailable" end
InlineChat.State.part = lifecyclePart
InlineChat.State.host = lifecyclePrimary
InlineChat.State.hosts = { lifecyclePrimary, lifecycleSecondary }
InlineChat.State.entries = { { id = "primary" }, { id = "secondary" } }
InlineChat.State.nextLifecycleAt, InlineChat.State.nextContextRefreshAt, InlineChat.State.nextControlsRefreshAt = 0, math.huge, math.huge
InlineChat.Update()
T.truthy(InlineChat.State.part, "secondary nearby recipient does not close compact input")
T.equal(#InlineChat.State.hosts, 1, "unavailable secondary recipient is pruned")
T.equal(lifecyclePrimary.session.updates, 1, "headless inline host advances conversation queue")
InlineChat.Close("test_cleanup_lifecycle")

local promotedPart = { inputMode = "nearby", refreshControls = function() end, updateModeButtonStyles = function() end }
local failedPrimary = { closed = false }
function failedPrimary:updateLifecycle() self.closed = true; return "npc_unavailable" end
local promotedSecondary = { closed = false }
function promotedSecondary:updateLifecycle() return nil end
InlineChat.State.part = promotedPart
InlineChat.State.mode = "nearby"
InlineChat.State.host = failedPrimary
InlineChat.State.hosts = { failedPrimary, promotedSecondary }
InlineChat.State.entries = { { id = "primary" }, { id = "secondary" } }
InlineChat.State.nextLifecycleAt, InlineChat.State.nextContextRefreshAt, InlineChat.State.nextControlsRefreshAt = 0, math.huge, math.huge
InlineChat.Update()
T.equal(InlineChat.State.host, promotedSecondary, "healthy nearby recipient is promoted")
T.equal(InlineChat.State.targetID, "secondary", "promoted nearby recipient becomes target")
InlineChat.Close("test_cleanup_promoted_lifecycle")

local recoveryPart = { inputMode = "nearby", refreshControls = function() end, updateModeButtonStyles = function() end }
failAllHosts = true
InlineChat.State.part = recoveryPart
InlineChat.State.mode = "nearby"
InlineChat.State.scope = "social"
InlineChat.State.targetID = firstTarget.id
InlineChat.State.host = nil
InlineChat.State.hosts = {}
InlineChat.State.entries = {}
InlineChat.State.nextLifecycleAt, InlineChat.State.nextContextRefreshAt, InlineChat.State.nextControlsRefreshAt = 0, math.huge, math.huge
InlineChat.Update()
T.truthy(InlineChat.State.part, "all unavailable hosts preserve panel for grace recovery")
failAllHosts = false
InlineChat.State.nextLifecycleAt = 0
InlineChat.State.nextRecoveryAt = 0
InlineChat.Update()
T.equal(#InlineChat.State.hosts, 2, "compact input recovers nearby hosts")
T.equal(InlineChat.State.targetID, firstTarget.id, "recovered nearby hosts preserve selected target")
InlineChat.Close("test_cleanup_recovery")

T.finish("pnc_pbrainz_highlight_smoke")
