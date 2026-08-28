--[[
    PNC Networking - Server Replication

    Stable entry point for transport fan-out, interest sets, roster deltas,
    record broadcasts, and detailed server payloads.
]]

PNC = PNC or {}
PNC.Network = PNC.Network or {}
PNC.Network.Internal = PNC.Network.Internal or {}

require "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Transport"
require "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_RosterInterest"
require "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Broadcasts"
require "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Character"
require "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_DebugPayloads"
require "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Colony"
require "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_LLM"

return PNC.Network
