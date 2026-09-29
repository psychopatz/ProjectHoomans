local Internal = PNC.Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

local function journalRowSequence(row)
    return type(row) == "table" and tonumber(row[1]) or nil
end

local function applyColonyJournal(delta)
    delta = type(delta) == "table" and delta or {}
    local journal = ClientState.colonyJournal or {}
    journal.rows = journal.rows or {}
    journal.rowSequences = journal.rowSequences or {}
    local incoming = type(delta.rows) == "table" and delta.rows or {}
    local currentCursor = tonumber(journal.cursor) or 0
    local afterCursor = tonumber(delta.afterCursor)
    local sequence
    local changed = delta.reset == true
    if afterCursor ~= nil and not delta.reset and afterCursor < currentCursor then
        return
    end
    if delta.reset == true then
        journal.rows = {}
        journal.rowSequences = {}
    else
        for index = 1, #journal.rows do
            sequence = journalRowSequence(journal.rows[index])
            if sequence ~= nil then journal.rowSequences[sequence] = true end
        end
    end
    -- The server sends each batch in chronological order. Prepending each
    -- row in that order leaves the newest row at index one without sorting or
    -- copying the entire bounded history on every poll.
    for index = 1, #incoming do
        sequence = journalRowSequence(incoming[index])
        if sequence == nil or not journal.rowSequences[sequence] then
            table.insert(journal.rows, 1, incoming[index])
            if sequence ~= nil then journal.rowSequences[sequence] = true end
            changed = true
        end
    end
    local maxRows = 128
    while #journal.rows > maxRows do table.remove(journal.rows) end
    journal.rowSequences = {}
    for index = 1, #journal.rows do
        sequence = journalRowSequence(journal.rows[index])
        if sequence ~= nil then journal.rowSequences[sequence] = true end
    end
    local cursor = tonumber(delta.nextCursor) or currentCursor
    if not delta.reset then cursor = math.max(cursor, currentCursor) end
    local latestSequence = math.max(
        tonumber(journal.latestSequence) or 0,
        tonumber(delta.latestSequence) or 0
    )
    if cursor ~= (tonumber(journal.cursor) or 0)
        or latestSequence ~= (tonumber(journal.latestSequence) or 0)
        or delta.error ~= journal.error
    then
        changed = true
    end
    journal.cursor = cursor
    journal.latestSequence = latestSequence
    journal.reset = delta.reset == true
    journal.error = delta.error
    journal.more = delta.more == true
    journal.lastSyncAt = Core.Now()
    ClientState.colonyJournal = journal
    if changed then
        ClientState.colonyJournalRevision =
            (tonumber(ClientState.colonyJournalRevision) or 0) + 1
    end
    ClientState.lastColonyJournalReceiveAt = Core.Now()
end

Internal.ApplyColonyJournal = applyColonyJournal

Internal.RegisterServerCommand(Const.CMD_COLONY_JOURNAL, function(args)
    applyColonyJournal(args and args.delta or {})
end)

--[[
    A sectioned response carries only the projection groups the caller asked
    for, so it is merged into whatever the client already holds. Omitting a key
    therefore preserves the previous value instead of clearing it. A response
    built without sections replaces the snapshot, as before.
]]
--[[
    Construction feedback.

    facility_create and building_queue results reach the client already, but
    nothing read them: the request is fire-and-forget, the selector and the
    placement cursor close before the server answers, and a rejected build
    therefore looked exactly like a successful one. Report the verdict once per
    request so a failure is always visible.
]]
local BUILD_RESULT_ACTIONS = {
    facility_create = true,
    facility_component_set = true,
    building_queue = true,
}

-- The same verdict is often delivered twice: once with the management
-- snapshot and again on the settlement delta that follows it. Remember the
-- last few request ids so a failure is reported exactly once.
local reportedRequestIds = {}
local reportedRequestOrder = {}
local REPORTED_REQUEST_LIMIT = 8

