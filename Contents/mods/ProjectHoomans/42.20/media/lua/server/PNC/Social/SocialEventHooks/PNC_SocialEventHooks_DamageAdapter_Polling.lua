-- Server-authoritative vanilla damage polling provider.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local Hooks = PNC.SocialEventHooks
local H = PNC.SocialEventHooksInternal
local Core = PNC.Core
local call = H.DamageCall
local audit = H.DamageAudit
local nowMillis = H.DamageNowMillis
local POLL_INTERVAL_MS = 100
local VANILLA_MARKER_WINDOW_MS = 500

local function partSnapshot(part)
    if not part then return nil end
    return {
        health = tonumber(call(part, "getHealth")) or 100,
        scratchTime = tonumber(call(part, "getScratchTime")) or 0,
        cutTime = tonumber(call(part, "getCutTime")) or 0,
        biteTime = tonumber(call(part, "getBiteTime")) or 0,
        scratched = call(part, "scratched") == true,
        cut = call(part, "isCut") == true,
        bitten = call(part, "bitten") == true,
    }
end

local function playerDamageSnapshot(player)
    local bodyDamage = call(player, "getBodyDamage")
    local parts = bodyDamage and call(bodyDamage, "getBodyParts") or nil
    local count = tonumber(parts and call(parts, "size")) or 0
    local snapshot = {
        overall = tonumber(
            bodyDamage and call(bodyDamage, "getOverallBodyHealth")
        ) or 100,
        hitReaction = tostring(call(player, "getHitReaction") or ""),
        parts = {},
    }
    local index
    for index = 0, count - 1 do
        snapshot.parts[index + 1] = partSnapshot(call(parts, "get", index))
    end
    return snapshot
end

local function woundDelta(previous, current)
    local bestDamage = 0
    local bestType
    local bestPriority = 0
    local index
    local before
    local after
    local healthLoss
    local damageType
    local priority
    if not previous or not current then
        return 0, nil
    end
    for index = 1, #current.parts do
        after = current.parts[index]
        before = previous.parts[index]
        if after and before then
            healthLoss = math.max(
                0,
                (tonumber(before.health) or 100)
                    - (tonumber(after.health) or 100)
            )
            damageType = nil
            priority = 0
            if after.biteTime > before.biteTime + 0.01
                or (after.bitten and not before.bitten)
            then
                damageType = "bite"
                priority = 3
            elseif after.cutTime > before.cutTime + 0.01
                or (after.cut and not before.cut)
            then
                damageType = "laceration"
                priority = 2
            elseif after.scratchTime > before.scratchTime + 0.01
                or (after.scratched and not before.scratched)
            then
                damageType = "scratch"
                priority = 1
            end
            if damageType and (healthLoss > bestDamage
                or priority > bestPriority)
            then
                bestDamage = healthLoss
                bestType = damageType
                bestPriority = priority
            end
        end
    end
    if not bestType then
        if current.hitReaction ~= ""
            and current.hitReaction ~= previous.hitReaction
        then
            bestDamage = math.max(
                0,
                (tonumber(previous.overall) or 100)
                    - (tonumber(current.overall) or 100)
            )
            if bestDamage > 0 then
                return bestDamage, "scratch"
            end
        end
        return 0, nil
    end
    if bestDamage <= 0 then
        bestDamage = bestType == "bite" and 12
            or bestType == "laceration" and 8 or 4
    end
    return bestDamage, bestType
end

local function isPlayer(value)
    return H.IsPlayer and H.IsPlayer(value) == true
end

local function isZombie(value)
    return H.IsZombie and H.IsZombie(value) == true
end

