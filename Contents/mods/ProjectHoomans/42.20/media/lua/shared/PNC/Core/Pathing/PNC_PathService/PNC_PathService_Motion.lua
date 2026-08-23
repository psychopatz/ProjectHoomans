--[[
    PNC Path Service Motion
    Compatibility entry point for motion lifecycle and execution providers.
]]

PNC = PNC or {}
PNC.PathService = PNC.PathService or {}
PNC.PathService.Internal = PNC.PathService.Internal or {}

require "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionLifecycle"
require "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionPassage"
require "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionRecovery"
require "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionScripted"
require "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionNativePassage"
require "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionNativeProgress"
require "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionNative"
require "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionPump"
require "PNC/Core/Pathing/PNC_PathService/Motion/PNC_PathService_MotionApi"
