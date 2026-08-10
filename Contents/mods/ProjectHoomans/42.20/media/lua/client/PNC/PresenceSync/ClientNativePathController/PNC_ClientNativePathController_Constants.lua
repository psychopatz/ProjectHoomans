--[[
    PNC Client Native Path Controller: shared timing configuration
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
Internal.NativePathController =
    Internal.NativePathController or {}
local Controller = Internal.NativePathController
local Const = PNC.Const or {}

local CONTROLLER_CHECK_MS = 250
local PROGRESS_EPSILON_SQ = 0.0025
local STALL_TIMEOUT_MS = math.max(
    1500,
    tonumber(Const and Const.CLIENT_NATIVE_PATH_STALL_MS)
        or 3000
)
local RETRY_BASE_MS = math.max(
    250,
    tonumber(Const and Const.CLIENT_NATIVE_PATH_RETRY_BASE_MS)
        or 350
)
local RETRY_MAX_MS = math.max(
    RETRY_BASE_MS,
    tonumber(Const and Const.CLIENT_NATIVE_PATH_RETRY_MAX_MS)
        or 4000
)
local REQUEST_GRACE_MS = math.max(
    500,
    tonumber(Const and Const.CLIENT_NATIVE_PATH_REQUEST_GRACE_MS)
        or 900
)
local MOVEMENT_LEASE_MS = math.max(
    250,
    tonumber(Const and Const.CLIENT_NATIVE_MOVEMENT_LEASE_MS)
        or 750
)
local WINDOW_SMASH_IMPACT_MS = 650
local WINDOW_SMASH_FINISH_MS = 1050
local WINDOW_CLIMB_RECOVERY_MS = 500

Controller.CONTROLLER_CHECK_MS = CONTROLLER_CHECK_MS
Controller.PROGRESS_EPSILON_SQ = PROGRESS_EPSILON_SQ
Controller.STALL_TIMEOUT_MS = STALL_TIMEOUT_MS
Controller.RETRY_BASE_MS = RETRY_BASE_MS
Controller.RETRY_MAX_MS = RETRY_MAX_MS
Controller.REQUEST_GRACE_MS = REQUEST_GRACE_MS
Controller.MOVEMENT_LEASE_MS = MOVEMENT_LEASE_MS
Controller.WINDOW_SMASH_IMPACT_MS = WINDOW_SMASH_IMPACT_MS
Controller.WINDOW_SMASH_FINISH_MS = WINDOW_SMASH_FINISH_MS
Controller.WINDOW_CLIMB_RECOVERY_MS = WINDOW_CLIMB_RECOVERY_MS

