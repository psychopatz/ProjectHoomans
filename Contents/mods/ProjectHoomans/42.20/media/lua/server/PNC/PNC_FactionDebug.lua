-- Read-only faction formatting plus guarded debug-service action routing.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.FactionDebug = PNC.FactionDebug or {}

local Debug = PNC.FactionDebug
local Factions = PNC.Factions
local Archetypes = PNC.FactionArchetypes
local Types = PNC.FactionTypes
local Core = PNC.Core
local Balance = PNC.FactionBalance

Debug.LastValidation = Debug.LastValidation or nil
Debug.LastScenario = Debug.LastScenario or nil

local function groupSpec(player, args, at)
    return {
        x = player and player.getX and player:getX() or 0,
        y = player and player.getY and player:getY() or 0,
        z = player and player.getZ and player:getZ() or 0,
        siteSelection = "random_house",
        communityMode = "settled",
        groupSize = args and args.groupSize,
        presenceMode = args and args.presenceMode,
        worldAgeHours = at,
        debug = true,
    }
end

local function mobileGroupSpec(player, args, at)
    return {
        x = player and player.getX and player:getX() or 0,
        y = player and player.getY and player:getY() or 0,
        z = player and player.getZ and player:getZ() or 0,
        groupSize = args and args.groupSize,
        presenceMode = args and args.presenceMode,
        mobilePathMode = args and args.mobilePathMode,
        worldAgeHours = at,
        debug = true,
    }
end

local function generatedFactionName(archetypeID, at)
    local Generator = PNC.FactionNameGenerator
    if not Generator or not Generator.GenerateFactionName then
        return "Survivor " .. tostring(archetypeID)
    end
    local randomSalt = 0
    if ZombRand then
        local ok
        local value
        ok, value = pcall(ZombRand, 1000000)
        if ok then randomSalt = tonumber(value) or 0 end
    end
    local used = {}
    for _, faction in ipairs(Factions.List()) do
        used[faction.name] = true
    end
    local attempt
    for attempt = 1, 32 do
        local seed = table.concat({
            tostring(archetypeID),
            tostring(math.floor((tonumber(at) or 0) * 1000)),
            tostring(randomSalt),
            tostring(attempt),
        }, ":")
        local name = Generator.GenerateFactionName(
            archetypeID,
            seed
        )
        if not used[name] then return name end
    end
    return "New " .. Generator.GenerateFactionName(
        archetypeID,
        tostring(at) .. ":fallback"
    )
