if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CommunityDebug = PNC.CommunityDebug or {}
PNC.CommunityDebugInternal = PNC.CommunityDebugInternal or {}

local Debug = PNC.CommunityDebug
local H = PNC.CommunityDebugInternal
local Communities = PNC.Communities
local CommunityMath = PNC.CommunityMath
local Constants = PNC.CommunityConstants
local Core = PNC.Core

function Debug.BuildSnapshot(
    selectedCommunityID,
    selectedFactionID,
    selectedNPCID,
    action,
    player
)
    local communities = Communities.List()
    local factions = {}
    local mobileGroups = {}
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
            worldAgeHours = H.WorldAgeHours(),
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
        local summary = H.FactionSummary(faction)
        factions[#factions + 1] = summary
        if summary.mobile then
            mobileGroups[#mobileGroups + 1] = summary
        end
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
            emblem = H.Copy(faction.emblem),
            leaderID = leader and leader.id or nil,
            leaderName = leader and leader.alive ~= false
                and tostring(leader.name or leader.id) or nil,
        }
    end
    table.sort(mobileGroups, function(left, right)
        return tostring(left.id) < tostring(right.id)
    end)
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
            local summary = H.NPCSummary(record)
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
        mobileGroups = mobileGroups,
        roster = roster,
        members = H.SelectedMembers(selected),
        selectedCommunity = H.Copy(selected),
        selectedFactionID = selectedFactionID,
        selectedNPC = H.Copy(selectedNPC),
        currentPlayerKey = playerKey,
        currentPlayerFactionID =
            actualPlayerFaction
            and actualPlayerFaction.id or nil,
        currentPlayerDiplomacyFactionID =
            playerFaction and playerFaction.id or nil,
        factionRelations = factionRelations,
        npcDiagnostics = diagnostics,
        validation = H.Copy(Debug.LastValidation),
        action = H.Copy(action),
        supplyCategories =
            H.Copy(Constants.SUPPLY_CATEGORIES),
        communityRoles = H.Copy(Constants.ROLES),
        generatedAt = H.WorldAgeHours(),
    }
end

return Debug
