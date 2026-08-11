-- Server-authoritative persistent faction identity and NPC affiliation.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.Factions = PNC.Factions or {}

local Factions = PNC.Factions
local Core = PNC.Core
local Constants = PNC.FactionConstants
local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef

Factions.Registry = Factions.Registry
    or Types.NewFactionRegistry()
Factions.Loaded = Factions.Loaded or false
Factions.Dirty = Factions.Dirty or false
Factions.IDGenerator = Factions.IDGenerator
    or function()
        return Core.GenerateID("faction")
    end

local function authority()
    return Core and Core.IsAuthority
        and Core.IsAuthority() == true
end

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function assignTable(target, source)
    for key, _ in pairs(target) do target[key] = nil end
    for key, value in pairs(source) do target[key] = value end
end

local function finiteTimestamp(value, fallback)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
        or value < 0
    then
        value = tonumber(fallback) or 0
    end
    return math.max(0, value)
end

local function registryRecord(factionID)
    return Types.IsValidFactionID(factionID)
        and Factions.Registry.byID[factionID] or nil
end

local function isProvisionalFaction(faction)
    return type(faction) == "table"
        and type(faction.tags) == "table"
        and faction.tags.provisionalPlayerFaction == true
end

local retireProvisionalFaction

local function npcRecord(npcID, allowDead)
    local record = Types.IsValidNPCID(npcID)
        and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcID) or nil
    if not record then return nil, "npc_not_found" end
    if not allowDead and record.alive == false then
        return nil, "npc_not_living"
    end
    return record
end

local function touchFaction(faction)
    faction.revision = math.max(
        0,
        math.floor(tonumber(faction.revision) or 0)
    ) + 1
end

local function touchRegistry()
    Factions.Registry.revision = math.max(
        0,
        math.floor(tonumber(Factions.Registry.revision) or 0)
    ) + 1
    Factions.Dirty = true
end

local function commitAffiliation(record, affiliation)
    affiliation.revision = math.max(
        0,
        math.floor(tonumber(
            record.affiliation and record.affiliation.revision
        ) or 0)
    ) + 1
    record.affiliation = affiliation
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "affiliation")
    end
end

local function addHistory(affiliation, factionID, at, reason)
    affiliation = Types.AppendFormerFaction(
        affiliation,
        factionID,
        at,
        reason
    )
    return affiliation.formerFactionIDs
end

local function affiliationFor(record, faction)
    return Types.NormalizeAffiliation(
        record and record.affiliation,
        faction
    )
end

local function normalizeRole(faction, requested)
    local role = requested
        or Archetypes.GetDefaultRole(faction.archetypeID)
    if not Types.IsValidFactionRole(role)
        or not Archetypes.IsRoleAllowed(
            faction.archetypeID,
            role
        )
    then
        return nil, "role_not_allowed"
    end
    return role
end

local function normalizeRank(value)
    value = value or "member"
    if not Types.IsValidFactionRank(value) then
        return nil, "invalid_rank"
    end
    return value
end

local function normalizeMembershipStatus(value)
    value = value or "member"
    if not Types.IsValidMembershipStatus(value)
        or value == "unaffiliated"
    then
        return nil, "invalid_membership_status"
    end
    return value
end

local function rebuildIndexes()
    local byArchetype = {}
    local byPlayerKey = {}
    local membersByFaction = {}
    local changed = false
    for factionID, faction in pairs(Factions.Registry.byID) do
        byArchetype[faction.archetypeID] =
            byArchetype[faction.archetypeID] or {}
        byArchetype[faction.archetypeID][factionID] = true
        membersByFaction[factionID] = {}
        for playerKey, _ in pairs(
            faction.playerMemberKeys or {}
        ) do
            if not byPlayerKey[playerKey] then
                byPlayerKey[playerKey] = factionID
            else
                faction.playerMemberKeys[playerKey] = nil
                if faction.ownerPlayerKey == playerKey then
                    faction.ownerPlayerKey = nil
                end
                changed = true
            end
        end
        if faction.ownerPlayerKey
            and faction.playerMemberKeys[
                faction.ownerPlayerKey
            ] ~= true
        then
            faction.ownerPlayerKey = nil
            changed = true
        end
    end
    local treatyPairs = {}
    for sourceID, faction in pairs(
        Factions.Registry.byID
    ) do
        for targetID, relation in pairs(
            faction.relations or {}
        ) do
            if relation.atWar == true
                or relation.allied == true
                or (tonumber(relation.truceUntil) or 0) > 0
            then
                local pairKey = Types.MakeDiplomacyKey(
                    sourceID,
                    targetID
                )
                if pairKey then treatyPairs[pairKey] = true end
            end
        end
    end
    for pairKey, _ in pairs(treatyPairs) do
        local firstID, secondID =
            string.match(pairKey, "^([^|]+)|([^|]+)$")
        local first = Factions.Registry.byID[firstID]
        local second = Factions.Registry.byID[secondID]
        if first and second then
            local firstRelation = Types.NormalizeRelation(
                first.relations[secondID],
                firstID,
                secondID
            )
            local secondRelation = Types.NormalizeRelation(
                second.relations[firstID],
                secondID,
                firstID
            )
            local active = first.status == "active"
                and second.status == "active"
            local atWar = active and (
                firstRelation.atWar == true
                or secondRelation.atWar == true
            )
            local allied = active and not atWar and (
                firstRelation.allied == true
                or secondRelation.allied == true
            )
            local truceUntil = active and not atWar
                and not allied and math.max(
                    tonumber(firstRelation.truceUntil) or 0,
                    tonumber(secondRelation.truceUntil) or 0
                ) or 0
            firstRelation.atWar = atWar
            secondRelation.atWar = atWar
            firstRelation.allied = allied
            secondRelation.allied = allied
            firstRelation.truceUntil = truceUntil
            secondRelation.truceUntil = truceUntil
            firstRelation.state =
                PNC.FactionDiplomacyMath.ResolveState(
                    firstRelation,
                    firstRelation.lastEvaluatedAt
                )
            secondRelation.state =
                PNC.FactionDiplomacyMath.ResolveState(
                    secondRelation,
                    secondRelation.lastEvaluatedAt
                )
            if not Types.AreEqual(
                first.relations[secondID],
                firstRelation
            ) then
                first.relations[secondID] = firstRelation
                changed = true
            end
            if not Types.AreEqual(
                second.relations[firstID],
                secondRelation
            ) then
                second.relations[firstID] = secondRelation
                changed = true
            end
        end
    end
    for npcID, record in pairs(
        PNC.Registry and PNC.Registry.Data or {}
    ) do
        local affiliation = Types.NormalizeAffiliation(
            record.affiliation
        )
        local faction = affiliation.factionID
            and Factions.Registry.byID[affiliation.factionID]
            or nil
        if affiliation.factionID and (
            not faction
            or faction.status == "archived"
            or faction.status == "destroyed"
        ) then
            local former = addHistory(
                affiliation,
                affiliation.factionID,
                math.max(
                    tonumber(affiliation.leftAt) or 0,
                    tonumber(affiliation.joinedAt) or 0
                ),
                faction and faction.status == "destroyed"
                    and "faction_destroyed"
                    or faction and "faction_archived"
                    or "unknown"
            )
            affiliation = Types.NewAffiliation({
                leftAt = affiliation.leftAt,
                formerFactionIDs = former,
                revision = affiliation.revision,
            })
        elseif faction then
            affiliation = Types.NormalizeAffiliation(
                affiliation,
                faction
            )
        end
        if not Types.AreEqual(record.affiliation, affiliation) then
            record.affiliation = affiliation
            if PNC.Registry and PNC.Registry.MarkDirty then
                PNC.Registry.MarkDirty(
                    record,
                    "affiliation_repair"
                )
            end
            changed = true
        end
        if affiliation.factionID
            and membersByFaction[affiliation.factionID]
        then
            membersByFaction[affiliation.factionID][npcID] = true
        end
    end
    for factionID, faction in pairs(Factions.Registry.byID) do
        local expected = membersByFaction[factionID] or {}
        if not Types.AreEqual(faction.memberIDs, expected) then
            faction.memberIDs = expected
            changed = true
        end
        if faction.leaderNPCID then
            local leader = PNC.Registry.Data[
                faction.leaderNPCID
            ]
            if not expected[faction.leaderNPCID]
                or not leader
                or leader.alive == false
            then
                faction.leaderNPCID = nil
                changed = true
            end
        end
    end
    if not Types.AreEqual(
        Factions.Registry.byArchetype,
        byArchetype
    ) then
        Factions.Registry.byArchetype = byArchetype
        changed = true
    end
    if not Types.AreEqual(
        Factions.Registry.byPlayerKey,
        byPlayerKey
    ) then
        Factions.Registry.byPlayerKey = byPlayerKey
        changed = true
    end
    if changed then Factions.Dirty = true end
    return changed
end

function Factions.Load()
    local raw
    local normalized
    if not authority() then return false, "not_authority" end
    if PNC.Registry and PNC.Registry.EnsureLoaded then
        PNC.Registry.EnsureLoaded()
    end
    raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Constants.REGISTRY_MODDATA_KEY)
        or {}
    normalized = Types.NormalizeFactionRegistry(raw)
    Factions.Registry = normalized
    Factions.Loaded = true
    Factions.Dirty = not Types.AreEqual(raw, normalized)
    rebuildIndexes()
    if Factions.ReconcilePlayerMemberships then
        Factions.ReconcilePlayerMemberships(
            getGameTime and getGameTime()
                and getGameTime().getWorldAgeHours
                and getGameTime():getWorldAgeHours() or 0
        )
    end
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileAll
    then
        PNC.FactionBehavior.ReconcileAll("registry_load")
    end
    return true, Factions.Dirty
end

function Factions.EnsureLoaded()
    if not Factions.Loaded then return Factions.Load() end
    return true
end

function Factions.Save()
    local target
    local normalized
    Factions.EnsureLoaded()
    if not Factions.Dirty then return false, "not_dirty" end
    target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Constants.REGISTRY_MODDATA_KEY)
        or nil
    if not target then return false, "moddata_unavailable" end
    normalized = Types.NormalizeFactionRegistry(Factions.Registry)
    assignTable(target, copy(normalized))
    Factions.Registry = normalized
    Factions.Dirty = false
    return true, "saved"
end

function Factions.RebuildIndexes()
    Factions.EnsureLoaded()
    return rebuildIndexes()
end

function Factions.GenerateID()
    Factions.EnsureLoaded()
    for _ = 1, Constants.ID_GENERATION_RETRIES do
        local candidate = Factions.IDGenerator()
        if Types.IsValidFactionID(candidate)
            and not Factions.Registry.byID[candidate]
        then
            return candidate
        end
    end
    return nil, "id_generation_failed"
end

function Factions.Get(factionID)
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    return faction and copy(faction) or nil,
        faction and nil or "faction_not_found"
end

function Factions.GetPresentation(factionID)
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return nil, "faction_not_found" end
    return {
        id = faction.id,
        name = faction.name,
        archetypeID = faction.archetypeID,
        status = faction.status,
        emblem = copy(faction.emblem),
    }
end

