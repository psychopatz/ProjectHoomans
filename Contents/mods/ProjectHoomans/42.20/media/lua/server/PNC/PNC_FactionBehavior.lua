-- Server-authoritative bridge from organizational factions to existing
-- companion/combat fields. Persistent faction identity remains canonical;
-- legacy tactical fields are derived compatibility state.

if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then
    return
end

PNC = PNC or {}
PNC.FactionBehavior = PNC.FactionBehavior or {}

local Behavior = PNC.FactionBehavior
local Factions = PNC.Factions
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
local Types = PNC.Types
local Const = PNC.Const
local Core = PNC.Core
local Balance = PNC.FactionBalance

Behavior.ReconciliationQueue =
    Behavior.ReconciliationQueue or {}
Behavior.ReconciliationKeys =
    Behavior.ReconciliationKeys or {}

local function same(left, right)
    return PNC.FactionTypes.AreEqual(left, right)
end

local function currentWorldAgeHours()
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

local function ownerIdentity(faction)
    local parsed = faction and faction.ownerPlayerKey
        and EntityRef.Parse(faction.ownerPlayerKey) or nil
    local player = parsed
        and PNC.PlayerCharacters
        and PNC.PlayerCharacters.RuntimeByUUID
        and PNC.PlayerCharacters.RuntimeByUUID[
            parsed.characterUUID
        ] or nil
    return parsed, player
end

local function factionHasPlayerMembers(faction)
    if not faction then return false end
    for _, _ in pairs(faction.playerMemberKeys or {}) do
        return true
    end
    return false
end

local function factionAtWarWithPlayerFaction(factionID)
    local faction = Factions.Registry.byID[factionID]
    if not faction then return false end
    for otherID, relation in pairs(faction.relations or {}) do
        if relation.atWar == true
            and Factions.AreAtWar(factionID, otherID)
        then
            local other = Factions.Registry.byID[otherID]
            if factionHasPlayerMembers(other) then
                return true
            end
        end
    end
    return false
end

local function playerEntityKey(player)
    local context = PNC.PlayerContext and PNC.PlayerContext.Peek
        and PNC.PlayerContext.Peek(player) or nil
    if context then return context.entityKey end
    local uuid = PNC.PlayerCharacters
        and PNC.PlayerCharacters.GetCharacterUUID
        and PNC.PlayerCharacters.GetCharacterUUID(player) or nil
    local record = uuid and PNC.PlayerCharacters.Registry
        and PNC.PlayerCharacters.Registry.byUUID
        and PNC.PlayerCharacters.Registry.byUUID[uuid] or nil
    return record and EntityRef.ForPlayerIdentity(
        record.accountKey or record.accountIdentity, uuid
    ) or nil
end

local function conversationParleyActive(record, targetKey)
    local parley = record and record.runtime
        and record.runtime.conversationParley or nil
    if type(parley) ~= "table" then return false end
    if (tonumber(parley.untilAt) or 0) <= Core.Now() then
        record.runtime.conversationParley = nil
        return false
    end
    return targetKey ~= nil
        and targetKey == parley.playerKey
end

local function targetContext(target)
    if type(target) ~= "table"
        and type(target) ~= "userdata"
    then
        return nil, nil, nil
    end
    if target.id and PNC.FactionTypes.IsValidNPCID
        and PNC.FactionTypes.IsValidNPCID(target.id)
    then
        local factionID =
            Factions.GetOrganizationalFactionID(target)
        return factionID, EntityRef.ForNPC(target.id), target
    end
    local playerFaction =
        Factions.GetPlayerDiplomacyFaction(target)
    return playerFaction and playerFaction.id or nil,
        playerEntityKey(target),
        nil
end

local function insideFactionCommunity(factionID, target)
    if not target or not target.getX or not target.getY
        or not PNC.Communities
        or not PNC.Communities.GetForFaction
        or not PNC.CommunityMath
        or not PNC.CommunityMath.IsInsideHomeArea
    then
        return false
    end
    local x = target:getX()
    local y = target:getY()
    local z = target.getZ and target:getZ() or 0
    for _, community in ipairs(
        PNC.Communities.GetForFaction(factionID) or {}
    ) do
        if community.status == "active"
            and PNC.CommunityMath.IsInsideHomeArea(
                community,
                x,
                y,
                z
            )
        then
            return true
        end
    end
    return false
