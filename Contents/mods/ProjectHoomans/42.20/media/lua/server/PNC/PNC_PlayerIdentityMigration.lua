-- Non-destructive schema-v4 repair for legacy single-player UUID splits.

if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.PlayerIdentityMigration = PNC.PlayerIdentityMigration or {}

local Migration = PNC.PlayerIdentityMigration
local Core = PNC.Core
local Characters = PNC.PlayerCharacters
local Types = PNC.PlayerCharacterTypes
local Constants = PNC.PlayerCharacterConstants
local EntityRef = PNC.EntityRef

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function call(value, method)
    local fn = value and value[method]
    if not fn then return nil end
    local ok, result = pcall(fn, value)
    return ok and result or nil
end

local function atNow(value)
    value = tonumber(value)
    if value then return math.max(0, value) end
    local gameTime = getGameTime and getGameTime()
    return gameTime and gameTime.getWorldAgeHours
        and math.max(0, tonumber(gameTime:getWorldAgeHours()) or 0) or 0
end

local function fingerprint(player)
    local descriptor = call(player, "getDescriptor")
    local first = descriptor and call(descriptor, "getForename") or nil
    local last = descriptor and call(descriptor, "getSurname") or nil
    if not first and not last then return nil end
    return string.lower(tostring(first or "")) .. "\31"
        .. string.lower(tostring(last or ""))
end

local function recordFingerprint(record)
    if not record or (not record.forename and not record.surname) then
        return nil
    end
    return string.lower(tostring(record.forename or "")) .. "\31"
        .. string.lower(tostring(record.surname or ""))
end

local function keyVariants(record)
    local result = {}
    local function add(identity)
        local key = identity and EntityRef.ForPlayerIdentity(identity, record.uuid)
        if key then result[key] = true end
    end
    add(record.accountKey)
    add(record.accountIdentity)
    for identity, enabled in pairs(record.legacyAccountIdentities or {}) do
        if enabled == true then add(identity) end
    end
    return result
end

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