function Factions.List(options)
    local output = {}
    options = type(options) == "table" and options or {}
    Factions.EnsureLoaded()
    for _, faction in pairs(Factions.Registry.byID) do
        if options.includeProvisional == true
            or not isProvisionalFaction(faction)
        then
            output[#output + 1] = copy(faction)
        end
    end
    table.sort(output, function(left, right)
        if left.name ~= right.name then return left.name < right.name end
        return left.id < right.id
    end)
    return output
end

function Factions.GetByArchetype(archetypeID)
    local output = {}
    Factions.EnsureLoaded()
    if not Archetypes.Exists(archetypeID) then
        return output, "unknown_archetype"
    end
    for factionID, _ in pairs(
        Factions.Registry.byArchetype[archetypeID] or {}
    ) do
        if Factions.Registry.byID[factionID]
            and not isProvisionalFaction(
                Factions.Registry.byID[factionID]
            )
        then
            output[#output + 1] =
                copy(Factions.Registry.byID[factionID])
        end
    end
    table.sort(output, function(left, right)
        return left.id < right.id
    end)
    return output
end

function Factions.GetNPCAffiliation(npcID)
    Factions.EnsureLoaded()
    local record, reason = npcRecord(npcID, true)
    if not record then return nil, reason end
    return copy(Types.NormalizeAffiliation(
        record.affiliation,
        record.affiliation and record.affiliation.factionID
            and registryRecord(record.affiliation.factionID)
            or nil
    ))
end

function Factions.GetNPCFaction(npcID)
    local affiliation, reason =
        Factions.GetNPCAffiliation(npcID)
    if not affiliation then return nil, reason end
    if not affiliation.factionID then
        return nil, "unaffiliated"
    end
    return Factions.Get(affiliation.factionID)
end

function Factions.IsMember(factionID, npcID)
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return false end
    local record = npcRecord(npcID, true)
    return record ~= nil
        and record.affiliation ~= nil
        and record.affiliation.factionID == factionID
end

function Factions.GetMembers(factionID)
    local output = {}
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return output, "faction_not_found" end
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry.Get(npcID)
        if record then
            output[#output + 1] = {
                npcID = npcID,
                name = tostring(record.name or npcID),
                alive = record.alive ~= false,
                affiliation = copy(record.affiliation),
            }
        end
    end
    table.sort(output, function(left, right)
        return left.npcID < right.npcID
    end)
    return output
end

function Factions.GetLeader(factionID)
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return nil, "faction_not_found" end
    if not faction.leaderNPCID then return nil, "no_leader" end
    local record = PNC.Registry.Get(faction.leaderNPCID)
    if not record then return nil, "leader_not_found" end
    return {
        npcID = record.id,
        name = tostring(record.name or record.id),
        alive = record.alive ~= false,
        affiliation = copy(record.affiliation),
    }
end

function Factions.GetArchetype(archetypeID)
    return Archetypes.Get(archetypeID)
end

function Factions.GetAllowedRoles(archetypeID)
    local archetype = Archetypes.Get(archetypeID)
    return archetype and copy(archetype.allowedRoles)
        or nil, archetype and nil or "unknown_archetype"
end

function Factions.GetOrganizationalFactionID(record)
    return type(record) == "table"
        and record.affiliation
        and record.affiliation.factionID
        or nil
end

function Factions.GetLegacyFactionClass(record)
    -- Compatibility facade. Phase 5B derives this tactical classification
    -- through the centralized faction behavior bridge.
    return type(record) == "table" and record.faction or nil
end

function Factions.Create(spec)
    local id
    local faction
    local leader
    local leaderAffiliation
    local createdAt
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    spec = type(spec) == "table" and spec or {}
    if not Archetypes.Exists(spec.archetypeID) then
        return false, "unknown_archetype"
    end
    id = Factions.GenerateID()
    if not id then return false, "id_generation_failed" end
    createdAt = finiteTimestamp(spec.createdAt, 0)
    faction = Types.NewFaction({
        id = id,
        name = spec.name,
        archetypeID = spec.archetypeID,
        status = "active",
        createdAt = createdAt,
        archivedAt = 0,
        tags = Types.NormalizeTags(spec.tags),
        ownerPlayerKey = spec.ownerPlayerKey,
        playerMemberKeys = spec.playerMemberKeys,
        policy = spec.policy,
        emblem = spec.emblem,
        revision = 1,
    })
    if not faction then return false, "invalid_name" end
    for playerKey, _ in pairs(
        faction.playerMemberKeys or {}
    ) do
        if Factions.Registry.byPlayerKey[playerKey] then
            return false, "player_already_affiliated"
        end
    end
    if spec.ownerPlayerKey ~= nil then
        if not EntityRef.IsPlayer(spec.ownerPlayerKey) then
            return false, "invalid_player_key"
        end
        faction.ownerPlayerKey = spec.ownerPlayerKey
        faction.playerMemberKeys[spec.ownerPlayerKey] = true
    end
    if spec.leaderNPCID ~= nil then
        leader = npcRecord(spec.leaderNPCID, false)
        if not leader then return false, "leader_not_found" end
        leaderAffiliation = Types.NormalizeAffiliation(
            leader.affiliation
        )
        if leaderAffiliation.factionID then
            return false, "npc_already_affiliated"
        end
        leaderAffiliation = Types.NormalizeAffiliation({
            factionID = id,
            membershipStatus = "member",
            role = "leader",
            rank = "leader",
            joinedAt = createdAt,
            originArchetypeID = faction.archetypeID,
            formerFactionIDs =
                leaderAffiliation.formerFactionIDs,
            revision = leaderAffiliation.revision,
        }, faction)
        faction.leaderNPCID = leader.id
        faction.memberIDs[leader.id] = true
    end
    Factions.Registry.byID[id] = faction
    Factions.Registry.byArchetype[faction.archetypeID] =
        Factions.Registry.byArchetype[faction.archetypeID] or {}
    Factions.Registry.byArchetype[faction.archetypeID][id] = true
    for playerKey, _ in pairs(
        faction.playerMemberKeys or {}
    ) do
        Factions.Registry.byPlayerKey[playerKey] = id
    end
    if leader then commitAffiliation(leader, leaderAffiliation) end
    touchRegistry()
    if leader and PNC.FactionBehavior
        and PNC.FactionBehavior.ApplyNPC
    then
        PNC.FactionBehavior.ApplyNPC(
            leader,
            "faction_created"
        )
    end
    return true, "created", copy(faction)
end

function Factions.SetName(factionID, value)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    local name = type(value) == "string"
        and string.match(value, "^%s*(.-)%s*$") or nil
    if not name or name == "" or #name > Constants.NAME_MAX_LENGTH then
        return false, "invalid_name"
    end
    if faction.name == name then return false, "unchanged", copy(faction) end
    faction.name = name
    touchFaction(faction)
    touchRegistry()
    return true, "renamed", copy(faction)
end

function Factions.MergeTags(factionID, values)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    local merged = copy(faction.tags or {})
    for key, value in pairs(type(values) == "table" and values or {}) do
        merged[key] = value
    end
    merged = Types.NormalizeTags(merged)
    if Types.AreEqual(faction.tags, merged) then
        return false, "unchanged", copy(faction)
    end
    faction.tags = merged
    touchFaction(faction)
    touchRegistry()
    return true, "tags_merged", copy(faction)
end

function Factions.AddNPC(factionID, npcID, options)
    local faction
    local record
    local affiliation
    local role
    local rank
    local membershipStatus
    local at
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    options = type(options) == "table" and options or {}
    faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if faction.status ~= "active" then
        return false, "faction_not_active"
    end
    record = npcRecord(npcID, false)
    if not record then return false, "npc_not_found" end
    affiliation = affiliationFor(record)
    if affiliation.factionID
        and affiliation.factionID ~= factionID
    then
        return false, "npc_already_affiliated"
    end
    role = normalizeRole(faction, options.role)
    if not role then return false, "role_not_allowed" end
    rank = normalizeRank(options.rank)
    if not rank then return false, "invalid_rank" end
    membershipStatus =
        normalizeMembershipStatus(options.membershipStatus)
    if not membershipStatus then
        return false, "invalid_membership_status"
    end
    at = finiteTimestamp(options.joinedAt, 0)
    local nextAffiliation = Types.NormalizeAffiliation({
        factionID = factionID,
        membershipStatus = membershipStatus,
        role = role,
        rank = rank,
        joinedAt = affiliation.factionID
            and affiliation.joinedAt or at,
        originArchetypeID = affiliation.originArchetypeID
            or faction.archetypeID,
        communityID = affiliation.factionID == factionID
            and affiliation.communityID or nil,
        communityRole = affiliation.factionID == factionID
            and affiliation.communityRole or "resident",
        communityJoinedAt = affiliation.factionID == factionID
            and affiliation.communityJoinedAt or 0,
        formerFactionIDs = affiliation.formerFactionIDs,
        revision = affiliation.revision,
    }, faction)
    if Types.AreEqual(affiliation, nextAffiliation)
        and faction.memberIDs[npcID] == true
    then
        return false, "unchanged"
    end
    faction.memberIDs[npcID] = true
    commitAffiliation(record, nextAffiliation)
    touchFaction(faction)
    touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ApplyNPC
    then
        PNC.FactionBehavior.ApplyNPC(record, "faction_joined")
    end
    return true, "added", copy(nextAffiliation)
end

function Factions.RemoveNPC(
    factionID,
    npcID,
    reason,
    worldAgeHours
)
    local faction
    local record
    local affiliation
    local former
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    record = npcRecord(npcID, true)
    if not record then return false, "npc_not_found" end
    affiliation = affiliationFor(record, faction)
    if affiliation.factionID ~= factionID then
        return false, "not_a_member"
    end
    reason = Constants.VALID_LEAVE_REASONS[reason]
        and reason or "unknown"
    former = addHistory(
        affiliation,
        factionID,
        finiteTimestamp(worldAgeHours, affiliation.joinedAt),
        reason
    )
    local nextAffiliation = Types.NewAffiliation({
        leftAt = finiteTimestamp(
            worldAgeHours,
            affiliation.joinedAt
        ),
        originArchetypeID = affiliation.originArchetypeID,
        formerFactionIDs = former,
        revision = affiliation.revision,
    })
    if PNC.Communities
        and PNC.Communities.OnFactionMembershipChanging
    then
        PNC.Communities.OnFactionMembershipChanging(record)
    end
    faction.memberIDs[npcID] = nil
    if faction.leaderNPCID == npcID then
        faction.leaderNPCID = nil
    end
    commitAffiliation(record, nextAffiliation)
    touchFaction(faction)
    touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ApplyUnaffiliated
    then
        PNC.FactionBehavior.ApplyUnaffiliated(
            record,
            "faction_removed"
        )
    end
    if PNC.FactionLeadership
        and PNC.FactionLeadership.OnMemberDeparture
    then
        PNC.FactionLeadership.OnMemberDeparture(
            factionID,
            "member_removed",
            worldAgeHours
        )
    end
    return true, "removed", copy(nextAffiliation)
end

function Factions.TransferNPC(npcID, destinationFactionID, options)
    local destination
    local source
    local record
    local affiliation
    local former
    local role
    local rank
    local membershipStatus
    local at
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    options = type(options) == "table" and options or {}
    destination = registryRecord(destinationFactionID)
    if not destination then return false, "faction_not_found" end
    if destination.status ~= "active" then
        return false, "faction_not_active"
    end
    record = npcRecord(npcID, false)
    if not record then return false, "npc_not_found" end
    affiliation = affiliationFor(record)
    if affiliation.factionID == destinationFactionID then
        return false, "already_a_member"
    end
    source = affiliation.factionID
        and registryRecord(affiliation.factionID) or nil
    role = normalizeRole(destination, options.role)
    if not role then return false, "role_not_allowed" end
    rank = normalizeRank(options.rank)
    if not rank then return false, "invalid_rank" end
    membershipStatus =
        normalizeMembershipStatus(options.membershipStatus)
    if not membershipStatus then
        return false, "invalid_membership_status"
    end
    at = finiteTimestamp(options.worldAgeHours, 0)
    former = affiliation.formerFactionIDs
    if source then
        if PNC.Communities
            and PNC.Communities.OnFactionMembershipChanging
        then
            PNC.Communities.OnFactionMembershipChanging(record)
        end
        former = addHistory(
            affiliation,
            source.id,
            at,
            "transferred"
        )
        source.memberIDs[npcID] = nil
        if source.leaderNPCID == npcID then
            source.leaderNPCID = nil
        end
        touchFaction(source)
    end
    local nextAffiliation = Types.NormalizeAffiliation({
        factionID = destination.id,
        membershipStatus = membershipStatus,
        role = role,
        rank = rank,
        joinedAt = at,
        originArchetypeID = affiliation.originArchetypeID
            or destination.archetypeID,
        formerFactionIDs = former,
        revision = affiliation.revision,
    }, destination)
    destination.memberIDs[npcID] = true
    commitAffiliation(record, nextAffiliation)
    touchFaction(destination)
    touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ApplyNPC
    then
        PNC.FactionBehavior.ApplyNPC(
            record,
            "faction_transferred"
        )
    end
    if source and PNC.FactionLeadership
        and PNC.FactionLeadership.OnMemberDeparture
    then
        PNC.FactionLeadership.OnMemberDeparture(
            source.id,
            "member_transferred",
            at
        )
    end
    return true, "transferred", copy(nextAffiliation)
end

local function updateAffiliationField(npcID, field, value)
    local record = npcRecord(npcID, false)
    if not record then return false, "npc_not_found" end
    local affiliation = Types.NormalizeAffiliation(record.affiliation)
    local faction = affiliation.factionID
        and registryRecord(affiliation.factionID) or nil
    if not faction then return false, "unaffiliated" end
    local nextAffiliation = Types.NormalizeAffiliation(
        affiliation,
        faction
    )
    nextAffiliation[field] = value
    nextAffiliation = Types.NormalizeAffiliation(
        nextAffiliation,
        faction
    )
    if Types.AreEqual(affiliation, nextAffiliation) then
        return false, "unchanged"
    end
    commitAffiliation(record, nextAffiliation)
    touchFaction(faction)
    touchRegistry()
    return true, "updated", copy(nextAffiliation)
end

function Factions.SetNPCStatus(npcID, membershipStatus)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    membershipStatus =
        normalizeMembershipStatus(membershipStatus)
    if not membershipStatus then
        return false, "invalid_membership_status"
    end
    return updateAffiliationField(
        npcID,
        "membershipStatus",
        membershipStatus
    )
end

function Factions.SetNPCRole(npcID, role)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local affiliation = Factions.GetNPCAffiliation(npcID)
    local faction = affiliation and affiliation.factionID
        and registryRecord(affiliation.factionID) or nil
    if not faction then return false, "unaffiliated" end
    role = normalizeRole(faction, role)
    if not role then return false, "role_not_allowed" end
    return updateAffiliationField(npcID, "role", role)
end

function Factions.SetNPCRank(npcID, rank)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    rank = normalizeRank(rank)
    if not rank then return false, "invalid_rank" end
    return updateAffiliationField(npcID, "rank", rank)
end

function Factions.SetLeader(
    factionID,
    npcID,
    worldAgeHours,
    options
)
    local faction
    local record
    local affiliation
    local oldRecord
    local oldAffiliation
    local at
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    options = type(options) == "table" and options or {}
    faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if faction.status ~= "active" then
        return false, "faction_not_active"
    end
    record = npcRecord(npcID, false)
    if not record then return false, "npc_not_found" end
    affiliation = affiliationFor(record)
    at = finiteTimestamp(worldAgeHours, 0)
    if affiliation.factionID ~= factionID then
        if options.addIfMissing ~= true then
            return false, "leader_not_member"
        end
        if affiliation.factionID then
            return false, "npc_already_affiliated"
        end
        affiliation = Types.NormalizeAffiliation({
            factionID = factionID,
            membershipStatus = "member",
            role = "leader",
            rank = "leader",
            joinedAt = at,
            originArchetypeID = faction.archetypeID,
            formerFactionIDs =
                affiliation.formerFactionIDs,
            revision = affiliation.revision,
        }, faction)
        faction.memberIDs[npcID] = true
    else
        affiliation = Types.NormalizeAffiliation(
            affiliation,
            faction
        )
        affiliation.role = "leader"
        affiliation.rank = "leader"
    end
    if faction.leaderNPCID
        and faction.leaderNPCID ~= npcID
    then
        oldRecord = PNC.Registry.Get(faction.leaderNPCID)
        if oldRecord then
            oldAffiliation = affiliationFor(oldRecord, faction)
            oldAffiliation.rank = "member"
            if oldAffiliation.role == "leader" then
                oldAffiliation.role =
                    Archetypes.GetDefaultRole(
                        faction.archetypeID
                    )
            end
            commitAffiliation(oldRecord, oldAffiliation)
        end
    end
    if faction.leaderNPCID == npcID
        and record.affiliation
        and record.affiliation.role == "leader"
        and record.affiliation.rank == "leader"
    then
        return false, "unchanged"
    end
    faction.leaderNPCID = npcID
    commitAffiliation(record, affiliation)
    touchFaction(faction)
    touchRegistry()
    return true, "leader_set", copy(faction)
end

local function tracePlayerIdentity(
    callback,
    worldAgeHours,
    playerKey,
    resultReason
)
    if PNC.FactionTelemetry
        and PNC.FactionTelemetry.RecordAttribution
    then
        PNC.FactionTelemetry.RecordAttribution({
            operation = callback or "player_identity_resolution",
            worldAgeHours = worldAgeHours,
            actorKey = playerKey,
            result = playerKey and "resolved" or "rejected",
            reason = resultReason or (
                playerKey and "resolved"
                    or "actor_identity_missing"
            ),
        })
    end
end

local function playerKeyFor(player, callback, ensure)
    if not player or not PNC.PlayerCharacters then
        tracePlayerIdentity(
            callback, 0, nil, "actor_identity_missing"
        )
        return nil, "player_identity_unavailable"
    end
    if ensure ~= true then
        local context = PNC.PlayerContext and PNC.PlayerContext.Peek
            and PNC.PlayerContext.Peek(player) or nil
        local uuid = context and context.characterUUID
            or PNC.PlayerCharacters.GetCharacterUUID
                and PNC.PlayerCharacters.GetCharacterUUID(player) or nil
        local record = uuid and PNC.PlayerCharacters.Registry
            and PNC.PlayerCharacters.Registry.byUUID
            and PNC.PlayerCharacters.Registry.byUUID[uuid] or nil
        local key = context and context.entityKey
            or record and EntityRef.ForPlayerIdentity(
                record.accountKey or record.accountIdentity, uuid
            ) or nil
        local reason = key and "resolved"
            or uuid and "invalid_character_uuid"
            or "actor_identity_missing"
        tracePlayerIdentity(callback, 0, key, reason)
        return key, key and "resolved"
            or "player_identity_unavailable"
    end
    if not PNC.PlayerCharacters.GetEntityKey then
        return nil, "player_identity_unavailable"
    end
    local at = getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
        and getGameTime():getWorldAgeHours() or 0
    local key
    local reason
    key, reason = PNC.PlayerCharacters.GetEntityKey(player, {
        callback = callback or "faction",
        worldAgeHours = finiteTimestamp(at, 0),
    })
    tracePlayerIdentity(callback, at, key, reason)
    return key, reason
end

function Factions.GetFactionForPlayerKey(playerKey)
    Factions.EnsureLoaded()
    if not EntityRef.IsPlayer(playerKey) then
        return nil, "invalid_player_key"
    end
    local factionID = Factions.Registry.byPlayerKey[playerKey]
    if not factionID then return nil, "unaffiliated" end
    local faction = registryRecord(factionID)
    if isProvisionalFaction(faction) then
        return nil, "provisional_only"
    end
    return faction and copy(faction) or nil,
        faction and nil or "faction_not_found"
end

function Factions.GetDiplomacyFactionForPlayerKey(playerKey)
    Factions.EnsureLoaded()
    if not EntityRef.IsPlayer(playerKey) then
        return nil, "invalid_player_key"
    end
    local factionID = Factions.Registry.byPlayerKey[playerKey]
    if not factionID then return nil, "unaffiliated" end
    return Factions.Get(factionID)
end

function Factions.GetPlayerFaction(player)
    local playerKey, reason = playerKeyFor(
        player,
        "get_player_faction",
        false
    )
    if not playerKey then return nil, reason end
    return Factions.GetFactionForPlayerKey(playerKey)
end

function Factions.GetPlayerDiplomacyFaction(player)
    local playerKey, reason = playerKeyFor(
        player,
        "get_player_diplomacy_faction",
        false
    )
    if not playerKey then return nil, reason end
    return Factions.GetDiplomacyFactionForPlayerKey(playerKey)
end

function Factions.IsProvisionalPlayerFaction(factionOrID)
    local faction = type(factionOrID) == "table"
        and factionOrID or registryRecord(factionOrID)
    return isProvisionalFaction(faction)
end

function Factions.IsTerritorialTollFaction(factionOrID)
    local faction = type(factionOrID) == "table"
        and factionOrID or registryRecord(factionOrID)
    return type(faction) == "table"
        and faction.archetypeID == "looter"
        and type(faction.tags) == "table"
        and faction.tags.territorialToll == true
end

function Factions.MarkTerritorialTollFaction(factionID, reason)
    local faction
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if faction.archetypeID ~= "looter" then
        return false, "not_looter_faction"
    end
    if Factions.IsTerritorialTollFaction(faction) then
        return true, "unchanged", copy(faction)
    end
    faction.tags = faction.tags or {}
    faction.tags.settlementType = "looter_toll"
    faction.tags.territorialToll = true
    touchFaction(faction)
    touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            tostring(reason or "territorial_toll_enabled")
        )
    end
    return true, "territorial_toll_enabled", copy(faction)
end

function Factions.ReconcileTerritorialLooterFactions()
    if not authority() then return 0, "not_authority" end
    Factions.EnsureLoaded()
    if not PNC.Communities
        or not PNC.Communities.GetForFaction
    then
        return 0, "communities_unavailable"
    end
    local candidates = {}
    for factionID, faction in pairs(
        Factions.Registry.byID or {}
    ) do
        if faction.status == "active"
            and faction.archetypeID == "looter"
            and not Factions.IsTerritorialTollFaction(faction)
        then
            for _, community in ipairs(
                PNC.Communities.GetForFaction(factionID)
                    or {}
            ) do
                if community.status == "active"
                    and community.mode == "settled"
                then
                    candidates[#candidates + 1] = factionID
                    break
                end
            end
        end
    end
    table.sort(candidates)
    for _, factionID in ipairs(candidates) do
        Factions.MarkTerritorialTollFaction(
            factionID,
            "existing_looter_settlement_reconciled"
        )
    end
    return #candidates,
        #candidates > 0 and "reconciled" or "unchanged"
end

function Factions.IsMobileGroup(factionOrID)
    local faction = type(factionOrID) == "table"
        and factionOrID or registryRecord(factionOrID)
    return type(faction) == "table"
        and type(faction.mobile) == "table"
        and faction.mobile.active == true
end

function Factions.GetMobileGroup(factionID)
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return nil, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return nil, "not_mobile_group"
    end
    return copy(faction.mobile)
end

-- Canonical aggregate Need state for autonomous mobile groups. This stays on
-- the existing faction record so normal faction save/load owns persistence.
function Factions.GetNeeds(factionID)
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return nil, "faction_not_found" end
    return copy(faction.needs)
end

function Factions.SetNeeds(factionID, needs, reason)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then return false, "not_mobile_group" end
    local normalized = PNC.NeedsUtils and PNC.NeedsUtils.NormalizeState
        and PNC.NeedsUtils.NormalizeState(needs, 0) or nil
    if not normalized then return false, "needs_unavailable" end
    faction.needs = normalized
    touchFaction(faction)
    touchRegistry()
    return true, reason or "group_needs_updated", copy(faction.needs)
end

local function mobileArchetypeAllowed(faction)
    return faction and (
        faction.archetypeID == "looter"
        or faction.archetypeID == "trader"
        or faction.archetypeID == "refugee"
    )
end

function Factions.SetMobileGroup(factionID, spec, reason)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not mobileArchetypeAllowed(faction) then
        return false, "mobile_archetype_not_allowed"
    end
    local mobile = Types.NormalizeMobileGroup(spec)
    if not mobile then return false, "invalid_mobile_group" end
    if Types.AreEqual(faction.mobile, mobile) then
        return true, "unchanged", copy(faction.mobile)
    end
    faction.mobile = mobile
    faction.tags = faction.tags or {}
    faction.tags.mobileGroup = true
    faction.tags.mobilePathMode = mobile.pathMode
    touchFaction(faction)
    touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            tostring(reason or "mobile_group_updated")
        )
    end
    return true, "mobile_group_updated", copy(faction.mobile)
end

function Factions.UpdateMobileGroup(factionID, patch, reason)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return false, "not_mobile_group"
    end
    patch = type(patch) == "table" and patch or {}
    local candidate = copy(faction.mobile)
    for key, value in pairs(patch) do
        candidate[key] = copy(value)
    end
    return Factions.SetMobileGroup(
        factionID,
        candidate,
        reason or "mobile_group_updated"
    )
end

function Factions.ClearMobileGroup(factionID, reason)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return true, "unchanged", nil
    end
    faction.mobile = nil
    faction.tags = faction.tags or {}
    faction.tags.mobileGroup = false
    faction.tags.mobilePathMode = nil
    touchFaction(faction)
    touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            tostring(reason or "mobile_group_cleared")
        )
    end
    return true, "mobile_group_cleared", nil
