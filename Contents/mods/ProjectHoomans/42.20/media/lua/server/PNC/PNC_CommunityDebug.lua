-- Sanitized community diagnostics and guarded debug action routing.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.CommunityDebug = PNC.CommunityDebug or {}

local Debug = PNC.CommunityDebug
local Communities = PNC.Communities
local CommunityMath = PNC.CommunityMath
local Constants = PNC.CommunityConstants
local Core = PNC.Core

Debug.LastValidation = Debug.LastValidation or nil

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

local function actionResult(ok, reason, action)
    return {
        ok = ok == true,
        reason = reason,
        action = action,
    }
end

local function factionSummary(faction)
    return {
        id = faction.id,
        name = faction.name,
        archetypeID = faction.archetypeID,
        status = faction.status,
    }
end

local function npcSummary(record)
    local affiliation = PNC.FactionTypes.NormalizeAffiliation(
        record.affiliation
    )
    local community = affiliation.communityID
        and Communities.Get(affiliation.communityID) or nil
    local distance = community
        and CommunityMath.GetDistanceFromHome(
            community,
            record.x,
            record.y,
            record.z
        ) or nil
    return {
        id = record.id,
        name = tostring(record.name or record.id),
        alive = record.alive ~= false,
        x = tonumber(record.x) or 0,
        y = tonumber(record.y) or 0,
        z = tonumber(record.z) or 0,
        factionID = affiliation.factionID,
        factionRole = affiliation.role,
        communityID = affiliation.communityID,
        communityName = community and community.name or nil,
        communityRole = affiliation.communityRole,
        communityJoinedAt = affiliation.communityJoinedAt,
        affiliationRevision = affiliation.revision,
        insideHome = community and
            CommunityMath.IsInsideHomeArea(
                community,
                record.x,
                record.y,
                record.z
            ) or false,
        distanceFromHome = distance,
        recordRevision = record.recordRevision,
        presenceRevision = record.presenceRevision,
    }
end

