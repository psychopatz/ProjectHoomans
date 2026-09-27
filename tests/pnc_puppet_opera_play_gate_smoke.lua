local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

local status = "blocked"
local preflight = {
    ready = false,
    reason = "npc_in_vehicle:actor_1",
    actors = {
        actor_1 = {
            actorID = "actor_1",
            bindingID = "npc-felix",
            ready = false,
            reasonDetail = "npc_in_vehicle:actor_1",
        },
    },
}
local startCalls = 0

local Client = {
    GetStatus = function() return status, nil end,
    GetPreflight = function() return preflight end,
    Preflight = function() return true, "preflight_cached" end,
    Start = function()
        startCalls = startCalls + 1
        return true, "sent"
    end,
    Replay = function()
        startCalls = startCalls + 1
        return true, "sent"
    end,
}

local Model = {
    State = {},
    Internal = {
        State = {},
        Client = Client,
        LIVE_PLAYER_ID = "__local_player__",
    },
    SaveDraft = function() return true end,
    GetValidation = function() return true, nil, { id = "scene" } end,
    GetBlueprintID = function() return "scene" end,
    GetChangeSerial = function() return 1 end,
    GetRuntimeActorBindings = function()
        return { actor_1 = "npc-felix" }
    end,
    GetSnapshot = function() return nil end,
    GetActorRows = function()
        return {
            {
                id = "actor_1",
                label = "Actor 1",
                liveName = "Felix patz",
            },
        }
    end,
}

PNC = {
    PuppetOpera = { Client = Client },
    PuppetOperaDebugModel = Model,
    PuppetOperaDebugWindow = {
        Internal = {
            Model = Model,
            Client = Client,
            tr = function(_, fallback) return fallback end,
        },
    },
}
ISPNCPuppetOperaDebugWindow = {}

T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Runtime.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugWindow_Actions.lua"
)

local Class = ISPNCPuppetOperaDebugWindow
local function newWindow()
    local instance = setmetatable({
        loopEnabled = false,
        refreshViews = function() end,
    }, { __index = Class })
    return instance
end

local blocked = newWindow()
blocked:onControl({ internal = "play" })
T.equal(startCalls, 0,
    "blocked preflight still issued a start request")
T.contains(blocked.editorStatus, "preflight_blocked:Felix patz",
    "blocked preflight did not identify the live actor")
T.contains(blocked.editorStatus, "npc_in_vehicle:actor_1",
    "blocked preflight did not preserve the server reason")

status = "preflight"
local pending = newWindow()
pending:onControl({ internal = "play" })
T.equal(startCalls, 0,
    "pending preflight issued a start request")
T.equal(pending.editorStatus, "preflight_pending",
    "pending preflight did not remain visibly pending")

status = "blocked"
pending:syncPreflightStatus()
T.contains(pending.editorStatus, "preflight_blocked:Felix patz",
    "preflight reply did not update the pending editor status")

status = "ready"
preflight = { ready = true, actors = {} }
local ready = newWindow()
ready:onControl({ internal = "play" })
T.equal(startCalls, 1,
    "ready preflight did not issue the start request")

return T.finish("pnc_puppet_opera_play_gate_smoke")
