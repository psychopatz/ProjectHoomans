-- Stable player-character lifecycle entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerCharacterLifecycle = PNC.PlayerCharacterLifecycle or {}
PNC.PlayerCharacterLifecycle.Internal =
    PNC.PlayerCharacterLifecycle.Internal or {}

local Lifecycle = PNC.PlayerCharacterLifecycle
Lifecycle.LastPumpAt = Lifecycle.LastPumpAt
Lifecycle.ValidatedUUIDByPlayer = Lifecycle.ValidatedUUIDByPlayer
    or setmetatable({}, { __mode = "k" })
Lifecycle.LastValidationAtByPlayer = Lifecycle.LastValidationAtByPlayer
    or setmetatable({}, { __mode = "k" })

require "PNC/Player/PlayerCharacterLifecycle/PNC_PlayerCharacterLifecycle_Core"
require "PNC/Player/PlayerCharacterLifecycle/PNC_PlayerCharacterLifecycle_Callbacks"
require "PNC/Player/PlayerCharacterLifecycle/PNC_PlayerCharacterLifecycle_Pump"
require "PNC/Player/PlayerCharacterLifecycle/PNC_PlayerCharacterLifecycle_Startup"

return Lifecycle
