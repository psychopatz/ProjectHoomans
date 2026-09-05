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

Internal.RegisterServerCommand(Const.CMD_COLONY_MANAGEMENT, function(args)
    ClientState.colonyManagement = args.snapshot
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
    local snapshot = ClientState.colonyManagement or {}
    snapshot.settlement = args.settlement
    if args.storage then snapshot.storage = args.storage end
    snapshot.actionResult = args.actionResult
    ClientState.colonyManagement = snapshot
    ClientState.colonyManagementRevision =
        (tonumber(ClientState.colonyManagementRevision) or 0) + 1
    ClientState.lastColonyManagementReceiveAt = Core.Now()
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
