-- Server-authoritative NPC-to-NPC social identity, bounded edge eviction,
-- and organic Kinsey-aware romance promotion.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

PNC = PNC or {}
PNC.Relationships = PNC.Relationships or {}
PNC.Relationships.Internal = PNC.Relationships.Internal or {}

local Relationships = PNC.Relationships
local Internal = Relationships.Internal
local Types = PNC.RelationshipTypes
local Constants = PNC.RelationshipConstants
local EntityRef = PNC.EntityRef
local Profiles = PNC.SocialProfiles
local ProfileMath = PNC.SocialProfileMath
local Policy = PNC.RelationshipProposalPolicy

Relationships.MAX_NPC_RELATIONSHIPS = Relationships.MAX_NPC_RELATIONSHIPS or 16
Relationships.NPC_ROMANCE_MIN_AGE_HOURS = Relationships.NPC_ROMANCE_MIN_AGE_HOURS or 24

local function worldAgeHours(value)
    value = tonumber(value)
    if value ~= nil
        and value == value
        and value ~= math.huge
        and value ~= -math.huge
    then
        return math.max(0, value)
    end
    if getGameTime and getGameTime() and getGameTime().getWorldAgeHours then
        return math.max(0, tonumber(getGameTime():getWorldAgeHours()) or 0)
    end
    return 0
end

local function isNPCTargetKey(targetKey)
    local key = tostring(targetKey or "")
    return string.sub(key, 1, 4) == "npc:" or string.sub(key, 1, 6) == "actor:"
end

local function isProtectedEdge(targetKey, rel, protectedKey)
    if targetKey == protectedKey then return true end
    if not isNPCTargetKey(targetKey) then return true end
    if type(rel) ~= "table" then return false end
    if rel.historicalPin == true then return true end
    local bondClass = type(rel.bond) == "table"
        and tostring(rel.bond.class or "none") or "none"
    if bondClass == "family" or bondClass == "lover" or bondClass == "friend" then
        return true
    end
    local state = tostring(rel.state or "unknown")
    if state == "friend" or state == "rival" or state == "enemy" then
        return true
    end
    return false
end