end

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
    local mobile = faction.mobile
    local archetypeLabel = archetype and archetype.label
        or faction.archetypeID
    if mobile and mobile.active == true then
        if faction.archetypeID == "looter" then
            archetypeLabel = "Mobile Looter Group"
        elseif faction.archetypeID == "trader" then
            archetypeLabel = "Trading Caravan"
        end
    end
    local communities = PNC.Communities
        and PNC.Communities.GetForFaction
        and PNC.Communities.GetForFaction(faction.id)
        or {}
    local communityNames = {}
    local communityPopulation = 0
    local communitySupplies = {
        food = 0,
        medicine = 0,
        ammunition = 0,
        tools = 0,
        materials = 0,
    }
    for _, community in ipairs(communities) do
        communityNames[#communityNames + 1] =
            community.name .. " (" .. community.mode
                .. "/" .. community.status .. ")"
        if community.status == "active" then
            communityPopulation = communityPopulation
                + (tonumber(community.currentPopulation) or 0)
        end
        for category, amount in pairs(
            community.supplies or {}
        ) do
            communitySupplies[category] =
                (tonumber(communitySupplies[category]) or 0)
                + (tonumber(amount) or 0)
        end
    end
    return {
        id = faction.id,
        name = faction.name,
        archetypeID = faction.archetypeID,
        archetypeLabel = archetypeLabel,
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
        emblem = copy(faction.emblem),
        mobile = copy(mobile),
        revision = faction.revision,
        communityCount = #communities,
        communityNames = communityNames,
        communityPopulation = communityPopulation,
        communitySupplies = communitySupplies,
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

local function targetSummary(target)
    if type(target) ~= "table" then return nil end
    return {
        kind = target.kind,
        id = target.id or target.npcID
            or target.onlineID or target.zombieId,
        username = target.username,
        visible = target.visible,
        threatening = target.threatening,
    }
end

local function relationshipChanges(record, playerKey)
    local output = {}
    local changes = record.runtime
        and record.runtime.relationshipDebugChanges or {}
    local first = math.max(1, #changes - 15)
    local index
    for index = first, #changes do
        local change = changes[index]
        if change.targetKey == playerKey then
            output[#output + 1] = copy(change)
            while #output > 5 do
                table.remove(output, 1)
            end
        end
    end
    return output
end

local function npcDiagnostic(
    record,
    player,
    playerKey,
    playerFaction,
    at
)
    local affiliation = Factions.GetNPCAffiliation(record.id)
        or {}
    local factionID = affiliation.factionID
    local faction = factionID and Factions.Get(factionID) or nil
    local relation = faction and playerFaction
        and faction.id ~= playerFaction.id
        and Factions.GetRelation(
            faction.id,
            playerFaction.id
        ) or nil
    local intent = player
        and PNC.FactionBehavior
        and PNC.FactionBehavior.ResolveIntent
        and PNC.FactionBehavior.ResolveIntent(
            record,
            player,
            {
                worldAgeHours = at,
                suppressTelemetry = true,
            }
        ) or nil
    local hostility = record.hostility or {}
    local runtime = record.runtime or {}
    local relationship = playerKey
        and PNC.Relationships
        and PNC.Relationships.Get
        and PNC.Relationships.Get(record.id, playerKey)
        or nil
    return {
        npcID = record.id,
        factionID = factionID,
        factionName = faction and faction.name or nil,
        archetypeID = faction and faction.archetypeID or nil,
        role = affiliation.role,
        rank = affiliation.rank,
        membershipStatus = affiliation.membershipStatus,
        affiliationRevision = affiliation.revision,
        legacyFaction = record.faction,
        recruited = record.recruited == true,
        ownerUsername = record.ownerUsername,
        hostilityMode = hostility.mode,
        attackPlayers = hostility.attackPlayers == true,
        attackNPCs = hostility.attackNPCs == true,
        attackZombies = hostility.attackZombies == true,
        orderKind = record.orderSpec
            and record.orderSpec.kind or nil,
        activeJob = record.activeJob,
        activeBehavior = record.activeBehavior,
        behaviorReason = runtime.factionBehaviorReason,
        target = targetSummary(runtime.target),
        playerFactionID =
            playerFaction and playerFaction.id or nil,
        relationState = relation and relation.state or "unknown",
        atWarWithPlayer = faction and playerFaction
            and Factions.AreAtWar(
                faction.id,
                playerFaction.id
            ) or false,
        alliedWithPlayer = relation
            and relation.allied == true or false,
        intent = intent and intent.intent or "observe",
        intentReason = intent and intent.reason
            or "player_identity_unavailable",
        attackAllowed = intent
            and intent.attackAllowed == true or false,
        pursueAllowed = intent
            and intent.pursueAllowed == true or false,
        commandable = intent
            and intent.commandable == true or false,
        relationship = {
            exists = relationship ~= nil,
            approval = relationship
                and relationship.approval or 0,
            respect = relationship
                and relationship.respect or 0,
            familiarity = relationship
                and relationship.familiarity or 0,
            state = relationship
                and relationship.state or "unknown",
            previousState = relationship
                and relationship.previousState or "unknown",
            revision = relationship
                and relationship.revision or 0,
            lastInteractionAt = relationship
                and relationship.lastInteractionAt or 0,
        },
        morale = record.social
            and record.social.morale or 0,
        socialRevision = record.social
            and record.social.revision or 0,
        relationshipChanges =
            relationshipChanges(record, playerKey),
        recordRevision = record.recordRevision,
        presenceRevision = record.presenceRevision,
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
    local playerDiplomacyFaction
    local diplomacy = {}
    local selectedTarget
    local relationForward
    local relationReverse
    local intentPreview
    local intentTrace
    local npcDiagnostics = {}
    local at = worldAgeHours()
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
        playerDiplomacyFaction = playerKey
            and Factions
                .GetDiplomacyFactionForPlayerKey(playerKey)
            or nil
    end
    for _, faction in ipairs(Factions.List()) do
        factions[#factions + 1] = factionSummary(faction)
    end
    for _, record in pairs(PNC.Registry.Data or {}) do
        if record.alive ~= false then
            roster[#roster + 1] = npcSummary(record)
            npcDiagnostics[#npcDiagnostics + 1] =
                npcDiagnostic(
                    record,
                    player,
                    playerKey,
                    playerDiplomacyFaction,
                    at
                )
        end
    end
    table.sort(roster, function(left, right)
        if left.name ~= right.name then
            return left.name < right.name
        end
        return left.id < right.id
    end)
    table.sort(npcDiagnostics, function(left, right)
        return tostring(left.npcID) < tostring(right.npcID)
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
            if not targetID and playerDiplomacyFaction
                and playerDiplomacyFaction.id ~= faction.id
            then
                targetID = playerDiplomacyFaction.id
            end
            if targetID and targetID ~= faction.id then
                local target = Factions.Get(targetID)
                if target then
                    selectedTarget = factionSummary(target)
                    relationForward =
                        Factions.GetRelation(faction.id, targetID)
                    relationReverse =
                        Factions.GetRelation(targetID, faction.id)
                    local preview = PNC.FactionIntent.ResolveWithTrace({
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
                    intentPreview = preview.result
                    intentTrace = preview.trace
                end
            end
        end
    end
    if Types.IsValidNPCID(selectedNPCID)
        and selectedTarget
        and PNC.FactionBehavior
        and PNC.FactionBehavior.ResolveIntentWithTrace
    then
        local observer = PNC.Registry.Get(selectedNPCID)
        local targetEntity
        if playerDiplomacyFaction
            and selectedTarget.id
                == playerDiplomacyFaction.id
        then
            targetEntity = player
        else
            local targetMembers =
                Factions.GetMembers(selectedTarget.id)
            local firstMember = targetMembers
                and targetMembers[1] or nil
            targetEntity = firstMember
                and PNC.Registry.Get(firstMember.npcID) or nil
        end
        if observer and targetEntity then
            local diagnostic =
                PNC.FactionBehavior.ResolveIntentWithTrace(
                    observer,
                    targetEntity,
                    { worldAgeHours = worldAgeHours() }
                )
            if diagnostic then
                intentPreview = diagnostic.result
                intentTrace = diagnostic.trace
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
        intentTrace = intentTrace,
        selectedNPCID = Types.IsValidNPCID(selectedNPCID)
            and selectedNPCID or nil,
        members = members,
        diplomacy = diplomacy,
        roster = roster,
        npcDiagnostics = npcDiagnostics,
        currentPlayerKey = playerKey,
        currentPlayerFactionID =
            playerFaction and playerFaction.id or nil,
        currentPlayerDiplomacyFactionID =
            playerDiplomacyFaction
            and playerDiplomacyFaction.id or nil,
        currentPlayerDiplomacyFaction =
            playerDiplomacyFaction
            and (
                not playerFaction
                or playerDiplomacyFaction.id
                    ~= playerFaction.id
            )
            and factionSummary(playerDiplomacyFaction)
            or nil,
        actionResult = copy(action),
        telemetry = PNC.FactionTelemetry
            and PNC.FactionTelemetry.BuildSnapshot({
                maximum = 128,
            }) or nil,
        activeAggregationEpisodes =
            PNC.FactionIncidentService
            and PNC.FactionIncidentService.GetActiveEpisodes
            and PNC.FactionIncidentService.GetActiveEpisodes()
            or {},
        reconciliationJobs = PNC.FactionBehavior
            and PNC.FactionBehavior.GetReconciliationSnapshot
            and PNC.FactionBehavior.GetReconciliationSnapshot()
            or {},
        validationResult = copy(Debug.LastValidation),
        scenarioResult = copy(Debug.LastScenario),
        scenarioNames = copy(
            PNC.FactionValidation
            and PNC.FactionValidation.Scenarios or {}
        ),
        balance = PNC.FactionBalance
            and PNC.FactionBalance.GetAll() or {},
        populationDirector = PNC.PopulationDirector
            and PNC.PopulationDirector.GetMetrics
            and copy(PNC.PopulationDirector.GetMetrics()) or nil,
        generatedAt = at,
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
    local groupResult
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
        local tags = {
            debugCreated = true,
        }
        local mobileGroup = args and args.creationKind
            == "mobile_group"
            or archetypeID == "refugee"
        if archetypeID == "settler" then
            tags.settlementType = "friendly"
        elseif archetypeID == "looter" and not mobileGroup then
            tags.settlementType = "looter_toll"
            tags.territorialToll = true
        end
        if mobileGroup then
            tags.mobileGroup = true
            tags.mobilePathMode = tostring(
                args and args.mobilePathMode or "random"
            )
        end
        ok, reason, value = Factions.Create({
            name = generatedFactionName(archetypeID, at),
            archetypeID = archetypeID,
            createdAt = at,
            tags = tags,
        })
        if ok then
            factionID = value.id
            if mobileGroup then
                ok, reason, groupResult =
                    PNC.MobileGroupDirector.GenerateForFaction(
                        factionID,
                        mobileGroupSpec(player, args, at)
                    )
            else
                ok, reason, groupResult =
                    PNC.CommunityDirector.GenerateForFaction(
                        factionID,
                        groupSpec(player, args, at)
                    )
            end
        end
    elseif action == "create_player_faction" then
        ok, reason, value = Factions.CreatePlayerFaction(
            player,
            {
                name = generatedFactionName("settler", at),
                archetypeID = "settler",
                createdAt = at,
                tags = { debugCreated = true },
                emblem = args and args.emblem,
            }
        )
        if ok and value then
            factionID = value.id
            ok, reason, groupResult =
                PNC.CommunityDirector.GenerateForFaction(
                    factionID,
                    groupSpec(player, args, at)
            )
        end
    elseif action == "set_emblem" then
        ok, reason, value =
            Factions.SetPlayerFactionEmblem(
                player,
                args and args.emblem
            )
        if ok and value then factionID = value.id end
    elseif action == "generate_group" then
        local faction = factionID and Factions.Get(factionID)
        if faction and Factions.IsMobileGroup(faction) then
            ok, reason, groupResult =
                PNC.MobileGroupDirector.GenerateForFaction(
                    factionID,
                    mobileGroupSpec(player, args, at)
                )
        else
            ok, reason, groupResult =
                PNC.CommunityDirector.GenerateForFaction(
                    factionID,
                    groupSpec(player, args, at)
                )
        end
    elseif action == "mobile_path_mode" then
        ok, reason, value = PNC.MobileGroupDirector.SetPathMode(
            factionID,
            args and args.mobilePathMode
        )
    elseif action == "mobile_relocate" then
        ok, reason, value =
            PNC.MobileGroupDirector.RelocateFaction(
                factionID,
                at,
                true
            )
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
                    truceUntil = at + (
                        Balance and Balance.Get(
                            "defaultTruceHours"
                        ) or 24
                    ),
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
    elseif action == "telemetry_clear" then
        ok, reason = PNC.FactionTelemetry.Clear()
    elseif action == "telemetry_toggle" then
        local config = PNC.Config.Factions
        config.EnableValidationTelemetry =
            config.EnableValidationTelemetry ~= true
        ok = true
        reason = config.EnableValidationTelemetry
            and "telemetry_enabled" or "telemetry_disabled"
    elseif action == "check_registry" then
        Debug.LastValidation =
            PNC.FactionValidation.CheckRegistry()
        ok = Debug.LastValidation.ok
        reason = ok and "registry_valid"
            or "registry_invalid"
    elseif action == "repair_indexes" then
        ok, reason =
            PNC.FactionValidation.RepairSecondaryIndexes()
        if ok == false and (
            reason == nil or reason == "unchanged"
        ) then
            ok = true
            reason = "indexes_already_valid"
        end
        Debug.LastValidation =
            PNC.FactionValidation.CheckRegistry()
    elseif action == "check_relation" then
        if not factionID or not targetFactionID
            or factionID == targetFactionID
        then
            ok, reason = false, "select_distinct_factions"
        else
            Debug.LastValidation =
                PNC.FactionValidation.CheckRelation(
                    factionID, targetFactionID
                )
            ok = Debug.LastValidation.ok
            reason = ok and "relation_valid"
                or "relation_invalid"
        end
    elseif action == "run_scenario" then
        Debug.LastScenario, reason =
            PNC.FactionValidation.RunScenario(
                args and args.scenarioName
                    or "single_minor_attack"
            )
        ok = Debug.LastScenario ~= nil
        reason = ok and "scenario_preview_complete" or reason
    elseif action == "reconcile_treaty" then
        if not factionID or not targetFactionID
            or factionID == targetFactionID
        then
            ok, reason = false, "select_distinct_factions"
        else
            ok, reason = PNC.FactionBehavior
                .QueueTreatyReconciliation(
                    factionID,
                    targetFactionID,
                    "manual_debug_reconciliation",
                    at
                )
        end
    elseif action == "export_snapshot" then
        local telemetry = PNC.FactionTelemetry.BuildSnapshot({
            maximum = 128,
        })
        Core.LogInfo(
            "Faction diagnostic snapshot schema="
            .. tostring(PNC.FactionConstants
                .REGISTRY_SCHEMA_VERSION)
            .. " registryRevision="
            .. tostring(Factions.Registry.revision)
            .. " telemetryCount="
            .. tostring(telemetry.count)
            .. " selected=" .. tostring(factionID)
            .. " target=" .. tostring(targetFactionID)
        )
        for _, entry in ipairs(telemetry.entries or {}) do
            Core.LogInfo(
                "Faction telemetry #" .. tostring(entry.sequence)
                .. " " .. tostring(entry.category)
                .. " op=" .. tostring(entry.operation)
                .. " result=" .. tostring(entry.result)
                .. " reason=" .. tostring(entry.reason)
            )
        end
        ok, reason = true, "snapshot_exported_to_log"
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
            groupResult = copy(groupResult),
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
