-- Run from the repository root with lua tests/benchmarks/npc_replication.lua.
local T = require "tests/support/test"
T.addPackagePaths()

local records, players, byID, sent
local now, serial = 10000, 0
local mode = arg[2] or "legacy"
local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

PNC = {
    Core = {
        Now = function() return now end,
        GenerateID = function(prefix)
            serial = serial + 1
            return prefix .. "_fixture_" .. serial
        end,
        IsAuthority = function() return true end,
        DeepCopy = copy,
        ShallowCopy = function(value)
            local result = {}
            for key, child in pairs(value) do result[key] = child end
            return result
        end,
        LogWarn = function() end,
        Distance = function(x1, y1, x2, y2)
            return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
        end,
        ForEachPlayer = function(callback)
            for _, player in ipairs(players) do callback(player) end
        end,
    },
    Registry = {
        ForEach = function(callback)
            for _, record in ipairs(records) do callback(record) end
        end,
        Get = function(id) return byID[id] end,
    },
    SpatialIndex = {
        QueryNPCs = function(x, y, radius)
            local result = {}
            for _, record in ipairs(records) do
                if math.abs(record.x - x) <= radius
                    and math.abs(record.y - y) <= radius
                then
                    result[#result + 1] = record
                end
            end
            return result
        end,
    },
    Inventory = {
        BuildSummaryPayload = function() return { revision = 1, itemCount = 3 } end,
        BuildFullPayload = function() return { revision = 1, items = {}, containers = {} } end,
    },
}
isServer = function() return true end
sendServerCommand = function(player, _, command, payload)
    sent[#sent + 1] = { player = player, command = command, payload = payload }
end

require "PNC/Core/Base/PNC_Constants"
require "PNC/Core/Identity/PNC_Identity"
require "PNC/Core/Identity/PNC_Identity_Portrait"

-- Fixed resolved appearance represents the generator/native boundary. The
-- portrait normalizer, cache lookup, snapshots, routing and budget are real.
function PNC.Identity.GetCharacterSummary(record)
    return {
        identitySeed = record.identitySeed, displayName = record.name,
        archetypeID = "fixture", archetypeLabel = "Fixture",
        isFemale = record.isFemale, survivor = {},
    }
end

function PNC.Identity.RollAppearance(record)
    return record.runtime.appearanceCache
end

require "PNC/Core/Networking/PNC_Network"
require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerCharacterReplicationCommandHandler"

local network, const, router = PNC.Network, PNC.Const, PNC.ServerCommandRouter
local totals
local function count(name)
    totals[name] = (totals[name] or 0) + 1
end

local buildPortrait = PNC.Identity.BuildPortraitSummary
function PNC.Identity.BuildPortraitSummary(record)
    count("portraitLookups")
    local previous = record.runtime.portraitSummaryCache
    local result = buildPortrait(record)
    if previous == result then count("portraitHits") else count("portraitMisses") end
    if previous and previous ~= result then count("invalidations") end
    return result
end

for _, name in ipairs({ "BuildRosterSnapshot", "BuildSnapshot", "BuildPresenceDelta",
    "BuildCharacterPayload" }) do
    local original = assert(network[name], name)
    network[name] = function(...)
        count(name)
        return original(...)
    end
end

local projectPortrait = PNC.Identity.ProjectPortrait
if projectPortrait then
    function PNC.Identity.ProjectPortrait(record)
        count("resolvedProjections")
        return projectPortrait(record)
    end
end

local budget = network.PayloadBudget
local estimatePayload = budget.Estimate
local splitPayload = budget.Split
function budget.Estimate(...)
    count("budgetEstimates")
    return estimatePayload(...)
end
function budget.Split(...)
    count("budgetSplits")
    return splitPayload(...)
end

local function init(npcs, clients, density)
    records, players, byID, sent = {}, {}, {}, {}
    network.ResetServerState()
    network.ServerState.fullSyncSerial = 0
    budget.ChunkSerial = 0
    network.ServerState.inventoryRecipients = {}
    now, serial = const.ROSTER_DELTA_INTERVAL_MS, 0
    for i = 1, npcs do
        local x = density == "sparse" and (i > 5 and 1000 + i or i - 1)
            or (i - 1) % 30
        local record = {
            id = "npc_" .. i, name = "Fixture NPC " .. i, identitySeed = 2000 + i,
            isFemale = i % 2 == 0, x = x, y = 0, z = 0, alive = true,
            presenceState = const.PRESENCE_LIVE, presenceRevision = 1,
            tacticalClass = "colonist", ownerUsername = nil,
            inventory = { revision = 1 },
            health = { current = 100, max = 100, state = "normal" },
            equipment = {
                worn = { Shirt = "Fixture.Shirt", Hat = "Fixture.Hat" },
                wornVisuals = {
                    Shirt = { fullType = "Fixture.Shirt", textureChoice = i % 4,
                        hue = 0.135792468, tint = { r = 0.2, g = 0.5, b = 0.7, a = 1 } },
                },
            },
            runtime = { appearanceCache = { hairModel = "Short", skinTexture = "MaleBody01",
                hairColor = { r = 0.3, g = 0.4, b = 0.5 }, outfitItems = { "Fixture.Shirt" } } },
        }
        records[i], byID[record.id] = record, record
    end
    for i = 1, clients do
        players[i] = {
            getUsername = function() return "player_" .. i end,
            getOnlineID = function() return i end,
            getAccessLevel = function() return "" end,
            getX = function() return 0 end,
            getY = function() return 0 end,
            getZ = function() return 0 end,
        }
    end
end

local function join(player)
    local args = {}
    if mode ~= "legacy" then args.portraitProtocol = const.ROSTER_PORTRAIT_PROTOCOL end
    assert(router.Handle(const.CMD_FULL_SYNC_REQUEST, player, args))
end

local function refresh()
    now = now + const.INTEREST_REFRESH_MS
    network.RefreshInterestSets(now)
end

local function measure(name, npcs, clients, density, trial, workload)
    totals, sent = {}, {}
    local started = os.clock()
    workload()
    local elapsed = 1000 * (os.clock() - started)
    local estimate, portraitBytes, entries, maxBatch, detail = 0, 0, 0, 0, 0
    local refusal, chunks = 0, 0
    local recipients = {}
    local function inspect(snapshot)
        if not snapshot then return end
        if snapshot.portrait then
            portraitBytes = portraitBytes + estimatePayload(snapshot.portrait, math.huge)
        end
        if snapshot.interestDetailed == true then detail = detail + 1 end
    end
    local function inspectRows(rows, wrapped)
        entries = entries + #rows
        maxBatch = math.max(maxBatch, #rows)
        for _, row in ipairs(rows) do
            if wrapped then inspect(row.snapshot) else inspect(row) end
        end
    end
    for _, packet in ipairs(sent) do
        recipients[packet.player] = true
        local payload = packet.payload
        local bytes, sections = estimatePayload(payload, math.huge)
        assert(sections._omittedSections == nil, "incomplete payload estimate")
        estimate = estimate + bytes
        if payload.pncOversize then refusal = refusal + 1 end
        if payload.entries then inspectRows(payload.entries, true) end
        if payload.snapshots then inspectRows(payload.snapshots, false) end
        inspect(payload.snapshot)
        if payload.portrait then inspect(payload) end
        if payload.pncChunk then
            chunks = chunks + 1
            for _, part in ipairs(payload.pncChunk.parts) do
                if #part.path == 1 and part.path[1] == "entries" then
                    inspectRows(part.slice or part.value, true)
                end
                if #part.path == 1 and part.path[1] == "snapshots" then
                    inspectRows(part.slice or part.value, false)
                end
            end
        end
    end
    local recipientCount, occupants = 0, 0
    for _ in pairs(recipients) do recipientCount = recipientCount + 1 end
    for _, record in ipairs(records) do
        if record.runtime.portraitSummaryCache then occupants = occupants + 1 end
    end
    print(table.concat({
        npcs, clients, density, trial, name, string.format("%.3f", elapsed),
        #sent, recipientCount, entries, maxBatch, estimate, portraitBytes, detail,
        totals.BuildRosterSnapshot or 0, totals.BuildSnapshot or 0,
        totals.BuildPresenceDelta or 0, totals.BuildCharacterPayload or 0,
        totals.portraitLookups or 0, totals.portraitHits or 0, totals.portraitMisses or 0,
        totals.invalidations or 0, occupants, refusal, chunks,
        totals.budgetEstimates or 0, totals.budgetSplits or 0,
        totals.resolvedProjections or 0,
    }, ","))
    sent = {}
end

local function run(npcs, clients, density, trial)
    init(npcs, clients, density)
    local function sample(name, action) measure(name, npcs, clients, density, trial, action) end

    sample("cold_join_burst", function()
        for _, player in ipairs(players) do join(player) end
    end)
    init(npcs, clients, density)
    sample("cold_join", function() join(players[1]) end)
    sample("warm_join_burst", function()
        for _, player in ipairs(players) do join(player) end
    end)
    sample("interest_enter", refresh)
    sample("movement", function()
        now = now + const.ROSTER_DELTA_INTERVAL_MS
        for _, record in ipairs(records) do
            record.x = record.x + 1
            network.QueuePeriodicRoster(record, now)
            network.BroadcastRecord(record, "tick")
        end
        network.FlushRosterDeltas(now)
    end)
    if mode ~= "legacy" then
        sample("hover", function()
            local record = records[1]
            local ref = network.Internal.GetPortraitReference(record)
            for _, player in ipairs(players) do
                assert(router.Handle(const.CMD_REQUEST_ROSTER_PORTRAIT, player, {
                    id = record.id, incarnation = ref.incarnation, requestID = "hover",
                }))
            end
        end)
    end
    sample("inspect", function()
        for _, player in ipairs(players) do
            assert(router.Handle(const.CMD_REQUEST_CHARACTER, player, { id = records[1].id }))
        end
    end)
    sample("visible_change", function()
        local record = records[1]
        record.equipment.wornVisuals.Shirt.textureChoice = 7
        if network.RefreshPortraitEquipment then network.RefreshPortraitEquipment(record) end
        network.BroadcastRecord(record, "equipment")
        network.FlushRosterDeltas(now, true)
    end)
    sample("nonvisible_change", function()
        local record = records[1]
        record.inventory.revision = 2
        if network.RefreshPortraitEquipment then network.RefreshPortraitEquipment(record) end
        network.BroadcastRecord(record, "inventory")
        network.FlushRosterDeltas(now, true)
    end)
    sample("remove_rejoin", function()
        local removed = table.remove(records, 1)
        byID[removed.id] = nil
        network.BroadcastRemoval(removed.id, "fixture")
        network.FlushRosterDeltas(now, true)
        if network.ForgetPortraitRecord then network.ForgetPortraitRecord(removed) end
        removed.runtime = { appearanceCache = removed.runtime.appearanceCache }
        table.insert(records, 1, removed)
        byID[removed.id] = removed
        network.BroadcastRecord(removed, "fixture_rejoin")
        network.FlushRosterDeltas(now, true)
        refresh()
    end)
    sample("reconnect", function() join(players[1]); refresh() end)
end

print("npcs,clients,interest,trial,scenario,cpu_ms,sends,recipients,roster_rows,max_batch,estimated_bytes,portrait_estimated_bytes,detailed_snapshots,roster_builds,full_builds,presence_builds,character_builds,portrait_lookups,cache_hits,cache_misses,invalidations,cache_entries,refusals,chunks,budget_estimates,budget_splits,resolved_projections")
local trials = tonumber(arg[1]) or 3
for _, npcs in ipairs({ 100, 300, 600 }) do
    for _, clients in ipairs({ 1, 8, 16 }) do
        for _, density in ipairs({ "sparse", "dense" }) do
            for trial = 1, trials do run(npcs, clients, density, trial) end
        end
    end
end
