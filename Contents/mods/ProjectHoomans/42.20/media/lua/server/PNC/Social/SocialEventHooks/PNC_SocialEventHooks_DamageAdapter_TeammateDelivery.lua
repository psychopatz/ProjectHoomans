-- Server-authoritative teammate damage presentation provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

require "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DamageAdapter_Context"

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local Core = PNC.Core
local Registry = PNC.Registry
local Network = PNC.Network
local audit = H.DamageAudit
local nowMillis = H.DamageNowMillis
local isAuthority = H.DamageIsAuthority
local nextEventID = H.DamageNextEventID
local sameID = H.DamageSameID
local factionIDForRecord = H.DamageFactionIDForRecord
local socialRole = H.DamageSocialRole
local playerCanReceive = H.DamagePlayerCanReceive
local witnessCanSeeDamage = H.DamageWitnessCanSeeDamage
local damageAttackerID = H.DamageAttackerID

local function deliverTeammateDamageFlavor(
    targetRecord,
    targetBody,
    attacker,
    hit,
    attackerKind,
    presentation
)
    local victimFactionID
    local amount
    local attackerID
    local observers = {}
    local candidates = 0
    local emitted = 0
    local attempted = 0
    local banditAttack = attackerKind == "bandit"
        or attackerKind == "foreign_npc"
            and hit and hit.attackerProvider == "Bandits"
    local eventType = banditAttack
        and "bandit_attack" or "witnessed_teammate_hurt"
    local flavorID = presentation and presentation.flavorID
        or banditAttack
        and "compat.bandits.hooman_hurt"
        or "social.witnessed_teammate_hurt"
    local playerCallback
    local throttleKey
    local currentTime
    if not isAuthority() then
        return 0, 0, "not_authority"
    end
    if not targetRecord or not targetRecord.id
        or targetRecord.alive == false
        or not targetBody
    then
        return 0, 0, "target_unavailable"
    end
    if not attacker then
        return 0, 0, "attacker_unavailable"
    end
    if not Registry or type(Registry.ForEachLive) ~= "function" then
        return 0, 0, "witness_registry_unavailable"
    end
    amount = tonumber(hit and (
        hit.healthLoss or hit.damage or hit.amount
    )) or 0
    if amount <= 0 then return 0, 0, "invalid_damage" end
    victimFactionID = factionIDForRecord(targetRecord)
    if not victimFactionID then
        audit({
            "luaSide=server",
            "event=TeammateHurtWitnessScan",
            "phase=faction_resolution",
            "result=false",
            "reason=victim_faction_missing",
            "victimNPCID=" .. tostring(targetRecord.id),
        })
        return 0, 0, "victim_faction_missing"
    end
    currentTime = nowMillis()
    throttleKey = tostring(victimFactionID) .. ":"
        .. tostring(targetRecord.id)
    if Hooks.LastTeammateHurtAt[throttleKey]
        and currentTime < Hooks.LastTeammateHurtAt[throttleKey]
    then
        audit({
            "luaSide=server",
            "event=TeammateHurtWitnessScan",
            "phase=server_throttle",
            "result=false",
            "reason=target_cooldown",
            "victimNPCID=" .. tostring(targetRecord.id),
            "victimFactionID=" .. tostring(victimFactionID),
            "damage=" .. tostring(amount),
        })
        return 0, 0, "target_cooldown"
    end
    Hooks.LastTeammateHurtAt[throttleKey] = currentTime + 1500
    attackerID = damageAttackerID(attacker, hit)
    Registry.ForEachLive(function(record, body, npcID)
        local factionID
        local medicalBandageAvailable
        if not record or not body or not npcID
            or record.alive == false
            or (body.isDead and body:isDead())
            or sameID(npcID, targetRecord.id)
        then
            return
        end
        factionID = factionIDForRecord(record)
        if not sameID(factionID, victimFactionID) then return end
        if not witnessCanSeeDamage(record, body, targetBody, attacker) then
            return
        end
        if flavorID == "social.witnessed_teammate_hurt" then
            local treatment = PNC.Treatment
            if treatment and type(treatment.GetNPCBandagePlan) == "function" then
                medicalBandageAvailable =
                    treatment.GetNPCBandagePlan(record) ~= nil
            end
        end
        candidates = candidates + 1
        observers[#observers + 1] = {
            id = tostring(npcID),
            record = record,
            body = body,
            medicalBandageAvailable = medicalBandageAvailable,
        }
    end)
    if not Core or type(Core.ForEachPlayer) ~= "function" then
        return 0, candidates, "player_iteration_unavailable"
    end
    playerCallback = function(player)
        local playerKey
        if not player or not playerCanReceive(
            player,
            targetBody,
            targetRecord
        ) then
            return
        end
        playerKey = Hooks.ResolvePlayerKey(player) or "unknown"
        for _, observer in ipairs(observers) do
            local role = socialRole(observer.record)
            local eventID = nextEventID(
                eventType,
                attackerID,
                observer.id .. ":" .. tostring(targetRecord.id)
            )
            local context = {
                eventType = eventType,
                damage = amount,
                healthLoss = tonumber(hit and hit.healthLoss) or amount,
                woundType = hit and hit.woundType or nil,
                attackerKind = attackerKind or "zombie",
                attackerID = attackerID,
                victimNPCID = tostring(targetRecord.id),
                victimFactionID = tostring(victimFactionID),
                relationshipScope = "teammate",
                socialRole = role,
                npcType = role,
            }
            if observer.medicalBandageAvailable == false then
                context.medicalBandageRequired = true
                context.medicalBandageStatus = "missing"
            end
            attempted = attempted + 1
            local sent, reason = false, nil
            if Network
                and type(Network.SendConversationRelationshipForNPC)
                    == "function"
            then
                sent, reason = Network.SendConversationRelationshipForNPC(
                    player,
                    observer.id,
                    eventType,
                    {
                        source = eventType,
                        eventID = eventID,
                        npcID = observer.id,
                        ambientFlavor = {
                            flavorID = flavorID,
                            eventType = eventType,
                            family = "combat_commentary",
                            priority = 55,
                            -- Keep the supply-shortage line grounded in the
                            -- authoritative inventory check above.
                            llmEligible = observer.medicalBandageAvailable
                                ~= false,
                            llmPriority = 90,
                            weight = 2,
                            npcID = observer.id,
                            npcType = role,
                            socialRole = role,
                            relationshipState = "unknown",
                            relationshipTier = "reserved",
                            mergeKey = observer.id .. ":combat_commentary",
                            cooldowns = {
                                familyMs = 20000,
                                speakerMs = 20000,
                                ambientMs = 4500,
                                mergeWindowMs = 5000,
                            },
                            context = context,
                        },
                    }
                )
            else
                reason = "relationship_transport_unavailable"
            end
            if sent == true then emitted = emitted + 1 end
            audit({
                "luaSide=server",
                "event=TeammateHurtWitness",
                "phase=flavor_dispatch",
                "result=" .. tostring(sent == true),
                "reason=" .. tostring(reason or "nil"),
                "playerKey=" .. tostring(playerKey),
                "observerNPCID=" .. observer.id,
                "victimNPCID=" .. tostring(targetRecord.id),
                "victimFactionID=" .. tostring(victimFactionID),
                "attackerID=" .. attackerID,
                "attackerKind=" .. tostring(attackerKind or "zombie"),
                "damage=" .. tostring(amount),
                "eventID=" .. eventID,
            })
        end
    end
    Core.ForEachPlayer(playerCallback)
    audit({
        "luaSide=server",
        "event=TeammateHurtWitnessScan",
        "phase=witness_scan",
        "result=" .. tostring(emitted > 0),
        "reason=" .. tostring(
            emitted > 0 and "teammates_notified"
                or attempted > 0 and "presentation_failed"
                or candidates > 0 and "no_nearby_player"
                or "no_visible_teammate"
        ),
        "victimNPCID=" .. tostring(targetRecord.id),
        "victimFactionID=" .. tostring(victimFactionID),
        "attackerID=" .. attackerID,
        "attackerKind=" .. tostring(attackerKind or "zombie"),
        "damage=" .. tostring(amount),
        "candidateCount=" .. tostring(candidates),
        "attemptedCount=" .. tostring(attempted),
        "emittedCount=" .. tostring(emitted),
    })
    return emitted, candidates, emitted > 0
        and "teammates_notified" or "no_teammate_event_emitted"
end


H.DeliverTeammateDamageFlavor = deliverTeammateDamageFlavor

return H
