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
                return type(value) == "table"
                    and (value.fallback or fallback)
                    or tostring(value or fallback or "")
            end,
        },
    },
    Keybinds = keybinds,
}
PNC = {
    Conversation = {},
    HoomansLLM = {
        IsBridgeEnabled = function() return true end,
    },
    CompanionTargetResolver = { SCOPE_SOCIAL = "social" },
}
UIFont = { Small = "Small", Medium = "Medium" }
getKeyCode = function(name)
    return name == "V" and 47 or 0
end

package.preload["PsychopatzCore/Input/PsychopatzKeybinds"] =
    function()
        return keybinds
    end
package.preload["PsychopatzCore/UI/Conversation/Parts/PsychopatzConversationLLMInput"] =
    function()
        PsychopatzConversationLLMInput = LLMInput
        return LLMInput
    end
package.preload["PNC/Commands/PNC_CompanionTargetResolver"] =
    function()
        return PNC.CompanionTargetResolver
    end

T.load(
    "ProjectHoomans",
    "client",
    "PNC/Integrations/PNC_HoomansLLMInput.lua"
)

local Integration = PNC.HoomansLLM

function LLMInput:new(_, _, _, _, options)
    return options
end

T.equal(registeredPress.type, keybinds.TYPE_PRESS,
    "LLM talk action uses a single press")
T.equal(registeredPress.defaultKey, 47,
    "LLM talk key defaults to V")

local targetPlayer = {
    getX = function() return 100 end,
    getY = function() return 100 end,
    getZ = function() return 0 end,
}
local requestedScopes = {}
PNC.CompanionTargetResolver.NormalizeMode = function(mode)
    return mode or "nearest"
end
PNC.CompanionTargetResolver.NormalizeScope = function(scope)
    return scope or "colonists"
