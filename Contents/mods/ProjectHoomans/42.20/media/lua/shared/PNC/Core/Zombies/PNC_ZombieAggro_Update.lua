local ZombieAggro = require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Core"

-- The ordered providers retain the explicit MP server movement branch:
-- publishMPTargetDirective is called when `if isMultiplayerServer() then`.
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Multiplayer"
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Path"
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Pursuit"
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Targets"
require "PNC/Core/Zombies/PNC_ZombieAggro_Update_Loop"

return ZombieAggro