end

local function playerCharacterRecord(playerKey)
    local parsed = EntityRef.Parse(playerKey)
    if not parsed or parsed.kind ~= "player"
        or not PNC.PlayerCharacters
    then
        return nil
    end
    if PNC.PlayerCharacters.EnsureLoaded then
        PNC.PlayerCharacters.EnsureLoaded()
    end
    return PNC.PlayerCharacters.Registry
        and PNC.PlayerCharacters.Registry.byUUID
        and PNC.PlayerCharacters.Registry.byUUID[
            parsed.characterUUID
        ] or nil
end

local function activePlayerMemberKeys(faction)
    local output = {}
    for playerKey, enabled in pairs(
        faction and faction.playerMemberKeys or {}
    ) do
        local record = enabled == true
            and playerCharacterRecord(playerKey) or nil
        if record and record.status == "active" then
            output[#output + 1] = playerKey
        end
    end
    table.sort(output)
    return output
end

local function membershipActorAllowed(faction, options)
    options = type(options) == "table" and options or {}
    if options.system == true then return true end
    return EntityRef.IsPlayer(options.actorKey)
        and faction.ownerPlayerKey == options.actorKey
end

function Factions.AddPlayerMember(
    factionID,
    playerKey,
    options
)
    local faction
    local character
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    options = type(options) == "table" and options or {}
    faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if faction.status ~= "active" then
        return false, "faction_not_active"
    end
    if not membershipActorAllowed(faction, options) then
        return false, "not_faction_owner"
    end
    if not EntityRef.IsPlayer(playerKey) then
        return false, "invalid_player_key"
    end
    character = playerCharacterRecord(playerKey)
    if not character then
        return false, "player_character_not_found"
    end
    if character.status ~= "active" then
        return false, "player_character_not_active"
    end
    if faction.playerMemberKeys[playerKey] == true then
        return false, "already_member"
    end
    local existingID = Factions.Registry.byPlayerKey[playerKey]
    if existingID then
        local existing = registryRecord(existingID)
        if not isProvisionalFaction(existing) then
            return false, "player_already_affiliated"
        end
        retireProvisionalFaction(
            existing,
            playerKey,
            options.worldAgeHours,
            "joined_player_faction"
        )
    end
    faction.playerMemberKeys[playerKey] = true
    Factions.Registry.byPlayerKey[playerKey] = faction.id
    touchFaction(faction)
    touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            "player_member_added"
        )
    end
    return true, "player_member_added", copy(faction)