end
PNC.CompanionTargetResolver.ResolveRecipients = function(_, _, _, scope)
    requestedScopes[#requestedScopes + 1] = scope
    if scope == "social" then
        local target = { id = "network-npc", name = "Network NPC" }
        return { scope = scope, target = target, targets = { target } }
    end
    return { scope = scope, target = nil, targets = {} }
end
getSpecificPlayer = function() return targetPlayer end
local inlineResolved = Integration.ResolveInlineRecipients(targetPlayer)
T.truthy(inlineResolved and inlineResolved.primary,
    "keybind recipient resolver falls back to social MP NPCs")
T.equal(inlineResolved.primary.id, "network-npc",
    "social fallback selected the network NPC")
T.equal(requestedScopes[1], "colonists", "companion scope remains first")
T.equal(requestedScopes[2], "social", "social scope is used as fallback")
local first = { highlights = {}, colors = {} }
local second = { highlights = {}, colors = {} }
function first:setOutlineHighlight(playerIndex, enabled)
    self.highlights[#self.highlights + 1] = {
        playerIndex = playerIndex,
        enabled = enabled,
    }
end
function first:setOutlineHighlightCol(playerIndex, r, g, b, a)
    self.colors[#self.colors + 1] = {
        playerIndex = playerIndex,
        r = r,
        g = g,
        b = b,
        a = a,
    }
end
function second:setOutlineHighlight(playerIndex, enabled)
    self.highlights[#self.highlights + 1] = {
        playerIndex = playerIndex,
        enabled = enabled,
    }
end
function second:setOutlineHighlightCol(playerIndex, r, g, b, a)
    self.colors[#self.colors + 1] = {
        playerIndex = playerIndex,
        r = r,
        g = g,
        b = b,
        a = a,
    }
end

Integration.Inline.entries = {
    { id = "npc-one", zombie = first },
    { id = "npc-two", zombie = second },
}
Integration.RefreshInlineHighlights()
T.equal(first.highlights[1].enabled, true,
    "nearby selection enables the native outline")
T.equal(second.highlights[1].enabled, true,
    "nearby selection enables every recipient outline")
T.equal(first.colors[1].r, 0, "selection outline is cyan")
T.equal(first.colors[1].g, 1, "selection outline is cyan")
T.equal(first.colors[1].b, 1, "selection outline is cyan")
T.equal(first.colors[1].a, 0.85, "selection outline has visible alpha")

Integration.Inline.entries = {
    { id = "npc-one", zombie = first },
}
Integration.RefreshInlineHighlights()
T.equal(second.highlights[2].enabled, false,
    "removed nearby recipient loses the native outline")

Integration.ClearInlineHighlights()
T.equal(first.highlights[3].enabled, false,
    "closing the inline chat clears the selected outline")

local focusPart = { focusCount = 0 }
function focusPart:focusInput()
    self.focusCount = self.focusCount + 1
end
Integration.Inline.part = focusPart
Integration.Inline.triggerBinding = { type = keybinds.TYPE_LONG_PRESS }
Integration.Inline.focusAfterTriggerRelease = true
T.falsy(Integration.FocusInlineInputWhenReady(),
    "long-press input stays unfocused while the trigger is held")
T.equal(focusPart.focusCount, 0,
    "the held trigger cannot send its key into the text field")
keyDown = false
T.truthy(Integration.FocusInlineInputWhenReady(),
    "long-press input focuses after the trigger is released")
T.equal(focusPart.focusCount, 1,
    "released trigger focuses the input once")

local inputOptions = Integration.CreateInputPart({
    x = 0,
    y = 0,
    width = 320,
    height = 108,
})
local readyState = inputOptions.getState({
    session = {},
    isConversationInteractive = function() return true end,
}, inputOptions)
T.equal(readyState.statusText, "",
    "ready inline input does not render a generic status footer")
local inlineSource = T.read(
    "ProjectHoomans",
    "client",
    "PNC/Integrations/PNC_HoomansLLMInput.lua"
)
T.contains(inlineSource, 'image = "media/ui/MP/mp_ui_emptyServer.png"',
    "inline single-target control keeps its person icon")
T.contains(inlineSource, 'fallback = "SINGLE NPC"',
    "inline single-target control has a distinct hover name")
T.contains(inlineSource, 'image = "media/ui/MP/mp_ui_playerCount.png"',
    "inline multi-target control keeps its group icon")
T.contains(inlineSource, 'fallback = "NEARBY NPCS"',
    "inline multi-target control has a distinct hover name")

local firstTarget = { id = "npc-one", name = "First NPC", zombie = first }
local secondTarget = { id = "npc-two", name = "Second NPC", zombie = second }
local otherTarget = { id = "npc-other", name = "Other NPC" }
local failHostID
local failAllHosts = false
PNC.CompanionTargetResolver.ResolveNearestCycle = function(_, currentID, _, scope)
    local target = tostring(currentID or "") == firstTarget.id
        and secondTarget or firstTarget
    return {
        scope = scope,
        target = target,
        targets = { target },
    }
end
PNC.CompanionTargetResolver.ResolveRecipients = function(_, mode, _, scope)
    if scope == "other" then
        return {
            scope = scope,
            target = otherTarget,
            targets = { otherTarget },
        }
    end
    if mode == "nearby" then
        return {
            scope = scope,
            target = firstTarget,
            targets = { firstTarget, secondTarget },
        }
    end
    return {
        scope = scope,
        target = firstTarget,
        targets = { firstTarget },
    }
end
PNC.CompanionTargetResolver.BuildConversationEntry = function(target)
    return {
        id = target.id,
        name = target.name,
        source = target,
        zombie = target.zombie,
    }
end
PNC.Conversation.BuildDefinition = function(entry)
    return { npcID = entry.id, context = {} }
end
PsychopatzCore.Conversation = {
    CreateHeadless = function(definition)
        if failAllHosts or failHostID == definition.npcID then
            return {
                spec = definition,
                closed = true,
                lifecycleError = "npc_unavailable",
            }
        end
        local host = { spec = definition, closed = false }
        function host:close() self.closed = true end
        return host
    end,
}
local modePart = {
    inputMode = "nearest",
    refreshControls = function() end,
    updateModeButtonStyles = function(self)
        self.visualMode = self.inputMode
    end,
}
local function commitModeForTest(mode)
    -- Production Core commits the widget mode after the integration callback
    -- returns true. These direct adapter calls model that final commit while
    -- keeping the integration from becoming a second UI state authority.
    modePart.inputMode = mode
    modePart:updateModeButtonStyles()
end
Integration.Inline.part = modePart
Integration.Inline.mode = "nearest"
Integration.Inline.scope = "social"
Integration.Inline.targetID = firstTarget.id
Integration.Inline.hosts = {}
Integration.Inline.entries = {}
Integration.Inline.host = nil
getSpecificPlayer = function() return targetPlayer end

T.truthy(Integration.SetInlineMode(modePart, "nearest", modePart),
    "repeated nearest mode click retargets immediately")
commitModeForTest("nearest")
T.equal(Integration.Inline.targetID, secondTarget.id,
    "nearest mode cycles to the next NPC without reopening")
T.equal(#Integration.Inline.hosts, 1,
    "nearest mode keeps one active conversation host")
T.equal(Integration.Inline.host.spec.context.nameplateConversation, true,
    "compact host uses the headless conversation context")
T.equal(Integration.Inline.host.spec.context.guardThreats, false,
    "compact host disables threat interruption")

T.truthy(Integration.SetInlineMode(modePart, "nearby", modePart),
    "nearby mode switches immediately")
commitModeForTest("nearby")
T.equal(modePart.inputMode, "nearby",
    "nearby mode updates the selected mode button state")
T.equal(modePart.visualMode, "nearby",
    "nearby mode refreshes the selected mode styling")
T.equal(#Integration.Inline.hosts, 2,
    "nearby mode creates a host for every nearby NPC")
T.equal(Integration.Inline.targetID, secondTarget.id,
    "nearby mode preserves the selected target")
T.equal(first.highlights[#first.highlights].enabled, true,
    "nearby mode highlights its first recipient")
T.equal(second.highlights[#second.highlights].enabled, true,
    "nearby mode highlights its second recipient")

T.truthy(Integration.SetInlineMode(modePart, "nearest", modePart),
    "nearest mode switches back immediately")
commitModeForTest("nearest")
T.equal(modePart.inputMode, "nearest",
    "nearest mode updates the selected mode button state")
T.equal(modePart.visualMode, "nearest",
    "nearest mode refreshes the selected mode styling")
T.equal(Integration.Inline.targetID, firstTarget.id,
    "switching back to nearest selects the closest NPC")
T.equal(#Integration.Inline.hosts, 1,
    "switching back to nearest retires the extra host")
T.equal(Integration.Inline.part, modePart,
    "mode switching keeps the existing compact input part")
T.equal(second.highlights[#second.highlights].enabled, false,
    "switching back to one target clears the unselected recipient outline")

T.truthy(Integration.SetInlineScope(modePart, true, modePart),
    "scope toggle switches to other NPCs immediately")
T.equal(Integration.Inline.scope, "other",
    "scope toggle commits the other-NPC scope")
T.equal(Integration.Inline.targetID, otherTarget.id,
    "scope toggle selects a target in the new scope")

-- A fallback request from another conversation must not overwrite the
-- compact input's committed mode while the panel is already open.
Integration.Inline.mode = "nearby"
Integration.Inline.scope = "social"
Integration.Inline.part = modePart
local activeTargetID = Integration.Inline.targetID
T.truthy(Integration.RequestInlineFallback(
    { id = "fallback-npc" },
    "test_fallback"
), "fallback request is accepted")
T.equal(Integration.Inline.mode, "nearby",
    "fallback request preserves the active nearby mode")
T.equal(Integration.Inline.scope, "social",
    "fallback request preserves the active scope")
T.equal(Integration.Inline.targetID, activeTargetID,
    "fallback request preserves the active target")
T.equal(Integration.Inline.pendingFallbackMode, "nearest",
    "fallback mode is deferred until fallback open")
Integration.Inline.pendingTargetEntry = nil
Integration.Inline.pendingFallbackMode = nil
Integration.Inline.pendingFallbackScope = nil
Integration.Inline.pendingFallbackReason = nil
Integration.Inline.pendingFallbackDeadline = nil
Integration.Inline.pendingFallbackNextAttemptAt = nil

-- Nearby mode keeps the panel and commits the healthy subset when one host
-- cannot be created during the switch.
failHostID = secondTarget.id
modePart.inputMode = "nearest"
Integration.Inline.mode = "nearest"
Integration.Inline.scope = "social"
Integration.Inline.targetID = firstTarget.id
T.truthy(Integration.SetInlineMode(modePart, "nearby", modePart),
    "nearby mode accepts healthy hosts when one recipient is unavailable")
T.equal(#Integration.Inline.hosts, 1,
    "nearby mode prunes the unavailable host during rebuild")
T.equal(Integration.Inline.targetID, firstTarget.id,
    "nearby mode preserves the healthy primary host")
failHostID = nil

-- A rejected rebuild must leave both the committed adapter mode and the
-- widget's selected mode untouched.  This is the path that used to flash the
-- other icon until the panel was reopened.
failAllHosts = true
modePart.inputMode = "nearest"
Integration.Inline.mode = "nearest"
Integration.Inline.scope = "social"
Integration.Inline.targetID = firstTarget.id
Integration.Inline.hosts = {}
Integration.Inline.entries = {}
T.falsy(Integration.SetInlineMode(modePart, "nearby", modePart),
    "mode switch rejects when no replacement host can be built")
T.equal(Integration.Inline.mode, "nearest",
    "rejected mode switch preserves the committed adapter mode")
T.equal(modePart.inputMode, "nearest",
    "rejected mode switch preserves the selected widget mode")
failAllHosts = false

-- Replacing a live body under the same NPC ID clears the old outline and
-- applies it to the current body instead of retaining a stale reference.
local replacement = { highlights = {}, colors = {} }
function replacement:setOutlineHighlight(playerIndex, enabled)
    self.highlights[#self.highlights + 1] = {
        playerIndex = playerIndex,
        enabled = enabled,
    }
end
function replacement:setOutlineHighlightCol(playerIndex, r, g, b, a)
    self.colors[#self.colors + 1] = {
        playerIndex = playerIndex,
        r = r,
        g = g,
        b = b,
        a = a,
    }
end
PNC.Registry = {
    GetLiveZombie = function(id)
        return tostring(id) == "npc-one" and replacement or nil
    end,
}
Integration.Inline.entries = {
    { id = "npc-one", zombie = first },
}
Integration.Inline.highlightedZombies = { ["npc-one"] = first }
Integration.RefreshInlineHighlights()
T.equal(first.highlights[#first.highlights].enabled, false,
    "stale body loses the native outline after replacement")
T.equal(replacement.highlights[1].enabled, true,
    "current body receives the native outline after replacement")
Integration.ClearInlineHighlights()

-- In client replica mode the visible body can be present in the presence
-- index before the logical registry is rebound.  The outline must follow
-- that validated body instead of disappearing until the panel is reopened.
local presenceOnlyBody = { highlights = {}, colors = {} }
function presenceOnlyBody:setOutlineHighlight(playerIndex, enabled)
    self.highlights[#self.highlights + 1] = {
        playerIndex = playerIndex,
        enabled = enabled,
    }
end
function presenceOnlyBody:setOutlineHighlightCol(playerIndex, r, g, b, a)
    self.colors[#self.colors + 1] = {
        playerIndex = playerIndex,
        r = r,
        g = g,
        b = b,
        a = a,
    }
end
PNC.Registry.GetLiveZombie = function() return nil end
PNC.ClientPresenceSync = {
    ResolveBodyForNPC = function(id)
        return tostring(id) == "npc-one" and presenceOnlyBody or nil
    end,
}
Integration.Inline.entries = { { id = "npc-one", zombie = first } }
Integration.RefreshInlineHighlights()
T.equal(presenceOnlyBody.highlights[1].enabled, true,
    "presence-index body receives the selected outline")
Integration.ClearInlineHighlights()
PNC.ClientPresenceSync = nil

Integration.Inline.part = nil
local closedReason
PsychopatzCore.Conversation.instance = {
    close = function(_, reason) closedReason = reason end,
}
local selectedEntry = {
    id = "hostile-selected",
    name = "Hostile Selected",
    x = 2,
    y = 0,
    z = 0,
}
T.truthy(Integration.OpenInlineForTarget(selectedEntry),
    "hostile conversation requests a nameplate handoff")
T.equal(Integration.Inline.pendingTargetEntry, selectedEntry,
    "handoff keeps the selected target entry")
T.equal(Integration.Inline.scope, "other",
    "hostile handoff selects the non-colonist nameplate scope")
T.equal(closedReason, "nameplate_fallback",
    "handoff closes the full conversation view")
PsychopatzCore.Conversation.instance = nil
Integration.Inline.pendingTargetEntry = nil
Integration.Inline.pendingFallbackReason = nil
Integration.Inline.pendingFallbackDeadline = nil
Integration.Inline.pendingFallbackNextAttemptAt = nil
Integration.CloseInline("test_cleanup")

-- Losing one nearby recipient must not close the compact input while the
-- selected/primary conversation remains healthy.
local lifecyclePart = {
    inputMode = "nearby",
    refreshControls = function() end,
    updateModeButtonStyles = function() end,
}
local lifecyclePrimary = { closed = false }
function lifecyclePrimary:updateLifecycle() return nil end
local lifecycleSecondary = { closed = false }
function lifecycleSecondary:updateLifecycle()
    self.closed = true
    return "npc_unavailable"
end
Integration.Inline.part = lifecyclePart
Integration.Inline.host = lifecyclePrimary
Integration.Inline.hosts = { lifecyclePrimary, lifecycleSecondary }
Integration.Inline.entries = {
    { id = "primary" },
    { id = "secondary" },
}
Integration.Inline.nextLifecycleAt = 0
Integration.Inline.nextContextRefreshAt = math.huge
Integration.Inline.nextControlsRefreshAt = math.huge
Integration.UpdateInline()
T.truthy(Integration.Inline.part,
    "secondary nearby recipient closed the compact input")
T.equal(#Integration.Inline.hosts, 1,
    "unavailable secondary recipient was not pruned")
T.equal(Integration.Inline.hosts[1], lifecyclePrimary,
    "primary nearby recipient was not preserved")
Integration.CloseInline("test_cleanup_lifecycle")

-- If the selected nearby recipient disappears, promote the first healthy
-- recipient instead of closing the compact input.
local promotedPart = {
    inputMode = "nearby",
    refreshControls = function() end,
    updateModeButtonStyles = function() end,
}
local failedPrimary = { closed = false }
function failedPrimary:updateLifecycle()
    self.closed = true
    return "npc_unavailable"
end
local promotedSecondary = { closed = false }
function promotedSecondary:updateLifecycle() return nil end
Integration.Inline.part = promotedPart
Integration.Inline.mode = "nearby"
Integration.Inline.host = failedPrimary
Integration.Inline.hosts = { failedPrimary, promotedSecondary }
Integration.Inline.entries = {
    { id = "primary" },
    { id = "secondary" },
}
Integration.Inline.nextLifecycleAt = 0
Integration.Inline.nextContextRefreshAt = math.huge
Integration.Inline.nextControlsRefreshAt = math.huge
Integration.UpdateInline()
T.truthy(Integration.Inline.part,
    "failed primary nearby recipient closed the compact input")
T.equal(Integration.Inline.host, promotedSecondary,
    "healthy nearby recipient was not promoted")
T.equal(Integration.Inline.targetID, "secondary",
    "promoted nearby recipient did not become the target")
Integration.CloseInline("test_cleanup_promoted_lifecycle")

-- When every nearby host briefly becomes unavailable, retain the panel and
-- retry the same mode instead of forcing the player to reopen it.
local recoveryPart = {
    inputMode = "nearby",
    refreshControls = function() end,
    updateModeButtonStyles = function() end,
}
failAllHosts = true
Integration.Inline.part = recoveryPart
Integration.Inline.mode = "nearby"
Integration.Inline.scope = "social"
Integration.Inline.targetID = firstTarget.id
Integration.Inline.host = nil
Integration.Inline.hosts = {}
Integration.Inline.entries = {}
Integration.Inline.nextLifecycleAt = 0
Integration.Inline.nextContextRefreshAt = math.huge
Integration.Inline.nextControlsRefreshAt = math.huge
Integration.UpdateInline()
T.truthy(Integration.Inline.part,
    "all unavailable nearby hosts closed the compact input")
T.equal(#Integration.Inline.hosts, 0,
    "unavailable nearby hosts were not held as stale hosts")
failAllHosts = false
Integration.Inline.nextLifecycleAt = 0
Integration.Inline.nextRecoveryAt = 0
Integration.UpdateInline()
T.equal(#Integration.Inline.hosts, 2,
    "compact input did not recover its nearby hosts")
T.equal(Integration.Inline.targetID, firstTarget.id,
    "recovered nearby hosts lost the selected target")
Integration.CloseInline("test_cleanup_recovery")

T.finish("pnc_hoomans_llm_highlight_smoke")