local function mergeListByID(target, source)
    local byID = {}
    for _, item in ipairs(target or {}) do
        if item.id then byID[item.id] = item end
    end
    for _, item in ipairs(source or {}) do
        if item.id and (not byID[item.id]
            or (tonumber(item.lastUpdatedAt or item.editedAt or item.createdAt) or 0)
                > (tonumber(byID[item.id].lastUpdatedAt
                    or byID[item.id].editedAt or byID[item.id].createdAt) or 0))
        then
            byID[item.id] = copy(item)
        end
    end
    local result = {}
    for _, item in pairs(byID) do result[#result + 1] = item end
    table.sort(result, function(a, b)
        local aa = tonumber(a.createdAt) or 0
        local bb = tonumber(b.createdAt) or 0
        if aa ~= bb then return aa < bb end
        return tostring(a.id) < tostring(b.id)
    end)
    return result
end

local function mergeKnowledge(canonical, candidates)
    local service = PNC.NPCKnowledge
    if not service then return end
    service.EnsureLoaded()
    local registry = service.Registry
    local destination = registry.byCharacter[canonical.uuid] or { byNPC = {} }
    registry.byCharacter[canonical.uuid] = destination
    for _, sourceRecord in ipairs(candidates) do
        local source = registry.byCharacter[sourceRecord.uuid]
        for npcID, note in pairs(source and source.byNPC or {}) do
            local target = destination.byNPC[npcID]
            if not target then
                destination.byNPC[npcID] = copy(note)
            else
                local firstA, firstB = tonumber(target.firstMetAt) or 0,
                    tonumber(note.firstMetAt) or 0
                if firstA == 0 or (firstB > 0 and firstB < firstA) then
                    target.firstMetAt = firstB
                end
                target.lastInteractionAt = math.max(
                    tonumber(target.lastInteractionAt) or 0,
                    tonumber(note.lastInteractionAt) or 0
                )
                for descriptorID, fact in pairs(note.discovered or {}) do
                    local current = target.discovered[descriptorID]
                    if not current or (tonumber(fact.lastUpdatedAt) or 0)
                        > (tonumber(current.lastUpdatedAt) or 0)
                    then target.discovered[descriptorID] = copy(fact) end
                end
                target.evidence = mergeListByID(target.evidence, note.evidence)
                target.journalEntries = mergeListByID(
                    target.journalEntries, note.journalEntries
                )
                target.manualNotes = mergeListByID(
                    target.manualNotes, note.manualNotes
                )
                target.revision = math.max(
                    tonumber(target.revision) or 0,
                    tonumber(note.revision) or 0
                ) + 1
            end
        end
    end
    service.Registry = service.NormalizeRegistry(registry)
    service.Registry.revision = (tonumber(service.Registry.revision) or 0) + 1
    service.Dirty = true
end

local function replaceKey(value, oldKeys, canonicalKey)
    return type(value) == "string" and oldKeys[value] and canonicalKey or value
end

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

local function mergeConduct(canonical, candidates, canonicalKey, oldKeys, at)
    local merged = copy(canonical.conduct or {})
    merged.evidence = merged.evidence or {}
    local selectedProfile = canonical.socialProfile
    for _, record in ipairs(candidates) do
        merged.evidence = mergeListByID(
            merged.evidence, record.conduct and record.conduct.evidence
        )
        local recentSet = {}
        for _, id in ipairs(merged.recentEvidenceIDs or {}) do
            recentSet[tostring(id)] = true
        end
        for _, id in ipairs(record.conduct
            and record.conduct.recentEvidenceIDs or {}) do
            recentSet[tostring(id)] = true
        end
        merged.recentEvidenceIDs = {}
        for id in pairs(recentSet) do
            merged.recentEvidenceIDs[#merged.recentEvidenceIDs + 1] = id
        end
        table.sort(merged.recentEvidenceIDs)
        merged.revision = math.max(
            tonumber(merged.revision) or 0,
            tonumber(record.conduct and record.conduct.revision) or 0
        )
        if record.socialProfile and (
            not selectedProfile
            or (tonumber(record.socialProfile.revision) or 0)
                > (tonumber(selectedProfile.revision) or 0)
        ) then
            selectedProfile = record.socialProfile
        end
    end
    for _, evidence in ipairs(merged.evidence) do
        evidence.actorKey = replaceKey(
            evidence.actorKey, oldKeys, canonicalKey
        )
        evidence.subjectKey = replaceKey(
            evidence.subjectKey, oldKeys, canonicalKey
        )
    end
    if PNC.ConductMath and PNC.ConductMath.Recalculate then
        merged = PNC.ConductMath.Recalculate(merged, at) or merged
    end
    canonical.conduct = merged
    canonical.socialProfile = copy(selectedProfile)
end

local function mergeFactions(canonicalKey, oldKeys)
    local service = PNC.Factions
    if not service or not service.Registry then return end
    service.EnsureLoaded()
    local factions = service.Registry.byID or {}
    local owned = {}
    for id, faction in pairs(factions) do
        local relevant = oldKeys[faction.ownerPlayerKey] == true
        for key in pairs(faction.playerMemberKeys or {}) do
            if oldKeys[key] then relevant = true end
        end
        if relevant then owned[#owned + 1] = faction end
        local pacifications = faction.playerPacifications or {}
        local selected
        for key, entry in pairs(pacifications) do
            if oldKeys[key] then
                if not selected or (tonumber(entry.revision) or 0)
                    > (tonumber(selected.revision) or 0) then selected = entry end
                pacifications[key] = nil
            end
        end
        if selected then pacifications[canonicalKey] = selected end
    end
    table.sort(owned, function(a, b)
        local ac, bc = 0, 0
        for _ in pairs(a.memberIDs or {}) do ac = ac + 1 end
        for _ in pairs(b.memberIDs or {}) do bc = bc + 1 end
        if ac ~= bc then return ac > bc end
        return (tonumber(a.revision) or 0) > (tonumber(b.revision) or 0)
    end)
    local chosen = owned[1]
    local supersededFactions = {}
    if chosen then
        chosen.playerMemberKeys = { [canonicalKey] = true }
        chosen.ownerPlayerKey = canonicalKey
        for index = 2, #owned do
            local duplicate = owned[index]
            for npcID in pairs(duplicate.memberIDs or {}) do
                chosen.memberIDs[npcID] = true
                local npc = PNC.Registry and PNC.Registry.Get
                    and PNC.Registry.Get(npcID)
                if npc and npc.affiliation then
                    npc.affiliation.factionID = chosen.id
                    PNC.Registry.MarkDirty(npc, "affiliation")
                end
            end
            for targetID, relation in pairs(duplicate.relations or {}) do
                local current = chosen.relations[targetID]
                if not current or (tonumber(relation.revision) or 0)
                    > (tonumber(current.revision) or 0)
                then chosen.relations[targetID] = copy(relation) end
            end
            duplicate.status = "archived"
            duplicate.archivedAt = atNow()
            duplicate.ownerPlayerKey = nil
            duplicate.playerMemberKeys = {}
            duplicate.memberIDs = {}
            duplicate.tags = duplicate.tags or {}
            duplicate.tags.supersededBy = chosen.id
            supersededFactions[duplicate.id] = chosen.id
            duplicate.revision = (tonumber(duplicate.revision) or 0) + 1
        end
        chosen.revision = (tonumber(chosen.revision) or 0) + 1
    end
    for _, faction in pairs(factions) do
        for duplicateID, canonicalID in pairs(supersededFactions) do
            local relation = faction.relations
                and faction.relations[duplicateID] or nil
            if relation and faction.id ~= canonicalID then
                local current = faction.relations[canonicalID]
                if not current or (tonumber(relation.revision) or 0)
                    > (tonumber(current.revision) or 0)
                then faction.relations[canonicalID] = relation end
                faction.relations[duplicateID] = nil
                faction.revision = (tonumber(faction.revision) or 0) + 1
            end
        end
        if chosen and faction.relations then
            faction.relations[faction.id] = nil
        end
    end
    service.Dirty = #owned > 0 or service.Dirty
    if service.RebuildIndexes then service.RebuildIndexes() end
    local communities = PNC.Communities
    if communities and communities.Registry then
        communities.EnsureLoaded()
        local changed = false
        for _, community in pairs(communities.Registry.byID or {}) do
            local replacement = supersededFactions[community.factionID]
            if replacement then
                community.factionID = replacement
                community.revision = (tonumber(community.revision) or 0) + 1
                changed = true
            end
        end
        for _, site in pairs(communities.Registry.sitesByID or {}) do
            if oldKeys[site.claimantKey] then
                site.claimantKey = canonicalKey
                site.revision = (tonumber(site.revision) or 0) + 1
                changed = true
            end
        end
        communities.Dirty = changed or communities.Dirty
    end
end

local function backupOnce(candidates)
    if not ModData or not ModData.getOrCreate then return end
    local target = ModData.getOrCreate(Constants.MIGRATION_BACKUP_MODDATA_KEY)
    if target.created ~= true then
        target.created = true
        target.sourceSchemaVersion = 3
        target.registry = copy(
            Characters.PendingLegacyBackup or Characters.Registry
        )
        target.knowledgeByCharacter = {}
        for _, record in ipairs(candidates or {}) do
            local notes = PNC.NPCKnowledge and PNC.NPCKnowledge.Registry
                and PNC.NPCKnowledge.Registry.byCharacter
                and PNC.NPCKnowledge.Registry.byCharacter[record.uuid]
            if notes then
                target.knowledgeByCharacter[record.uuid] = copy(notes)
            end
        end
        target.factionRegistry = copy(
            PNC.Factions and PNC.Factions.Registry or {}
        )
        target.affectedNPCSocial = {}
        if PNC.Registry and PNC.Registry.ForEach then
            PNC.Registry.ForEach(function(npc)
                local affected = false
                for _, record in ipairs(candidates or {}) do
                    for key in pairs(keyVariants(record)) do
                        if npc.social and npc.social.relationships
                            and npc.social.relationships[key]
                        then affected = true end
                    end
                end
                if affected then
                    target.affectedNPCSocial[tostring(npc.id)] =
                        copy(npc.social)
                end
            end)
        end
    end
end

function Migration.RunForPlayer(player, accountKey, at)
    Characters.EnsureLoaded()
    local state = Characters.Registry.migration or {}
    if state.status == "complete" then
        return state.canonicalUUID, "already_migrated"
    end
    if type(accountKey) ~= "string"
        or string.sub(accountKey, 1, 8) ~= "sp_slot_"
    then
        return nil, "not_singleplayer"
    end
    if PNC.NPCKnowledge and PNC.NPCKnowledge.EnsureLoaded then
        PNC.NPCKnowledge.EnsureLoaded()
    end
    if PNC.Factions and PNC.Factions.EnsureLoaded then PNC.Factions.EnsureLoaded() end

    local candidates = collectCandidates(player)
    if #candidates == 0 then
        local active = 0
        for _, record in pairs(Characters.Registry.byUUID or {}) do
            if record.status == Constants.STATUS_ACTIVE then active = active + 1 end
        end
        if active > 0 then
            state.status = "ambiguous"
            state.diagnostic = "active_survivor_descriptor_conflict"
            state.revision = (tonumber(state.revision) or 0) + 1
            Characters.Registry.migration = state
            Characters.Dirty = true
            return nil, "identity_ambiguous"
        end
        return nil, "no_legacy_candidate"
    end
    local canonical, selectedBy = chooseCanonical(player, candidates)
    if not canonical then
        state.status = "ambiguous"
        state.diagnostic = "no_safe_canonical_candidate"
        Characters.Registry.migration = state
        Characters.Dirty = true
        return nil, "identity_ambiguous"
    end
    backupOnce(candidates)
    local canonicalKey = EntityRef.ForPlayerIdentity(accountKey, canonical.uuid)
    local oldKeys = mergeRelationships(
        canonicalKey, candidates, atNow(at)
    ) or {}
    mergeKnowledge(canonical, candidates)
    mergeConduct(canonical, candidates, canonicalKey, oldKeys, atNow(at))
    mergeFactions(canonicalKey, oldKeys)

    canonical.accountKey = accountKey
    canonical.accountIdentity = accountKey
    canonical.legacyAccountIdentities = canonical.legacyAccountIdentities or {}
    for _, record in ipairs(candidates) do
        canonical.legacyAccountIdentities[record.accountIdentity] = true
        canonical.legacyAccountIdentities[record.accountKey] = true
        if record.uuid ~= canonical.uuid then
            record.status = Constants.STATUS_RETIRED
            record.retiredAt = atNow(at)
            record.supersededBy = canonical.uuid
            record.revision = (tonumber(record.revision) or 0) + 1
            Characters.Registry.uuidAliases[record.uuid] = canonical.uuid
        end
    end
    canonical.revision = (tonumber(canonical.revision) or 0) + 1
    Characters.Registry.revision = (tonumber(Characters.Registry.revision) or 0) + 1
    Characters.Registry.migration = {
        revision = (tonumber(state.revision) or 0) + 1,
        status = "complete",
        completedAt = atNow(at),
        canonicalUUID = canonical.uuid,
        diagnostic = "merged_" .. tostring(#candidates)
            .. "_selected_by_" .. selectedBy,
    }
    Characters.Registry = Types.NormalizeRegistry(Characters.Registry)
    Characters.Dirty = true
    if PNC.PersistenceCoordinator and PNC.PersistenceCoordinator.Commit then
        local committed, reason = PNC.PersistenceCoordinator.Commit(
            "identity_v4_migration"
        )
        if not committed then return nil, reason end
    end
    return canonical.uuid, "migrated"
end

return Migration