end

function Factions.RemovePlayerMember(
    factionID,
    playerKey,
    options
)
    local faction
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    options = type(options) == "table" and options or {}
    faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not membershipActorAllowed(faction, options) then
        return false, "not_faction_owner"
    end
    if faction.playerMemberKeys[playerKey] ~= true then
        return false, "not_member"
    end
    if faction.ownerPlayerKey == playerKey
        and options.system ~= true
    then
        return false, "cannot_banish_faction_owner"
    end
    faction.playerMemberKeys[playerKey] = nil
    if Factions.Registry.byPlayerKey[playerKey] == faction.id then
        Factions.Registry.byPlayerKey[playerKey] = nil
    end
    if faction.ownerPlayerKey == playerKey then
        faction.ownerPlayerKey = nil
    end
    touchFaction(faction)
    touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            tostring(options.reason or "player_member_removed")
        )
    end
    return true, "player_member_removed", copy(faction)
end

function Factions.TransferPlayerLeadership(
    factionID,
    playerKey,
    options
)
    local faction
    local character
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    options = type(options) == "table" and options or {}
    faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not membershipActorAllowed(faction, options) then
        return false, "not_faction_owner"
    end
    if faction.playerMemberKeys[playerKey] ~= true then
        return false, "target_not_member"
    end
    character = playerCharacterRecord(playerKey)
    if not character or character.status ~= "active" then
        return false, "player_character_not_active"
    end
    if faction.ownerPlayerKey == playerKey then
        return false, "unchanged"
    end
    faction.ownerPlayerKey = playerKey
    touchFaction(faction)
    touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            tostring(options.reason or "leadership_transferred")
        )
    end
    return true, "leadership_transferred", copy(faction)
end

local function actorFaction(player, callback)
    local actorKey
    local reason
    local faction
    actorKey, reason = playerKeyFor(
        player,
        callback,
        true
    )
    if not actorKey then return nil, nil, reason end
    faction, reason = Factions.GetFactionForPlayerKey(actorKey)
    if not faction then return nil, actorKey, reason end
    return faction, actorKey
end

function Factions.AddPlayerToCurrentFaction(
    player,
    targetPlayerKey
)
    local faction, actorKey, reason = actorFaction(
        player,
        "add_player_faction_member"
    )
    if not faction then return false, reason end
    return Factions.AddPlayerMember(
        faction.id,
        targetPlayerKey,
        { actorKey = actorKey }
    )
end

function Factions.BanishPlayerFromCurrentFaction(
    player,
    targetPlayerKey,
    worldAgeHours
)
    local faction, actorKey, reason = actorFaction(
        player,
        "banish_player_faction_member"
    )
    if not faction then return false, reason end
    return Factions.RemovePlayerMember(
        faction.id,
        targetPlayerKey,
        {
            actorKey = actorKey,
            reason = "banished",
            worldAgeHours = worldAgeHours,
        }
    )
end

function Factions.TransferCurrentFactionLeadership(
    player,
    targetPlayerKey
)
    local faction, actorKey, reason = actorFaction(
        player,
        "transfer_player_faction_leadership"
    )
    if not faction then return false, reason end
    return Factions.TransferPlayerLeadership(
        faction.id,
        targetPlayerKey,
        {
            actorKey = actorKey,
            reason = "leader_transfer",
        }
    )
end

local function refugeeFactionName(faction)
    local base = tostring(faction.name or "Former Survivors")
    local stripped = string.match(base, "^(.-)%s+Survivors$")
    if stripped and stripped ~= "" then base = stripped end
    if not string.match(base, "%s+Refugees$") then
        base = base .. " Refugees"
    end
    base = string.sub(base, 1, Constants.NAME_MAX_LENGTH)
    for otherID, other in pairs(Factions.Registry.byID or {}) do
        if otherID ~= faction.id and other.name == base then
            local suffix = " " .. string.sub(faction.id, -6)
            base = string.sub(
                base,
                1,
                Constants.NAME_MAX_LENGTH - #suffix
            ) .. suffix
            break
        end
    end
    return base
end

local function endFactionTreaties(faction, at)
    local reconcileIDs = {}
    for otherID, relation in pairs(faction.relations or {}) do
        local other = registryRecord(otherID)
        local reverse = other and other.relations
            and other.relations[faction.id] or nil
        local changed = relation.atWar == true
            or relation.allied == true
            or (tonumber(relation.truceUntil) or 0) > 0
            or reverse and (
                reverse.atWar == true
                or reverse.allied == true
                or (tonumber(reverse.truceUntil) or 0) > 0
            )
        if changed then
            for _, item in ipairs({ relation, reverse }) do
                if item then
                    item.atWar = false
                    item.allied = false
                    item.truceUntil = 0
                    item.warEndedAt = at
                    item.state =
                        PNC.FactionDiplomacyMath.ResolveState(
                            item,
                            at
                        )
                    item.revision = math.max(
                        0,
                        math.floor(tonumber(item.revision) or 0)
                    ) + 1
                end
            end
            if other then touchFaction(other) end
            reconcileIDs[otherID] = true
        end
    end
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        for otherID, _ in pairs(reconcileIDs) do
            PNC.FactionBehavior.ReconcileFaction(
                otherID,
                "player_faction_disbanded"
            )
        end
    end
end

retireProvisionalFaction = function(
    faction,
    playerKey,
    worldAgeHours,
    reason
)
    if not isProvisionalFaction(faction) then
        return false, "not_provisional"
    end
    local at = finiteTimestamp(
        worldAgeHours,
        faction.createdAt
    )
    if EntityRef.IsPlayer(playerKey) then
        faction.playerMemberKeys[playerKey] = nil
        if Factions.Registry.byPlayerKey[playerKey]
            == faction.id
        then
            Factions.Registry.byPlayerKey[playerKey] = nil
        end
    end
    faction.ownerPlayerKey = nil
    faction.playerMemberKeys = {}
    faction.status = "archived"
    faction.archivedAt = at
    faction.tags = faction.tags or {}
    faction.tags.hiddenFromFactionLists = true
    faction.tags.provisionalRetired = true
    faction.tags.retiredReason = tostring(
        reason or "player_identity_ended"
    )
    endFactionTreaties(faction, at)
    touchFaction(faction)
    touchRegistry()
    return true, "provisional_retired", copy(faction)
end

local function convertPlayerFactionToRefugees(
    faction,
    formerOwnerKey,
    at
)
    local previousArchetypeID = faction.archetypeID
    local livingMembers = {}
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry.Get(npcID)
        if record and record.alive ~= false then
            livingMembers[#livingMembers + 1] = npcID
        end
    end
    table.sort(livingMembers)

    Factions.Registry.byArchetype[previousArchetypeID] =
        Factions.Registry.byArchetype[previousArchetypeID]
        or {}
    Factions.Registry.byArchetype[previousArchetypeID][
        faction.id
    ] = nil
    Factions.Registry.byArchetype.refugee =
        Factions.Registry.byArchetype.refugee or {}
    Factions.Registry.byArchetype.refugee[faction.id] = true

    faction.name = refugeeFactionName(faction)
    faction.archetypeID = "refugee"
    faction.policy = Types.NormalizePolicy(
        {},
        "refugee",
        faction.id
    )
    for playerKey, _ in pairs(
        faction.playerMemberKeys or {}
    ) do
        if Factions.Registry.byPlayerKey[playerKey]
            == faction.id
        then
            Factions.Registry.byPlayerKey[playerKey] = nil
        end
    end
    faction.ownerPlayerKey = nil
    faction.playerMemberKeys = {}
    faction.leaderNPCID = livingMembers[1]
    faction.tags = faction.tags or {}
    faction.tags.formerPlayerFaction = true
    faction.tags.disbandReason = "player_leadership_ended"
    if EntityRef.IsPlayer(formerOwnerKey) then
        faction.tags.formerOwnerKey = formerOwnerKey
    end
    endFactionTreaties(faction, at)

    for _, npcID in ipairs(livingMembers) do
        local record = PNC.Registry.Get(npcID)
        local affiliation = affiliationFor(record, faction)
        if npcID == faction.leaderNPCID then
            affiliation.role = "leader"
            affiliation.rank = "leader"
        else
            if not Archetypes.IsRoleAllowed(
                "refugee",
                affiliation.role
            ) then
                affiliation.role =
                    Archetypes.GetDefaultRole("refugee")
            end
            if affiliation.rank == "leader" then
                affiliation.rank = "member"
            end
        end
        commitAffiliation(
            record,
            Types.NormalizeAffiliation(affiliation, faction)
        )
    end

    touchFaction(faction)
    touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            faction.id,
            "player_faction_became_refugees"
        )
    end
    return true, "converted_to_refugees", copy(faction)
