if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Factions = PNC.Factions
local Internal = Factions.Internal
local Core = PNC.Core
local Constants = PNC.FactionConstants
local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
function Factions.Archive(factionID, reason, worldAgeHours)
    local faction
    local at
    local memberIDs = {}
    local reconcileFactionIDs = {}
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    faction = Internal.registryRecord(factionID)
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
    at = Internal.finiteTimestamp(worldAgeHours, faction.createdAt)
    for npcID, _ in pairs(faction.memberIDs or {}) do
        memberIDs[#memberIDs + 1] = npcID
    end
    table.sort(memberIDs)
    for _, npcID in ipairs(memberIDs) do
        local record = PNC.Registry.Get(npcID)
        if record and record.affiliation
            and record.affiliation.factionID == factionID
        then
            local affiliation = Internal.affiliationFor(record, faction)
            local former = Internal.addHistory(
                affiliation,
                factionID,
                at,
                "faction_archived"
            )
            Internal.commitAffiliation(record, Types.NewAffiliation({
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
        local other = Internal.registryRecord(otherID)
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
            if other then Internal.touchFaction(other) end
            reconcileFactionIDs[otherID] = true
        end
    end
    if type(reason) == "string" and reason ~= "" then
        local tags = Types.NormalizeTags({
            archiveReason = reason,
        })
        faction.tags.archiveReason = tags.archiveReason
    end
    Internal.touchFaction(faction)
    Internal.touchRegistry()
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
    return true, "archived", Internal.copy(faction)
end

function Factions.Destroy(factionID, reason, worldAgeHours)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    if faction.status == "destroyed" then
        return false, "already_destroyed"
    end
    local at = Internal.finiteTimestamp(
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
        faction = Internal.registryRecord(factionID)
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
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    return true, "destroyed", Internal.copy(faction)
end

function Factions.OnNPCDeath(npcID)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local record = PNC.Registry.Get(npcID)
    if PNC.Communities and PNC.Communities.OnNPCDeath then
        PNC.Communities.OnNPCDeath(npcID)
    end
    local affiliation = record
        and Types.NormalizeAffiliation(record.affiliation)
        or nil
    local faction = affiliation and affiliation.factionID
        and Internal.registryRecord(affiliation.factionID) or nil
    local entityKey = EntityRef and EntityRef.ForNPC
        and Types.IsValidNPCID(npcID)
        and EntityRef.ForNPC(npcID) or nil
    Internal.traceFactionCallback("callback", {
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
    local leaderAffiliation = Internal.affiliationFor(record, faction)
    leaderAffiliation.rank = "member"
    if leaderAffiliation.role == "leader" then
        leaderAffiliation.role = Archetypes.GetDefaultRole(
            faction.archetypeID
        )
    end
    Internal.commitAffiliation(record, leaderAffiliation)
    faction.leaderNPCID = nil
    Internal.touchFaction(faction)
    Internal.touchRegistry()
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
