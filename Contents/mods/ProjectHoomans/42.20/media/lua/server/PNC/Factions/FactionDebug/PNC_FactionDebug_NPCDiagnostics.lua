if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionDebug = PNC.FactionDebug or {}
PNC.FactionDebug.Internal = PNC.FactionDebug.Internal or {}

local Debug = PNC.FactionDebug
local Internal = Debug.Internal
local Factions = PNC.Factions
local Archetypes = PNC.FactionArchetypes
local Types = PNC.FactionTypes
local Core = PNC.Core
local Balance = PNC.FactionBalance
local IdentityVerifier = PNC.Identity
    and PNC.Identity.Verifier or nil
local worldAgeHours = Internal.worldAgeHours
local targetSummary = Internal.targetSummary
local relationshipChanges = Internal.relationshipChanges

local function npcDiagnostic(
    record,
    player,
    playerKey,
    playerFaction,
    at
)
    local affiliation = Factions.GetNPCAffiliation(record.id)
        or {}
    local factionID = IdentityVerifier
        and IdentityVerifier.GetFactionID(record)
        or affiliation.factionID
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
    local identity = IdentityVerifier
        and IdentityVerifier.BuildView(record, { includeOwner = true })
        or nil
    local identityVerification = IdentityVerifier
        and IdentityVerifier.Verify(record)
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
        tacticalClass = record.faction,
        recruited = identity and identity.recruited
            or record.recruited == true,
        ownerUsername = identity and identity.ownerUsername
            or record.ownerUsername,
        ownerOnlineID = identity and identity.ownerOnlineID
            or record.ownerOnlineID,
        identity = identity,
        identityVerification = identityVerification,
        colonyOwned = identity and identity.colonyOwned
            or false,
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


Internal.npcDiagnostic = npcDiagnostic
Internal.actionResult = actionResult

return Debug