end

function Factions.HandlePlayerCharacterDeath(
    playerKey,
    worldAgeHours
)
    local factionID
    local faction
    local wasOwner
    local successors
    local at
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    if not EntityRef.IsPlayer(playerKey) then
        return false, "invalid_player_key"
    end
    factionID = Factions.Registry.byPlayerKey[playerKey]
    faction = factionID and registryRecord(factionID) or nil
    if not faction
        or faction.playerMemberKeys[playerKey] ~= true
    then
        return false, "player_not_affiliated"
    end
    at = finiteTimestamp(worldAgeHours, faction.createdAt)
    if isProvisionalFaction(faction) then
        return retireProvisionalFaction(
            faction,
            playerKey,
            at
        )
    end
    wasOwner = faction.ownerPlayerKey == playerKey
    faction.playerMemberKeys[playerKey] = nil
    Factions.Registry.byPlayerKey[playerKey] = nil

    if not wasOwner then
        touchFaction(faction)
        touchRegistry()
        return true, "dead_member_removed", copy(faction)
    end

    faction.ownerPlayerKey = nil
    successors = activePlayerMemberKeys(faction)
    if #successors > 0 then
        faction.ownerPlayerKey = successors[1]
        touchFaction(faction)
        touchRegistry()
        if PNC.FactionBehavior
            and PNC.FactionBehavior.ReconcileFaction
        then
            PNC.FactionBehavior.ReconcileFaction(
                faction.id,
                "player_leadership_succeeded"
            )
        end
        return true, "leadership_succeeded", copy(faction)
    end
    return convertPlayerFactionToRefugees(
        faction,
        playerKey,
        at
    )
end

function Factions.ReconcilePlayerMemberships(worldAgeHours)
    if not authority() then return 0, "not_authority" end
    if not Factions.Loaded then Factions.EnsureLoaded() end
    local removals = {}
    for factionID, faction in pairs(
        Factions.Registry.byID or {}
    ) do
        for playerKey, enabled in pairs(
            faction.playerMemberKeys or {}
        ) do
            local character = enabled == true
                and playerCharacterRecord(playerKey) or nil
            if character and (
                character.status == "dead"
                or character.status == "retired"
            ) then
                removals[#removals + 1] = {
                    factionID = factionID,
                    playerKey = playerKey,
                }
            end
        end
    end
    table.sort(removals, function(left, right)
        if left.factionID ~= right.factionID then
            return left.factionID < right.factionID
        end
        return left.playerKey < right.playerKey
    end)
    local changed = 0
    for _, item in ipairs(removals) do
        local ok = Factions.HandlePlayerCharacterDeath(
            item.playerKey,
            worldAgeHours
        )
        if ok then changed = changed + 1 end
    end
    for _, faction in pairs(
        Factions.Registry.byID or {}
    ) do
        if faction.status == "active"
            and faction.ownerPlayerKey == nil
        then
            local successors = activePlayerMemberKeys(faction)
            if #successors > 0 then
                faction.ownerPlayerKey = successors[1]
                touchFaction(faction)
                touchRegistry()
                changed = changed + 1
                if PNC.FactionBehavior
                    and PNC.FactionBehavior.ReconcileFaction
                then
                    PNC.FactionBehavior.ReconcileFaction(
                        faction.id,
                        "player_leadership_repaired"
                    )
                end
            end
        end
    end
    return changed, changed > 0 and "reconciled" or "unchanged"
end

function Factions.GetPlayerPacification(
    factionID,
    playerKey,
    worldAgeHours
)
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return nil, "faction_not_found" end
    if not EntityRef.IsPlayer(playerKey) then
        return nil, "invalid_player_key"
    end
    local entry = Types.NormalizePlayerPacification(
        faction.playerPacifications
            and faction.playerPacifications[playerKey],
        playerKey
    )
    if not entry then return nil, "not_pacified" end
    local at = finiteTimestamp(worldAgeHours, 0)
    if entry.untilWorldAgeHours <= at then
        return nil, "pacification_expired"
    end
    return copy(entry), "active"
end

function Factions.IsPacifiedForPlayer(
    factionID,
    playerKey,
    worldAgeHours
)
    local entry = Factions.GetPlayerPacification(
        factionID,
        playerKey,
        worldAgeHours
    )
    return entry ~= nil
end

function Factions.PacifyForPlayer(
    factionID,
    playerKey,
    options
)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not EntityRef.IsPlayer(playerKey) then
        return false, "invalid_player_key"
    end
    options = type(options) == "table" and options or {}
    local at = finiteTimestamp(options.worldAgeHours, 0)
    local durationHours = finiteTimestamp(
        options.durationHours,
        Constants.PLAYER_PACIFICATION_DEFAULT_HOURS
    )
    if durationHours <= 0 then
        return false, "invalid_duration"
    end
    local existing = faction.playerPacifications
        and faction.playerPacifications[playerKey] or nil
    local entry = Types.NormalizePlayerPacification({
        playerKey = playerKey,
        createdAt = at,
        untilWorldAgeHours = at + durationHours,
        reason = options.reason or "temporary_pacification",
        sourceNPCID = options.sourceNPCID,
        revision = math.max(
            0,
            math.floor(tonumber(
                existing and existing.revision
            ) or 0)
        ) + 1,
    }, playerKey)
    if not entry then
        return false, "invalid_pacification"
    end
    faction.playerPacifications =
        faction.playerPacifications or {}
    faction.playerPacifications[playerKey] = entry
    faction.playerPacifications =
        Types.NormalizePlayerPacifications(
            faction.playerPacifications
        )
    if not faction.playerPacifications[playerKey] then
        return false, "pacification_limit"
    end
    touchFaction(faction)
    touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior
            .ReconcilePlayerPacification
    then
        PNC.FactionBehavior.ReconcilePlayerPacification(
            factionID,
            playerKey,
            "player_pacified"
        )
    end
    return true, "pacified", copy(entry)
end

function Factions.PacifyForRuntimePlayer(
    factionID,
    player,
    options
)
    local playerKey, reason = playerKeyFor(
        player,
        "pacify_for_player",
        true
    )
    if not playerKey then return false, reason end
    return Factions.PacifyForPlayer(
        factionID,
        playerKey,
        options
    )
end

function Factions.ClearPlayerPacification(
    factionID,
    playerKey
)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if not EntityRef.IsPlayer(playerKey) then
        return false, "invalid_player_key"
    end
    if not faction.playerPacifications
        or not faction.playerPacifications[playerKey]
    then
        return false, "not_pacified"
    end
    faction.playerPacifications[playerKey] = nil
    touchFaction(faction)
    touchRegistry()
    return true, "cleared"
end

function Factions.ClearRuntimePlayerPacification(
    factionID,
    player
)
    local playerKey, reason = playerKeyFor(
        player,
        "clear_player_pacification",
        true
    )
    if not playerKey then return false, reason end
    return Factions.ClearPlayerPacification(
        factionID,
        playerKey
    )
end

function Factions.PrunePlayerPacifications(worldAgeHours)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local at = finiteTimestamp(worldAgeHours, 0)
    local removed = 0
    for _, faction in pairs(Factions.Registry.byID or {}) do
        local changed = false
        for playerKey, raw in pairs(
            faction.playerPacifications or {}
        ) do
            local entry = Types.NormalizePlayerPacification(
                raw,
                playerKey
            )
            if not entry
                or entry.untilWorldAgeHours <= at
            then
                faction.playerPacifications[playerKey] = nil
                removed = removed + 1
                changed = true
            end
        end
        if changed then touchFaction(faction) end
    end
    if removed > 0 then touchRegistry() end
    return true, removed > 0 and "pruned" or "unchanged",
        removed
end

local function defaultPlayerFactionName(player, playerKey)
    local parsed = EntityRef.Parse(playerKey)
    local playerName = tostring(
        player and player.getDisplayName
            and player:getDisplayName()
            or parsed and parsed.accountIdentity
            or "Player"
    )
    return string.sub(playerName, 1, 80)
        .. " Survivors"
end

function Factions.EnsurePlayerDiplomacyFaction(player, options)
    local playerKey
    local reason
    local existing
    local parsed
    local ok
    local faction
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    playerKey, reason = playerKeyFor(
        player,
        "ensure_player_diplomacy_faction",
        true
    )
    if not playerKey then return false, reason end
    existing = Factions.GetDiplomacyFactionForPlayerKey(
        playerKey
    )
    if existing then
        return true,
            isProvisionalFaction(existing)
                and "existing_provisional" or "existing",
            existing
    end
    options = type(options) == "table" and options or {}
    parsed = EntityRef.Parse(playerKey)
    ok, reason, faction = Factions.Create({
        name = string.sub(
            tostring(
                parsed and parsed.accountIdentity
                    or "Player"
            ) .. " Diplomacy",
            1,
            Constants.NAME_MAX_LENGTH
        ),
        archetypeID = "settler",
        createdAt = options.worldAgeHours,
        tags = {
            provisionalPlayerFaction = true,
            hiddenFromFactionLists = true,
        },
        ownerPlayerKey = playerKey,
        playerMemberKeys = {
            [playerKey] = true,
        },
    })
    if not ok then return false, reason, faction end
    return true, "provisional_created", faction
end

local function promoteProvisionalFaction(
    faction,
    playerKey,
    player,
    spec
)
    local archetypeID = spec.archetypeID or "settler"
    local name = spec.name
        or defaultPlayerFactionName(player, playerKey)
    local candidate = Types.NewFaction({
        id = faction.id,
        name = name,
        archetypeID = archetypeID,
        status = "active",
        createdAt = faction.createdAt,
        ownerPlayerKey = playerKey,
        playerMemberKeys = {
            [playerKey] = true,
        },
        policy = spec.policy,
        emblem = spec.emblem,
        tags = spec.tags,
    })
    if not candidate then return false, "invalid_name" end
    if faction.archetypeID ~= candidate.archetypeID then
        Factions.Registry.byArchetype[
            faction.archetypeID
        ] = Factions.Registry.byArchetype[
            faction.archetypeID
        ] or {}
        Factions.Registry.byArchetype[
            faction.archetypeID
        ][faction.id] = nil
        Factions.Registry.byArchetype[
            candidate.archetypeID
        ] = Factions.Registry.byArchetype[
            candidate.archetypeID
        ] or {}
        Factions.Registry.byArchetype[
            candidate.archetypeID
        ][faction.id] = true
    end
    faction.name = candidate.name
    faction.archetypeID = candidate.archetypeID
    faction.status = "active"
    faction.archivedAt = 0
    faction.ownerPlayerKey = playerKey
    faction.playerMemberKeys = {
        [playerKey] = true,
    }
    faction.policy = candidate.policy
    faction.emblem = candidate.emblem
    faction.tags = Types.NormalizeTags(spec.tags)
    faction.tags.promotedFromProvisional = true
    Factions.Registry.byPlayerKey[playerKey] = faction.id
    touchFaction(faction)
    touchRegistry()
    return true, "promoted_provisional", copy(faction)
end

function Factions.CreatePlayerFaction(player, spec)
    local playerKey
    local reason
    local name
    local existing
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    playerKey, reason = playerKeyFor(
        player,
        "create_player_faction",
        true
    )
    if not playerKey then return false, reason end
    spec = type(spec) == "table" and spec or {}
    existing = Factions.GetDiplomacyFactionForPlayerKey(
        playerKey
    )
    if existing and isProvisionalFaction(existing) then
        return promoteProvisionalFaction(
            registryRecord(existing.id),
            playerKey,
            player,
            spec
        )
    end
    if existing then
        return false, "player_already_affiliated",
            existing
    end
    name = spec.name
        or defaultPlayerFactionName(player, playerKey)
    return Factions.Create({
        name = name,
        archetypeID = spec.archetypeID or "settler",
        createdAt = spec.createdAt,
        tags = spec.tags,
        emblem = spec.emblem,
        ownerPlayerKey = playerKey,
        playerMemberKeys = {
            [playerKey] = true,
        },
    })
