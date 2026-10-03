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

local function copyHurtContext(context, attacker)
    local source = type(context) == "table" and context or {}
    local damage = tonumber(source.damage or source.healthLoss) or 0
    return {
        damage = damage,
        healthLoss = tonumber(source.healthLoss) or damage,
        woundType = source.woundType,
        attackerKind = source.attackerKind or "zombie",
        attackerID = source.attackerID
            or call(attacker, "getOnlineID")
            or "unknown",
        source = source.source or "vanilla_zombie_poll",
    }
end

H.DamageCopyHurtContext = copyHurtContext

return H