local function selectedMembers(community)
    local output = {}
    if not community then return output end
    for npcID, present in pairs(community.memberIDs or {}) do
        local record = present == true
            and PNC.Registry.Get(npcID) or nil
        if record then
            output[#output + 1] = npcSummary(record)
        end
    end
    table.sort(output, function(left, right)
        return left.name < right.name
    end)
    return output
end

function Debug.BuildSnapshot(
    selectedCommunityID,
    selectedFactionID,
    selectedNPCID,
    action,
    player
)
    local communities = Communities.List()
    local factions = {}
    local roster = {}
    local diagnostics = {}
    local selected
    local selectedNPC
    local playerKey
    local playerFaction
    local actualPlayerFaction
    local factionRelations = {}
    Communities.EnsureLoaded()
    if player and PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetEntityKey
    then
        playerKey = PNC.PlayerCharacters.GetEntityKey(player, {
            callback = "community_debug_snapshot",
            worldAgeHours = worldAgeHours(),
        })
        playerFaction = playerKey
            and PNC.Factions
                .GetDiplomacyFactionForPlayerKey(playerKey)
            or nil
        actualPlayerFaction = playerKey
            and PNC.Factions.GetFactionForPlayerKey(
                playerKey
            ) or nil
    end
    for _, faction in ipairs(PNC.Factions.List()) do
        factions[#factions + 1] = factionSummary(faction)
        local leader = faction.leaderNPCID
            and PNC.Registry.Get(faction.leaderNPCID) or nil
        local relation = playerFaction
            and faction.id ~= playerFaction.id
            and PNC.Factions.GetRelation(
                faction.id,
                playerFaction.id
            ) or nil
        factionRelations[faction.id] = {
            isPlayerFaction = actualPlayerFaction ~= nil
                and faction.id == actualPlayerFaction.id,
            state = relation and relation.state
                or playerFaction and "neutral" or "unknown",
            atWar = playerFaction ~= nil
                and faction.id ~= playerFaction.id
                and PNC.Factions.AreAtWar(
                    faction.id,
                    playerFaction.id
                ) or false,
            allied = relation
                and relation.allied == true or false,
            factionStatus = faction.status,
            emblem = copy(faction.emblem),
            leaderID = leader and leader.id or nil,
            leaderName = leader and leader.alive ~= false
                and tostring(leader.name or leader.id) or nil,
        }
    end
    for _, community in ipairs(communities) do
        if community.id == selectedCommunityID then
            selected = community
        end
    end
    if not selected then selected = communities[1] end
    selectedCommunityID = selected and selected.id or nil
    selectedFactionID = selectedFactionID
        or selected and selected.factionID
        or factions[1] and factions[1].id
        or nil
    for _, record in pairs(PNC.Registry.Data or {}) do
        if record.alive ~= false then
            local summary = npcSummary(record)
            diagnostics[#diagnostics + 1] = summary
            if not selectedFactionID
                or summary.factionID == selectedFactionID
            then
                roster[#roster + 1] = summary
            end
            if record.id == selectedNPCID then
                selectedNPC = summary
            end
        end
    end
    table.sort(roster, function(left, right)
        return left.name < right.name
    end)
    table.sort(diagnostics, function(left, right)
        return left.id < right.id
    end)
    return {
        registry = {
            schemaVersion =
                Communities.Registry.schemaVersion,
            revision = Communities.Registry.revision,
            count = #communities,
        },
        communities = communities,
        sites = Communities.ListSites(),
        factions = factions,
        roster = roster,
        members = selectedMembers(selected),
        selectedCommunity = copy(selected),
        selectedFactionID = selectedFactionID,
        selectedNPC = copy(selectedNPC),
        currentPlayerKey = playerKey,
        currentPlayerFactionID =
            actualPlayerFaction
            and actualPlayerFaction.id or nil,
        currentPlayerDiplomacyFactionID =
            playerFaction and playerFaction.id or nil,
        factionRelations = factionRelations,
        npcDiagnostics = diagnostics,
        validation = copy(Debug.LastValidation),
        action = copy(action),
        supplyCategories =
            copy(Constants.SUPPLY_CATEGORIES),
        communityRoles = copy(Constants.ROLES),
        generatedAt = worldAgeHours(),
    }
end

function Debug.PerformAction(player, args)
    local action = tostring(
        args and args.communityAction or ""
    )
    local communityID = args and args.communityID
    local factionID = args and args.factionID
    local npcID = args and args.npcID
    local at = worldAgeHours()
    local ok
    local reason
    local value
    if action == "create_settlement"
        or action == "create_camp"
    then
        local record = npcID and PNC.Registry.Get(npcID)
            or nil
        local x = record and record.x
            or player and player.getX and player:getX()
        local y = record and record.y
            or player and player.getY and player:getY()
        local z = record and record.z
            or player and player.getZ and player:getZ()
        local mode = action == "create_camp"
            and "camped" or "settled"
        ok, reason, value = Communities.Create({
            factionID = factionID,
            name = mode == "camped"
                and "Debug Community Camp "
                    .. tostring(math.floor(at * 1000))
                or "Debug Community Settlement "
                    .. tostring(math.floor(at * 1000)),
            mode = mode,
            home = { x = x, y = y, z = z },
            createdAt = at,
        })
        if ok then
            communityID = value.id
            local site = PNC.CommunitySiteResolver
                and PNC.CommunitySiteResolver.DescribeAt
                and PNC.CommunitySiteResolver.DescribeAt(
                    x,
                    y,
                    z,
                    { createdAt = at }
                ) or nil
            if site then
                ok, reason, value = Communities.ReserveSite(
                    communityID,
                    site,
                    at
                )
            end
        end
    elseif action == "assign" then
        ok, reason, value = Communities.AddNPC(
            communityID,
            npcID,
            {
                communityRole = args.communityRole,
                joinedAt = at,
            }
        )
    elseif action == "transfer" then
        ok, reason, value = Communities.TransferNPC(
            npcID,
            communityID,
            {
                communityRole = args.communityRole,
                worldAgeHours = at,
            }
        )
    elseif action == "remove" then
        ok, reason, value = Communities.RemoveNPC(
            communityID,
            npcID,
            "debug_removed",
            at
        )
    elseif action == "leader" then
        ok, reason, value = Communities.SetLeader(
            communityID,
            npcID,
            at
        )
    elseif action == "role" then
        if args.communityRole == "leader" then
            ok, reason, value = Communities.SetLeader(
                communityID,
                npcID,
                at
            )
        else
            ok, reason, value = Communities.AddNPC(
                communityID,
                npcID,
                {
                    communityRole = args.communityRole,
                    joinedAt = at,
                }
            )
        end
    elseif action == "set_home_to_npc" then
        local record = npcID and PNC.Registry.Get(npcID)
            or nil
        if not record then
            ok, reason = false, "npc_not_found"
        else
            local community = Communities.Get(communityID)
            ok, reason, value = Communities.SetHome(
                communityID,
                {
                    x = record.x,
                    y = record.y,
                    z = record.z,
                    radius = community
                        and community.home.radius,
                }
            )
        end
    elseif action == "security" then
        local community = Communities.Get(communityID)
        if not community then
            ok, reason = false, "community_not_found"
        else
            ok, reason, value = Communities.SetSecurity(
                communityID,
                community.security
                    + (tonumber(args.delta) or 0)
            )
        end
    elseif action == "morale" then
        local community = Communities.Get(communityID)
        if not community then
            ok, reason = false, "community_not_found"
        else
            ok, reason, value = Communities.SetMorale(
                communityID,
                community.morale
                    + (tonumber(args.delta) or 0)
            )
        end
    elseif action == "supply_add" then
        ok, reason, value = Communities.AddSupply(
            communityID,
            args.category,
            tonumber(args.amount) or 0
        )
    elseif action == "supply_remove" then
        ok, reason, value = Communities.RemoveSupply(
            communityID,
            args.category,
            tonumber(args.amount) or 0
        )
    elseif action == "archive" then
        ok, reason, value = Communities.Archive(
            communityID,
            "manual_debug",
            at
        )
    elseif action == "destroy" then
        ok, reason, value = Communities.Destroy(
            communityID,
            "manual_debug",
            at
        )
    elseif action == "claim_site" then
        local playerKey = PNC.PlayerCharacters
            and PNC.PlayerCharacters.GetEntityKey
            and PNC.PlayerCharacters.GetEntityKey(player, {
                callback = "community_site_claim",
                worldAgeHours = at,
            }) or nil
        ok, reason, value = Communities.ClaimSite(
            args and args.siteID,
            playerKey,
            at
        )
    elseif action == "unclaim_site" then
        local playerKey = PNC.PlayerCharacters
            and PNC.PlayerCharacters.GetEntityKey
            and PNC.PlayerCharacters.GetEntityKey(player, {
                callback = "community_site_unclaim",
                worldAgeHours = at,
            }) or nil
        ok, reason, value = Communities.UnclaimSite(
            args and args.siteID,
            playerKey
        )
    elseif action == "validate" then
        Debug.LastValidation =
            PNC.CommunityValidation.ValidateRegistry()
        ok = Debug.LastValidation.ok
        reason = ok and "registry_valid"
            or "registry_invalid"
    elseif action == "repair_indexes" then
        local changed =
            PNC.CommunityValidation.RepairIndexes()
        Debug.LastValidation =
            PNC.CommunityValidation.ValidateRegistry()
        ok = true
        reason = changed and "indexes_repaired"
            or "indexes_already_valid"
    else
        ok, reason = false, "unsupported_community_action"
    end
    return Debug.BuildSnapshot(
        communityID,
        factionID,
        npcID,
        actionResult(ok, reason, action),
        player
    )
end

function Debug.FormatCommunity(communityID)
    local community, reason = Communities.Get(communityID)
    if not community then
        return "Community Debug\nStatus: " .. tostring(reason)
    end
    return table.concat({
        "Community Debug",
        "ID: " .. community.id,
        "Name: " .. community.name,
        "Faction: " .. community.factionID,
        "Mode/status: " .. community.mode
            .. "/" .. community.status,
        "Population: "
            .. tostring(community.currentPopulation)
            .. "/" .. tostring(
                community.populationCapacity
            ),
        "Security: " .. tostring(community.security),
        "Morale: " .. tostring(community.morale),
        "Revision: " .. tostring(community.revision),
    }, "\n")
end

return Debug
