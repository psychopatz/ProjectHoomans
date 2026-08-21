local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "client" } })

local requests = {}
local opened
PNC = {
    Const = { SCAVENGE_DEFAULT_RADIUS = 12 },
    Client = { SendScavengeRequest = function(action, payload)
        requests[#requests + 1] = { action = action, payload = payload }
        return true, "request_sent"
    end },
    ScavengeUI = { OpenSetup = function(npcId, context)
        opened = { npcId = npcId, context = context }
        return true
    end },
}

local Controller = T.load("ProjectHoomans", "client",
    "PNC/Scavenge/PNC_ScavengeController.lua")

Controller.SetAssigned("bob", true)
Controller.SetAssigned("sue", true)
T.truthy(Controller.IsAssigned("bob"), "controller owns party assignment")
T.equal(#Controller.TeamIDs(), 2, "controller exposes shared party")

local ok = Controller.StartSearch({
    npcId = "bob",
    sourcePolicy = { containers = true },
})
T.truthy(ok, "dedicated UI pipeline starts search")
T.equal(requests[1].action, "start_search", "start action routed once")
T.equal(#requests[1].payload.npcIds, 2, "start uses shared assigned party")

Controller.StopSearch({ sessionId = "session:1", npcId = "bob" })
T.equal(requests[2].action, "cancel_search", "search toggle routes stop action")
T.equal(requests[2].payload.sessionId, "session:1", "stop targets active run")

T.truthy(Controller.Open("bob", { name = "Bob" }),
    "context and colony triggers share open pipeline")
T.equal(opened.npcId, "bob", "open preserves selected NPC")
T.equal(#opened.context.npcIds, 2, "open presents shared party")

Controller.ReceiveSnapshot({ npcIds = { "sue" }, runActive = true,
    state = "DISCOVERING" })
T.falsy(Controller.IsAssigned("bob"), "authoritative snapshot replaces party")
T.truthy(Controller.IsAssigned("sue"), "snapshot party retained")
T.truthy(Controller.IsSearchActive({ runActive = true,
    state = "DISCOVERING" }), "active snapshot drives toggle feedback")
T.falsy(Controller.IsSearchActive({ runActive = false,
    state = "CANCELLED" }), "stopped snapshot clears toggle feedback")

local windowSource = T.read("ProjectHoomans", "client",
    "PNC/UI/Scavenge/PNC_ScavengeWindow.lua")
T.contains(windowSource, "UI.CreateToggleButton",
    "dedicated UI exposes start/stop visual state")
T.contains(windowSource, "Controller.StopSearch",
    "dedicated UI owns the stop-search command")
T.contains(windowSource, "ISPNCScavengeSection",
    "manifest and activity lists are isolated in responsive sections")
T.contains(windowSource, "entry.npcName",
    "activity log identifies the scavenger who performed each action")
T.contains(windowSource, "UI_PNC_Scavenge_LogCollected",
    "activity log describes successful pickups")
T.contains(windowSource, "snapshot.scavengeDebug",
    "live debug view renders authority-side worker and source state")
T.contains(windowSource, "ScavengeWindow:v2",
    "rescaled window discards incompatible oversized saved geometry")

T.finish("pnc_scavenge_controller_smoke")
