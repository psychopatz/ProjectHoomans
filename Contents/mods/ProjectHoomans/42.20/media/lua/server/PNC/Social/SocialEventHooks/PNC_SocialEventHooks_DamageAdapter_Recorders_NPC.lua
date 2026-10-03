if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local Core = PNC.Core
local EntityRef = PNC.EntityRef
local Registry = PNC.Registry
local Network = PNC.Network
local Factions = PNC.Factions
local WITNESS_RADIUS = tonumber(H.WitnessRadius) or 12
local call = H.DamageCall
local audit = H.DamageAudit
local nowMillis = H.DamageNowMillis
local isAuthority = H.DamageIsAuthority
local nextEventID = H.DamageNextEventID
local positionOf = H.DamagePositionOf
local emitRelationshipEvent = H.DamageEmitRelationshipEvent
local emitForWitness = H.DamageEmitForWitness
local sameID = H.DamageSameID
local factionIDForRecord = H.DamageFactionIDForRecord
local playerFactionIDFor = H.DamagePlayerFactionIDFor
local factionIDForMember = H.DamageFactionIDForMember
local socialRole = H.DamageSocialRole
local playerCanReceive = H.DamagePlayerCanReceive
local witnessCanSeeDamage = H.DamageWitnessCanSeeDamage
local damageAttackerID = H.DamageAttackerID
local deliverTeammateDamageFlavor = H.DeliverTeammateDamageFlavor
local copyHurtContext = H.DamageCopyHurtContext

function H.RecordNPCDamagedByZombie(
    record,
    body,
    attacker,
    hit,
    presentation
)
    return deliverTeammateDamageFlavor(
        record,
        body,
        attacker,
        hit,
        hit and hit.attackerKind or "zombie",
        presentation
    )
end

function H.RecordNPCDamagedByNPC(record, body, attackerRecord, hit)
    local attackerBody
    if not attackerRecord or not attackerRecord.id then
        return 0, 0, "attacker_record_unavailable"
    end
    attackerBody = Registry and Registry.GetLiveZombie
        and Registry.GetLiveZombie(attackerRecord.id) or nil
    return deliverTeammateDamageFlavor(
        record,
        body,
        attackerBody,
        hit,
        "npc"
    )
end


return H
