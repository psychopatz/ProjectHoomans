--[[
    PNC Client Actions
    Owns outbound debug, map, health, companion, and inventory commands.
]]

PNC = PNC or {}
PNC.Client = PNC.Client or {}

require "PNC/Networking/ClientActions/PNC_ClientActions_Inventory"
require "PNC/Networking/ClientActions/PNC_ClientActions_Debug"
require "PNC/Networking/ClientActions/PNC_ClientActions_CompanionSupport"
require "PNC/Networking/ClientActions/PNC_ClientActions_Companion"
require "PNC/Networking/ClientActions/PNC_ClientActions_Social"
require "PNC/Networking/ClientActions/PNC_ClientActions_LLMRequest"
require "PNC/Networking/ClientActions/PNC_ClientActions_Faction"
require "PNC/Networking/ClientActions/PNC_ClientActions_Map"
require "PNC/Networking/ClientActions/PNC_ClientActions_Treatment"
require "PNC/Networking/ClientActions/PNC_ClientActions_Scavenge"

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

-- Keep manual-activity feedback in the same client state that drives the
-- Colonists window. This lets local and multiplayer command paths present the
-- same rejection reason without adding a second activity-specific transport.
function Client.RecordManualActivityDiagnostic(npcID, commandID, accepted,
        reason, requestID, details)
    local id = tostring(npcID or "")
    local state = ClientState
    local diagnostic
    local snapshot
    local person
    local index
    if id == "" then return false end
    diagnostic = {
        commandID = tostring(commandID or ""),
        result = accepted == true,
        reason = tostring(reason or (accepted and "commanded" or
            "command_rejected")),
        requestID = requestID,
        details = Core.DeepCopy(details),
        at = Core.Now(),
    }
    state.manualActivityDiagnostics = state.manualActivityDiagnostics or {}
    state.manualActivityDiagnostics[id] = diagnostic
    snapshot = state.colonyManagement
    if type(snapshot) ~= "table" or type(snapshot.people) ~= "table" then
        return true
    end
    for index = 1, #snapshot.people do
        person = snapshot.people[index]
        if person and tostring(person.id or "") == id then
            person.manualActivityDiagnostic = diagnostic
            state.colonyManagementRevision =
                (tonumber(state.colonyManagementRevision) or 0) + 1
            state.lastColonyManagementReceiveAt = Core.Now()
            return true
        end
    end
    return true
end