local function alreadyReported(requestId)
    if not requestId then return false end
    if reportedRequestIds[requestId] then return true end
    reportedRequestIds[requestId] = true
    reportedRequestOrder[#reportedRequestOrder + 1] = requestId
    while #reportedRequestOrder > REPORTED_REQUEST_LIMIT do
        local oldest = table.remove(reportedRequestOrder, 1)
        reportedRequestIds[oldest] = nil
    end
    return false
end

local function notifyBuildResult(result)
    if type(result) ~= "table" then return end
    local action = tostring(result.action or "")
    if not BUILD_RESULT_ACTIONS[action] then return end
    local requestId = result.requestId and tostring(result.requestId) or nil
    if alreadyReported(requestId) then return end
    local BuildAudit = require "PNC/Core/Diagnostics/PNC_BuildAudit"
    BuildAudit.TracePlacement("pnc_build_result", {
        "action=" .. action,
        "ok=" .. tostring(result.ok == true),
        "reason=" .. tostring(result.reason),
        BuildAudit.RequestField(requestId),
    })
    if BuildAudit.Enabled() then
        BuildAudit.Log("result", {
            BuildAudit.RequestField(requestId),
            "action=" .. action,
            "ok=" .. tostring(result.ok == true),
            "reason=" .. tostring(result.reason),
            BuildAudit.ElapsedField(requestId, "rtt_ms"),
        })
    end
    local Shared = require "PNC/UI/Shared/PNC_ColonyUIShared"
    if result.ok == false then
        Shared.NotifyBuildFailure(result.reason)
        return
    end
    if action == "building_queue" then Shared.NotifyBuildQueued() end
end

Internal.NotifyBuildResult = notifyBuildResult

local function applySnapshot(scopeKey, incoming, sectioned)
    local current = ClientState[scopeKey]
    if sectioned == true and type(current) == "table"
        and type(incoming) == "table"
    then
        for key, value in pairs(incoming) do current[key] = value end
        return current
    end
    return incoming
end

Internal.RegisterServerCommand(Const.CMD_COLONY_MANAGEMENT, function(args)
    args = type(args) == "table" and args or {}
    notifyBuildResult(args.snapshot and args.snapshot.actionResult)
    if args.scope == "base" then
        ClientState.colonyBase = applySnapshot(
            "colonyBase", args.snapshot, args.sectioned)
        ClientState.colonyBaseRevision =
            (tonumber(ClientState.colonyBaseRevision) or 0) + 1
        ClientState.lastColonyBaseReceiveAt = Core.Now()
        return
    end
    ClientState.colonyManagement = applySnapshot(
        "colonyManagement", args.snapshot, args.sectioned)
    ClientState.colonyManagementRevision =
        (tonumber(ClientState.colonyManagementRevision) or 0) + 1
    ClientState.lastColonyManagementReceiveAt = Core.Now()
    if args.snapshot and args.snapshot.actionResult
        and (args.snapshot.actionResult.action == "storage_player_deposit"
            or args.snapshot.actionResult.action == "storage_player_withdraw"
            or args.snapshot.actionResult.action == "storage_npc_deposit"
            or args.snapshot.actionResult.action == "storage_npc_deposit_all")
        and PNC.InventoryWindow
        and PNC.InventoryWindow.OnColonyStorageResult
    then
        PNC.InventoryWindow.OnColonyStorageResult(args.snapshot.actionResult)
    end
    if PNC.ColonyNamePrompt and PNC.ColonyNamePrompt.OpenIfNeeded then
        PNC.ColonyNamePrompt.OpenIfNeeded(args.snapshot)
    end
end)

Internal.RegisterServerCommand(Const.CMD_SETTLEMENT_DELTA, function(args)
    args = type(args) == "table" and args or {}
    notifyBuildResult(args.actionResult)
    local baseSnapshot = ClientState.colonyBase
    if type(baseSnapshot) == "table" then
        baseSnapshot.settlement = args.settlement
        baseSnapshot.actionResult = args.actionResult
        ClientState.colonyBaseRevision =
            (tonumber(ClientState.colonyBaseRevision) or 0) + 1
        ClientState.lastColonyBaseReceiveAt = Core.Now()
    end
    local snapshot = ClientState.colonyManagement
    if type(snapshot) == "table" then
        snapshot.settlement = args.settlement
        if args.storage then snapshot.storage = args.storage end
        snapshot.actionResult = args.actionResult
        ClientState.colonyManagementRevision =
            (tonumber(ClientState.colonyManagementRevision) or 0) + 1
        ClientState.lastColonyManagementReceiveAt = Core.Now()
    end
end)

Internal.RegisterServerCommand(Const.CMD_COLONY_KNOWLEDGE_DELTA, function(args)
    local delta = args and args.delta or nil
    local snapshot = ClientState.colonyManagement
    local research = snapshot and snapshot.research
    if not delta or not research or not snapshot.colony
        or tostring(snapshot.colony.id or "") ~= tostring(delta.colonyId or "")
    then return end
    local current = tonumber(research.knowledgeRevision) or 0
    if tonumber(delta.revision) ~= current + 1 then
        if PNC.Client and PNC.Client.RequestColonyManagement then
            PNC.Client.RequestColonyManagement()
        end
        return
    end
    research.knowledgeRevision = delta.revision
    if delta.recipeId then
        research.learnedRecipeIds = research.learnedRecipeIds or {}
        research.learnedRecipeIds[#research.learnedRecipeIds + 1] = delta.recipeId
        table.sort(research.learnedRecipeIds)
        snapshot.workshop = snapshot.workshop or {}
        snapshot.workshop.knownRecipes = snapshot.workshop.knownRecipes or {}
        if delta.recipe then
            snapshot.workshop.knownRecipes[#snapshot.workshop.knownRecipes + 1]
                = delta.recipe
        end
    elseif delta.technologyId then
        research.learnedTechnologyIds = research.learnedTechnologyIds or {}
        research.learnedTechnologyIds[#research.learnedTechnologyIds + 1]
            = delta.technologyId
        for _, entry in ipairs(research.entries or {}) do
            if entry.id == delta.technologyId then entry.known = true end
        end
    end
    ClientState.colonyManagementRevision =
        (tonumber(ClientState.colonyManagementRevision) or 0) + 1
    ClientState.lastColonyManagementReceiveAt = Core.Now()
end)

return PNC.Client
