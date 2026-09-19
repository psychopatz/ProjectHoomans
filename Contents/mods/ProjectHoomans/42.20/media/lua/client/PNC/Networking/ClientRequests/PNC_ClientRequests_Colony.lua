-- Colony snapshot and journal request transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

function Client.RequestColonyManagement(taskBrainNpcID, snapshotScope)
    local player = Internal.GetPlayer()
    local options = {}
    if taskBrainNpcID ~= nil and tostring(taskBrainNpcID) ~= "" then
        options.taskBrainNpcID = tostring(taskBrainNpcID)
    end
    if snapshotScope ~= nil and tostring(snapshotScope) ~= "" then
        options.snapshotScope = tostring(snapshotScope)
    end
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE,
                Const.CMD_COLONY_MANAGEMENT_REQUEST, options)
            return true
        end
        return false
    end
    if not PNC.ColonyManagement then return false end
    local builder
    if options.snapshotScope == "base" then
        builder = PNC.ColonyManagement.BuildBaseSnapshot
    else
        builder = PNC.ColonyManagement.BuildSnapshot
    end
    if not builder then return false end
    local snapshot = builder(player, options)
    if options.snapshotScope == "base" then
        ClientState.colonyBase = snapshot
        ClientState.colonyBaseRevision =
            (tonumber(ClientState.colonyBaseRevision) or 0) + 1
        ClientState.lastColonyBaseReceiveAt = Core.Now()
    else
        ClientState.colonyManagement = snapshot
        ClientState.colonyManagementRevision =
            (tonumber(ClientState.colonyManagementRevision) or 0) + 1
        ClientState.lastColonyManagementReceiveAt = Core.Now()
    end
    if PNC.ColonyNamePrompt and PNC.ColonyNamePrompt.OpenIfNeeded then
        PNC.ColonyNamePrompt.OpenIfNeeded(snapshot)
    end
    return true
end

function Client.RequestBaseBootstrap()
    return Client.RequestColonyManagement(nil, "base")
end

function Client.RequestColonyJournal(after, limit)
    local player = Internal.GetPlayer()
    local state = ClientState.colonyJournal or {}
    local args = {
        after = math.max(0, math.floor(tonumber(after)
            or tonumber(state.cursor) or 0)),
        limit = math.min(32, math.max(1, math.floor(tonumber(limit) or 32))),
        requestID = Internal.RequestID("journal"),
    }
    ClientState.lastColonyJournalRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE,
                Const.CMD_COLONY_JOURNAL_REQUEST, args)
            return true
        end
        return false
    end
    if not PNC.ColonyJournalFeed or not PNC.ColonyJournalFeed.GetDelta
    then
        return false
    end
    if Internal.ApplyColonyJournal then
        Internal.ApplyColonyJournal(PNC.ColonyJournalFeed.GetDelta(player, args))
        return true
    end
    return false
end

return Client
