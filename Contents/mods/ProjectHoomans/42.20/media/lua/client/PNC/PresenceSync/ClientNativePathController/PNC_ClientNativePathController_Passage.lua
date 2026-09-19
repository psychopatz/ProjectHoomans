--[[
    PNC Client Native Path Controller: ordered passage behavior entry.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Controller = Sync.Internal.NativePathController
Controller.PassageInternal = Controller.PassageInternal or {}

require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage_Common"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage_Fence_Common"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage_Fence_Start"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage_Fence_Update"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage_Fence"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage_Window_Actions"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage_Window_Update"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage_Window"
require "PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage_Routing"
