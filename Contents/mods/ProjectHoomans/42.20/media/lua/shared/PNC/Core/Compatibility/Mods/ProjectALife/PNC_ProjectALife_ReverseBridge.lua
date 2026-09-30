-- Keep Project A-Life from treating managed Hoomans bodies as ordinary zombies.
-- This is a runtime bridge owned by Hoomans; the Workshop copy is untouched.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}

local Bridge = PNC.Compatibility.ProjectALifeReverseBridge
    or { installAttempts = 0 }
PNC.Compatibility.ProjectALifeReverseBridge = Bridge
Bridge.installAttempts = tonumber(Bridge.installAttempts) or 0

local function isHoomansBody(body)
    local ownership = PNC.Compatibility.ActorOwnership
    if not ownership or type(ownership.IsHoomansOwned) ~= "function" then
        return false
    end
    local ok, owned = pcall(ownership.IsHoomansOwned, body)
    return ok and owned == true
end

local function adapter()
    return PNC.Compatibility.ProjectALifeAdapter
end

local function canProjectALifeAttack(actor, body, phase)
    local integration = adapter()
    if not integration or type(integration.CanProjectALifeAttack) ~= "function" then
        return false, "projectalife_adapter_unavailable"
    end
    local ok, allowed, reason = pcall(
        integration.CanProjectALifeAttack,
        actor,
        body,
        { phase = phase }
    )
    if not ok then return false, "projectalife_relation_failed" end
    return allowed == true, reason
end

local function installReverseBridge()
    local alife = ProjectALife
    local perception = alife and alife.Perception
    local combat = alife and alife.Combat
    if not perception or type(perception.findThreat) ~= "function"
        or not combat or type(combat.friendlyBody) ~= "function"
    then
        return false
    end

    if Bridge.perception == perception
        and perception.findThreat == Bridge.findThreatWrapper
        and Bridge.combat == combat
        and combat.friendlyBody == Bridge.friendlyBodyWrapper
        and (type(combat.kindOf) ~= "function"
            or combat.kindOf == Bridge.kindOfWrapper)
        and (type(combat.peekKind) ~= "function"
            or combat.peekKind == Bridge.peekKindWrapper)
        and (type(combat.targetIsHuman) ~= "function"
            or combat.targetIsHuman == Bridge.targetIsHumanWrapper)
        and (type(combat.hostileToActor) ~= "function"
            or combat.hostileToActor == Bridge.hostileToActorWrapper)
    then
        return true
    end

    local originalFindThreat = perception.findThreat
    local originalFriendlyBody = combat.friendlyBody
    local originalKindOf = combat.kindOf
    local originalPeekKind = combat.peekKind
    local originalTargetIsHuman = combat.targetIsHuman
    local originalHostileToActor = combat.hostileToActor

    local findThreatWrapper
    findThreatWrapper = function(actor, shell, mode)
        local target, distance, kind = originalFindThreat(actor, shell, mode)
        if target and isHoomansBody(target) then
            local allowed = canProjectALifeAttack(actor, target, "perception")
            if not allowed then
                local engagements = perception.engagements
                if type(engagements) == "table" and type(actor) == "table" then
                    engagements[actor.uid] = nil
                end
                return nil, math.huge, nil
            end
            -- Deliberately keep the kind A-Life derived. Re-labelling a managed
            -- body as "actor" made A-Life route it into actor-only logic: an
            -- ActorRegistry lookup it can never satisfy, actor grudge keys, and
            -- the Risk/speech path that expects an A-Life record. Engagement
            -- style for managed bodies is still human-like, but that comes from
            -- the kindOf/peekKind wrappers below, not from this classification.
        end
        return target, distance, kind
    end

    local friendlyBodyWrapper
    friendlyBodyWrapper = function(actor, shell, body)
        if isHoomansBody(body) then
            local allowed, reason = canProjectALifeAttack(
                actor, body, "damage")
            if not allowed then return true, reason end
            return false
        end
        return originalFriendlyBody(actor, shell, body)
    end

    local kindOfWrapper
    if type(originalKindOf) == "function" then
        kindOfWrapper = function(body)
            if isHoomansBody(body) then return "actor" end
            return originalKindOf(body)
        end
        combat.kindOf = kindOfWrapper
    end

    local peekKindWrapper
    if type(originalPeekKind) == "function" then
        peekKindWrapper = function(body)
            if isHoomansBody(body) then return "actor" end
            return originalPeekKind(body)
        end
        combat.peekKind = peekKindWrapper
    end

    local targetIsHumanWrapper
    if type(originalTargetIsHuman) == "function" then
        targetIsHumanWrapper = function(body)
            if isHoomansBody(body) then return true end
            return originalTargetIsHuman(body)
        end
        combat.targetIsHuman = targetIsHumanWrapper
    end

    -- A-Life classifies any body without its own stamp as hostile, which made
    -- managed Hoomans bodies valid line-of-fire bystanders and valid "enemy in
    -- lane" picks. That native damage bypassed the Hoomans wound pipeline and
    -- gave managed actors a real attacker to retaliate against, so a neutral
    -- patrol ended up in a firefight it never started.
    local hostileToActorWrapper
    if type(originalHostileToActor) == "function" then
        hostileToActorWrapper = function(actor, body, shell)
            if isHoomansBody(body) then
                local allowed = canProjectALifeAttack(
                    actor, body, "line_of_fire")
                return allowed == true
            end
            return originalHostileToActor(actor, body, shell)
        end
        combat.hostileToActor = hostileToActorWrapper
    end

    perception.findThreat = findThreatWrapper
    combat.friendlyBody = friendlyBodyWrapper
    Bridge.perception = perception
    Bridge.findThreatWrapper = findThreatWrapper
    Bridge.combat = combat
    Bridge.friendlyBodyWrapper = friendlyBodyWrapper
    Bridge.kindOfWrapper = kindOfWrapper
    Bridge.peekKindWrapper = peekKindWrapper
    Bridge.targetIsHumanWrapper = targetIsHumanWrapper
    Bridge.hostileToActorWrapper = hostileToActorWrapper
    return true