end

function Factions.SetEmblem(factionID, value)
    local faction
    local normalized
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if type(value) ~= "table" then
        return false, "invalid_emblem"
    end
    normalized = PNC.FactionEmblems.Normalize(
        value,
        faction.archetypeID,
        faction.id .. ":" .. faction.name
    )
    normalized.revision = math.max(
        tonumber(faction.emblem and faction.emblem.revision) or 0,
        tonumber(normalized.revision) or 0
    )
    if Types.AreEqual(faction.emblem, normalized) then
        return true, "unchanged", copy(faction)
    end
    normalized.revision = normalized.revision + 1
    faction.emblem = normalized
    touchFaction(faction)
    touchRegistry()
    return true, "updated", copy(faction)
end

function Factions.SetPlayerFactionEmblem(player, value)
    local playerKey
    local reason
    local faction
    if not authority() then return false, "not_authority" end
    playerKey, reason = playerKeyFor(
        player,
        "set_player_faction_emblem",
        true
    )
    if not playerKey then return false, reason end
    faction, reason = Factions.GetFactionForPlayerKey(playerKey)
    if not faction then return false, reason end
    if faction.ownerPlayerKey ~= playerKey then
        return false, "not_faction_owner"
    end
    return Factions.SetEmblem(faction.id, value)
end

function Factions.EnsurePlayerFaction(player, options)
    local faction
    local reason
    local ok
    faction, reason = Factions.GetPlayerFaction(player)
    if faction then return true, "existing", faction end
    options = type(options) == "table" and options or {}
    ok, reason, faction = Factions.CreatePlayerFaction(player, {
        name = options.name,
        archetypeID = options.archetypeID or "settler",
        createdAt = options.worldAgeHours,
        tags = options.tags or {
            automaticallyCreated = true,
        },
    })
    if not ok and reason == "player_already_affiliated"
        and faction
    then
        return true, "existing", faction
    end
    return ok, reason, faction
end

function Factions.IsPlayerFaction(factionID)
    local faction = registryRecord(factionID)
    if not faction or isProvisionalFaction(faction) then
        return false
    end
    for _, _ in pairs(faction.playerMemberKeys or {}) do
        return true
    end
    return false
end

local function relationPair(sourceFactionID, targetFactionID)
    local source = registryRecord(sourceFactionID)
    local target = registryRecord(targetFactionID)
    if not source or not target
        or sourceFactionID == targetFactionID
    then
        return nil, nil, "invalid_faction_pair"
    end
    return source, target
end

local function currentRelation(source, targetFactionID)
    return Types.NormalizeRelation(
        source.relations and source.relations[targetFactionID],
        source.id,
        targetFactionID
    )
end

function Factions.GetRelation(sourceFactionID, targetFactionID)
    Factions.EnsureLoaded()
    local source, _, reason = relationPair(
        sourceFactionID,
        targetFactionID
    )
    if not source then return nil, reason end
    local relation = source.relations
        and source.relations[targetFactionID] or nil
    if not relation then return nil, "relation_not_found" end
    return copy(Types.NormalizeRelation(
        relation,
        sourceFactionID,
        targetFactionID
    ))
end

-- Compatibility alias. V3 is directed, so argument order now matters.
Factions.GetDiplomacy = Factions.GetRelation

function Factions.AreAtWar(firstFactionID, secondFactionID)
    Factions.EnsureLoaded()
    local first = registryRecord(firstFactionID)
    local second = registryRecord(secondFactionID)
    if not first or not second then return false end
    local forward = first.relations
        and first.relations[secondFactionID]
    local reverse = second.relations
        and second.relations[firstFactionID]
    return forward ~= nil and reverse ~= nil
        and forward.atWar == true and reverse.atWar == true
end

function Factions.AreAllied(firstFactionID, secondFactionID)
    Factions.EnsureLoaded()
    local first = registryRecord(firstFactionID)
    local second = registryRecord(secondFactionID)
    if not first or not second then return false end
    local forward = first.relations
        and first.relations[secondFactionID]
    local reverse = second.relations
        and second.relations[firstFactionID]
    return forward ~= nil and reverse ~= nil
        and forward.allied == true and reverse.allied == true
end

function Factions.GetTruceUntil(firstFactionID, secondFactionID)
    Factions.EnsureLoaded()
    local first = registryRecord(firstFactionID)
    local second = registryRecord(secondFactionID)
    if not first or not second then return 0 end
    local forward = first.relations
        and first.relations[secondFactionID]
    local reverse = second.relations
        and second.relations[firstFactionID]
    if not forward or not reverse then return 0 end
    local left = tonumber(forward.truceUntil) or 0
    local right = tonumber(reverse.truceUntil) or 0
    return left == right and left or 0
end

function Factions.IsFactionAtWar(factionID)
    local faction = registryRecord(factionID)
    if not faction then return false end
    for targetID, relation in pairs(faction.relations or {}) do
        if relation.atWar == true
            and Factions.AreAtWar(factionID, targetID)
        then
            return true
        end
    end
    return false
end

local function rememberIncidentID(relation, incidentID)
    relation.recentIncidentIDs =
        relation.recentIncidentIDs or {}
    for _, existingID in ipairs(relation.recentIncidentIDs) do
        if existingID == incidentID then return false end
    end
    relation.recentIncidentIDs[
        #relation.recentIncidentIDs + 1
    ] = incidentID
    while #relation.recentIncidentIDs
        > (
            PNC.FactionBalance
            and PNC.FactionBalance.Get(
                "recentIncidentIDLimit"
            ) or Constants.RECENT_INCIDENT_ID_LIMIT
        )
    do
        table.remove(relation.recentIncidentIDs, 1)
    end
    return true
end

