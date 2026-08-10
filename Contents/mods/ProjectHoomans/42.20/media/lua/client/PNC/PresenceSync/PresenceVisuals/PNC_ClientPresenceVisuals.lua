--[[
    PNC Client Presence Visuals
    Ordered entry point for snapshot-to-body presentation.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

require "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_RecordView"
require "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_Keys"
require "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_Attack"
require "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_Treatment"
require "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_Scene"
require "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_BodyPresentation"
require "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_ActionMotion"
require "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_Locomotion"
require "PNC/PresenceSync/PresenceVisuals/PNC_ClientPresenceVisuals_Apply"

return PNC.ClientPresenceSync
