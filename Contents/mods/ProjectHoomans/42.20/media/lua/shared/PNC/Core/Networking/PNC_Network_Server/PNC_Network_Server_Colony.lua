local Network = PNC.Network
local Internal = Network.Internal
local Core = PNC.Core
local Const = PNC.Const

function Network.SendColonyManagement(targetPlayer, snapshot)
    local payload = { snapshot=snapshot, serverTime=Core.Now() }
    if isServer and isServer() and targetPlayer then sendServerCommand(targetPlayer, Const.MODULE, Const.CMD_COLONY_MANAGEMENT, payload)
    elseif not isServer or not isServer() then triggerEvent("OnServerCommand", Const.MODULE, Const.CMD_COLONY_MANAGEMENT, payload) end
end

function Network.SendColonyJournal(targetPlayer, delta)
    local payload = { delta = delta, serverTime = Core.Now() }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE,
            Const.CMD_COLONY_JOURNAL, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE,
            Const.CMD_COLONY_JOURNAL, payload)
    end
end

function Network.SendSettlementDelta(targetPlayer, settlement, actionResult, storage)
    local payload = { settlement = settlement, actionResult = actionResult,
        storage = storage,
        serverTime = Core.Now() }
    if isServer and isServer() and targetPlayer then
        sendServerCommand(targetPlayer, Const.MODULE,
            Const.CMD_SETTLEMENT_DELTA, payload)
    elseif not isServer or not isServer() then
        triggerEvent("OnServerCommand", Const.MODULE,
            Const.CMD_SETTLEMENT_DELTA, payload)
    end
end

function Network.SendColonyKnowledgeDelta(targetPlayer, delta)
    Internal.SendToPlayer(targetPlayer, Const.CMD_COLONY_KNOWLEDGE_DELTA, {
        delta = delta, serverTime = Core.Now(),
    })
end

function Network.SendWorldDiscovery(targetPlayer, payload)
    Internal.SendIdentityPayload(
        targetPlayer,
        Const.CMD_WORLD_DISCOVERY_STATE,
        payload
    )
end