local function appendAudit(
    relation,
    relationSourceID,
    relationTargetID,
    incidentType,
    at,
    initiatingFactionID
)
    local incidentID = table.concat({
        "treaty",
        incidentType,
        tostring(at),
        tostring(initiatingFactionID or relationSourceID),
        relationSourceID,
        relationTargetID,
    }, ":")
    if not rememberIncidentID(relation, incidentID) then
        return false
    end
    local definition =
        PNC.FactionIncidentDefinitions.Get(incidentType)
    local incident = Types.NormalizeIncident({
        id = incidentID,
        type = incidentType,
        sourceFactionID = initiatingFactionID
            or relationSourceID,
        targetFactionID = initiatingFactionID == relationTargetID
            and relationSourceID or relationTargetID,
        occurredAt = at,
        standingEffect = definition.standing,
        trustEffect = definition.trust,
        fearEffect = definition.fear,
        grievanceEffect = definition.grievance,
        severity = definition.severity,
        public = true,
        witnessed = true,
        preserve = true,
        tags = definition.tags,
    }, relationSourceID, relationTargetID)
    if incident then
        relation.incidents[#relation.incidents + 1] = incident
    end
    return incident ~= nil
end

local function reconcilePair(
    firstFactionID,
    secondFactionID,
    reason,
    worldAgeHours
)
    if not PNC.FactionBehavior
        or not PNC.FactionBehavior.QueueTreatyReconciliation
    then
        return
    end
    PNC.FactionBehavior.QueueTreatyReconciliation(
        firstFactionID,
        secondFactionID,
        reason,
        worldAgeHours
    )
    if PNC.FactionBehavior.PumpReconciliation then
        PNC.FactionBehavior.PumpReconciliation()
    end
end

function Factions.CommitDirectedRelation(
    sourceFactionID,
    targetFactionID,
    relation,
    reason
)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local source, _, pairReason = relationPair(
        sourceFactionID,
        targetFactionID
    )
    if not source then return false, pairReason end
    local existing = currentRelation(source, targetFactionID)
    local normalized = Types.NormalizeRelation(
        relation,
        sourceFactionID,
        targetFactionID
    )
    normalized.revision = existing.revision
    if Types.AreEqual(existing, normalized) then
        return false, "unchanged", copy(existing)
    end
    normalized.revision = existing.revision + 1
    source.relations[targetFactionID] = normalized
    touchFaction(source)
    touchRegistry()
    reconcilePair(
        sourceFactionID,
        targetFactionID,
        reason or "directed_relation_changed"
    )
    return true, "updated", copy(normalized)
end

function Factions.RecalculateRelation(
    sourceFactionID,
    targetFactionID,
    worldAgeHours
)
    local source, _, reason = relationPair(
        sourceFactionID,
        targetFactionID
    )
    if not source then return false, reason end
    local relation = currentRelation(source, targetFactionID)
    local recalculated, changed =
        PNC.FactionDiplomacyMath.RecalculateRelation(
            relation,
            finiteTimestamp(worldAgeHours, 0)
        )
    if not changed then
        return false, "unchanged", copy(relation)
    end
    return Factions.CommitDirectedRelation(
        sourceFactionID,
        targetFactionID,
        recalculated,
        "diplomacy_recalculated"
    )
end

local function mutateTreaty(
    firstFactionID,
    secondFactionID,
    incidentType,
    options,
    mutate
)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local first, second, reason = relationPair(
        firstFactionID,
        secondFactionID
    )
    if not first then return false, reason end
    if first.status ~= "active" or second.status ~= "active" then
        return false, "faction_not_active"
    end
    options = type(options) == "table" and options or {}
    local suppliedAt = tonumber(options.worldAgeHours)
    if suppliedAt == nil or suppliedAt ~= suppliedAt
        or suppliedAt == math.huge or suppliedAt == -math.huge
        or suppliedAt < 0
    then
        return false, "invalid_world_age"
    end
    if options.instigatorFactionID ~= nil
        and options.instigatorFactionID ~= firstFactionID
        and options.instigatorFactionID ~= secondFactionID
    then
        return false, "invalid_instigator_faction"
    end
    local at = suppliedAt
    local forward = currentRelation(first, secondFactionID)
    local reverse = currentRelation(second, firstFactionID)
    local oldForward = copy(forward)
    local oldReverse = copy(reverse)
    local ok, mutationReason = mutate(
        forward,
        reverse,
        at,
        options,
        first,
        second
    )
    if ok == false then
        return false, mutationReason, copy(forward)
    end
    local forwardState = forward.state
    local reverseState = reverse.state
    local resolvedForward =
        PNC.FactionDiplomacyMath.ResolveState(
        forward,
        at
    )
    local resolvedReverse =
        PNC.FactionDiplomacyMath.ResolveState(
        reverse,
        at
    )
    if resolvedForward ~= forwardState then
        forward.previousState = forwardState
        forward.state = resolvedForward
    end
    if resolvedReverse ~= reverseState then
        reverse.previousState = reverseState
        reverse.state = resolvedReverse
    end
    appendAudit(
        forward,
        firstFactionID,
        secondFactionID,
        incidentType,
        at,
        options.instigatorFactionID or firstFactionID
    )
    appendAudit(
        reverse,
        secondFactionID,
        firstFactionID,
        incidentType,
        at,
        options.instigatorFactionID or firstFactionID
    )
    if Types.AreEqual(oldForward, forward)
        and Types.AreEqual(oldReverse, reverse)
    then
        return false, "unchanged", copy(forward)
    end
    forward.revision = oldForward.revision + 1
    reverse.revision = oldReverse.revision + 1
    first.relations[secondFactionID] = forward
    second.relations[firstFactionID] = reverse
    touchFaction(first)
    touchFaction(second)
    touchRegistry()
    reconcilePair(
        firstFactionID,
        secondFactionID,
        "diplomacy_" .. incidentType,
        at
    )
    return true, incidentType, copy(forward)
end

function Factions.DeclareWar(firstFactionID, secondFactionID, options)
    options = type(options) == "table" and options or {}
    local warReason = Constants.WAR_REASONS[options.reason]
        and options.reason or nil
    if not warReason then return false, "invalid_war_reason" end
    return mutateTreaty(
        firstFactionID,
        secondFactionID,
        "war_declared",
        options,
        function(forward, reverse, at)
            if forward.atWar and reverse.atWar then
                return false, "unchanged"
            end
            forward.atWar = true
            reverse.atWar = true
            forward.allied = false
            reverse.allied = false
            forward.truceUntil = 0
            reverse.truceUntil = 0
            forward.warStartedAt = at
            reverse.warStartedAt = at
            forward.warReason = warReason
            reverse.warReason = warReason
            forward.initiatingFactionID =
                options.instigatorFactionID or firstFactionID
            reverse.initiatingFactionID =
                forward.initiatingFactionID
            forward.triggeringIncidentID =
                options.triggeringIncidentID
            reverse.triggeringIncidentID =
                options.triggeringIncidentID
            return true
        end
    )
end

function Factions.EndWar(firstFactionID, secondFactionID, options)
    return mutateTreaty(
        firstFactionID,
        secondFactionID,
        "peace_made",
        options,
        function(forward, reverse, at)
            if not forward.atWar and not reverse.atWar then
                return false, "not_at_war"
            end
            forward.atWar = false
            reverse.atWar = false
            forward.warEndedAt = at
            reverse.warEndedAt = at
            return true
        end
    )
end

function Factions.StartTruce(firstFactionID, secondFactionID, options)
    options = type(options) == "table" and options or {}
    local at = finiteTimestamp(options.worldAgeHours, 0)
    local untilAt = options.truceUntil ~= nil
        and finiteTimestamp(options.truceUntil, 0)
        or at + (
            PNC.FactionBalance
            and PNC.FactionBalance.Get("defaultTruceHours")
            or 24
        )
    return mutateTreaty(
        firstFactionID,
        secondFactionID,
        "truce_started",
        options,
        function(forward, reverse, at)
            if untilAt <= at then
                return false, "invalid_truce_expiry"
            end
            forward.atWar = false
            reverse.atWar = false
            forward.allied = false
            reverse.allied = false
            forward.truceUntil = untilAt
            reverse.truceUntil = untilAt
            forward.warEndedAt = at
            reverse.warEndedAt = at
            return true
        end
    )
end

function Factions.MakePeace(firstFactionID, secondFactionID, options)
    return mutateTreaty(
        firstFactionID,
        secondFactionID,
        "peace_made",
        options,
        function(forward, reverse, at)
            local changed = forward.atWar or reverse.atWar
                or forward.allied or reverse.allied
                or forward.truceUntil > 0
                or reverse.truceUntil > 0
            if not changed then return false, "unchanged" end
            for _, relation in ipairs({ forward, reverse }) do
                relation.atWar = false
                relation.allied = false
                relation.truceUntil = 0
                relation.warEndedAt = at
                relation.standing =
                    PNC.FactionDiplomacyMath.ClampStanding(
                        relation.standing + (
                            PNC.FactionBalance
                            and PNC.FactionBalance.Get(
                                "peaceStandingGain"
                            ) or 15
                        )
                    )
                relation.trust =
                    PNC.FactionDiplomacyMath.ClampTrust(
                        relation.trust + (
                            PNC.FactionBalance
                            and PNC.FactionBalance.Get(
                                "peaceTrustGain"
                            ) or 10
                        )
                    )
                relation.grievance =
                    PNC.FactionDiplomacyMath.ClampGrievance(
                        relation.grievance * (
                            PNC.FactionBalance
                            and PNC.FactionBalance.Get(
                                "peaceGrievanceMultiplier"
                            ) or 0.5
                        )
                    )
            end
            return true
        end
    )
end

function Factions.FormAlliance(firstFactionID, secondFactionID, options)
    options = type(options) == "table" and options or {}
    return mutateTreaty(
        firstFactionID,
        secondFactionID,
        "alliance_formed",
        options,
        function(forward, reverse)
            if forward.allied and reverse.allied then
                return false, "unchanged"
            end
            if forward.atWar or reverse.atWar then
                return false, "cannot_ally_during_war"
            end
            if options.override ~= true and (
                forward.standing < 30 or forward.trust < 10
                or reverse.standing < 30 or reverse.trust < 10
            ) then
                return false, "alliance_threshold_not_met"
            end
            forward.atWar = false
            reverse.atWar = false
            forward.truceUntil = 0
            reverse.truceUntil = 0
            forward.allied = true
            reverse.allied = true
            return true
        end
    )
end

function Factions.BreakAlliance(firstFactionID, secondFactionID, options)
    return mutateTreaty(
        firstFactionID,
        secondFactionID,
        "alliance_broken",
        options,
        function(forward, reverse)
            if not forward.allied and not reverse.allied then
                return false, "not_allied"
            end
            for _, relation in ipairs({ forward, reverse }) do
                relation.allied = false
                relation.trust =
                    PNC.FactionDiplomacyMath.ClampTrust(
                        relation.trust - 15
                    )
                relation.grievance =
                    PNC.FactionDiplomacyMath.ClampGrievance(
                        relation.grievance + 10
                    )
            end
            return true
        end
    )
end

local function factionForPlayer(player, create, at)
    local faction
    if create then
        local ok
        local reason
        ok, reason, faction =
            Factions.EnsurePlayerDiplomacyFaction(
                player,
                { worldAgeHours = at }
            )
        if PNC.FactionTelemetry then
            PNC.FactionTelemetry.RecordAttribution({
                operation = "player_faction_resolution",
                worldAgeHours = at,
                actorKey = faction and faction.ownerPlayerKey,
                sourceFactionID = faction and faction.id,
                result = ok and "resolved" or "rejected",
                reason = reason or (
                    ok and "resolved"
                        or "actor_faction_missing"
                ),
            })
        end
        return ok and faction or nil
    end
    faction = Factions.GetPlayerDiplomacyFaction(player)
    if PNC.FactionTelemetry then
        PNC.FactionTelemetry.RecordAttribution({
            operation = "player_faction_resolution",
            worldAgeHours = at,
            actorKey = faction and faction.ownerPlayerKey,
            sourceFactionID = faction and faction.id,
            result = faction and "resolved" or "rejected",
            reason = faction and "existing"
                or "actor_faction_missing",
        })
    end
    return faction
end

local function traceFactionCallback(category, fields)
    local telemetry = PNC.FactionTelemetry
    if not telemetry then return end
    if category == "callback" then
        telemetry.RecordCallback(fields)
    else
        telemetry.RecordAttribution(fields)
    end
end

function Factions.OnPlayerAggression(
    player,
    targetRecord,
    worldAgeHours,
    context
)
    local targetFactionID =
        Factions.GetOrganizationalFactionID(targetRecord)
    local playerFaction
    traceFactionCallback("callback", {
        operation = context and context.callback
            or "player_aggression",
        worldAgeHours = worldAgeHours,
        subjectKey = targetRecord and targetRecord.id
            and EntityRef.ForNPC(targetRecord.id) or nil,
        targetFactionID = targetFactionID,
        result = "received",
        damage = context and context.damage,
        severe = context and context.severe,
        killed = context and context.killed,
    })
    if not targetFactionID then
        traceFactionCallback("attribution", {
            operation = "resolve_player_attack",
            worldAgeHours = worldAgeHours,
            result = "rejected",
            reason = "victim_faction_missing",
        })
        return false, "target_unaffiliated"
    end
    playerFaction = factionForPlayer(
        player,
        true,
        worldAgeHours
    )
    if not playerFaction then
        traceFactionCallback("attribution", {
            operation = "resolve_player_attack",
            worldAgeHours = worldAgeHours,
            targetFactionID = targetFactionID,
            result = "rejected",
            reason = "actor_identity_missing",
        })
        return false, "player_faction_unavailable"
    end
    if playerFaction.id == targetFactionID then
        traceFactionCallback("attribution", {
            operation = "resolve_player_attack",
            worldAgeHours = worldAgeHours,
            actorKey = playerFaction.ownerPlayerKey,
            sourceFactionID = playerFaction.id,
            targetFactionID = targetFactionID,
            result = "rejected",
            reason = "same_faction",
        })
        return false, "same_faction"
    end
    if not PNC.FactionIncidentService then
        return false, "incident_service_unavailable"
    end
    context = type(context) == "table" and context or {}
    traceFactionCallback("attribution", {
        operation = "resolve_player_attack",
        worldAgeHours = worldAgeHours,
        actorKey = playerFaction.ownerPlayerKey,
        subjectKey = EntityRef.ForNPC(targetRecord.id),
        sourceFactionID = playerFaction.id,
        targetFactionID = targetFactionID,
        result = "accepted",
        reason = "accepted_cross_faction_attack",
    })
    return PNC.FactionIncidentService.RecordAttack(
        playerFaction.id,
        targetFactionID,
        {
            worldAgeHours = worldAgeHours,
            actorKey = playerFaction.ownerPlayerKey,
            subjectKey = EntityRef.ForNPC(targetRecord.id),
            callbackID = context.callbackID,
            severe = context.severe,
            killed = context.killed,
            damage = context.damage,
            intentionality = context.intentionality,
            targetRecord = targetRecord,
        }
    )
end

function Factions.OnNPCAggression(
    attackerRecord,
    targetRecord,
    worldAgeHours,
    context
)
    local attackerFactionID =
        Factions.GetOrganizationalFactionID(attackerRecord)
    local targetFactionID =
        Factions.GetOrganizationalFactionID(targetRecord)
    context = type(context) == "table" and context or {}
    traceFactionCallback("callback", {
        operation = context.callback or "npc_aggression",
        worldAgeHours = worldAgeHours,
        actorKey = attackerRecord and attackerRecord.id
            and EntityRef.ForNPC(attackerRecord.id) or nil,
        subjectKey = targetRecord and targetRecord.id
            and EntityRef.ForNPC(targetRecord.id) or nil,
        sourceFactionID = attackerFactionID,
        targetFactionID = targetFactionID,
        result = "received",
        damage = context.damage,
        severe = context.severe,
        killed = context.killed,
    })
    if not attackerFactionID or not targetFactionID then
        traceFactionCallback("attribution", {
            operation = "resolve_npc_attack",
            worldAgeHours = worldAgeHours,
            actorKey = attackerRecord and attackerRecord.id
                and EntityRef.ForNPC(attackerRecord.id) or nil,
            subjectKey = targetRecord and targetRecord.id
                and EntityRef.ForNPC(targetRecord.id) or nil,
            sourceFactionID = attackerFactionID,
            targetFactionID = targetFactionID,
            result = "rejected",
            reason = not attackerFactionID
                and "actor_faction_missing"
                or "victim_faction_missing",
        })
        return false, "unaffiliated"
    end
    if attackerFactionID == targetFactionID then
        traceFactionCallback("attribution", {
            operation = "resolve_npc_attack",
            worldAgeHours = worldAgeHours,
            sourceFactionID = attackerFactionID,
            targetFactionID = targetFactionID,
            result = "rejected",
            reason = "same_faction",
        })
        return false, "same_faction"
    end
    if not PNC.FactionIncidentService then
        return false, "incident_service_unavailable"
    end
    traceFactionCallback("attribution", {
        operation = "resolve_npc_attack",
        worldAgeHours = worldAgeHours,
        actorKey = EntityRef.ForNPC(attackerRecord.id),
        subjectKey = EntityRef.ForNPC(targetRecord.id),
        sourceFactionID = attackerFactionID,
        targetFactionID = targetFactionID,
        result = "accepted",
        reason = "accepted_cross_faction_attack",
    })
    return PNC.FactionIncidentService.RecordAttack(
        attackerFactionID,
        targetFactionID,
        {
            worldAgeHours = worldAgeHours,
            actorKey = EntityRef.ForNPC(attackerRecord.id),
            subjectKey = EntityRef.ForNPC(targetRecord.id),
            targetRecord = targetRecord,
            callbackID = context.callbackID,
            severe = context.severe,
            killed = context.killed,
            damage = context.damage,
            intentionality = context.intentionality,
        }
    )
end

function Factions.OnNPCAttackPlayer(
    attackerRecord,
    player,
    worldAgeHours,
    context
)
    local attackerFactionID =
        Factions.GetOrganizationalFactionID(attackerRecord)
    local playerFaction
    context = type(context) == "table" and context or {}
    traceFactionCallback("callback", {
        operation = context.callback or "npc_attack_player",
        worldAgeHours = worldAgeHours,
        actorKey = attackerRecord and attackerRecord.id
            and EntityRef.ForNPC(attackerRecord.id) or nil,
        sourceFactionID = attackerFactionID,
        result = "received",
        damage = context.damage,
        severe = context.severe,
        killed = context.killed,
    })
    if not attackerFactionID then
        traceFactionCallback("attribution", {
            operation = "resolve_npc_attack_player",
            worldAgeHours = worldAgeHours,
            result = "rejected",
            reason = "actor_faction_missing",
        })
        return false, "attacker_unaffiliated"
    end
    playerFaction = factionForPlayer(
        player,
        true,
        worldAgeHours
    )
    if not playerFaction
        or playerFaction.id == attackerFactionID
    then
        traceFactionCallback("attribution", {
            operation = "resolve_npc_attack_player",
            worldAgeHours = worldAgeHours,
            actorKey = EntityRef.ForNPC(attackerRecord.id),
            subjectKey = playerFaction
                and playerFaction.ownerPlayerKey or nil,
            sourceFactionID = attackerFactionID,
            targetFactionID = playerFaction
                and playerFaction.id or nil,
            result = "rejected",
            reason = not playerFaction
                and "victim_faction_missing"
                or "same_faction",
        })
        return false, "same_or_missing_faction"
    end
    if not PNC.FactionIncidentService then
        return false, "incident_service_unavailable"
    end
    traceFactionCallback("attribution", {
        operation = "resolve_npc_attack_player",
        worldAgeHours = worldAgeHours,
        actorKey = EntityRef.ForNPC(attackerRecord.id),
        subjectKey = playerFaction.ownerPlayerKey,
        sourceFactionID = attackerFactionID,
        targetFactionID = playerFaction.id,
        result = "accepted",
        reason = "accepted_cross_faction_attack",
    })
    return PNC.FactionIncidentService.RecordAttack(
        attackerFactionID,
        playerFaction.id,
        {
            worldAgeHours = worldAgeHours,
            actorKey = EntityRef.ForNPC(attackerRecord.id),
            subjectKey = playerFaction.ownerPlayerKey,
            callbackID = context.callbackID,
            severe = context.severe,
            killed = context.killed,
            damage = context.damage,
            intentionality = context.intentionality,
        }
    )
end

function Factions.CanNPCTargetPlayer(record, player)
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ResolveIntent
    then
        local result = PNC.FactionBehavior.ResolveIntent(
            record,
            player,
            {}
        )
        return result and result.attackAllowed == true
    end
    return record and record.hostility
        and record.hostility.attackPlayers == true
end

function Factions.OnRelationshipChanged(
    observerRecord,
    targetKey,
    relationship
)
    local observerFactionID =
        Factions.GetOrganizationalFactionID(observerRecord)
    local targetFaction
    local parsed
    local livePlayer
    if not observerFactionID
        or not relationship
        or relationship.state ~= "enemy"
        or not EntityRef.IsPlayer(targetKey)
    then
        return false, "not_faction_enemy"
    end
    targetFaction =
        Factions.GetDiplomacyFactionForPlayerKey(targetKey)
    if not targetFaction then
        parsed = EntityRef.Parse(targetKey)
        livePlayer = parsed
            and PNC.PlayerCharacters
            and PNC.PlayerCharacters.RuntimeByUUID
            and PNC.PlayerCharacters.RuntimeByUUID[
                parsed.characterUUID
            ] or nil
        targetFaction = livePlayer
            and factionForPlayer(
                livePlayer,
                true,
                relationship.lastEvaluatedAt
            ) or nil
    end
    if not targetFaction
        or targetFaction.id == observerFactionID
    then
        return false, "target_faction_unavailable"
    end
    local rank = observerRecord.affiliation
        and observerRecord.affiliation.rank or "member"
    if rank ~= "leader" and rank ~= "second"
        and rank ~= "officer"
    then
        return false, "insufficient_faction_authority"
    end
    if not PNC.FactionIncidentService then
        return false, "incident_service_unavailable"
    end
    local ok, reason = PNC.FactionIncidentService.AddIncident(
        targetFaction.id,
        observerFactionID,
        "personal_grievance_report",
        {
            worldAgeHours = relationship.lastEvaluatedAt,
            actorKey = targetKey,
            subjectKey = EntityRef.ForNPC(observerRecord.id),
            relationSourceFactionID = observerFactionID,
            relationTargetFactionID = targetFaction.id,
            authorityRank = rank,
            externalID = "relationship:"
                .. observerRecord.id .. ":"
                .. targetKey .. ":"
                .. tostring(relationship.revision or 0),
        }
    )
    if ok and PNC.Config and PNC.Config.Factions
        and PNC.Config.Factions
            .EnemyRelationshipCanImmediatelyDeclareWar == true
    then
        return Factions.DeclareWar(
            observerFactionID,
            targetFaction.id,
            {
                worldAgeHours =
                    relationship.lastEvaluatedAt,
                reason = "scripted",
                instigatorFactionID = observerFactionID,
            }
        )
    end
    return ok, reason
end

function Factions.Archive(factionID, reason, worldAgeHours)
    local faction
    local at
    local memberIDs = {}
    local reconcileFactionIDs = {}
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if PNC.NeedsDebug and PNC.NeedsDebug.CleanupGroup then
        PNC.NeedsDebug.CleanupGroup(factionID)
    end
    if faction.status == "archived" then
        return false, "already_archived"
    end
    if faction.status == "destroyed" then
        return false, "faction_destroyed"
    end
    at = finiteTimestamp(worldAgeHours, faction.createdAt)
    for npcID, _ in pairs(faction.memberIDs or {}) do
        memberIDs[#memberIDs + 1] = npcID
    end
    table.sort(memberIDs)
    for _, npcID in ipairs(memberIDs) do
        local record = PNC.Registry.Get(npcID)
        if record and record.affiliation
            and record.affiliation.factionID == factionID
        then
            local affiliation = affiliationFor(record, faction)
            local former = addHistory(
                affiliation,
                factionID,
                at,
                "faction_archived"
            )
            commitAffiliation(record, Types.NewAffiliation({
                leftAt = at,
                originArchetypeID =
                    affiliation.originArchetypeID,
                formerFactionIDs = former,
                revision = affiliation.revision,
            }))
            if PNC.FactionBehavior
                and PNC.FactionBehavior.ApplyUnaffiliated
            then
                PNC.FactionBehavior.ApplyUnaffiliated(
                    record,
                    "faction_archived"
                )
            end
        end
    end
    if Factions.DestroyingFactionID ~= factionID
        and PNC.Communities
        and PNC.Communities.OnFactionArchived
    then
        PNC.Communities.OnFactionArchived(factionID, at)
    end
    faction.status = "archived"
    faction.archivedAt = at
    faction.leaderNPCID = nil
    faction.memberIDs = {}
    for playerKey, _ in pairs(
        faction.playerMemberKeys or {}
    ) do
        Factions.Registry.byPlayerKey[playerKey] = nil
    end
    faction.playerMemberKeys = {}
    faction.ownerPlayerKey = nil
    for otherID, relation in pairs(faction.relations or {}) do
        local other = registryRecord(otherID)
        local reverse = other and other.relations
            and other.relations[factionID] or nil
        local changedTreaty = relation.atWar
            or relation.allied
            or (tonumber(relation.truceUntil) or 0) > 0
            or reverse and (
                reverse.atWar or reverse.allied
                or (tonumber(reverse.truceUntil) or 0) > 0
            )
        if changedTreaty then
            for _, item in ipairs({ relation, reverse }) do
                if item then
                    item.atWar = false
                    item.allied = false
                    item.truceUntil = 0
                    item.warEndedAt = at
                    item.state =
                        PNC.FactionDiplomacyMath.ResolveState(
                            item,
                            at
                        )
                    item.revision = math.max(
                        0,
                        math.floor(
                            tonumber(item.revision) or 0
                        )
                    ) + 1
                end
            end
            if other then touchFaction(other) end
            reconcileFactionIDs[otherID] = true
        end
    end
    if type(reason) == "string" and reason ~= "" then
        local tags = Types.NormalizeTags({
            archiveReason = reason,
        })
        faction.tags.archiveReason = tags.archiveReason
    end
    touchFaction(faction)
    touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        for otherID, _ in pairs(reconcileFactionIDs) do
            PNC.FactionBehavior.ReconcileFaction(
                otherID,
                "faction_archived_peace"
            )
        end
    end
    return true, "archived", copy(faction)
end

function Factions.Destroy(factionID, reason, worldAgeHours)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if faction.status == "destroyed" then
        return false, "already_destroyed"
    end
    local at = finiteTimestamp(
        worldAgeHours,
        faction.createdAt
    )
    if faction.status ~= "archived" then
        Factions.DestroyingFactionID = factionID
        local ok, archiveReason =
            Factions.Archive(factionID, reason, at)
        Factions.DestroyingFactionID = nil
        if not ok and archiveReason ~= "already_archived" then
            return false, archiveReason
        end
        faction = registryRecord(factionID)
    end
    faction.status = "destroyed"
    faction.archivedAt = at
    faction.tags = faction.tags or {}
    faction.tags.destroyReason = tostring(
        reason or "destroyed"
    )
    if PNC.Communities
        and PNC.Communities.OnFactionDestroyed
    then
        PNC.Communities.OnFactionDestroyed(factionID, at)
    end
    touchFaction(faction)
    touchRegistry()
    return true, "destroyed", copy(faction)
end

function Factions.OnNPCDeath(npcID)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local record = PNC.Registry.Get(npcID)
    if PNC.Communities and PNC.Communities.OnNPCDeath then
        PNC.Communities.OnNPCDeath(npcID)
    end
    local affiliation = record
        and Types.NormalizeAffiliation(record.affiliation)
        or nil
    local faction = affiliation and affiliation.factionID
        and registryRecord(affiliation.factionID) or nil
    local entityKey = EntityRef and EntityRef.ForNPC
        and Types.IsValidNPCID(npcID)
        and EntityRef.ForNPC(npcID) or nil
    traceFactionCallback("callback", {
        operation = "npc_death",
        worldAgeHours = getGameTime and getGameTime()
            and getGameTime().getWorldAgeHours
            and getGameTime():getWorldAgeHours() or 0,
        subjectKey = entityKey,
        targetFactionID = faction and faction.id or nil,
        result = faction and "resolved" or "rejected",
        reason = faction and "faction_member_death"
            or "victim_faction_missing",
    })
    if not faction then return false, "unaffiliated" end
    if faction.leaderNPCID ~= npcID then
        return false, "not_leader"
    end
    local leaderAffiliation = affiliationFor(record, faction)
    leaderAffiliation.rank = "member"
    if leaderAffiliation.role == "leader" then
        leaderAffiliation.role = Archetypes.GetDefaultRole(
            faction.archetypeID
        )
    end
    commitAffiliation(record, leaderAffiliation)
    faction.leaderNPCID = nil
    touchFaction(faction)
    touchRegistry()
    if PNC.FactionLeadership
        and PNC.FactionLeadership.OnMemberDeparture
    then
        local succeeded, reason =
            PNC.FactionLeadership.OnMemberDeparture(
                faction.id,
                "leader_died"
            )
        if succeeded then
            return true, "leader_succeeded"
        end
        if reason == "no_eligible_successor" then
            return true, "leader_lost"
        end
    end
    return true, "death_reconciled"
end

Factions.NormalizeFactionRegistry =
    Types.NormalizeFactionRegistry
Factions.NormalizeFaction = Types.NormalizeFaction
Factions.NormalizeAffiliation = Types.NormalizeAffiliation

local function onInitGlobalModData()
    Factions.Load()
end

if Events and Events.OnInitGlobalModData
    and not Factions.GlobalModDataHookRegistered
then
    Events.OnInitGlobalModData.Add(onInitGlobalModData)
    Factions.GlobalModDataHookRegistered = true
end

return Factions