local function onBeingHitByZombie(first, second)
    local player = isPlayer(first) and first
        or isPlayer(second) and second or nil
    local zombie = isZombie(first) and first
        or isZombie(second) and second or nil
    if player and zombie then
        Hooks.VanillaDamageMarkers[player] = {
            zombie = zombie,
            at = nowMillis(),
        }
        audit({
            "luaSide=server",
            "event=OnBeingHitByZombie",
            "phase=engine_callback",
            "result=true",
            "attackerID=" .. tostring(call(zombie, "getOnlineID") or "nil"),
        })
    else
        audit({
            "luaSide=server",
            "event=OnBeingHitByZombie",
            "phase=engine_callback",
            "result=false",
            "reason=unexpected_callback_arguments",
        })
    end
end

local function pollPlayer(player)
    local previous = Hooks.VanillaDamageSnapshots[player]
    local current = playerDamageSnapshot(player)
    local marker = Hooks.VanillaDamageMarkers[player]
    local attacker = call(player, "getAttackedBy")
    local damage
    local woundType
    local emitted
    local candidates
    local reason
    if not previous then
        Hooks.VanillaDamageSnapshots[player] = current
        return
    end
    if not isZombie(attacker)
        and marker
        and nowMillis() - (tonumber(marker.at) or 0)
            <= VANILLA_MARKER_WINDOW_MS
    then
        attacker = marker.zombie
    end
    damage, woundType = woundDelta(previous, current)
    Hooks.VanillaDamageSnapshots[player] = current
    if marker and nowMillis() - (tonumber(marker.at) or 0)
        > VANILLA_MARKER_WINDOW_MS
    then
        Hooks.VanillaDamageMarkers[player] = nil
    end
    if damage <= 0 or not isZombie(attacker) then
        return
    end
    emitted, candidates, reason = H.RecordPlayerHurtWitnesses(
        player,
        attacker,
        {
            damage = damage,
            healthLoss = damage,
            woundType = woundType,
            attackerKind = "zombie",
            attackerID = H.ThreatIDFor and H.ThreatIDFor(attacker) or nil,
            source = "vanilla_zombie_poll",
        }
    )
    audit({
        "luaSide=server",
        "event=VanillaZombieDamage",
        "phase=damage_observed",
        "result=true",
        "attackerID=" .. tostring(
            H.ThreatIDFor and H.ThreatIDFor(attacker) or "unknown"
        ),
        "damage=" .. tostring(damage),
        "woundType=" .. tostring(woundType),
        "witnessCandidates=" .. tostring(candidates),
        "witnessCount=" .. tostring(emitted),
        "reason=" .. tostring(reason),
    })
end

local function onTick()
    local now = nowMillis()
    if now - (tonumber(Hooks.LastVanillaDamagePollAt) or 0)
        < POLL_INTERVAL_MS
    then
        return
    end
    Hooks.LastVanillaDamagePollAt = now
    if Core and Core.ForEachPlayer then
        Core.ForEachPlayer(pollPlayer)
    end
end

if Events and Events.OnBeingHitByZombie
    and Events.OnBeingHitByZombie.Add
    and not Hooks.VanillaDamageCallbackRegistered
then
    Events.OnBeingHitByZombie.Add(onBeingHitByZombie)
    Hooks.VanillaDamageCallbackRegistered = true
    audit({
        "luaSide=server",
        "event=OnBeingHitByZombie",
        "phase=registration",
        "result=true",
    })
elseif not Hooks.VanillaDamageCallbackRegistered then
    audit({
        "luaSide=server",
        "event=OnBeingHitByZombie",
        "phase=registration",
        "result=false",
        "reason=engine_event_unavailable",
    })
end

if Events and Events.OnTick and Events.OnTick.Add
    and not Hooks.VanillaDamagePollRegistered
then
    Events.OnTick.Add(onTick)
    Hooks.VanillaDamagePollRegistered = true
    audit({
        "luaSide=server",
        "event=VanillaZombieDamage",
        "phase=registration",
        "result=true",
        "pollIntervalMs=" .. tostring(POLL_INTERVAL_MS),
    })
elseif not Hooks.VanillaDamagePollRegistered then
    audit({
        "luaSide=server",
        "event=VanillaZombieDamage",
        "phase=registration",
        "result=false",
        "reason=ontick_unavailable",
    })
end

return Hooks

