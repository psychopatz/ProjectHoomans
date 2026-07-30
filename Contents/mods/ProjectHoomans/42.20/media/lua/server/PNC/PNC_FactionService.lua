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
    for _, relation in pairs(
        Factions.Registry.diplomacy or {}
    ) do
        local first = Factions.Registry.byID[
            relation.factionAID
        ]
        local second = Factions.Registry.byID[
            relation.factionBID
        ]
        if relation.state == Constants.DIPLOMACY_WAR
            and (not first or first.status ~= "active"
                or not second or second.status ~= "active")
        then
            relation.state = Constants.DIPLOMACY_PEACE
            relation.reason = "faction_not_active"
            changed = true
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
    Factions.EnsureLoaded()
    if not Factions.Dirty then return false, "not_dirty" end
    target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Constants.REGISTRY_MODDATA_KEY)
        or nil
    if not target then return false, "moddata_unavailable" end
    assignTable(
        target,
        Types.NormalizeFactionRegistry(Factions.Registry)
    )
    Factions.Registry =
        Types.NormalizeFactionRegistry(target)
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

function Factions.List()
    local output = {}
    Factions.EnsureLoaded()
    for _, faction in pairs(Factions.Registry.byID) do
        output[#output + 1] = copy(faction)
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
        if Factions.Registry.byID[factionID] then
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

local function playerKeyFor(player, callback, ensure)
    if not player or not PNC.PlayerCharacters then
        return nil, "player_identity_unavailable"
    end
    if ensure ~= true then
        local uuid = PNC.PlayerCharacters.GetCharacterUUID
            and PNC.PlayerCharacters.GetCharacterUUID(player)
            or nil
        local accountIdentity = player.getUsername
            and player:getUsername() or nil
        local key = uuid and EntityRef.ForPlayerIdentity(
            accountIdentity,
            uuid
        ) or nil
        return key, key and "resolved"
            or "player_identity_unavailable"
    end
    if not PNC.PlayerCharacters.GetEntityKey then
        return nil, "player_identity_unavailable"
    end
    local at = getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
        and getGameTime():getWorldAgeHours() or 0
    return PNC.PlayerCharacters.GetEntityKey(player, {
        callback = callback or "faction",
        worldAgeHours = finiteTimestamp(at, 0),
    })
end

function Factions.GetFactionForPlayerKey(playerKey)
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

function Factions.CreatePlayerFaction(player, spec)
    local playerKey
    local reason
    local parsed
    local name
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    playerKey, reason = playerKeyFor(
        player,
        "create_player_faction",
        true
    )
    if not playerKey then return false, reason end
    if Factions.Registry.byPlayerKey[playerKey] then
        return false, "player_already_affiliated",
            Factions.Get(
                Factions.Registry.byPlayerKey[playerKey]
            )
    end
    spec = type(spec) == "table" and spec or {}
    parsed = EntityRef.Parse(playerKey)
    name = spec.name
    if not name then
        local playerName = tostring(
            player.getDisplayName
                and player:getDisplayName()
                or parsed and parsed.accountIdentity
                or "Player"
        )
        name = string.sub(playerName, 1, 80)
            .. " Survivors"
    end
    return Factions.Create({
        name = name,
        archetypeID = spec.archetypeID or "settler",
        createdAt = spec.createdAt,
        tags = spec.tags,
        ownerPlayerKey = playerKey,
        playerMemberKeys = {
            [playerKey] = true,
        },
    })
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
    return faction ~= nil
        and next(faction.playerMemberKeys or {}) ~= nil
end

function Factions.GetDiplomacy(firstFactionID, secondFactionID)
    Factions.EnsureLoaded()
    local pairKey = Types.MakeDiplomacyKey(
        firstFactionID,
        secondFactionID
    )
    if not pairKey then return nil, "invalid_faction_pair" end
    local relation = Factions.Registry.diplomacy[pairKey]
    return relation and copy(relation) or nil,
        relation and nil or "diplomacy_not_found"
end

function Factions.AreAtWar(firstFactionID, secondFactionID)
    Factions.EnsureLoaded()
    local pairKey = Types.MakeDiplomacyKey(
        firstFactionID,
        secondFactionID
    )
    local relation = pairKey
        and Factions.Registry.diplomacy[pairKey] or nil
    return relation ~= nil
        and relation.state == Constants.DIPLOMACY_WAR
end

function Factions.IsFactionAtWar(factionID)
    if not Types.IsValidFactionID(factionID) then
        return false
    end
    for _, relation in pairs(
        Factions.Registry.diplomacy or {}
    ) do
        if relation.state == Constants.DIPLOMACY_WAR
            and (relation.factionAID == factionID
                or relation.factionBID == factionID)
        then
            return true
        end
    end
    return false
end

local function setDiplomacy(
    firstFactionID,
    secondFactionID,
    state,
    options
)
    Factions.EnsureLoaded()
    local first = registryRecord(firstFactionID)
    local second = registryRecord(secondFactionID)
    local pairKey = Types.MakeDiplomacyKey(
        firstFactionID,
        secondFactionID
    )
    local existing
    local relation
    if not authority() then return false, "not_authority" end
    if not first or not second or not pairKey then
        return false, "invalid_faction_pair"
    end
    if first.status ~= "active"
        or second.status ~= "active"
    then
        return false, "faction_not_active"
    end
    options = type(options) == "table" and options or {}
    existing = Factions.Registry.diplomacy[pairKey]
    if existing and existing.state == state then
        return false, "unchanged", copy(existing)
    end
    relation = Types.NormalizeDiplomacy({
        factionAID = firstFactionID,
        factionBID = secondFactionID,
        state = state,
        changedAt = options.worldAgeHours,
        reason = options.reason,
        instigatorFactionID = options.instigatorFactionID,
        revision = math.max(
            tonumber(existing and existing.revision) or 0,
            0
        ) + 1,
    }, pairKey)
    Factions.Registry.diplomacy[pairKey] = relation
    touchFaction(first)
    touchFaction(second)
    touchRegistry()
    if PNC.FactionBehavior
        and PNC.FactionBehavior.ReconcileFaction
    then
        PNC.FactionBehavior.ReconcileFaction(
            firstFactionID,
            "diplomacy_" .. state
        )
        PNC.FactionBehavior.ReconcileFaction(
            secondFactionID,
            "diplomacy_" .. state
        )
    end
    return true, state, copy(relation)
end

function Factions.DeclareWar(
    firstFactionID,
    secondFactionID,
    options
)
    return setDiplomacy(
        firstFactionID,
        secondFactionID,
        Constants.DIPLOMACY_WAR,
        options
    )
end

function Factions.MakePeace(
    firstFactionID,
    secondFactionID,
    options
)
    return setDiplomacy(
        firstFactionID,
        secondFactionID,
        Constants.DIPLOMACY_PEACE,
        options
    )
end

local function factionForPlayer(player, create, at)
    local faction
    if create then
        local ok
        ok, _, faction = Factions.EnsurePlayerFaction(player, {
            worldAgeHours = at,
        })
        return ok and faction or nil
    end
    return Factions.GetPlayerFaction(player)
end

function Factions.OnPlayerAggression(
    player,
    targetRecord,
    worldAgeHours
)
    local targetFactionID =
        Factions.GetOrganizationalFactionID(targetRecord)
    local playerFaction
    if not targetFactionID then
        return false, "target_unaffiliated"
    end
    playerFaction = factionForPlayer(
        player,
        true,
        worldAgeHours
    )
    if not playerFaction then
        return false, "player_faction_unavailable"
    end
    if playerFaction.id == targetFactionID then
        return false, "same_faction"
    end
    return Factions.DeclareWar(
        playerFaction.id,
        targetFactionID,
        {
            worldAgeHours = worldAgeHours,
            reason = "player_attacked_member",
            instigatorFactionID = playerFaction.id,
        }
    )
end

function Factions.OnNPCAggression(
    attackerRecord,
    targetRecord,
    worldAgeHours
)
    local attackerFactionID =
        Factions.GetOrganizationalFactionID(attackerRecord)
    local targetFactionID =
        Factions.GetOrganizationalFactionID(targetRecord)
    if not attackerFactionID or not targetFactionID then
        return false, "unaffiliated"
    end
    if attackerFactionID == targetFactionID then
        return false, "same_faction"
    end
    return Factions.DeclareWar(
        attackerFactionID,
        targetFactionID,
        {
            worldAgeHours = worldAgeHours,
            reason = "npc_attacked_member",
            instigatorFactionID = attackerFactionID,
        }
    )
end

function Factions.OnNPCAttackPlayer(
    attackerRecord,
    player,
    worldAgeHours
)
    local attackerFactionID =
        Factions.GetOrganizationalFactionID(attackerRecord)
    local playerFaction
    if not attackerFactionID then
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
        return false, "same_or_missing_faction"
    end
    return Factions.DeclareWar(
        attackerFactionID,
        playerFaction.id,
        {
            worldAgeHours = worldAgeHours,
            reason = "npc_attacked_player",
            instigatorFactionID = attackerFactionID,
        }
    )
end

function Factions.CanNPCTargetPlayer(record, player)
    local factionID =
        Factions.GetOrganizationalFactionID(record)
    local faction = factionID and registryRecord(factionID)
    local playerFaction
    if not faction then
        return record and record.hostility
            and record.hostility.attackPlayers == true
    end
    playerFaction = Factions.GetPlayerFaction(player)
    if playerFaction and playerFaction.id == factionID then
        return false
    end
    if Archetypes.IsHostileToOutsiders(
        faction.archetypeID
    ) then
        return true
    end
    return playerFaction ~= nil
        and Factions.AreAtWar(factionID, playerFaction.id)
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
    targetFaction = Factions.GetFactionForPlayerKey(targetKey)
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
    return Factions.DeclareWar(
        observerFactionID,
        targetFaction.id,
        {
            worldAgeHours =
                relationship.lastEvaluatedAt,
            reason = "member_relationship_enemy",
            instigatorFactionID = observerFactionID,
        }
    )
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
    for _, relation in pairs(
        Factions.Registry.diplomacy or {}
    ) do
        if relation.factionAID == factionID
            or relation.factionBID == factionID
        then
            local otherID = relation.factionAID == factionID
                and relation.factionBID
                or relation.factionAID
            if relation.state == Constants.DIPLOMACY_WAR then
                relation.state = Constants.DIPLOMACY_PEACE
                relation.changedAt = at
                relation.reason = "faction_archived"
                relation.revision = math.max(
                    0,
                    math.floor(
                        tonumber(relation.revision) or 0
                    )
                ) + 1
                local other = registryRecord(otherID)
                if other then touchFaction(other) end
                reconcileFactionIDs[otherID] = true
            end
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

function Factions.OnNPCDeath(npcID)
    if not authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local record = PNC.Registry.Get(npcID)
    local affiliation = record
        and Types.NormalizeAffiliation(record.affiliation)
        or nil
    local faction = affiliation and affiliation.factionID
        and registryRecord(affiliation.factionID) or nil
    if not faction then return false, "unaffiliated" end
    if faction.leaderNPCID ~= npcID then
        return false, "not_leader"
    end
    faction.leaderNPCID = nil
    touchFaction(faction)
    touchRegistry()
    return true, "death_reconciled"
end

Factions.NormalizeFactionRegistry =
    Types.NormalizeFactionRegistry
Factions.NormalizeFaction = Types.NormalizeFaction
Factions.NormalizeAffiliation = Types.NormalizeAffiliation

local function onInitGlobalModData()
    Factions.Load()
end

local function onSave()
    Factions.Save()
end

if Events and Events.OnInitGlobalModData
    and not Factions.GlobalModDataHookRegistered
then
    Events.OnInitGlobalModData.Add(onInitGlobalModData)
    Factions.GlobalModDataHookRegistered = true
end

if Events and Events.OnSave
    and not Factions.SaveHookRegistered
then
    Events.OnSave.Add(onSave)
    Factions.SaveHookRegistered = true
end

return Factions