end

-- Project A-Life asks its speech layer for a player key even when it is
-- addressing a non-player: Risk.plead() computes `isPlayer` and then always
-- passes `isPlayer and target or nil` to Talk.bark(), while mayInitiate() only
-- reaches plead() for kind "player" or "actor". Speech.playerKey() indexes that
-- argument without a nil guard, so pleading to an actor -- any A-Life NPC,
-- including two of its own -- throws inside its own pcall. The throw is caught,
-- so it only shows up with break-on-error enabled, but it is noise the
-- compatibility layer can remove: return the same value playerKey() already
-- returns when its own pcall fails, and never touch a successful lookup.
local function installSpeechGuard()
    local alife = ProjectALife
    local speech = alife and alife.Speech
    if speech == nil or type(speech.playerKey) ~= "function" then
        return false
    end
    if speech.playerKey == Bridge.playerKeyWrapper then return true end
    local originalPlayerKey = speech.playerKey
    local wrapper
    wrapper = function(player)
        if player == nil or player.getUsername == nil then return nil end
        return originalPlayerKey(player)
    end
    speech.playerKey = wrapper
    Bridge.speech = speech
    Bridge.playerKeyWrapper = wrapper
    return true
end

local function installAll()
    local bridges = installReverseBridge()
    -- A-Life's Speech module is server-side; on a client it never appears, so
    -- this guard is optional and must not gate the perception/combat bridges.
    local speech = installSpeechGuard()
    return bridges, speech
end

local function removeRetry()
    if Bridge.retry and Events and Events.OnTick
        and Events.OnTick.Remove
    then
        Events.OnTick.Remove(Bridge.retry)
    end
end

local function retryInstall()
    Bridge.installAttempts = Bridge.installAttempts + 1
    local bridges, speech = installAll()
    if (bridges and speech) or Bridge.installAttempts >= 120 then
        removeRetry()
    end
end

local installedBridges, installedSpeech = installAll()
if not (installedBridges and installedSpeech)
    and Events and Events.OnTick and Events.OnTick.Add
then
    Bridge.retry = retryInstall
    Events.OnTick.Add(retryInstall)
end

return installReverseBridge