end

function Behavior.ResolveIntent(observerRecord, target, context)
    context = type(context) == "table" and context or {}
    if not observerRecord then
        local invalid = {
            intent = "observe",
            attackAllowed = false,
            pursueAllowed = false,
            commandable = false,
            reason = "invalid_observer",
        }
        if context.returnDebugTrace == true then
            return {
                result = invalid,
                trace = {
                    selectedRule = "invalid_observer",
                    fallback = "observe",
                },
            }
        end
        return invalid
    end
    local observerFactionID =
        Factions.GetOrganizationalFactionID(observerRecord)
    local observerFaction = observerFactionID
        and Factions.Registry.byID[observerFactionID] or nil
    local targetFactionID, targetKey, targetRecord =
        targetContext(target)
    if not observerFaction then
        local hostile = observerRecord.hostility
            and (
                targetRecord
                    and observerRecord.hostility.attackNPCs
                or not targetRecord
                    and observerRecord.hostility.attackPlayers
            ) == true
        local legacy = {
            intent = hostile and "attack" or "observe",
            attackAllowed = hostile,
            pursueAllowed = hostile,
            commandable = false,
            reason = hostile and "legacy_hostility"
                or "unaffiliated_neutral",
        }
        if context.returnDebugTrace == true then
            return {
                result = legacy,
                trace = {
                    selectedRule = legacy.reason,
                    fallback = "observe",
                    organizationalFaction = false,
                },
            }
        end
        return legacy
    end
    local sameFaction = targetFactionID ~= nil
        and targetFactionID == observerFactionID
    local relation = targetFactionID and not sameFaction
        and observerFaction.relations[targetFactionID] or nil
    relation = relation and PNC.FactionTypes.NormalizeRelation(
        relation,
        observerFactionID,
        targetFactionID
    ) or nil
    local at = tonumber(context.worldAgeHours)
        or currentWorldAgeHours()
    local state = relation
        and PNC.FactionDiplomacyMath.ResolveState(relation, at)
        or "unknown"
    local personal = targetKey and observerRecord.social
        and observerRecord.social.relationships
        and observerRecord.social.relationships[targetKey] or nil
    local samePlayerOwnedFaction = sameFaction
        and factionHasPlayerMembers(observerFaction)
    local targetIsOwner = targetKey ~= nil
        and targetKey == observerFaction.ownerPlayerKey
    local commandable = samePlayerOwnedFaction
        and (
            targetIsOwner
            or observerFaction.playerMemberKeys[targetKey] == true
        )
    local pacification = targetKey
        and EntityRef.IsPlayer(targetKey)
        and Factions.GetPlayerPacification
        and Factions.GetPlayerPacification(
            observerFactionID,
            targetKey,
            at
        ) or nil
    local runtimeSelfDefense = (
        tonumber(
            observerRecord.runtime
                and observerRecord.runtime
                    .factionSelfDefenseUntil
        ) or 0
    ) > Core.Now()
    local activeParley = conversationParleyActive(
        observerRecord,
        targetKey
    )
    local spec = {
        archetypeID = observerFaction.archetypeID,
        policy = observerFaction.policy,
        diplomaticState = state,
        sameFaction = sameFaction,
        samePlayerOwnedFaction = samePlayerOwnedFaction,
        targetIsOwner = targetIsOwner,
        commandable = commandable,
        playerPacified = pacification ~= nil,
        playerPacifiedUntil = pacification
            and pacification.untilWorldAgeHours or 0,
        playerPacificationReason = pacification
            and pacification.reason or nil,
        atWar = relation and relation.atWar == true,
        allied = relation and relation.allied == true,
        activeTruce = relation
            and relation.truceUntil > at,
        personalState = personal and personal.state,
        immediateSelfDefense =
            context.immediateSelfDefense == true
            or runtimeSelfDefense,
        conversationParley = activeParley,
        targetAggression = context.targetAggression == true
            or runtimeSelfDefense,
        observerStrength = context.observerStrength,
        targetStrength = context.targetStrength,
        territorialToll =
            Factions.IsTerritorialTollFaction(
                observerFaction
            ),
        targetInsideTerritory =
            not targetRecord
            and insideFactionCommunity(
                observerFactionID,
                target
            ) or false,
    }
    local resolved = context.returnDebugTrace == true
        and PNC.FactionIntent.ResolveWithTrace(spec)
        or PNC.FactionIntent.Resolve(spec)
    if context.suppressTelemetry ~= true
        and PNC.FactionTelemetry
        and PNC.FactionTelemetry.RecordIntent
    then
        local result = resolved.result or resolved
        PNC.FactionTelemetry.RecordIntent({
            operation = "resolve_intent",
            worldAgeHours = at,
            observerNPCID = observerRecord.id,
            actorKey = EntityRef.ForNPC(observerRecord.id),
            subjectKey = targetKey,
            sourceFactionID = observerFactionID,
            targetFactionID = targetFactionID,
            result = result.intent,
            reason = result.reason,
            attackAllowed = result.attackAllowed,
            pursueAllowed = result.pursueAllowed,
        })
    end
    return resolved
