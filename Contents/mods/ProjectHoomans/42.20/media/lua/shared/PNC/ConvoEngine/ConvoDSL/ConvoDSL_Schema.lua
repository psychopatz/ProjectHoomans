-- Project Hoomans thin adopter shim for PsychopatzCore's shared ConvoDSL_Schema.
-- Registers Hoomans-specific predicates via Core's RegisterFields extension hook.
PNC = PNC or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local CoreSchema = require "PsychopatzCore/ConvoEngine/ConvoDSL/ConvoDSL_Schema"

local function spec(luaKey, valueType, allowed)
    return { luaKey = luaKey, valueType = valueType, allowed = allowed }
end

CoreSchema.RegisterFields({
    ["epistemic.provenance"] = spec("epistemicProvenance", "string"),
    ["leader.grief"] = spec("leaderGrief", "string"),
    ["leader.succession"] = spec("leaderSuccession", "string"),
    ["corpse.revenge"] = spec("corpseRevenge", "bool"),
    ["dog.sex"] = spec("companionDogSex", "string"),
    ["dog.fed"] = spec("companionDogFed", "string"),
    ["alife.kind"] = spec("projectALifeKind", "string"),
    ["alife.stance"] = spec("projectALifeStance", "string"),
    ["alife.conflict_dir"] = spec("projectALifeConflictDirection", "string"),
    ["alife.conflict_direction"] = spec("projectALifeConflictDirection", "string"),
    ["alife.conflict_dmg"] = spec("projectALifeConflictDamage", "string"),
    ["alife.conflict_damage"] = spec("projectALifeConflictDamage", "string"),
})

return CoreSchema
