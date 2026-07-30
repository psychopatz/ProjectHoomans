-- Read-only faction formatting plus guarded debug-service action routing.

if isClient and isClient() and (not isServer or not isServer()) then
    return
end

PNC = PNC or {}
PNC.FactionDebug = PNC.FactionDebug or {}

local Debug = PNC.FactionDebug
local Factions = PNC.Factions
local Archetypes = PNC.FactionArchetypes
local Types = PNC.FactionTypes
local Core = PNC.Core

local function copy(value)
    return Core.DeepCopy(value)
end

local function worldAgeHours()
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return math.max(
            0,
            tonumber(getGameTime():getWorldAgeHours()) or 0
        )
    end
    return 0
end

local function factionSummary(faction)
    local archetype = Archetypes.Get(faction.archetypeID)
    return {
        id = faction.id,
        name = faction.name,
        archetypeID = faction.archetypeID,
        archetypeLabel = archetype and archetype.label
            or faction.archetypeID,
        status = faction.status,
        leaderNPCID = faction.leaderNPCID,
        memberCount = Core.TableSize(faction.memberIDs),
        createdAt = faction.createdAt,
        archivedAt = faction.archivedAt,
        tags = copy(faction.tags),
        revision = faction.revision,
    }
end

local function npcSummary(record)
    local affiliation = Factions.GetNPCAffiliation(record.id)
    return {
        id = record.id,
        name = tostring(record.name or record.id),
        alive = record.alive ~= false,
        legacyFaction = record.faction,
        recordRevision = record.recordRevision,
        presenceRevision = record.presenceRevision,
        affiliation = affiliation,
    }
end

local function actionResult(ok, reason, fields)
    local result = fields or {}
    result.ok = ok == true
    result.reason = reason
    return result
end

function Debug.BuildSnapshot(selectedFactionID, selectedNPCID, action)
    local factions = {}
    local roster = {}
    local selected
    local members = {}
    Factions.EnsureLoaded()
    for _, faction in ipairs(Factions.List()) do
        factions[#factions + 1] = factionSummary(faction)
    end
    for _, record in pairs(PNC.Registry.Data or {}) do
        if record.alive ~= false then
            roster[#roster + 1] = npcSummary(record)
        end
    end
    table.sort(roster, function(left, right)
        if left.name ~= right.name then
            return left.name < right.name
        end
        return left.id < right.id
    end)
    if Types.IsValidFactionID(selectedFactionID) then
        local faction = Factions.Get(selectedFactionID)
        if faction then
            selected = factionSummary(faction)
            members = copy(Factions.GetMembers(faction.id))
        end
    end
    return {
        registrySchemaVersion =
            PNC.FactionConstants.REGISTRY_SCHEMA_VERSION,
        registryRevision = Factions.Registry.revision,
        factions = factions,
        selectedFaction = selected,
        selectedFactionID = selected and selected.id or nil,
        selectedNPCID = Types.IsValidNPCID(selectedNPCID)
            and selectedNPCID or nil,
        members = members,
        roster = roster,
        actionResult = copy(action),
        generatedAt = worldAgeHours(),
    }
end

function Debug.PerformAction(player, args)
    local action = tostring(args and args.factionAction or "")
    local factionID = args and args.factionID
    local npcID = args and args.npcID
    local at = worldAgeHours()
    local ok
    local reason
    local value
    if action == "create" then
        local archetypeID = tostring(
            args and args.archetypeID or ""
        )
        local archetype = Archetypes.Get(archetypeID)
        if not archetype then
            return Debug.BuildSnapshot(
                factionID,
                npcID,
                actionResult(false, "unknown_archetype")
            )
        end
        ok, reason, value = Factions.Create({
            name = "Debug " .. archetype.label .. " "
                .. tostring(math.floor(at * 1000)),
            archetypeID = archetypeID,
            createdAt = at,
            tags = { debugCreated = true },
        })
        if ok then factionID = value.id end
    elseif action == "assign" then
        ok, reason, value = Factions.AddNPC(
            factionID,
            npcID,
            {
                membershipStatus = "member",
                joinedAt = at,
            }
        )
    elseif action == "transfer" then
        ok, reason, value = Factions.TransferNPC(
            npcID,
            factionID,
            {
                membershipStatus = "member",
                worldAgeHours = at,
            }
        )
    elseif action == "remove" then
        ok, reason, value = Factions.RemoveNPC(
            factionID,
            npcID,
            "removed",
            at
        )
    elseif action == "leader" then
        ok, reason, value = Factions.SetLeader(
            factionID,
            npcID,
            at
        )
    elseif action == "role" then
        ok, reason, value = Factions.SetNPCRole(
            npcID,
            tostring(args and args.role or "")
        )
    elseif action == "rank" then
        ok, reason, value = Factions.SetNPCRank(
            npcID,
            tostring(args and args.rank or "")
        )
    elseif action == "archive" then
        ok, reason, value = Factions.Archive(
            factionID,
            "debug_archive",
            at
        )
    else
        ok, reason = false, "unsupported_faction_action"
    end
    return Debug.BuildSnapshot(
        factionID,
        npcID,
        actionResult(ok, reason, {
            action = action,
            factionID = factionID,
            npcID = npcID,
            resultingRevision = value and value.revision,
        })
    )
end

function Debug.FormatList()
    local lines = { "Faction Debug", "Factions:" }
    for _, faction in ipairs(Factions.List()) do
        lines[#lines + 1] = string.format(
            "  %s | %s | %s | %s",
            faction.id,
            faction.name,
            faction.archetypeID,
            faction.status
        )
    end
    if #lines == 2 then lines[#lines + 1] = "  (none)" end
    return table.concat(lines, "\n")
end

function Debug.FormatFaction(factionID)
    local faction, reason = Factions.Get(factionID)
    if not faction then
        return "Faction Debug\nStatus: " .. tostring(reason)
    end
    return table.concat({
        "Faction Debug",
        "ID: " .. faction.id,
        "Name: " .. faction.name,
        "Archetype: " .. faction.archetypeID,
        "Status: " .. faction.status,
        "Leader: " .. tostring(faction.leaderNPCID),
        "Members: " .. tostring(Core.TableSize(faction.memberIDs)),
        "Revision: " .. tostring(faction.revision),
    }, "\n")
end

function Debug.FormatMembers(factionID)
    local members, reason = Factions.GetMembers(factionID)
    local lines = {
        "Faction Members",
        "Faction: " .. tostring(factionID),
    }
    if reason then
        lines[#lines + 1] = "Status: " .. tostring(reason)
        return table.concat(lines, "\n")
    end
    for _, member in ipairs(members) do
        local affiliation = member.affiliation or {}
        lines[#lines + 1] = string.format(
            "  %s | %s | %s | %s | %s",
            member.npcID,
            member.name,
            affiliation.membershipStatus or "unknown",
            affiliation.role or "unknown",
            affiliation.rank or "unknown"
        )
    end
    if #members == 0 then lines[#lines + 1] = "  (none)" end
    return table.concat(lines, "\n")
end

return Debug