end

function Behavior.ResolveIntentWithTrace(
    observerRecord,
    target,
    context
)
    local options = {}
    for name, value in pairs(
        type(context) == "table" and context or {}
    ) do
        options[name] = value
    end
    options.returnDebugTrace = true
    return Behavior.ResolveIntent(observerRecord, target, options)
end

local function assign(record, key, value)
    if record[key] == value then return false end
    record[key] = value
    return true
end

local function clearCombatRuntime(record)
    record.runtime = record.runtime or {}
    record.runtime.target = nil
    record.runtime.attackAction = nil
    record.runtime.lastPathX = nil
    record.runtime.lastPathY = nil
    record.runtime.followState = nil
    record.nextThinkAt = Core.Now()
end

local function desiredOrder(record, mode, owner, faction, preservePlayerOrder)
    local mobile = faction and faction.mobile
    local home = mobile and mobile.site and mobile.site.home
    if mobile and mobile.active == true and home then
        local pathMode = mobile.pathMode
        if mode == "aggressive" then
            if pathMode == PNC.FactionConstants.MOBILE_PATH_RANDOM then
                return {
                    kind = Const.ORDER_HOSTILE_ROAM,
                    roamMode = Const.ROAM_MODE_AREA,
                    x = home.x,
                    y = home.y,
                    z = home.z,
                    radius = home.radius,
                    targetRadius = Const.ROAM_TARGET_RADIUS,
                }
            end
            return {
                kind = Const.ORDER_HOSTILE_HUNT,
                x = home.x,
                y = home.y,
                z = home.z,
            }
        end
        return {
            kind = Const.ORDER_ROAM,
            roamMode = pathMode
                == PNC.FactionConstants.MOBILE_PATH_PLAYER
                and Const.ROAM_MODE_PLAYER
                or Const.ROAM_MODE_AREA,
            x = home.x,
            y = home.y,
            z = home.z,
            radius = home.radius,
        }
    end
    if mode == "player_owned" then
        local current = record.orderSpec or {}
        local kind = tostring(current.kind or "")
        local registeredJob = PNC.JobSystem and PNC.JobSystem.OrderJobs
            and PNC.JobSystem.OrderJobs[kind] or nil
        if preservePlayerOrder == true and (
            kind == Const.ORDER_GUARD
            or kind == Const.ORDER_PATROL
            or kind == Const.ORDER_TRAVEL
            or registeredJob ~= nil
        ) then
            return Core.DeepCopy(current)
        end
        return {
            kind = Const.ORDER_FOLLOW,
            ownerUsername = owner.username,
            ownerOnlineID = owner.onlineID,
        }
    end
    if mode == "aggressive" then
        return {
            kind = Const.ORDER_HOSTILE_HUNT,
            x = record.x,
            y = record.y,
            z = record.z,
        }
    end
    return {
        kind = Const.ORDER_ROAM,
        roamMode = Const.ROAM_MODE_AREA,
        x = record.x,
        y = record.y,
        z = record.z,
        radius = Const.ROAM_DEFAULT_RADIUS,
    }
end

