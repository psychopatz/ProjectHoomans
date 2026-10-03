local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core
local Const = PNC.Const or {}
local ClientState = PNC.Network and PNC.Network.ClientState or nil
local Effects = Internal.Effects
local TargetIndex = Internal.TargetIndex
local AGGRO_TIER_MS = Internal.AggroTierMS
local AGGRO_TIER_COUNT = Internal.AggroTierCount
local isForeignOwnedBody = Internal.IsForeignOwnedBody
local isMultiplayerMode = Internal.IsMultiplayerMode
local isStandaloneSingleplayer = Internal.IsStandaloneSingleplayer
local findNearestTarget = Internal.FindNearestTarget
local getPursuitDirective = Internal.GetPursuitDirective
local logPursuitDiagnostic = Internal.LogPursuitDiagnostic

local CONTROLLER_BY_ZOMBIE = setmetatable({}, { __mode = "k" })
local NEXT_UPDATE_TIER = 0
local ACTION_OWNED_ELSEWHERE = {
    ["attack"] = true,
    ["attack-network"] = true,
    bumped = true,
    climbfence = true,
    climbwindow = true,
    getup = true,
    lunge = true,
    onground = true,
    staggerback = true,
    turnalerted = true,
}

local function ensureControllerEntry(zombie)
    local entry = CONTROLLER_BY_ZOMBIE[zombie]
    if not entry then
        entry = {
            updateTier = NEXT_UPDATE_TIER,
        }
        NEXT_UPDATE_TIER =
            (NEXT_UPDATE_TIER + 1) % AGGRO_TIER_COUNT
        CONTROLLER_BY_ZOMBIE[zombie] = entry
    end
    return entry
end

local function isScheduledAggroTier(zombie, now)
    local entry = ensureControllerEntry(zombie)
    local currentTier = math.floor(now / AGGRO_TIER_MS)
        % AGGRO_TIER_COUNT
    return entry.updateTier == currentTier
end

local function isLocalZombieUpdate(zombie)
    -- Build 42 raises OnZombieUpdate for the local simulation lane. Keep this
    -- guard for the short remote-shell update window without touching the
    -- non-exposed server-side UdpConnection owner object.
    return not zombie.isRemoteZombie or zombie:isRemoteZombie() ~= true
end

function Internal.ResetClientZombieAggro()
    CONTROLLER_BY_ZOMBIE = setmetatable({}, { __mode = "k" })
    NEXT_UPDATE_TIER = 0
    TargetIndex.Reset()
end

