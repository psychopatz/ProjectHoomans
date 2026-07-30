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
    local membersByFaction = {}
    local changed = false
    for factionID, faction in pairs(Factions.Registry.byID) do
        byArchetype[faction.archetypeID] =
            byArchetype[faction.archetypeID] or {}
        byArchetype[faction.archetypeID][factionID] = true
        membersByFaction[factionID] = {}
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
    -- Compatibility facade only. Never derive this tactical classification
    -- from an organizational faction archetype.
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
        revision = 1,
    })
    if not faction then return false, "invalid_name" end
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
    if leader then commitAffiliation(leader, leaderAffiliation) end
    touchRegistry()
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

function Factions.Archive(factionID, reason, worldAgeHours)
    local faction
    local at
    local memberIDs = {}
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
        end
    end
    faction.status = "archived"
    faction.archivedAt = at
    faction.leaderNPCID = nil
    faction.memberIDs = {}
    if type(reason) == "string" and reason ~= "" then
        local tags = Types.NormalizeTags({
            archiveReason = reason,
        })
        faction.tags.archiveReason = tags.archiveReason
    end
    touchFaction(faction)
    touchRegistry()
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
