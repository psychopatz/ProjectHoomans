-- Projects expiring zombie combat diagnostics for the combat snapshot.

local Network = PNC.Network
local Parts = Network.Internal.SnapshotParts
local Const = PNC.Const

function Parts.BuildCombatDebugTemporalState(record, runtime, now,
    npcIdentity)
    runtime = type(runtime) == "table" and runtime or {}
    local zombieAttacker = runtime.zombieAttacker
    local zombieStimulus = runtime.zombieStimulus
    local zombieAlert = runtime.zombieAlert
    local zombieAttackerAge = zombieAttacker
        and math.max(
            0,
            now - (tonumber(zombieAttacker.observedAt) or now)
        ) or nil
    local zombieStimulusAge = zombieStimulus
        and math.max(
            0,
            now - (tonumber(zombieStimulus.emittedAt) or now)
        ) or nil
    local zombieStimulusDebug
    if type(zombieStimulus) == "table"
        and zombieStimulusAge <= (
            tonumber(Const.ZOMBIE_ATTACKER_OBSERVATION_MS) or 1500
        )
    then
        zombieStimulusDebug = {
            sequence = zombieStimulus.sequence,
            state = zombieStimulus.state,
            reason = zombieStimulus.reason,
            ageMs = zombieStimulusAge,
            emittedAt = zombieStimulus.emittedAt,
            x = zombieStimulus.x,
            y = zombieStimulus.y,
            z = zombieStimulus.z,
            radius = zombieStimulus.radius,
            volume = zombieStimulus.volume,
        }
    elseif runtime.combatBlockReason == "follow_stealth_hidden"
        or runtime.combatBlockReason == "travel_stealth_hidden"
    then
        zombieStimulusDebug = {
            state = "suppressed",
            reason = runtime.combatBlockReason,
            ageMs = 0,
            emittedAt = now,
            x = record.x,
            y = record.y,
            z = record.z,
        }
    end

    return {
        zombieAttacker = zombieAttacker
            and zombieAttackerAge <= 1500 and {
                zombieId = zombieAttacker.zombieId,
                onlineID = zombieAttacker.onlineID,
                targetKind = "npc",
                targetId = record.id,
                targetName = npcIdentity.displayName
                    or record.displayName
                    or record.name
                    or "Unknown survivor",
                phase = zombieAttacker.phase,
                ageMs = zombieAttackerAge,
                x = zombieAttacker.x,
                y = zombieAttacker.y,
                z = zombieAttacker.z,
                distSq = zombieAttacker.distSq,
                actionState = zombieAttacker.actionState,
                bumpType = zombieAttacker.bumpType,
                path2Active = zombieAttacker.path2Active == true,
            } or nil,
        zombieStimulus = zombieStimulusDebug,
        zombieAlert = zombieAlert and {
            zombieId = zombieAlert.zombieId,
            sourceId = zombieAlert.sourceId,
            sequence = zombieAlert.sequence,
            x = zombieAlert.x,
            y = zombieAlert.y,
            z = zombieAlert.z,
            distSq = zombieAlert.distSq,
            ageMs = math.max(
                0,
                now - (tonumber(zombieAlert.observedAt) or now)
            ),
            remainingMs = math.max(
                0,
                (tonumber(zombieAlert.expiresAt) or now) - now
            ),
        } or nil,
    }
end

return Parts