function Internal.UpdateClientZombieAggro(zombie, now)
    local actionState
    local body
    local distanceSq
    local target
    local targetIsNPC
    local npcId
    local entry
    local directive
    local hasActiveDirective
    local directiveApplied
    now = tonumber(now) or (Core and Core.Now and Core.Now() or 0)
    if not zombie or (zombie.isDead and zombie:isDead()) then
        return false
    end
    entry = ensureControllerEntry(zombie)
    if entry.handlerSeen ~= true then
        entry.handlerSeen = true
        logPursuitDiagnostic(
            zombie,
            nil,
            "handler_enter",
            "isClient=" .. tostring(isClient and isClient() == true)
                .. " isServer=" .. tostring(isServer and isServer() == true)
                .. " remote=" .. tostring(
                    zombie.isRemoteZombie
                        and zombie:isRemoteZombie() == true or false
                ),
            now
        )
    end
    directive = isClient and isClient() == true
        and getPursuitDirective(zombie) or nil
    hasActiveDirective = directive
        and directive.active == true
        and (tonumber(directive.expiresAt) or 0) > now
        or false
    if not isLocalZombieUpdate(zombie) then
        if hasActiveDirective then
            logPursuitDiagnostic(
                zombie, directive.npcId, "not_local_simulation",
                "revision=" .. tostring(directive.revision)
                    .. " expiresAt=" .. tostring(directive.expiresAt), now
            )
        end
        return false
    end
    -- Bandits owns its own client-side zombie mind. Do not clear targets,
    -- hands, teeth, or lunge variables before its update lane runs.
    if isForeignOwnedBody(zombie) then
        if hasActiveDirective then
            logPursuitDiagnostic(
                zombie, directive.npcId, "foreign_owned_skip",
                "revision=" .. tostring(directive.revision), now
            )
        end
        return false
    end
    if Effects.EnforceManagedSafetyGuard(zombie) then return false end
    if isStandaloneSingleplayer()
        and PNC.ZombieAggro
        and type(PNC.ZombieAggro.Pump) == "function"
    then
        logPursuitDiagnostic(
            zombie,
            nil,
            "sp_authority_lane",
            "client_fallback_skipped",
            now
        )
        return false
    end
    if PNC.ZombieAggro
        and PNC.ZombieAggro.Internal
        and PNC.ZombieAggro.Internal.ShouldYieldToPursuitOwner
        and PNC.ZombieAggro.Internal.ShouldYieldToPursuitOwner(
            zombie,
            "ProjectHoomans",
            now
        )
    then
        local lease = PNC.ZombieAggro.Internal.GetPursuitLease
            and PNC.ZombieAggro.Internal.GetPursuitLease(zombie, now)
            or nil
        logPursuitDiagnostic(
            zombie,
            nil,
            "foreign_pursuit_owner",
            "owner=" .. tostring(lease and lease.owner or "unknown"),
            now
        )
        return false
    end
    -- The server owns MP target selection. Only the local client applies its
    -- short-lived coordinate directive to the locally simulated zombie.
    if isMultiplayerMode() and not (isClient and isClient() == true) then
        if hasActiveDirective then
            logPursuitDiagnostic(
                zombie, directive.npcId, "mp_not_client_skip",
                "revision=" .. tostring(directive.revision), now
            )
        end
        return false
    end
    actionState = zombie.getActionStateName
        and string.lower(tostring(
            zombie:getActionStateName() or ""
        ))
        or ""
    if ACTION_OWNED_ELSEWHERE[actionState] == true
        or (zombie.isProne and zombie:isProne())
    then
        if hasActiveDirective then
            logPursuitDiagnostic(
                zombie, directive.npcId, "action_state_skip",
                "action=" .. actionState
                    .. " prone=" .. tostring(
                        zombie.isProne and zombie:isProne() or false
                    )
                    .. " revision=" .. tostring(directive.revision), now
            )
        end
        return false
    end
    -- A live server directive is already an authoritative work item. Do not
    -- defer it behind the round-robin scan: OnZombieUpdate cadence can be
    -- slower than the directive TTL, which otherwise makes every directive
    -- expire while the client reports update_tier_skip. Keep tiering for
    -- idle scans and for releasing a directive that is no longer active.
    if not hasActiveDirective
        and entry.directiveActive ~= true
        and not isScheduledAggroTier(zombie, now)
    then
        return false
    end

    if isClient and isClient() == true then
        directive = directive or getPursuitDirective(zombie)
        if directive
            and directive.active == true
            and (tonumber(directive.expiresAt) or 0) > now
        then
            directiveApplied = Effects.ApplyCoordinateDirective(
                zombie,
                directive.x,
                directive.y,
                directive.z,
                now,
                directive.npcId,
                directive.approach,
                directive.owner,
                directive.provider,
                directive.expiresAt,
                directive.priority,
                directive.reason
            )
        end
        if directiveApplied then
            entry.directiveActive = true
            logPursuitDiagnostic(
                zombie, directive.npcId, "mp_directive_applied",
                "revision=" .. tostring(directive.revision)
                    .. " expiresIn=" .. tostring(
                        (tonumber(directive.expiresAt) or 0) - now
                    )
                    .. " targetX=" .. tostring(directive.x)
                    .. " targetY=" .. tostring(directive.y)
                    .. " targetZ=" .. tostring(directive.z)
                    .. " approach=" .. tostring(directive.approach == true),
                now
            )
            return true
        end
        if entry.directiveActive then
            logPursuitDiagnostic(
                zombie,
                directive and directive.npcId or nil,
                directive and directive.active == true
                    and "mp_directive_expired" or "mp_directive_cleared",
                "revision=" .. tostring(directive and directive.revision)
                    .. " expiresAt="
                    .. tostring(directive and directive.expiresAt)
                    .. " now=" .. tostring(now),
                now
            )
            Effects.ReleaseCoordinateDirective(zombie)
            entry.directiveActive = false
        elseif directive and directive.active == true then
            logPursuitDiagnostic(
                zombie, directive.npcId, "mp_directive_not_applied",
                "revision=" .. tostring(directive.revision)
                    .. " expiresAt=" .. tostring(directive.expiresAt)
                    .. " now=" .. tostring(now), now
            )
        end
        return false
    end

    logPursuitDiagnostic(
        zombie,
        nil,
        "sp_target_scan",
        "bodyIndex=" .. tostring(Sync.BodyByID ~= nil)
            .. " snapshots=" .. tostring(ClientState and ClientState.snapshots ~= nil),
        now
    )
    target, distanceSq, targetIsNPC = findNearestTarget(zombie, now)
    if not target then
        logPursuitDiagnostic(
            zombie,
            nil,
            "sp_no_target",
            "distanceSq=" .. tostring(distanceSq),
            now
        )
        Effects.ReleaseManagedTarget(zombie)
        return false
    end
    if not targetIsNPC then
        Effects.ApplyPlayerTarget(zombie, target)
        return false
    end
    body = target
    if not body
    then
        Effects.ReleaseManagedTarget(zombie)
        return false
    end
    npcId = body.getModData and body:getModData()
        and body:getModData().PNC_UUID or nil
    logPursuitDiagnostic(
        zombie, npcId, "sp_npc_selected",
        "distanceSq=" .. tostring(distanceSq)
            .. " npcX=" .. tostring(body:getX())
            .. " npcY=" .. tostring(body:getY())
            .. " action=" .. actionState,
        now
    )
    Effects.ApplySingleplayerAggro(
        zombie,
        body,
        distanceSq,
        now,
        npcId
    )
    return true
end

function Internal.OnClientZombieAggroUpdate(zombie)
    Internal.UpdateClientZombieAggro(
        zombie,
        Core and Core.Now and Core.Now() or 0
    )
end

-- This file is client-side, but also runs in standalone singleplayer where
-- isClient() is false. Register in both modes: SP keeps only the safety guard,
-- while an MP client applies the server's short-lived coordinate directive.
if Events and Events.OnZombieUpdate then
    if Sync.ClientZombieAggroUpdateHandler then
        Events.OnZombieUpdate.Remove(
            Sync.ClientZombieAggroUpdateHandler
        )
    end
    Sync.ClientZombieAggroUpdateHandler =
        Internal.OnClientZombieAggroUpdate
    Events.OnZombieUpdate.Add(
        Sync.ClientZombieAggroUpdateHandler
    )
end


return Internal
