-- Candidate discovery and canonical identity selection.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerIdentityMigration = PNC.PlayerIdentityMigration or {}
local Internal = PNC.PlayerIdentityMigration.Internal
local Characters = PNC.PlayerCharacters
local Types = PNC.PlayerCharacterTypes
local Constants = PNC.PlayerCharacterConstants
local call = Internal.Call
local fingerprint = Internal.Fingerprint
local recordFingerprint = Internal.RecordFingerprint
local keyVariants = Internal.KeyVariants

local function dependentScore(record)
    local score = tonumber(record.revision) or 0
    local knowledge = PNC.NPCKnowledge and PNC.NPCKnowledge.Registry
    local notes = knowledge and knowledge.byCharacter
        and knowledge.byCharacter[record.uuid]
    for _, note in pairs(notes and notes.byNPC or {}) do
        score = score + 100
        for _ in pairs(note.discovered or {}) do score = score + 20 end
        score = score + #(note.evidence or {}) + #(note.journalEntries or {})
    end
    score = score + #(record.conduct and record.conduct.evidence or {}) * 10
    score = score + (tonumber(record.socialProfile
        and record.socialProfile.revision) or 0)
    local oldKeys = keyVariants(record)
    if PNC.Registry and PNC.Registry.ForEach then
        PNC.Registry.ForEach(function(npc)
            for key, relationship in pairs(npc.social
                and npc.social.relationships or {}) do
                if oldKeys[key] then
                    score = score + 25 + #(relationship.memories or {}) * 5
                end
            end
        end)
    end
    for key in pairs(oldKeys) do
        if PNC.Factions and PNC.Factions.Registry
            and PNC.Factions.Registry.byPlayerKey
            and PNC.Factions.Registry.byPlayerKey[key]
        then
            score = score + 50
        end
    end
    return score
end

local function collectCandidates(player)
    local expected = fingerprint(player)
    local output = {}
    for _, record in pairs(Characters.Registry.byUUID or {}) do
        if record.status == Constants.STATUS_ACTIVE
            and recordFingerprint(record) == expected
        then
            output[#output + 1] = record
        end
    end
    table.sort(output, function(left, right)
        local leftScore, rightScore = dependentScore(left), dependentScore(right)
        if leftScore ~= rightScore then return leftScore > rightScore end
        local leftSeen = tonumber(left.lastSeenAt) or 0
        local rightSeen = tonumber(right.lastSeenAt) or 0
        if leftSeen ~= rightSeen then return leftSeen > rightSeen end
        return left.uuid < right.uuid
    end)
    return output
end

local function chooseCanonical(player, candidates)
    local mirror = Types.ResolveUUID(
        Characters.Registry,
        call(player, "getModData") and call(player, "getModData")[
            Constants.MODDATA_UUID_FIELD
        ] or nil
    )
    if mirror then
        for _, record in ipairs(candidates) do
            if record.uuid == mirror then return record, "player_mirror" end
        end
    end
    return candidates[1], "durable_state"
end

Internal.DependentScore = dependentScore
Internal.CollectCandidates = collectCandidates
Internal.ChooseCanonical = chooseCanonical

return Internal
