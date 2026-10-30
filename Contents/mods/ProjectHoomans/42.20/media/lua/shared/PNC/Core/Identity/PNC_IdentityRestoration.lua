-- Identity hydration commands stay separate from portable schema queries.
local Repository = {}
local Identity = PNC.Identity

function Repository.RestoreTraits(record, raw)
    if PNC.NPCTraits and PNC.NPCTraits.NormalizeSet then
        record.npcTraits = PNC.NPCTraits.NormalizeSet(raw.npcTraits)
        record.npcTraitFingerprint = PNC.NPCTraits.Fingerprint(
            record.npcTraits)
    end
end

function Repository.RestoreRecord(record, raw, identity)
    Identity.ApplyRecordIdentity(record, {
        archetypeID = raw.archetypeID or record.archetypeID,
        identitySeed = identity and identity.seed or record.identitySeed,
        identity = identity,
        displayName = raw.displayName or raw.name,
        name = raw.displayName or raw.name,
        visualProfile = raw.visualProfile,
        outfit = raw.outfit,
        isFemale = raw.isFemale == true
            or (identity and identity.isFemale == true),
    })
end

return Repository
