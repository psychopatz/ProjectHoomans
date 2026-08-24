if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.RelationshipDebug = PNC.RelationshipDebug or {}
PNC.RelationshipDebug.Internal = PNC.RelationshipDebug.Internal or {}

local Debug = PNC.RelationshipDebug
local Internal = Debug.Internal
local Relationships = PNC.Relationships
local Types = PNC.RelationshipTypes
local EntityRef = PNC.EntityRef
local Registry = PNC.Registry
local copy = Internal.copy
local worldAgeHours = Internal.worldAgeHours
local displayName = Internal.displayName
local summarizeRelationship = Internal.summarizeRelationship
local memorySnapshot = Internal.memorySnapshot
local personalitySnapshot = Internal.personalitySnapshot
local factionSnapshot = Internal.factionSnapshot
local playerFactionSnapshot = Internal.playerFactionSnapshot
local actionSnapshot = Internal.actionSnapshot

function Debug.BuildSnapshot(
    observerNPCID,
    targetKey,
    target,
    at,
    actionResult
)
    local observer = Registry and Registry.Get
        and Registry.Get(tostring(observerNPCID or "")) or nil
    local relationship
    local exists
    local reverse
    local reverseExists
    local reverseKey
    local memories = {}
    local observerFactionSnapshot
    local targetFactionSnapshot
    local factionRelation
    local factionIntent
    local playerPacification
    local index
    if not observer or observer.alive == false then
        return nil, "observer_not_found"
    end
    if not EntityRef.IsValid(targetKey) then
        return nil, "invalid_target_key"
    end
    at = tonumber(at)
    if at == nil
        or at ~= at
        or at == math.huge
        or at == -math.huge
    then
        at = worldAgeHours()
    end
    at = math.max(0, at)
    relationship = Relationships.Get(observer.id, targetKey)
    exists = relationship ~= nil
    relationship = relationship or Types.NewRelationship(targetKey)
    if not relationship then
        return nil, "invalid_relationship"
    end
    for index = 1, #(relationship.memories or {}) do
        memories[#memories + 1] =
            memorySnapshot(relationship.memories[index], at)
    end
    table.sort(memories, function(left, right)
        if left.createdAt ~= right.createdAt then
            return left.createdAt > right.createdAt
        end
        return tostring(left.id) < tostring(right.id)
    end)
    if target and target.kind == "npc" then
        reverseKey = EntityRef.ForNPC(observer.id)
        reverse = Relationships.Get(target.npcID, reverseKey)
        reverseExists = reverse ~= nil
        reverse = reverse or Types.NewRelationship(reverseKey)
    end
    local observerKey = EntityRef.ForNPC(observer.id)
    observerFactionSnapshot = factionSnapshot(observer)
    if target and target.kind == "npc" then
        targetFactionSnapshot = factionSnapshot(
            Registry.Get(target.npcID)
        )
    else
        targetFactionSnapshot = playerFactionSnapshot(targetKey)
    end
    if observerFactionSnapshot.organizationalFaction then
        local sameFaction =
            targetFactionSnapshot.organizationalFaction
            and observerFactionSnapshot.factionID
                == targetFactionSnapshot.factionID
        if targetFactionSnapshot.organizationalFaction
            and not sameFaction
        then
            factionRelation = PNC.Factions.GetRelation(
                observerFactionSnapshot.factionID,
                targetFactionSnapshot.factionID
            )
        end
        local observerFaction = PNC.Factions.Get(
            observerFactionSnapshot.factionID
        )
        if EntityRef.IsPlayer(targetKey)
            and PNC.Factions.GetPlayerPacification
        then
            playerPacification =
                PNC.Factions.GetPlayerPacification(
                    observerFactionSnapshot.factionID,
                    targetKey,
                    at
                )
        end
        factionIntent = PNC.FactionIntent.Resolve({
            archetypeID = observerFaction
                and observerFaction.archetypeID,
            policy = observerFaction and observerFaction.policy,
            sameFaction = sameFaction,
            diplomaticState = factionRelation
                and factionRelation.state or "unknown",
            atWar = factionRelation
                and factionRelation.atWar,
            allied = factionRelation
                and factionRelation.allied,
            activeTruce = factionRelation
                and factionRelation.truceUntil > at,
            personalState = relationship.state,
            playerPacified = playerPacification ~= nil,
            playerPacifiedUntil = playerPacification
                and playerPacification.untilWorldAgeHours or 0,
            playerPacificationReason = playerPacification
                and playerPacification.reason or nil,
        })
    end
    return {
        generatedAt = at,
        observer = {
            npcID = observer.id,
            key = EntityRef.ForNPC(observer.id),
            label = displayName(observer),
            identitySeed = observer.identitySeed
                or observer.identitySummary
                    and observer.identitySummary.identitySeed,
            archetypeID = observer.archetypeID
                or observer.identitySummary
                    and observer.identitySummary.archetypeID,
            morale = observer.social
                and observer.social.morale or 0,
            moraleBaseline = observer.social
                and observer.social.moraleBaseline or 0,
            recordRevision = observer.recordRevision or 0,
            presenceRevision = observer.presenceRevision or 0,
            socialRevision = observer.social
                and observer.social.revision or 0,
            personality = personalitySnapshot(observer),
            faction = observerFactionSnapshot,
        },
        target = (function()
            local output = copy(target)
            output.faction = targetFactionSnapshot
            return output
        end)(),
        factionRelation = factionRelation,
        factionIntent = factionIntent,
        playerPacification = copy(playerPacification),
        observerConduct = PNC.ConductDebug
            and PNC.ConductDebug.BuildSnapshot(observerKey, at)
            or nil,
        targetConduct = target
            and target.key
            and PNC.ConductDebug
            and PNC.ConductDebug.BuildSnapshot(target.key, at)
            or nil,
        relationship = summarizeRelationship(
            relationship,
            exists
        ),
        memories = memories,
        saturation = copy(relationship.saturation or {}),
        cooldowns = copy(relationship.cooldowns or {}),
        reverse = reverse and summarizeRelationship(
            reverse,
            reverseExists
        ) or nil,
        actionResult = actionSnapshot(actionResult),
    }
end
