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
    local radioOS = PsychopatzCore and PsychopatzCore.RadioOS
    if radioOS and radioOS.EmitContactRefresh then
        radioOS.EmitContactRefresh("projecthoomans:contacts")
    end
    return true
end

function Internal.ApplyScavengeSnapshot(payload)
    if type(payload) ~= "table" then return false end
    if payload.requestFailed == true then
        ClientState.lastScavengeFailure = payload.reason
        return false
    end
    local cats = PNC.WorldItemCategories
    local current = ClientState.scavengePolicy or {}
    if payload.enabled ~= nil then
        current.enabled = payload.enabled == true
    elseif current.enabled == nil then
        current.enabled = true
    end
    if type(payload.categories) == "table" then
        current.categories = cats and cats.NormalizeCategories
            and cats.NormalizeCategories(payload.categories) or payload.categories
    elseif not current.categories then
        current.categories = cats and cats.Defaults and cats.Defaults(false) or {}
    end
    if type(payload.preferences) == "table" then
        current.preferences = {
            containers = payload.preferences.containers ~= false,
            floorItems = payload.preferences.floorItems ~= false,
            corpses = payload.preferences.corpses ~= false,
        }
    end
    ClientState.scavengePolicy = current
    ClientState.scavengePolicySynced = true
    ClientState.lastScavengeFailure = nil
    return true
end

Internal.RegisterServerCommand(Const.CMD_WORLD_DISCOVERY_STATE,
    Internal.ApplyWorldDiscoverySnapshot)
Internal.RegisterServerCommand(Const.CMD_SCAVENGE_STATE,
    Internal.ApplyScavengeSnapshot)

-- Public lifecycle/delivery contract; the owner retains its internal reference.
PNC.Client.ApplyScavengeSnapshot = Internal.ApplyScavengeSnapshot

return PNC.Client