local function apply(record, mode, owner, reason, faction)
    local changed = false
    local legacyFaction
    local hostility
    local order
    local preservePlayerOrder
    local recordOwnerUsername
    local ownerUsername
    local recordOwnerOnlineID
    local ownerOnlineID
    if not record or record.alive == false then
        return false, "invalid_record"
    end
    recordOwnerUsername = tostring(record.ownerUsername or "")
    ownerUsername = tostring(owner and owner.username or "")
    recordOwnerOnlineID = tonumber(record.ownerOnlineID)
    ownerOnlineID = tonumber(owner and owner.onlineID)
    preservePlayerOrder = mode == "player_owned"
        and record.recruited == true
        and (
            recordOwnerUsername ~= ""
                and recordOwnerUsername == ownerUsername
            or recordOwnerOnlineID ~= nil
                and ownerOnlineID ~= nil
                and recordOwnerOnlineID == ownerOnlineID
        )
    if mode == "player_owned" then
        legacyFaction = Const.FACTION_COLONIST
        hostility = Types.DefaultHostility(legacyFaction)
        changed = assign(record, "recruited", true) or changed
        changed = assign(
            record,
            "ownerUsername",
            owner.username
        ) or changed
        changed = assign(
            record,
            "ownerOnlineID",
            owner.onlineID
        ) or changed
    elseif mode == "aggressive" then
        legacyFaction = Const.FACTION_HOSTILE
        hostility = {
            mode = "faction_war",
            attackPlayers = owner.attackPlayers == true,
            attackNPCs = true,
            attackZombies = true,
        }
        changed = assign(record, "recruited", false) or changed
        changed = assign(record, "ownerUsername", nil) or changed
        changed = assign(record, "ownerOnlineID", nil) or changed
    else
        legacyFaction = Const.FACTION_NEUTRAL
        hostility = Types.DefaultHostility(legacyFaction)
        changed = assign(record, "recruited", false) or changed
        changed = assign(record, "ownerUsername", nil) or changed
        changed = assign(record, "ownerOnlineID", nil) or changed
    end
    changed = assign(record, "faction", legacyFaction) or changed
    if not same(record.hostility, hostility) then
        record.hostility = hostility
        changed = true
    end
    order = desiredOrder(
        record,
        mode,
        owner,
        faction,
        preservePlayerOrder
    )
    if not same(record.orderSpec, order) then
        if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
            PNC.OrderSystem.SetOrder(record, order)
        else
            record.orderSpec = order
        end
        changed = true
    end
    if not changed then return false, "unchanged" end
    local runtimeTarget = record.runtime
        and record.runtime.target or nil
    if not runtimeTarget or runtimeTarget.kind ~= "zombie" then
        clearCombatRuntime(record)
    end
    record.runtime = record.runtime or {}
    record.runtime.factionBehaviorReason =
        tostring(reason or "faction_policy")
    record.runtime.factionBehaviorAt = Core.Now()
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "faction_behavior")
    end
    if PNC.Network and PNC.Network.BroadcastRecord then
        PNC.Network.BroadcastRecord(
            record,
            tostring(reason or "faction_behavior")
        )
    end
    if PNC.SimulationClock and PNC.SimulationClock.Wake then
        PNC.SimulationClock.Wake(record, nil, Core.Now())
    end
    return true, "applied"
end

function Behavior.ApplyNPC(record, reason)
    local factionID = Factions.GetOrganizationalFactionID(record)
    local faction = factionID
        and Factions.Registry.byID[factionID] or nil
    local parsed
    local livePlayer
    local owner
    local aggressive
    if not faction then
        return Behavior.ApplyUnaffiliated(record, reason)
    end
    if faction.ownerPlayerKey then
        parsed, livePlayer = ownerIdentity(faction)
        owner = {
            username = livePlayer and parsed
                and parsed.accountIdentity or nil,
            onlineID = livePlayer
                and livePlayer.getOnlineID
                and livePlayer:getOnlineID() or nil,
        }
        return apply(record, "player_owned", owner, reason, faction)
    end
    local territorialToll =
        Factions.IsTerritorialTollFaction(faction)
    aggressive = (
        faction.archetypeID == "looter"
            and not territorialToll
        )
        or Archetypes.IsHostileToOutsiders(
            faction.archetypeID
        )
        or Factions.IsFactionAtWar(factionID)
    return apply(
        record,
        aggressive and "aggressive" or "neutral",
        {
            attackPlayers =
                faction.archetypeID == "looter"
                    and not territorialToll
                or Archetypes.IsHostileToOutsiders(
                    faction.archetypeID
                )
                or factionAtWarWithPlayerFaction(factionID),
        },
        reason,
        faction
    )
