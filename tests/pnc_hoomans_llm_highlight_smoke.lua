local T = require "tests/support/test"
T.addPackagePaths()

local LLMInput = {}
local keyDown = true
local keybinds = {
    TYPE_LONG_PRESS = "longpress",
    RegisterLongPress = function() end,
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
    CompanionTargetResolver = {},
}
UIFont = { Small = "Small", Medium = "Medium" }

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

T.finish("pnc_hoomans_llm_highlight_smoke")
