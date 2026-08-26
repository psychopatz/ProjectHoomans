local T = require "tests/support/test"

local SHARED_ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local CLIENT_ROOT = T.path("ProjectHoomans", "client", "")

local marker = {
    id = "dead_npc",
    name = "Dead NPC",
    x = 11,
    y = 21,
    z = 0,
    corpseToken = "corpse_token",
    createdWorldHour = 50,
    infected = false,
}
local markerRuntime = {
    corpseState = "inert_loaded",
    missingSinceAt = 0,
    reanimateAt = 0,
}
local liveRecord = {
    id = "living_npc",
    name = "Living NPC",
    tacticalClass = "neutral",
    presenceState = "abstract",
    alive = true,
    x = 1,
    y = 2,
    z = 0,
    runtime = {},
    health = { current = 100, max = 100, state = "normal" },
}

PNC = {
    Const = { PRESENCE_CORPSE = "corpse" },
    Core = {
        DeepCopy = function(value) return value end,
    },
    Registry = {
        ForEach = function(callback) callback(liveRecord) end,
        ForEachDeathMarker = function(callback) callback(marker) end,
        GetLiveZombie = function() return nil end,
        GetDeathMarkerRuntime = function() return markerRuntime end,
    },
    BodyLifecycle = {
        Internal = {
            registry = function() return PNC.Registry end,
            ensureRuntime = function()
                return {
                    phase = "abstract",
                    bodyState = "missing",
                    corpseState = "none",
                }
            end,
        },
    },
}

T.load(SHARED_ROOT
    .. "Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Diagnostics.lua")

local roster = PNC.BodyLifecycle.BuildDebugRoster()
T.equal(#roster, 2, "live and death-marker diagnostics share roster")
local dead = roster[1]
T.equal(dead.id, marker.id, "death marker roster identity")
T.equal(dead.deathMarker, true, "death marker diagnostic flag")
T.equal(dead.presenceState, "corpse", "death marker corpse filter state")
T.equal(dead.corpseToken, marker.corpseToken, "death marker token exposed")
T.equal(dead.createdWorldHour, 50, "death marker creation hour exposed")
T.equal(dead.corpseState, "inert_loaded", "death marker runtime exposed")

package.preload["PsychopatzCore/UI/PsychopatzUI"] = function() return true end
PsychopatzCore = { UI = {} }
getText = function(key) return key end
T.load(CLIENT_ROOT .. "PNC/UI/NPCMonitor/PNC_NPCMonitorSupport.lua")

T.equal(PNC.NPCMonitorSupport.MatchesFilter(dead, "Corpse"), true,
    "death marker visible in corpse filter")
local details = { items = {} }
function details:clear() self.items = {} end
function details:addItem(label, value)
    self.items[#self.items + 1] = { label = label, item = value }
end
PNC.NPCMonitorSupport.PopulateDetails(details, dead, true, {})
local values = {}
for _, entry in ipairs(details.items) do
    values[entry.item.label] = entry.item.value
end
T.equal(values.Metadata, "Lightweight death marker",
    "monitor identifies compact metadata")
T.equal(values["Corpse token"], marker.corpseToken,
    "monitor displays corpse token")
T.equal(values.Infected, "No", "monitor displays infection state")
T.finish("pnc_npc_monitor_death_marker_smoke")

T.finish("pnc_npc_monitor_death_marker_smoke")
