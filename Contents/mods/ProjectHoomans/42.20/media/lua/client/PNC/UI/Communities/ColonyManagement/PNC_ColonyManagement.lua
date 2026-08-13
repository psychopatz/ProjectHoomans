PNC = PNC or {}
PNC.ColonyManagementUI = PNC.ColonyManagementUI or {}
PNC.ColonyManagementClient = PNC.ColonyManagementClient or {}

local Client = PNC.ColonyManagementClient

local function clientState()
    return PNC.Network and PNC.Network.ClientState or {}
end

function Client.ReadSnapshot()
    local state = clientState()
    return {
        snapshot = state.colonyManagement or {},
        revision = tonumber(state.colonyManagementRevision) or 0,
        receivedAt = state.lastColonyManagementReceiveAt,
    }
end

function Client.HasUpdate(lastRevision, lastReceiveAt)
    local update = Client.ReadSnapshot()
    return update.revision > (tonumber(lastRevision) or 0)
        or (tonumber(update.receivedAt) or 0)
            > (tonumber(lastReceiveAt) or 0),
        update
end

function Client.RequestSnapshot()
    local ok = false
    local reason = "client_unavailable"
    if PNC.Client and PNC.Client.RequestColonyManagement then
        ok, reason = PNC.Client.RequestColonyManagement()
    end
    return ok, reason, PNC.Core.Now()
end

require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Registry"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Layout"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Diagnostics"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Tabs"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Controller"
require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Window"

return PNC.ColonyManagementUI
