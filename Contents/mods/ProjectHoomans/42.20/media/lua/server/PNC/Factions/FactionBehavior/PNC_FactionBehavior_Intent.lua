if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionBehavior = PNC.FactionBehavior or {}
PNC.FactionBehavior.Internal = PNC.FactionBehavior.Internal or {}

local Behavior = PNC.FactionBehavior
local Internal = Behavior.Internal
local Factions = PNC.Factions
local EntityRef = PNC.EntityRef
local Core = PNC.Core
local currentWorldAgeHours = Internal.currentWorldAgeHours
local factionHasPlayerMembers = Internal.factionHasPlayerMembers
local conversationParleyActive = Internal.conversationParleyActive
local targetContext = Internal.targetContext
local insideFactionCommunity = Internal.insideFactionCommunity

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
