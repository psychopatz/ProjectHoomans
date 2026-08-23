-- Server-authoritative body-part wounds for managed NPCs.

PNC = PNC or {}
PNC.NPCWounds = PNC.NPCWounds or {}
PNC.NPCWounds.Internal = PNC.NPCWounds.Internal or {}

require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Definitions"
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_ClothingCoverage"
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Clothing"
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_BodyState"
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Infection"
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Mutation"
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_ZombieAttack"
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Debug"
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Treatment"
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Update"
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Snapshot"

return PNC.NPCWounds
