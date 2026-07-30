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
        ownerPlayerKey = faction.ownerPlayerKey,
        playerMemberCount =
            Core.TableSize(faction.playerMemberKeys),
        createdAt = faction.createdAt,
        archivedAt = faction.archivedAt,
        tags = copy(faction.tags),
        policy = copy(faction.policy),
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

function Debug.BuildSnapshot(
    selectedFactionID,
    selectedNPCID,
    action,
    player,
    selectedTargetFactionID
)
    local factions = {}
    local roster = {}
    local selected
    local members = {}
    local playerKey
    local playerFaction
    local diplomacy = {}
    local selectedTarget
    local relationForward
    local relationReverse
    local intentPreview
    Factions.EnsureLoaded()
    if player and PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetEntityKey
    then
        playerKey = PNC.PlayerCharacters.GetEntityKey(player, {
            callback = "faction_debug_snapshot",
            worldAgeHours = worldAgeHours(),
        })
        playerFaction = playerKey
            and Factions.GetFactionForPlayerKey(playerKey)
            or nil
    end
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
            for targetID, relation in pairs(
                faction.relations or {}
            ) do
                local item = copy(relation)
                item.sourceFactionID = faction.id
                item.targetFactionID = targetID
                diplomacy[#diplomacy + 1] = item
            end
            table.sort(diplomacy, function(left, right)
                return left.targetFactionID
                    < right.targetFactionID
            end)
            local targetID = Types.IsValidFactionID(
                selectedTargetFactionID
            ) and selectedTargetFactionID or nil
            if not targetID and playerFaction
                and playerFaction.id ~= faction.id
            then
                targetID = playerFaction.id
            end
            if targetID and targetID ~= faction.id then
                local target = Factions.Get(targetID)
                if target then
                    selectedTarget = factionSummary(target)
                    relationForward =
                        Factions.GetRelation(faction.id, targetID)
                    relationReverse =
                        Factions.GetRelation(targetID, faction.id)
                    local preview = PNC.FactionIntent.Resolve({
                        archetypeID = faction.archetypeID,
                        policy = faction.policy,
                        diplomaticState = relationForward
                            and relationForward.state or "unknown",
                        atWar = relationForward
                            and relationForward.atWar,
                        allied = relationForward
                            and relationForward.allied,
                        activeTruce = relationForward
                            and relationForward.truceUntil
                                > worldAgeHours(),
                    })
                    intentPreview = preview
                end
            end
        end
    end
    return {
        registrySchemaVersion =
            PNC.FactionConstants.REGISTRY_SCHEMA_VERSION,
        registryRevision = Factions.Registry.revision,
        factions = factions,
        selectedFaction = selected,
        selectedFactionID = selected and selected.id or nil,
        selectedTargetFaction = selectedTarget,
        selectedTargetFactionID =
            selectedTarget and selectedTarget.id or nil,
        relationForward = relationForward,
        relationReverse = relationReverse,
        intentPreview = intentPreview,
        selectedNPCID = Types.IsValidNPCID(selectedNPCID)
            and selectedNPCID or nil,
        members = members,
        diplomacy = diplomacy,
        roster = roster,
        currentPlayerKey = playerKey,
        currentPlayerFactionID =
            playerFaction and playerFaction.id or nil,
        actionResult = copy(action),
        generatedAt = worldAgeHours(),
    }
end

function Debug.PerformAction(player, args)
    local action = tostring(args and args.factionAction or "")
    local factionID = args and args.factionID
    local targetFactionID = args and args.targetFactionID
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
                actionResult(false, "unknown_archetype"),
                player
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
    elseif action == "create_player_faction" then
        ok, reason, value = Factions.CreatePlayerFaction(
            player,
            {
                archetypeID = "settler",
                createdAt = at,
                tags = { debugCreated = true },
            }
        )
        if ok and value then factionID = value.id end
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
    elseif action == "war" or action == "peace"
        or action == "truce" or action == "alliance"
        or action == "break_alliance"
    then
        if not factionID or not targetFactionID
            or factionID == targetFactionID
        then
            ok, reason = false, "select_distinct_factions"
        elseif action == "war" then
            ok, reason, value = Factions.DeclareWar(
                factionID,
                targetFactionID,
                {
                    worldAgeHours = at,
                    reason = "manual_debug",
                    instigatorFactionID = factionID,
                }
            )
        elseif action == "peace" then
            ok, reason, value = Factions.MakePeace(
                factionID,
                targetFactionID,
                {
                    worldAgeHours = at,
                    instigatorFactionID = factionID,
                }
            )
        elseif action == "truce" then
            ok, reason, value = Factions.StartTruce(
                factionID,
                targetFactionID,
                {
                    worldAgeHours = at,
                    truceUntil = at + 24,
                    instigatorFactionID = factionID,
                }
            )
        elseif action == "alliance" then
            ok, reason, value = Factions.FormAlliance(
                factionID,
                targetFactionID,
                {
                    worldAgeHours = at,
                    instigatorFactionID = factionID,
                    override = true,
                }
            )
        else
            ok, reason, value = Factions.BreakAlliance(
                factionID,
                targetFactionID,
                {
                    worldAgeHours = at,
                    instigatorFactionID = factionID,
                }
            )
        end
    elseif action == "incident_minor"
        or action == "incident_severe"
        or action == "incident_killed"
        or action == "incident_rescue"
        or action == "recalculate"
    then
        if not factionID or not targetFactionID
            or factionID == targetFactionID
        then
            ok, reason = false, "select_distinct_factions"
        elseif action == "recalculate" then
            ok, reason, value = Factions.RecalculateRelation(
                factionID,
                targetFactionID,
                at
            )
        else
            local incidentTypes = {
                incident_minor = "member_attacked_minor",
                incident_severe = "member_attacked_severe",
                incident_killed = "member_killed",
                incident_rescue = "member_rescued",
            }
            ok, reason, value =
                PNC.FactionIncidentService.AddIncident(
                    factionID,
                    targetFactionID,
                    incidentTypes[action],
                    {
                        worldAgeHours = at,
                        externalID = "debug:" .. action .. ":"
                            .. factionID .. ":" .. targetFactionID
                            .. ":" .. tostring(at),
                        public = true,
                        witnessed = true,
                    }
                )
        end
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
        }),
        player,
        targetFactionID
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
