-- Presence-payload combat-debug cadence provider.
-- Owns refresh admission and replicated transition markers while the payload
-- builder retains the broader presence schema.

local Network = PNC.Network
local H = Network.Internal.PresencePayload
if not H then return Network end

local Const = H.Const
local Diagnostics = H.Diagnostics
local Equipment = H.Equipment
local buildCombatSummary = H.BuildCombatSummary
local buildCombatDebugState = H.BuildCombatDebugState

function H.BuildCombatDebugDelta(record, inCombat, now, firearmState)
    local lastCombatDebugAt = record.runtime
        and tonumber(record.runtime.combatDebugReplicatedAt) or 0
    local zombieAttackerAt = record.runtime
        and tonumber(record.runtime.zombieAttacker
            and record.runtime.zombieAttacker.observedAt) or 0
    local zombieAlertAt = record.runtime
        and tonumber(record.runtime.zombieAlert
            and record.runtime.zombieAlert.observedAt) or 0
    local zombieStimulusAt = record.runtime
        and tonumber(record.runtime.zombieStimulus
            and record.runtime.zombieStimulus.emittedAt) or 0
    local baseZombieDebugActive =
        (zombieAttackerAt > 0
            and now - zombieAttackerAt <= 1500)
        or (zombieStimulusAt > 0
            and now - zombieStimulusAt <= 1500)
    -- Alert state is gameplay state. It must not make every nearby NPC build
    -- the full combat-debug observation payload in normal play. Opt-in threat
    -- auditing may still request the richer view at a slower cadence.
    local zombieAlertDebugActive = Diagnostics
        and Diagnostics.NPCThreatAuditEnabled == true
        and zombieAlertAt > 0
        and now - zombieAlertAt <= (
            tonumber(Const and Const.ZOMBIE_ALERT_TTL_MS) or 1800
        )
        or false
    local zombieDebugActive = baseZombieDebugActive
        or zombieAlertDebugActive
    local zombieDebugTransitioned = record.runtime
        and record.runtime.zombieDebugWasActive ~= zombieDebugActive
        or false
    local combatDebugTransitioned = record.runtime
        and record.runtime.combatDebugWasActive ~= inCombat
        or false
    local sc = record.runtime and record.runtime.secondaryChannel or nil
    local clues = record.runtime and record.runtime.clueMemory or nil
    local agState = record.id ~= nil
        and PNC.AgitationService
        and type(PNC.AgitationService.GetState) == "function"
        and PNC.AgitationService.GetState(record.id, now) or nil
    local reactivitySignature = tostring(agState and agState.stage or "calm")
        .. ":" .. tostring(clues and #clues or 0)
        .. ":" .. tostring(sc and sc.alertLevel or "calm")
        .. ":" .. tostring(sc and sc.posture or "relaxed")
        .. ":" .. tostring(sc and sc.secondaryState or "")
    local reactivityTransitioned = record.runtime
        and record.runtime.lastReactivityDebugSig ~= reactivitySignature
        or false
    local reactivityActive = (agState and agState.active == true)
        or (clues and #clues > 0)
        or (sc ~= nil and (sc.alertLevel ~= "calm" or sc.posture ~= "relaxed" or (sc.secondaryState or "") ~= ""))
    local combatDebugState
    if lastCombatDebugAt <= 0
        or combatDebugTransitioned
        or zombieDebugTransitioned
        or reactivityTransitioned
        or (inCombat and now - lastCombatDebugAt >= 150)
        or (baseZombieDebugActive
            and now - lastCombatDebugAt >= 350)
        or (reactivityActive and now - lastCombatDebugAt >= 750)
        or (zombieAlertDebugActive
            and now - lastCombatDebugAt >= (
                tonumber(Const and Const.ZOMBIE_ALERT_DEBUG_REFRESH_MS)
                    or 750
            ))
    then
        local equipmentInfo = Equipment
            and Equipment.Describe
            and Equipment.Describe(record)
            or {}
        local combat = buildCombatSummary(record, equipmentInfo)
        combatDebugState = buildCombatDebugState(
            record,
            combat,
            firearmState
        )
        if record.runtime then
            record.runtime.combatDebugReplicatedAt = now
        end
    end
    if record.runtime then
        record.runtime.combatDebugWasActive = inCombat
        record.runtime.zombieDebugWasActive = zombieDebugActive
        record.runtime.lastReactivityDebugSig = reactivitySignature
    end
    return combatDebugState
end

return Network
