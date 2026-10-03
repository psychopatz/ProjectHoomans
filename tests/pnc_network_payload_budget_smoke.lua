--[[
    Payload budget guard.

    The engine serializes a server command into a fixed per-connection packet
    buffer and throws BufferOverflowException before sending when the payload is
    too large. These assertions pin the three contracts that keep that failure
    visible instead of silent:

    1. an oversized mod payload is never handed to the engine,
    2. direct `sendServerCommand` callers in the mod are covered too,
    3. the client reports a sync failure and never treats the envelope as data.
]]

local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

-- ---------------------------------------------------------------------------
-- Server side: the payload budget guard
-- ---------------------------------------------------------------------------

local sent = {}
local warned = {}

PNC = {
    Const = {
        MODULE = "PNC",
        CMD_COLONY_MANAGEMENT = "ColonyManagement",
        NETWORK_PAYLOAD_BUDGET_BYTES = 1024,
        NETWORK_PAYLOAD_ENVELOPE = "pncOversize",
        NETWORK_PAYLOAD_CHUNK = "pncChunk",
    },
    Network = { Internal = {} },
    Core = {
        Now = function() return 1000 end,
        LogWarn = function(message) warned[#warned + 1] = message end,
    },
}

isServer = function() return true end

sendServerCommand = function(...)
    sent[#sent + 1] = { ... }
end

local Budget = T.load("ProjectHoomans", "shared",
    "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Budget.lua")

local Internal = PNC.Network.Internal

T.truthy(Budget, "payload budget module loaded")
T.equal(Budget.GetBudgetBytes(), 1024, "configured budget honored")
T.equal(Internal.SendGuardInstalled, true, "engine send guard installed")
T.equal(type(Internal.RawSendServerCommand), "function",
    "raw engine sender captured")

local function lastSent()
    return sent[#sent]
end

local small = { snapshot = { people = { { id = "a", name = "A" } } } }
T.equal(Internal.SendGuarded({}, "PNC", "ColonyManagement", small), true,
    "small payload accepted")
T.equal(lastSent()[4], small, "accepted payload identity preserved")
T.equal(lastSent()[3], "ColonyManagement", "accepted command preserved")

-- The global safety net covers mod files that call the engine binding directly.
local directCount = #sent
sendServerCommand({}, "PNC", "SomeOtherCommand", small)
T.equal(#sent, directCount + 1, "direct engine call covered by the guard")
T.equal(lastSent()[4], small, "direct small payload passes through")

-- The engine serializer skips unsupported values instead of throwing, so the
-- budget must not turn them into a refusal.
T.equal(Internal.SendGuarded({}, "PNC", "NoArgs", nil), true,
    "nil payload is not a size problem")
T.equal(lastSent()[4], nil, "nil payload still forwarded")
T.equal(Internal.SendGuarded({}, "PNC", "Mixed", {
    snapshot = { ok = true, callback = function() return 1 end },
}), true, "unsavable values are left to the engine")
T.equal(Budget.Estimate(nil, 1024) <= 1024, true, "nil measures under budget")

-- A payload close to the budget must still be delivered: the guard exists to
-- stop the engine exception, not to shrink the protocol.
local nearBudget = { blob = string.rep("y", 800) }
T.truthy(Budget.Estimate(nearBudget, 1024) <= 1024,
    "near-budget payload measured under the limit")
T.equal(Internal.SendGuarded({}, "PNC", "ColonyManagement", nearBudget), true,
    "payload under the budget is still sent")
T.equal(lastSent()[4], nearBudget, "near-budget payload identity preserved")

local overBudget = { blob = string.rep("y", 1200) }
T.equal(Internal.SendGuarded({}, "PNC", "ColonyManagement", overBudget), false,
    "payload over the budget is refused")

-- A realistic oversized colony projection.
local big = { snapshot = { rows = {} } }
for index = 1, 200 do
    big.snapshot.rows[index] = {
        name = string.rep("x", 40),
        quantity = index,
    }
end

local ok, reason, bytes, limit =
    Internal.SendGuarded({}, "PNC", "ColonyManagement", big)
T.equal(ok, false, "oversized payload refused")
T.equal(reason, "payload_too_large", "refusal reason")
T.truthy(bytes > limit, "estimate exceeds the budget")

local envelope = lastSent()[4]
T.truthy(envelope ~= big, "oversized payload replaced")
T.equal(envelope.pncOversize, true, "oversize envelope marker")
T.equal(envelope.estimatedBytes, bytes, "envelope reports the estimate")
T.equal(envelope.budgetBytes, limit, "envelope reports the budget")
T.truthy(type(envelope.sections) == "table", "section attribution present")
T.truthy(warned[#warned] ~= nil, "refusal is always logged")
T.contains(warned[#warned], "network_payload event=rejected",
    "refusal log marker")

for _, call in ipairs(sent) do
    T.truthy(call[4] ~= big, "oversized payload never reached the engine")
end

-- Other modules share the UDP buffer budget with the engine, but this mod must
-- not silently drop third-party traffic it does not own.
local foreignCount = #sent
sendServerCommand({}, "SomeOtherMod", "Whatever", big)
T.equal(#sent, foreignCount + 1, "foreign module payload still sent")
T.equal(lastSent()[4], big, "foreign module payload untouched")

-- An action response must resolve explicitly instead of appearing to hang.
local action = {
    action = "base_expand",
    requestId = "request-1",
    settlement = big.snapshot,
}
Internal.SendGuarded({}, "PNC", "ColonyManagementAction", action)
local actionEnvelope = lastSent()[4]
T.equal(actionEnvelope.actionResult.ok, false, "action marked failed")
T.equal(actionEnvelope.actionResult.reason, "payload_too_large",
    "action failure reason")
T.equal(actionEnvelope.requestId, "request-1", "request id preserved")

-- Broadcast form: no target means the refusal cannot be reported, but the
-- doomed engine write must still not happen.
local broadcastCount = #sent
sendServerCommand("PNC", "Broadcast", big)
T.equal(#sent, broadcastCount, "oversize broadcast refused without a target")
sendServerCommand("PNC", "Broadcast", small)
T.equal(lastSent()[1], "PNC", "broadcast form forwarded")
T.equal(lastSent()[3], small, "broadcast payload identity preserved")

-- Pathological shapes must be refused rather than reaching the native writer.
local deep = {}
local cursor = deep
for _ = 1, 48 do
    cursor.child = {}
    cursor = cursor.child
end
T.truthy(Budget.Estimate(deep, 1024) > 1024, "pathologically nested payload refused")

local huge = { rows = {} }
for index = 1, 20000 do
    huge.rows[index] = { name = "stack-" .. tostring(index), quantity = index }
end
local startedAt = os.clock()
T.truthy(Budget.Estimate(huge, 1024) > 1024, "huge payload over budget")
T.truthy(os.clock() - startedAt < 1, "estimate stays bounded for huge payloads")

-- ---------------------------------------------------------------------------
-- Client side: the envelope never reaches a command handler
-- ---------------------------------------------------------------------------

local handled = 0
local lastHandled

PNC.Network.ClientState = {}

local Registry = T.load("ProjectHoomans", "client",
    "PNC/Networking/ClientCommandRouter/PNC_ClientCommandRouter_Registry.lua")

Registry.Internal.RegisterServerCommand("ColonyManagement", function(args)
    handled = handled + 1
    lastHandled = args
end)

Registry.HandleServerCommand("ColonyManagement", { snapshot = { people = {} } })
T.equal(handled, 1, "normal payload dispatched")
T.truthy(lastHandled ~= nil, "handler received the payload")
T.equal(Registry.GetPayloadSync("ColonyManagement", nil), nil,
    "healthy delivery records no failure")

Registry.HandleServerCommand("ColonyManagement", {
    pncOversize = true,
    estimatedBytes = 2048,
    budgetBytes = 1024,
    sections = { snapshot = 2048 },
})
T.equal(handled, 1, "envelope not dispatched to the command handler")
local status = Registry.GetPayloadSync("ColonyManagement", nil)
T.equal(status.state, "unavailable", "refusal surfaced as unavailable")
T.equal(status.reason, "payload_too_large", "refusal reason recorded")
T.equal(status.estimatedBytes, 2048, "refusal estimate recorded")

Registry.HandleServerCommand("ColonyManagement", { snapshot = {} })
T.equal(handled, 2, "recovery dispatched after a refusal")
T.equal(Registry.GetPayloadSync("ColonyManagement", nil), nil,
    "recovery clears the failure")

Registry.HandleServerCommand("ColonyManagement", {
    pncOversize = true, scope = "base",
})
T.equal(Registry.GetPayloadSync("ColonyManagement", "base").state,
    "unavailable", "base scope failure recorded")
T.equal(Registry.GetPayloadSync("ColonyManagement", nil), nil,
    "base failure does not mark the full snapshot")
Registry.HandleServerCommand("ColonyManagement", { snapshot = {} })
T.equal(Registry.GetPayloadSync("ColonyManagement", "base").state,
    "unavailable", "full snapshot success leaves the base failure intact")
Registry.HandleServerCommand("ColonyManagement", { snapshot = {}, scope = "base" })
T.equal(Registry.GetPayloadSync("ColonyManagement", "base"), nil,
    "base snapshot success clears the base failure")

-- ---------------------------------------------------------------------------
-- Client snapshot contract and the colonist empty state
-- ---------------------------------------------------------------------------

local ColonyClient = T.load("ProjectHoomans", "client",
    "PNC/Networking/PNC_ColonyManagementClient.lua")

PNC.Network.ClientState.colonyManagement = nil
Registry.HandleServerCommand("ColonyManagement", { pncOversize = true })
T.equal(ColonyClient.ReadSnapshot().snapshot.syncStatus.state, "unavailable",
    "reader surfaces the refused snapshot")
T.equal(ColonyClient.ReadBaseSnapshot().snapshot.syncStatus.state, "ready",
    "unrelated scope still reports ready")

Registry.HandleServerCommand("ColonyManagement", { snapshot = { people = {} } })
T.equal(ColonyClient.ReadSnapshot().snapshot.syncStatus.state, "ready",
    "reader reports ready after a successful delivery")

package.preload["PNC/UI/Shared/PNC_ColonyUIShared"] = function()
    return {
        Tr = function(_, fallback) return fallback end,
        Text = function(value, fallback)
            local text = value ~= nil and tostring(value) or ""
            return text ~= "" and text or tostring(fallback or "")
        end,
        NEED_TYPES = {},
    }
end
package.preload["PNC/UI/Communities/PNC_ColonistJournalPresentation"] = function()
    return {}
end

local Presentation = T.load("ProjectHoomans", "client",
    "PNC/UI/Communities/PNC_ColonyPresentation.lua")

local syncRows = Presentation.BuildNeeds(nil, {
    syncStatus = { state = "unavailable", reason = "payload_too_large" },
})
T.equal(#syncRows, 1, "one sync failure row")
T.contains(syncRows[1].label, "SYNCED", "sync failure message is explicit")

local emptyRows = Presentation.BuildNeeds(nil, { syncStatus = { state = "ready" } })
T.contains(emptyRows[1].label, "NO COMPANIONS",
    "a genuinely empty colony keeps its own message")

-- ---------------------------------------------------------------------------
-- Cross-boundary round trip: a payload too large for one packet is split by
-- the server, rebuilt exactly by the client, and dispatched exactly once.
-- ---------------------------------------------------------------------------

local rebuilds = 0
local rebuilt

Registry.Internal.RegisterServerCommand("ChunkedProbe", function(args)
    rebuilds = rebuilds + 1
    rebuilt = args
end)

local bigPayload = {
    snapshot = { rows = {}, colony = { id = "c1", revision = 4 } },
    reason = "roster_refresh",
}
for index = 1, 240 do
    bigPayload.snapshot.rows[index] = {
        name = "row-" .. tostring(index),
        quantity = index,
        blob = string.rep("z", 24),
    }
end

local sentBefore = #sent
T.equal(Internal.SendChunked({}, "PNC", "ChunkedProbe", bigPayload), true,
    "payload larger than one packet is chunked")
local chunks = {}
for index = sentBefore + 1, #sent do
    chunks[#chunks + 1] = sent[index][4]
end
T.truthy(#chunks > 1, "payload was split across several packets")
for index = 1, #chunks do
    T.truthy(type(chunks[index] and chunks[index].pncChunk) == "table",
        "chunk envelope marker on packet " .. tostring(index))
end
T.equal(rebuilds, 0, "nothing is dispatched before the payload is complete")
for index = 1, #chunks - 1 do
    Registry.HandleServerCommand("ChunkedProbe", chunks[index])
end
T.equal(rebuilds, 0, "an incomplete chunk set is not dispatched")
Registry.HandleServerCommand("ChunkedProbe", chunks[#chunks])
T.equal(rebuilds, 1, "the completed chunk set dispatches exactly once")
T.equal(#rebuilt.snapshot.rows, 240, "every array element survived the split")
T.equal(rebuilt.snapshot.rows[1].name, "row-1", "first element order preserved")
T.equal(rebuilt.snapshot.rows[240].quantity, 240, "last element preserved")
T.equal(rebuilt.snapshot.colony.id, "c1", "hash keys survive chunking")
T.equal(rebuilt.reason, "roster_refresh", "scalar siblings survive chunking")

-- A duplicated packet must not double-append an array slice.
Registry.HandleServerCommand("ChunkedProbe", chunks[1])
T.equal(rebuilds, 1, "a repeated packet starts a new pending payload")

-- Nothing further is dispatched, so the client holds no stale state.
T.equal(Registry.GetPayloadSync("ChunkedProbe", nil), nil,
    "chunked delivery records no sync failure")

-- Splitting measures every part, so it must not inherit the much smaller node
-- allowance used to short-circuit a refusal. A node-heavy payload that exhausts
-- the refusal estimate must still split into correctly sized parts.
local wide = { rows = {} }
for index = 1, 2500 do
    local row = {}
    for field = 1, 150 do row[field] = field end
    wide.rows[index] = row
end
local wideLimit = 200000
local wideEntries, wideReason = Budget.Split(wide, wideLimit)
T.truthy(type(wideEntries) == "table",
    "node-heavy payload still splits: " .. tostring(wideReason))
T.truthy(#wideEntries > 1, "node-heavy payload produced several parts")
local partBudget = math.floor(wideLimit * 0.7)
for index = 1, #wideEntries do
    T.truthy(wideEntries[index].bytes <= partBudget,
        "part " .. tostring(index) .. " fits the transport budget")
end

-- A single element larger than the budget cannot be split, so it is refused
-- rather than written as a doomed packet.
local unsplittable = { blob = { string.rep("q", 4000) } }
sentBefore = #sent
T.equal(Internal.SendChunked({}, "PNC", "ChunkedProbe", unsplittable), false,
    "unsplittable payload is refused")
local refusal = sent[#sent][4]
T.equal(refusal.pncOversize, true, "refusal still reports the oversize envelope")
T.equal(sent[#sent][3], "ChunkedProbe", "refusal is reported on the same command")

T.finish("pnc_network_payload_budget_smoke")
