if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Conduct = PNC.Conduct
local H = Conduct.Internal
local Core = PNC.Core
local EntityRef = PNC.EntityRef
local Types = PNC.ConductTypes
local Math = PNC.ConductMath
local Constants = PNC.ConductConstants

function H.Authority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

function H.Copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

function H.Resolve(entityKey)
    local parsed = EntityRef.Parse(entityKey)
    local record
    if not parsed then return nil, "invalid_entity_key" end
    if parsed.kind == "npc" then
        record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(parsed.npcID) or nil
        if not record then return nil, "npc_not_found" end
        return {
            kind = "npc",
            key = entityKey,
            id = parsed.npcID,
            record = record,
            conduct = Types.NormalizeConductRecord(
                record.social and record.social.conduct
            ),
        }
    end
    record = PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetRegistryRecord
        and PNC.PlayerCharacters.GetRegistryRecord(
            parsed.characterUUID
        ) or nil
    local legacyMatch = record and record.legacyAccountIdentities
        and record.legacyAccountIdentities[parsed.accountIdentity] == true
    if not record
        or (record.accountKey ~= parsed.accountIdentity
            and record.accountIdentity ~= parsed.accountIdentity
            and not legacyMatch)
    then
        return nil, "player_character_not_found"
    end
    return {
        kind = "player",
        key = entityKey,
        id = parsed.characterUUID,
        record = record,
        conduct = Types.NormalizeConductRecord(record.conduct),
    }
end

function H.Commit(owner, conduct)
    if owner.kind == "player" then
        return PNC.PlayerCharacters.ApplyConductRecord(
            owner.id,
            conduct
        )
    end
    local record = PNC.Registry.Get(owner.id)
    if not record then return false, "npc_not_found" end
    local social = PNC.RelationshipTypes.NormalizeSocialState(
        record.social,
        record.identitySeed,
        record.archetypeID
    )
    social.conduct = Types.NormalizeConductRecord(conduct)
    social.revision = math.max(
        tonumber(record.social and record.social.revision) or 0,
        tonumber(social.revision) or 0
    ) + 1
    record.social = social
    PNC.Registry.MarkDirty(record, "social")
    return true, "updated", H.Copy(social.conduct)
end
