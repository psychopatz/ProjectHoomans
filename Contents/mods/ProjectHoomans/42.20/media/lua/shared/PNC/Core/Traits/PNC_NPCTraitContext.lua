-- Shared, normalized NPC trait context for conversation and rule evaluation.
-- NPC consumers receive only registered NPC traits. Player-only traits remain
-- in the player physiology/history catalog and are not part of this context.

PNC = PNC or {}
PNC.NPCTraitContext = PNC.NPCTraitContext or {}

local TraitContext = PNC.NPCTraitContext
local Registry = PNC.NPCTraits

function TraitContext.Collect(record)
    if type(record) ~= "table" then return {} end
    if PNC.ConditionStats and PNC.ConditionStats.EnsureTraits then
        PNC.ConditionStats.EnsureTraits(record)
    end
    if Registry and Registry.Collect then
        return Registry.Collect(record)
    end
    return {}
end

return TraitContext
