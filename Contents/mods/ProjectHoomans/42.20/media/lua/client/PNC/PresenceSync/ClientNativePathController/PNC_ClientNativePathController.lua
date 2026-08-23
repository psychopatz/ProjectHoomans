--[[
    Multiplayer native path controller.
    Ordered entry point for client-owned engine path delegation.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

require "PNC/Core/Pathing/PNC_TraversalAction"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Constants"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_State"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Goal"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Binding"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Request"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Update"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Lifecycle"

return PNC.ClientPresenceSync.Internal