end

function Behavior.ReconcilePlayerPacification(
    factionID,
    playerKey,
    reason
)
    local faction = Factions.Registry.byID[factionID]
    local cleared = 0
    if not faction or not EntityRef.IsPlayer(playerKey) then
        return 0
    end
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry.Get(npcID)
        local target = record and record.runtime
            and record.runtime.target or nil
        local targetKey = target
            and target.kind == "player"
            and target.player
            and playerEntityKey(target.player) or nil
        if targetKey == playerKey then
            clearCombatRuntime(record)
            record.runtime.factionBehaviorReason =
                tostring(reason or "player_pacified")
            if PNC.SimulationClock
                and PNC.SimulationClock.Wake
            then
                PNC.SimulationClock.Wake(
                    record,
                    nil,
                    Core.Now()
                )
            end
            cleared = cleared + 1
        end
    end
    return cleared
end

function Behavior.ApplyUnaffiliated(record, reason)
    return apply(record, "neutral", {}, reason, nil)
end

function Behavior.ReconcileFaction(factionID, reason)
    local faction = Factions.Registry.byID[factionID]
    local changed = 0
    if not faction then return 0 end
    for npcID, _ in pairs(faction.memberIDs or {}) do
        local record = PNC.Registry.Get(npcID)
        if record and Behavior.ApplyNPC(record, reason) then
            changed = changed + 1
        end
    end
    return changed
end

function Behavior.ReconcileAll(reason)
    local changed = 0
    for factionID, _ in pairs(Factions.Registry.byID or {}) do
        changed = changed
            + Behavior.ReconcileFaction(factionID, reason)
    end
    return changed
end

local function reconciliationKey(firstFactionID, secondFactionID)
    if tostring(firstFactionID) > tostring(secondFactionID) then
        firstFactionID, secondFactionID =
            secondFactionID, firstFactionID
    end
    return tostring(firstFactionID) .. "|"
        .. tostring(secondFactionID)
end

