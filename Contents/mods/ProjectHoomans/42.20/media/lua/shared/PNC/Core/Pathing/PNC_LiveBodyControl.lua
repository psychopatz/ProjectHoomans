--[[
    PNC Live Body Control
    Stable entry point for managed NPC body-state ownership.
]]

PNC = PNC or {}
PNC.LiveBodyControl = PNC.LiveBodyControl or {}
PNC.LiveBodyControl.Internal = PNC.LiveBodyControl.Internal or {}

require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_NativeMovementLease"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_GroundedLease"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_GroundedCounter"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_DamageReaction"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_GroundedRecovery"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Presentation"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Audio"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Maintenance"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Safety"
require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_Events"
