-- Colony snapshot and journal request transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

--[[
    Requests a colony-management projection.

    `sections` lists the projection groups the caller needs. Omitted groups are
    not built and not sent, which is what keeps the colonist roster inside one
    engine packet. Passing no `sections` requests the complete snapshot.
]]
function Client.RequestColonyManagement(taskBrainNpcID, snapshotScope, sections,
    detailNpcID)
    local player = Internal.GetPlayer()
    local options = {}
    if taskBrainNpcID ~= nil and tostring(taskBrainNpcID) ~= "" then
        options.taskBrainNpcID = tostring(taskBrainNpcID)
    end
    if snapshotScope ~= nil and tostring(snapshotScope) ~= "" then
        options.snapshotScope = tostring(snapshotScope)
    end
    if type(sections) == "table" and #sections > 0 then
        options.sections = sections
    end
    if detailNpcID ~= nil and tostring(detailNpcID) ~= "" then
        options.detailNpcID = tostring(detailNpcID)
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
    -- The local path has no packet budget, but it must still merge sectioned
    -- rebuilds so a partial request cannot clear the rest of the snapshot.
    local function apply(scopeKey, revisionKey, receivedAtKey)
        local current = ClientState[scopeKey]
        if options.sections ~= nil and type(current) == "table"
            and type(snapshot) == "table"
        then
            for key, value in pairs(snapshot) do current[key] = value end
            snapshot = current
        end
        ClientState[scopeKey] = snapshot
        ClientState[revisionKey] =
            (tonumber(ClientState[revisionKey]) or 0) + 1
        ClientState[receivedAtKey] = Core.Now()
    end
    if options.snapshotScope == "base" then
        apply("colonyBase", "colonyBaseRevision", "lastColonyBaseReceiveAt")
    else
        apply("colonyManagement", "colonyManagementRevision",
            "lastColonyManagementReceiveAt")
    end
    snapshot = options.snapshotScope == "base"
        and ClientState.colonyBase or ClientState.colonyManagement
    if PNC.ColonyNamePrompt and PNC.ColonyNamePrompt.OpenIfNeeded then
        PNC.ColonyNamePrompt.OpenIfNeeded(snapshot)
    end
    return true
end

function Client.RequestBaseBootstrap(sections)
    return Client.RequestColonyManagement(nil, "base", sections)
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
