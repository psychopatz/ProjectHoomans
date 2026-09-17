local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "client" },
})

PsychopatzCore = {
    RuntimeRole = { AllowsClientCode = function() return true end },
    Core = { Now = function() return 123 end },
}
PNC = { PerceptionDebug = {} }

local Diagnostics = T.load("ProjectHoomans", "client",
    "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_CampDiagnostics.lua")

local runtimeHint = {
    source = "client_loaded_rooms",
    scope = "room",
    label = "bedroom",
    siteID = "room:1",
    x = 1,
    y = 2,
    z = 0,
    runtimeObject = function() end,
}

Diagnostics.RecordClient("PENDING", "network_queued", {
    commandID = "camp",
    npcID = "npc:1",
    scope = "here",
    requestID = "request:1",
}, runtimeHint)
Diagnostics.RecordServer({
    commandID = "camp",
    id = "npc:1",
    scope = "here",
    requestID = "request:1",
    accepted = false,
    reason = "camp_room_hint_stale",
    siteScope = "room",
    siteID = "room:1",
    siteLabel = "bedroom",
})

local snapshot = Diagnostics.Get()
T.equal(snapshot.client.status, "PENDING",
    "client camp transport state is retained")
T.equal(snapshot.client.reason, "network_queued",
    "client camp transport reason is retained")
T.equal(snapshot.server.status, "REJECTED",
    "authoritative camp rejection is retained")
T.equal(snapshot.server.reason, "camp_room_hint_stale",
    "authoritative camp rejection reason is retained")
T.equal(snapshot.last.stage, "server",
    "the latest camp result is the authoritative result")
T.equal(snapshot.client.hint.runtimeObject, nil,
    "camp diagnostics copy only primitive hint data")
T.equal(snapshot.server.hint.source, "server_authoritative_site",
    "server camp metadata becomes an inspectable primitive hint")
T.equal(snapshot.server.hint.label, "bedroom",
    "server camp metadata preserves the authoritative zone label")

local Model = T.load("ProjectHoomans", "client",
    "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_Model.lua")
local rows = Model.CampPreviewRows({
    campPreview = {
        policy = "room then campfire",
        status = "SAFE",
        source = "client_loaded_rooms",
        scope = "room",
        label = "bedroom",
        roomType = "bedroom",
        siteID = "room:1",
    },
    diagnostics = { campCommand = snapshot },
})
local rowText = {}
for index = 1, #rows do
    rowText[#rowText + 1] = tostring(rows[index].label or "")
        .. "=" .. tostring(rows[index].value or "")
end
rowText = table.concat(rowText, "\n")
T.contains(rowText, "REJECTED",
    "camp preview rows expose the server result to the debug hub")
T.contains(rowText, "bedroom",
    "camp preview rows expose the resolved room label")

local scanCalls = 0
PNC.Perception = {
    WorldObjects = {
        DEFAULT_RADIUS = 32,
        MAX_OBJECTS = 256,
        ClearSnapshotCache = function() scanCalls = scanCalls + 1 end,
        GetSnapshot = function()
            return {
                status = "READY",
                objects = {},
                zones = {},
                campPreview = {
                    status = "SAFE",
                    scope = "room",
                    label = "bedroom",
                },
            }
        end,
    },
}
local Provider = T.load("ProjectHoomans", "client",
    "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_CoreProvider.lua")
local refreshed = Provider.RefreshSnapshot()
T.equal(scanCalls, 1,
    "the Core provider refreshes the local observer only explicitly")
T.equal(refreshed.diagnostics.campCommand.server.reason,
    "camp_room_hint_stale",
    "the Core provider attaches event diagnostics to the frozen snapshot")

Diagnostics.Clear()
local cleared = Diagnostics.Get()
T.equal(cleared.client, nil, "clearing diagnostics removes client state")
T.equal(cleared.server, nil, "clearing diagnostics removes server state")
T.equal(cleared.last, nil, "clearing diagnostics removes the latest state")

T.finish("pnc_perception_debug_camp_diagnostics_smoke")
