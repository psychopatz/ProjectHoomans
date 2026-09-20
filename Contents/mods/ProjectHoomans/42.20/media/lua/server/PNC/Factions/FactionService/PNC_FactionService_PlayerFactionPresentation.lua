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

local function refreshFactionDogTags(faction)
    local inventory = PNC.Inventory
    local factionID = faction and faction.id or nil
    local members
    local index
    local member
    local record
    local _, changed
    if not Factions.GetMembers or not inventory
        or type(inventory.RefreshFactionDogTag) ~= "function"
    then
        return
    end
    members = Factions.GetMembers(factionID)
    if type(members) ~= "table" then return end
    for index = 1, #members do
        member = members[index]
        if member and member.alive ~= false then
            record = PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(member.npcID) or nil
            if record and record.alive ~= false
                and record.affiliation
                and tostring(record.affiliation.factionID or "")
                    == tostring(factionID or "")
            then
                _, changed = inventory.RefreshFactionDogTag(
                    record,
                    faction
                )
                if changed == true and PNC.Network
                    and type(PNC.Network.BroadcastRecord) == "function"
                then
                    PNC.Network.BroadcastRecord(
                        record,
                        "faction_dogtag_renamed"
                    )
                end
            end
        end
    end
end

function Factions.SetEmblem(factionID, value)
    local faction
    local normalized
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    faction = Internal.registryRecord(factionID)
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
        return true, "unchanged", Internal.copy(faction)
    end
    normalized.revision = normalized.revision + 1
    faction.emblem = normalized
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    for npcID, present in pairs(faction.memberIDs or {}) do
        local member = present == true and PNC.Registry.Get(npcID) or nil
        if member and PNC.Registry.MarkDirty then
            PNC.Registry.MarkDirty(member, "faction_emblem")
        end
    end
    return true, "updated", Internal.copy(faction)
end

function Factions.SetPlayerFactionEmblem(player, value)
    local playerKey
    local reason
    local faction
    if not Internal.authority() then return false, "not_authority" end
    playerKey, reason = Internal.playerKeyFor(
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
    if faction then
        local record = Internal.registryRecord(faction.id)
        local generatedName = record
            and type(record.name) == "string"
            and string.find(record.name, " Survivors$") ~= nil
        if record and record.tags
            and (record.tags.automaticallyCreated == true
                or generatedName)
            and record.tags.factionNameConfirmed ~= true
            and record.tags.factionNamePending ~= true
        then
            record.tags.factionNamePending = true
            Internal.touchFaction(record)
            Internal.touchRegistry()
            faction = Internal.copy(record)
        end
        return true, "existing", faction
    end
    options = type(options) == "table" and options or {}
    local tags = Internal.copy(type(options.tags) == "table" and options.tags or {})
    tags.automaticallyCreated = true
    tags.factionNamePending = true
    ok, reason, faction = Factions.CreatePlayerFaction(player, {
        name = options.name,
        archetypeID = options.archetypeID or "settler",
        createdAt = options.worldAgeHours,
        tags = tags,
    })
    if not ok and reason == "player_already_affiliated"
        and faction
    then
        return true, "existing", faction
    end
    return ok, reason, faction
end

function Factions.SetPlayerFactionName(player, value)
    local playerKey
    local reason
    local faction
    if not Internal.authority() then return false, "not_authority" end
    playerKey, reason = Internal.playerKeyFor(player, "rename_player_faction", true)
    if not playerKey then return false, reason end
    faction, reason = Factions.GetFactionForPlayerKey(playerKey)
    if not faction then return false, reason end
    if faction.ownerPlayerKey ~= playerKey then
        return false, "not_faction_owner"
    end
    local changed
    changed, reason, faction = Factions.SetName(faction.id, value)
    if not changed and reason ~= "unchanged" then
        return false, reason, faction
    end
    local record = Internal.registryRecord(faction.id)
    if record then
        record.tags = record.tags or {}
        if record.tags.factionNamePending ~= nil
            or record.tags.factionNameConfirmed ~= true
        then
            record.tags.factionNamePending = nil
            record.tags.factionNameConfirmed = true
            Internal.touchFaction(record)
            Internal.touchRegistry()
        end
    end
    refreshFactionDogTags(faction)
    return true, changed and "renamed" or "name_confirmed", Internal.copy(record)
end

function Factions.IsPlayerFaction(factionID)
    local faction = Internal.registryRecord(factionID)
    if not faction or Internal.isProvisionalFaction(faction) then
        return false
    end
    for _, _ in pairs(faction.playerMemberKeys or {}) do
        return true
    end
    return false
end

return Factions
