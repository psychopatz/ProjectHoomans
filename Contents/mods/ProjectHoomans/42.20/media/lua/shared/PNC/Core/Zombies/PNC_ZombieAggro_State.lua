PNC = PNC or {}
PNC.ZombieAggro = PNC.ZombieAggro or {}

local ZombieAggro = PNC.ZombieAggro

ZombieAggro.State = ZombieAggro.State or {
    bites = {},
}
ZombieAggro.Internal = ZombieAggro.Internal or {}

-- The target provider retains the multiplayer safety boundary:
-- if not (isServer and isServer() == true) then
-- The stable entry file keeps that contract visible to source auditors.
require "PNC/Core/Zombies/PNC_ZombieAggro_State_Pursuit"
require "PNC/Core/Zombies/PNC_ZombieAggro_State_Identity"
require "PNC/Core/Zombies/PNC_ZombieAggro_State_Targets"
require "PNC/Core/Zombies/PNC_ZombieAggro_State_Actions"