---Bounds per-NPC npc:* relationship edges to MAX_NPC_RELATIONSHIPS by evicting
---the stalest, lowest-familiarity neutral/unknown acquaintances first.
function Relationships.PruneNPCRelationships(social, protectedKey, maxEdges)
    if type(social) ~= "table" or type(social.relationships) ~= "table" then
        return 0
    end
    local cap = math.max(1, math.floor(tonumber(maxEdges)
        or Relationships.MAX_NPC_RELATIONSHIPS or 16))
    local npcCount = 0
    local evictable = {}
    local key
    local rel
    for key, rel in pairs(social.relationships) do
        if isNPCTargetKey(key) then
            npcCount = npcCount + 1
            if not isProtectedEdge(key, rel, protectedKey) then
                evictable[#evictable + 1] = {
                    key = key,
                    familiarity = tonumber(rel and rel.familiarity) or 0,
                    lastAt = tonumber(rel and (rel.lastInteractionAt or rel.lastEvaluatedAt)) or 0,
                }
            end
        end
    end
    local excess = npcCount - cap
    if excess <= 0 or #evictable == 0 then return 0 end
    table.sort(evictable, function(a, b)
        if a.familiarity ~= b.familiarity then
            return a.familiarity < b.familiarity
        end
        if a.lastAt ~= b.lastAt then
            return a.lastAt < b.lastAt
        end
        return tostring(a.key) < tostring(b.key)
    end)
    local removed = 0
    local index
    for index = 1, math.min(excess, #evictable) do
        social.relationships[evictable[index].key] = nil
        removed = removed + 1
    end
    return removed
end

local function npcIsFemale(record)
    if type(record) ~= "table" then return nil end
    if type(record.isFemale) == "boolean" then return record.isFemale end
    if record.identity and type(record.identity.isFemale) == "boolean" then
        return record.identity.isFemale
    end
    return nil
end

local function resolveNPCProfile(record)
    if Profiles and type(Profiles.GetNPCProfile) == "function" then
        local profile = Profiles.GetNPCProfile(record and record.id)
        if profile then return profile end
    end
    if record and record.social and record.social.personality then
        return record.social.personality
    end
    if PNC.SocialProfileTypes
        and type(PNC.SocialProfileTypes.NormalizeNPCPersonality) == "function"
    then
        return PNC.SocialProfileTypes.NormalizeNPCPersonality(
            nil,
            record and (record.identitySeed or record.id) or 1,
            record and record.archetypeID or "General"
        )
    end
    return nil
end

function Relationships.HasLivingLover(record, ignoreTargetKey)
    local rels = record and record.social and record.social.relationships or nil
    if type(rels) ~= "table" then return false end
    local registry = PNC.Registry
    local key
    local rel
    for key, rel in pairs(rels) do
        if key ~= ignoreTargetKey and type(rel) == "table"
            and type(rel.bond) == "table" and rel.bond.class == "lover"
            and rel.historical ~= true
        then
            if isNPCTargetKey(key) then
                local id = string.match(tostring(key), "^[^:]+:(.+)$")
                local other = id and registry and registry.GetRecord
                    and registry.GetRecord(id) or nil
                if other and other.alive ~= false then
                    return true, key
                end
            else
                return true, key
            end
        end
    end
    return false
end

function Relationships.MarkKnownName(observerNPCID, targetKey, at)
    if not Internal.isAuthority or not Internal.isAuthority() then
        return false, "not_authority"
    end
    local record = Internal.resolveObserver and Internal.resolveObserver(observerNPCID)
    if not record then return false, "observer_not_found" end
    local key = tostring(targetKey or "")
    if key == "" then return false, "invalid_target" end
    local now = worldAgeHours(at)
    local social = Types.NormalizeSocialState(
        record.social, record.identitySeed, record.archetypeID
    )
    local existing = social.relationships[key]
    local rel = Types.NormalizeRelationship(existing, key)
    if not rel then return false, "invalid_target" end
    local changed = rel.knowsName ~= true
    rel.knowsName = true
    if rel.firstMetAt == nil then
        rel.firstMetAt = now
        changed = true
    end
    rel.lastInteractionAt = math.max(tonumber(rel.lastInteractionAt) or 0, now)
    if rel.state == Constants.STATE_UNKNOWN then
        rel.state = Constants.STATE_NEUTRAL
        changed = true
    end
    social.relationships[key] = rel
    Relationships.PruneNPCRelationships(social, key)
    if changed and Internal.commit then
        Internal.commit(record, social, key, rel, true, now, {
            kind = "name_exchanged",
        })
    else
        record.social = social
    end
    return true, changed and "name_marked" or "already_known", rel
end

local function makeOrganicLoverMemory(targetKey, at, accepted, eventID)
    return Types.NewMemory({
        id = eventID,
        type = accepted
            and "relationship_proposal_accepted"
            or "relationship_proposal_rejected",
        aboutKey = targetKey,
        createdAt = at,
        lastEvaluatedAt = at,
        approvalEffect = 0,
        respectEffect = 0,
        moraleEffect = 0,
        strength = accepted and 1 or 0.5,
        decayPerDay = accepted and 0 or 0.1,
        permanent = accepted,
        shareable = accepted,
        knowledgeSource = Constants.KNOWLEDGE_EXPERIENCED,
        sourceKey = targetKey,
        tags = {
            social_history = true,
            relationship_proposal = true,
            npc_organic_romance = true,
            accepted = accepted,
        },
    })
end

local function applyLoverOutcome(record, targetKey, at, accepted, style)
    local social = Types.NormalizeSocialState(
        record.social, record.identitySeed, record.archetypeID
    )
    local rel = Types.NormalizeRelationship(social.relationships[targetKey], targetKey)
    if not rel then return false end
    local eventID = "social:npc_romance_"
        .. (accepted and "accepted:" or "rejected:")
        .. tostring(record.id) .. ":" .. tostring(targetKey) .. ":"
        .. tostring((tonumber(rel.revision) or 0) + 1)
    local mem = makeOrganicLoverMemory(targetKey, at, accepted, eventID)
    if mem then
        rel.memories[#rel.memories + 1] = mem
        while #rel.memories > Constants.MEMORY_LIMIT do
            table.remove(rel.memories, 1)
        end
    end
    if accepted then
        rel.bond = {
            schemaVersion = Constants.DURABLE_BOND_SCHEMA_VERSION,
            class = "lover",
            kind = nil,
            establishedAt = at,
            source = "npc_organic_romance",
        }
        rel.knowsName = true
        rel.cooldowns[Policy.CooldownType()] = nil
    else
        rel.cooldowns[Policy.CooldownType()] = at + Policy.CooldownHours(style)
    end
    rel.lastInteractionAt = at
    social.relationships[targetKey] = rel
    Relationships.PruneNPCRelationships(social, targetKey)
    if Internal.commit then
        Internal.commit(record, social, targetKey, rel, true, at, {
            kind = accepted and "npc_lover_promoted" or "npc_lover_rejected",
            eventID = eventID,
        })
    else
        record.social = social
    end
    return true
end

function Relationships.EvaluateNPCRomancePromotion(npcAID, npcBID, at)
    if not Internal.isAuthority or not Internal.isAuthority() then
        return false, "not_authority"
    end
    local recA = Internal.resolveObserver and Internal.resolveObserver(npcAID)
    local recB = Internal.resolveObserver and Internal.resolveObserver(npcBID)
    if not recA or not recB or tostring(recA.id) == tostring(recB.id) then
        return false, "participants_unavailable"
    end
    if recA.alive == false or recB.alive == false then
        return false, "participant_dead"
    end
    local keyA = EntityRef and EntityRef.ForNPC and EntityRef.ForNPC(recA.id)
        or ("npc:" .. tostring(recA.id))
    local keyB = EntityRef and EntityRef.ForNPC and EntityRef.ForNPC(recB.id)
        or ("npc:" .. tostring(recB.id))
    local relAB = Internal.getRelationship and Internal.getRelationship(recA, keyB)
    local relBA = Internal.getRelationship and Internal.getRelationship(recB, keyA)
    if not relAB or not relBA then
        return false, "relationship_not_found"
    end
    relAB = Types.NormalizeRelationship(relAB, keyB)
    relBA = Types.NormalizeRelationship(relBA, keyA)
    local bondAB = Types.NormalizeBond(relAB.bond)
    local bondBA = Types.NormalizeBond(relBA.bond)
    local now = worldAgeHours(at)
    local profA = resolveNPCProfile(recA)
    local profB = resolveNPCProfile(recB)
    if not profA or not profB then
        return false, "social_profile_unavailable"
    end
    if profA.jealousyStyle ~= "unpossessive" and Relationships.HasLivingLover(recA, keyB) then
        return false, "already_has_lover"
    end
    if profB.jealousyStyle ~= "unpossessive" and Relationships.HasLivingLover(recB, keyA) then
        return false, "already_has_lover"
    end
    local minAge = math.max(0, tonumber(Relationships.NPC_ROMANCE_MIN_AGE_HOURS) or 24)
    local metA = tonumber(relAB.firstMetAt)
    local metB = tonumber(relBA.firstMetAt)
    if (metA and (now - metA) < minAge) or (metB and (now - metB) < minAge) then
        return false, "relationship_too_new"
    end
    local genderA = npcIsFemale(recA)
    local genderB = npcIsFemale(recB)
    local attractionWeight = 0
    if genderA ~= nil and genderB ~= nil and ProfileMath
        and type(ProfileMath.MutualAttractionWeight) == "function"
    then
        attractionWeight = ProfileMath.MutualAttractionWeight(
            profA, genderA, profB, genderB
        )
    end
    local compatible = attractionWeight > 0
    local evalAB = Policy.EvaluateEligibility(relAB, bondAB, compatible, true, now)
    if not evalAB.eligible then return false, evalAB.reason end
    local evalBA = Policy.EvaluateEligibility(relBA, bondBA, compatible, true, now)
    if not evalBA.eligible then return false, evalBA.reason end

    local accA = Policy.EvaluateAcceptance(
        recA.identitySeed or recA.id,
        keyB .. ":" .. tostring(relAB.revision) .. ":npc_romance",
        relAB, profA, attractionWeight
    )
    local accB = Policy.EvaluateAcceptance(
        recB.identitySeed or recB.id,
        keyA .. ":" .. tostring(relBA.revision) .. ":npc_romance",
        relBA, profB, attractionWeight
    )
    if accA.accepted and accB.accepted then
        applyLoverOutcome(recA, keyB, now, true, profA.romanceStyle)
        applyLoverOutcome(recB, keyA, now, true, profB.romanceStyle)
        return true, "lover_promoted", {
            attractionWeight = attractionWeight,
            probabilityA = accA.probability,
            probabilityB = accB.probability,
        }
    end
    applyLoverOutcome(recA, keyB, now, false, profA.romanceStyle)
    applyLoverOutcome(recB, keyA, now, false, profB.romanceStyle)
    return false, "romance_rejected", {
        attractionWeight = attractionWeight,
        probabilityA = accA.probability,
        probabilityB = accB.probability,
    }
end

return Relationships
