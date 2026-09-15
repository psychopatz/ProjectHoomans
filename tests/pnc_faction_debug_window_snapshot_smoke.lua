local T = require "tests/support/test"

local ROOT =
    T.path("ProjectHoomans", "client", "PNC/")
local CONTROLS = ROOT
    .. "UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_Controls.lua"
local SNAPSHOT = ROOT
    .. "UI/Factions/FactionDebugWindow/PNC_FactionDebugWindow_Snapshot.lua"

local model = {
    BuildMobilePoolCounts = function()
        return {
            all = 5,
            staging = 1,
            player_colony = 2,
            ai_settlement = 1,
            street_roaming = 1,
        }
    end,
    MobileFilterCount = function(counts, filter)
        return counts[filter] or 0
    end,
    MobileFilterLabel = function(filter)
        return filter
    end,
}

PNC = {
    FactionDebugUI = {
        Internal = {
            Model = model,
            ClientState = {},
            UI = {
                SetButtonVariant = function(button, variant)
                    button.variant = variant
                end,
            },
            Text = function(key) return key end,
        },
    },
}
ISPNCFactionDebugWindow = {}

T.load(CONTROLS)
T.load(SNAPSHOT)

local window = {
    controls = {},
    mobileFilter = "player_colony",
}
for index in ipairs(PNC.FactionDebugUI.Internal.Controls) do
    window.controls[index] = {
        setTitle = function(button, title)
            button.title = title
        end,
    }
end

ISPNCFactionDebugWindow.refreshMobileFilterControls(
    window,
    {}
)

local controls = PNC.FactionDebugUI.Internal.Controls
local map = PNC.FactionDebugUI.Internal.MobileFilterControlMap
local function buttonFor(filter)
    for index, definition in ipairs(controls) do
        if map[definition.id] == filter then
            return window.controls[index]
        end
    end
    return nil
end

T.equal(buttonFor("all").title, "all (5)",
    "all mobile filter refreshes its count")
T.equal(buttonFor("player_colony").title, "player_colony (2)",
    "player mobile filter refreshes its count")
T.equal(buttonFor("player_colony").variant, "selected",
    "active mobile filter receives selected styling")
T.equal(buttonFor("ai_settlement").variant, "quiet",
    "inactive mobile filter receives quiet styling")

T.finish("pnc_faction_debug_window_snapshot_smoke")
