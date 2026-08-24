-- Faction and community merge for player identity migration.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PlayerIdentityMigration = PNC.PlayerIdentityMigration or {}
local Internal = PNC.PlayerIdentityMigration.Internal
local copy = Internal.Copy
local atNow = Internal.AtNow

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

Internal.MergeFactions = mergeFactions

return Internal