local function collectMembers(firstFactionID, secondFactionID)
    local found = {}
    local output = {}
    for _, factionID in ipairs({
        firstFactionID,
        secondFactionID,
    }) do
        local faction = Factions.Registry.byID[factionID]
        for npcID, _ in pairs(
            faction and faction.memberIDs or {}
        ) do
            if not found[npcID] then
                found[npcID] = true
                output[#output + 1] = npcID
            end
        end
    end
    table.sort(output)
    return output
end

function Behavior.QueueTreatyReconciliation(
    firstFactionID,
    secondFactionID,
    operation,
    worldAgeHours
)
    local key = reconciliationKey(
        firstFactionID, secondFactionID
    )
    if Behavior.ReconciliationKeys[key] then
        for _, job in ipairs(Behavior.ReconciliationQueue) do
            if job.key == key then
                job.operation = tostring(
                    operation or job.operation
                )
                job.createdAt = math.max(
                    0,
                    tonumber(worldAgeHours)
                        or currentWorldAgeHours()
                )
                break
            end
        end
        if PNC.FactionTelemetry then
            PNC.FactionTelemetry.RecordTreatyReconciliation({
                operation = tostring(
                    operation or "treaty_changed"
                ),
                worldAgeHours = tonumber(worldAgeHours)
                    or currentWorldAgeHours(),
                sourceFactionID = firstFactionID,
                targetFactionID = secondFactionID,
                encounterKey = key,
                result = "deduplicated",
                reason = "already_queued",
            })
        end
        return false, "already_queued"
    end
    local maximum = math.floor(
        Balance and Balance.Get("reconciliationQueueLimit")
            or 64
    )
    if #Behavior.ReconciliationQueue >= maximum then
        return false, "queue_full"
    end
    local members = collectMembers(
        firstFactionID, secondFactionID
    )
    local job = {
        key = key,
        sourceFactionID = firstFactionID,
        targetFactionID = secondFactionID,
        operation = tostring(operation or "treaty_changed"),
        createdAt = math.max(
            0, tonumber(worldAgeHours)
                or currentWorldAgeHours()
        ),
        cursor = 1,
        memberIDs = members,
        memberCount = #members,
        processedCount = 0,
        staleTargetsCleared = 0,
        intentsChanged = 0,
    }
    Behavior.ReconciliationKeys[key] = true
    Behavior.ReconciliationQueue[
        #Behavior.ReconciliationQueue + 1
    ] = job
    if PNC.FactionTelemetry then
        PNC.FactionTelemetry.RecordTreatyReconciliation({
            operation = job.operation,
            worldAgeHours = job.createdAt,
            sourceFactionID = firstFactionID,
            targetFactionID = secondFactionID,
            encounterKey = key,
            result = "queued",
            memberCount = job.memberCount,
        })
    end
    return true, "queued", job
end

local function runtimeTargetValue(target)
    if not target then return nil end
    if target.kind == "npc" then
        return target.id and PNC.Registry.Get(target.id) or nil
    end
    if target.kind == "player" then
        return target.player
    end
    return nil
end

function Behavior.PumpReconciliation(maximum)
    maximum = math.max(
        1,
        math.floor(tonumber(maximum)
            or (
                Balance
                and Balance.Get("reconciliationBatchSize")
                or 16
            ))
    )
    local processed = 0
    while processed < maximum
        and #Behavior.ReconciliationQueue > 0
    do
        local job = Behavior.ReconciliationQueue[1]
        local npcID = job.memberIDs[job.cursor]
        if not npcID then
            Behavior.ReconciliationKeys[job.key] = nil
            table.remove(Behavior.ReconciliationQueue, 1)
            if PNC.FactionTelemetry then
                PNC.FactionTelemetry.RecordTreatyReconciliation({
                    operation = job.operation,
                    worldAgeHours = currentWorldAgeHours(),
                    sourceFactionID = job.sourceFactionID,
                    targetFactionID = job.targetFactionID,
                    encounterKey = job.key,
                    result = "completed",
                    memberCount = job.memberCount,
                    processedCount = job.processedCount,
                    staleTargetsCleared =
                        job.staleTargetsCleared,
                    intentsChanged = job.intentsChanged,
                })
            end
        else
            job.cursor = job.cursor + 1
            job.processedCount = job.processedCount + 1
            processed = processed + 1
            local record = PNC.Registry.Get(npcID)
            if record then
                local memberIntentChanged = false
                local beforeTarget = record.runtime
                    and record.runtime.target or nil
                local beforeReason = record.runtime
                    and record.runtime.factionBehaviorReason
                Behavior.ApplyNPC(record, job.operation)
                local target = record.runtime
                    and record.runtime.target or beforeTarget
                if target and target.kind ~= "zombie" then
                    local value = runtimeTargetValue(target)
                    local selfDefense = target.targetAggression == true
                        or target.immediateSelfDefense == true
                        or (
                            tonumber(record.runtime
                                .factionSelfDefenseUntil) or 0
                        ) > Core.Now()
                    local intent = value and Behavior.ResolveIntent(
                        record,
                        value,
                        {
                            worldAgeHours =
                                currentWorldAgeHours(),
                            immediateSelfDefense = selfDefense,
                            targetAggression = selfDefense,
                        }
                    ) or nil
                    if intent and intent.attackAllowed ~= true then
                        clearCombatRuntime(record)
                        job.staleTargetsCleared =
                            job.staleTargetsCleared + 1
                        memberIntentChanged = true
                    elseif intent and selfDefense
                        and record.runtime.target == nil
                    then
                        record.runtime.target = target
                    end
                end
                local afterReason = record.runtime
                    and record.runtime.factionBehaviorReason
                if beforeReason ~= afterReason then
                    memberIntentChanged = true
                end
                if memberIntentChanged then
                    job.intentsChanged =
                        job.intentsChanged + 1
                end
            end
        end
    end
    return processed
end

function Behavior.GetReconciliationSnapshot()
    local output = {}
    for _, job in ipairs(Behavior.ReconciliationQueue) do
        output[#output + 1] = {
            key = job.key,
            sourceFactionID = job.sourceFactionID,
            targetFactionID = job.targetFactionID,
            operation = job.operation,
            createdAt = job.createdAt,
            memberCount = job.memberCount,
            processedCount = job.processedCount,
            staleTargetsCleared = job.staleTargetsCleared,
            intentsChanged = job.intentsChanged,
        }
    end
    return output
end

return Behavior
