local Internal = PNC.Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

function Internal.ApplyWorldDiscoverySnapshot(payload)
    if type(payload) ~= "table" then return false end
    local current = ClientState.worldDiscovery
    if current and current.characterUUID and payload.characterUUID
        and tostring(current.characterUUID)
            ~= tostring(payload.characterUUID)
    then current = nil end
    if current and tonumber(payload.revision)
        < (tonumber(current.revision) or 0)
    then return false end
    ClientState.worldDiscovery = payload
    ClientState.lastWorldDiscoveryReceiveAt = Core.Now()
    local contactsUI = PNC.ContactsUI or PNC.WorldDiscoveryUI
    if contactsUI and contactsUI.ReceiveSnapshot then
        contactsUI.ReceiveSnapshot(payload)
    end
    if PNC.RadioDiscoveryPresentation
        and PNC.RadioDiscoveryPresentation.ShowResult
    then
        PNC.RadioDiscoveryPresentation.ShowResult(payload)
    end
    return true
end

function Internal.ApplyScavengeSnapshot(payload)
    if type(payload) ~= "table" then return false end
    ClientState.scavengeSessions = ClientState.scavengeSessions or {}
    local sessionId = payload.sessionId and tostring(payload.sessionId) or nil
    if payload.requestFailed == true then
        ClientState.lastScavengeFailure = payload.reason
        if PNC.ScavengeUI and PNC.ScavengeUI.ReceiveSnapshot then
            PNC.ScavengeUI.ReceiveSnapshot(payload)
        end
        if PNC.ColonyScavengeTab and PNC.ColonyScavengeTab.ReceiveSnapshot then
            PNC.ColonyScavengeTab.ReceiveSnapshot(payload)
        end
        return false
    end
    local current = sessionId and ClientState.scavengeSessions[sessionId] or nil
    local incomingRevision = tonumber(payload.revision)
    if current and incomingRevision
        < (tonumber(current.revision) or 0)
    then return false end
    if payload.disbanded == true then
        if sessionId then ClientState.scavengeSessions[sessionId] = nil end
        if tostring(ClientState.activeScavengeSessionId or "")
            == tostring(sessionId or "")
        then ClientState.activeScavengeSessionId = nil end
    else
        if sessionId then ClientState.scavengeSessions[sessionId] = payload end
        ClientState.activeScavengeSessionId = sessionId
            or ClientState.activeScavengeSessionId
    end
    ClientState.lastScavengeFailure = nil
    if PNC.ScavengeController and PNC.ScavengeController.ReceiveSnapshot then
        PNC.ScavengeController.ReceiveSnapshot(payload)
    end
    if PNC.ScavengeNotifications and PNC.ScavengeNotifications.Receive then
        PNC.ScavengeNotifications.Receive(current, payload)
    end
    if PNC.ScavengeUI and PNC.ScavengeUI.ReceiveSnapshot then
        PNC.ScavengeUI.ReceiveSnapshot(payload)
    end
    if PNC.ColonyScavengeTab and PNC.ColonyScavengeTab.ReceiveSnapshot then
        PNC.ColonyScavengeTab.ReceiveSnapshot(payload)
    end
    return true
end

Internal.RegisterServerCommand(Const.CMD_WORLD_DISCOVERY_STATE,
    Internal.ApplyWorldDiscoverySnapshot)
Internal.RegisterServerCommand(Const.CMD_SCAVENGE_STATE,
    Internal.ApplyScavengeSnapshot)

return PNC.Client
