-- Stable entry point for scripted zombie bite lifecycle behavior.

PNC = PNC or {}
PNC.ZombieAggro = PNC.ZombieAggro or {}
PNC.ZombieAggro.BiteInternal = PNC.ZombieAggro.BiteInternal or {}

require "PNC/Core/Zombies/PNC_ZombieAggro_Bite/PNC_ZombieAggro_Bite_Lane"
require "PNC/Core/Zombies/PNC_ZombieAggro_Bite/PNC_ZombieAggro_Bite_Diagnostics"
require "PNC/Core/Zombies/PNC_ZombieAggro_Bite/PNC_ZombieAggro_Bite_Release"
require "PNC/Core/Zombies/PNC_ZombieAggro_Bite/PNC_ZombieAggro_Bite_Start"
require "PNC/Core/Zombies/PNC_ZombieAggro_Bite/PNC_ZombieAggro_Bite_Damage"
require "PNC/Core/Zombies/PNC_ZombieAggro_Bite/PNC_ZombieAggro_Bite_Update"

return PNC.ZombieAggro
