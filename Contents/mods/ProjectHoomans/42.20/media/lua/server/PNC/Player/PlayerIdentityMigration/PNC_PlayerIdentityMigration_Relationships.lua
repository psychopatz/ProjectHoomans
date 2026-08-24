-- NPC relationship rekeying for player identity migration.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerIdentityMigration = PNC.PlayerIdentityMigration or {}
local Internal = PNC.PlayerIdentityMigration.Internal
local copy = Internal.Copy
local keyVariants = Internal.KeyVariants
local mergeListByID = Internal.MergeListByID
local replaceKey = Internal.ReplaceKey

local function mergeRelationships(canonicalKey, candidates, at)
    if not PNC.Registry or not PNC.Registry.ForEach then return end
    local oldKeys = {}
    for _, record in ipairs(candidates) do
        for key in pairs(keyVariants(record)) do oldKeys[key] = true end
    end
    PNC.Registry.ForEach(function(npc)
        local relationships = npc.social and npc.social.relationships
        if type(relationships) ~= "table" then return end
        local merged
        for key, relationship in pairs(relationships) do
            if oldKeys[key] then
                if not merged then merged = copy(relationship) else
                    merged.memories = mergeListByID(
                        merged.memories, relationship.memories
                    )
                    merged.familiarity = math.max(
                        tonumber(merged.familiarity) or 0,
                        tonumber(relationship.familiarity) or 0
                    )
                    merged.baselineApproval = math.max(
                        tonumber(merged.baselineApproval) or 0,
                        tonumber(relationship.baselineApproval) or 0
                    )
                    merged.baselineRespect = math.max(
                        tonumber(merged.baselineRespect) or 0,
                        tonumber(relationship.baselineRespect) or 0
                    )
                    merged.revision = math.max(
                        tonumber(merged.revision) or 0,
                        tonumber(relationship.revision) or 0
                    )
                end
                relationships[key] = nil
            end
        end
        if merged then
            for _, memory in ipairs(merged.memories or {}) do
                memory.aboutKey = replaceKey(memory.aboutKey, oldKeys, canonicalKey)
                memory.sourceKey = replaceKey(memory.sourceKey, oldKeys, canonicalKey)
            end
            merged = PNC.RelationshipMath.RecalculateRelationship(
                merged, canonicalKey, at
            )
            merged.revision = (tonumber(merged.revision) or 0) + 1
            relationships[canonicalKey] = merged
            PNC.Registry.MarkDirty(npc, "social")
        end
    end)
    return oldKeys
end

Internal.MergeRelationships = mergeRelationships

return Internal
