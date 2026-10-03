-- Client-side zombie safety and MP directive application.
-- Target selection and directive application remain behind this stable module.
PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core
local Const = PNC.Const or {}
local ClientState = PNC.Network and PNC.Network.ClientState or nil
Internal.TargetIndex = require
    "PNC/PresenceSync/PNC_ClientZombieAggroController_TargetIndex"
Internal.Effects = require
    "PNC/PresenceSync/PNC_ClientZombieAggroController_BodyEffects"
Internal.AggroRadius = tonumber(Const.ZOMBIE_AGGRO_RADIUS) or 12
Internal.AggroTierMS = math.max(
    10,
    tonumber(Const.CLIENT_ZOMBIE_AGGRO_TIER_MS) or 50
)
Internal.AggroTierCount = math.max(
    1,
    math.floor(tonumber(Const.CLIENT_ZOMBIE_AGGRO_TIER_COUNT) or 4)
)

require "PNC/PresenceSync/PNC_ClientZombieAggroController_Targeting"
require "PNC/PresenceSync/PNC_ClientZombieAggroController_Update"

return Internal
