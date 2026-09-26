-- Receives short-lived, server-selected coordinate goals for ordinary zombies.

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Core = PNC.Core
local Const = PNC.Const
local ClientState = PNC.Network.ClientState

ClientState.zombiePursuitDirectives =
    ClientState.zombiePursuitDirectives or {}
ClientState.zombiePursuitLogThrottle =
    ClientState.zombiePursuitLogThrottle or {}

local function diagnosticsIncrement(name)
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if diagnostics and diagnostics.Increment then
        diagnostics.Increment(name)
    end
end

local function finiteNumber(value)
    local number = tonumber(value)
    return number ~= nil
        and number == number
        and math.abs(number) < math.huge
        and number or nil
end

local function logDirectiveDiagnostic(
    onlineID, npcId, state, detail, now
)
    local diagnostics = PNC.PerformanceScalingDiagnostics
    local key = tostring(onlineID or "unknown")
    local previous = ClientState.zombiePursuitLogThrottle[key]
    local fields
    if diagnostics
        and type(diagnostics.IsZombieAggroAuditEnabled) == "function"
        and not diagnostics.IsZombieAggroAuditEnabled()
    then
        return false
    end
    if not Core or not Core.LogInfo then return end
    now = tonumber(now) or Core.Now()
    state = tostring(state or "unknown")
    if previous
        and previous.state == state
        and now - (tonumber(previous.at) or 0) < 2500
    then
        return
    end
    if previous
        and previous.state ~= state
        and now - (tonumber(previous.at) or 0) < 500
    then
        return
    end
    ClientState.zombiePursuitLogThrottle[key] = {
        state = state,
        at = now,
    }
    fields = {
        "zombieOnlineID=" .. key,
        "npc=" .. tostring(npcId or "unknown"),
        "state=" .. state,
        tostring(detail or ""),
    }
    if diagnostics
        and type(diagnostics.LogZombieAggroAudit) == "function"
    then
        return diagnostics.LogZombieAggroAudit("mp_receive", fields)
    end
    Core.LogInfo(
        "ZombieAggro.mp_receive " .. table.concat(fields, " ")
    )
    return true
end

local function receiveDirective(args)
    local onlineID
    local id
    local active
    local revision
    local x
    local y
    local z
    local now
    local ttl
    local historyTTL
    local previous
    local directives = ClientState.zombiePursuitDirectives
    local key
    if type(args) ~= "table" then
        diagnosticsIncrement("ZombieAggro.MPDirectiveIgnored")
        return
    end
    onlineID = finiteNumber(args.zombieOnlineID)
    revision = finiteNumber(args.revision)
    active = args.active == true
    if onlineID == nil or onlineID < 0 or revision == nil or revision < 0 then
        diagnosticsIncrement("ZombieAggro.MPDirectiveIgnored")
        return
    end
    onlineID = math.floor(onlineID)
    revision = math.floor(revision)
    key = tostring(onlineID)
    x = finiteNumber(args.x)
    y = finiteNumber(args.y)
    z = finiteNumber(args.z)
    if active and (x == nil or y == nil or z == nil) then
        diagnosticsIncrement("ZombieAggro.MPDirectiveIgnored")
        logDirectiveDiagnostic(
            onlineID, args.npcId, "ignored_invalid_coordinate",
            "revision=" .. tostring(revision), Core.Now()
        )
        return
    end
    now = Core.Now()
    if now - (tonumber(ClientState.zombiePursuitLogCleanupAt) or 0)
        >= 10000
    then
        for cachedID, logEntry in pairs(
            ClientState.zombiePursuitLogThrottle
        ) do
            if now - (tonumber(logEntry.at) or 0) > 30000 then
                ClientState.zombiePursuitLogThrottle[cachedID] = nil
            end
        end
        ClientState.zombiePursuitLogCleanupAt = now
    end
    ttl = math.max(
        250,
        tonumber(Const.ZOMBIE_NPC_DIRECTIVE_TTL_MS) or 1100
    )
    historyTTL = math.max(ttl * 4, 5000)
    for candidateID, candidate in pairs(directives) do
        if not candidate
            or (tonumber(candidate.historyExpiresAt) or 0) <= now
        then
            directives[candidateID] = nil
        end
    end
    previous = directives[key]
    if previous then
        local previousRevision = tonumber(previous.revision) or -1
        if revision < previousRevision
            or (revision == previousRevision
                and previous.active ~= true
                and active)
        then
            diagnosticsIncrement("ZombieAggro.MPDirectiveIgnored")
            logDirectiveDiagnostic(
                onlineID, args.npcId, "ignored_stale_revision",
                "revision=" .. tostring(revision)
                    .. " previousRevision=" .. tostring(previousRevision),
                now
            )
            return
        end
    end
    id = args.npcId ~= nil and tostring(args.npcId) or nil
    directives[key] = {
        active = active,
        owner = args.owner ~= nil and tostring(args.owner)
            or "ProjectHoomans",
        provider = args.provider ~= nil and tostring(args.provider)
            or "Hoomans",
        priority = tonumber(args.priority) or 100,
        reason = args.reason ~= nil and tostring(args.reason)
            or "hoomans_npc",
        approach = active and args.approach == true or false,
        zombieOnlineID = onlineID,
        npcId = id,
        x = x,
        y = y,
        z = z,
        revision = revision,
        receivedAt = now,
        expiresAt = now + ttl,
        historyExpiresAt = now + historyTTL,
    }
    diagnosticsIncrement(
        active and "ZombieAggro.MPDirectiveReceived"
            or "ZombieAggro.MPDirectiveCleared"
    )
    logDirectiveDiagnostic(
        onlineID, id,
        active and "directive_received" or "directive_cleared",
        "revision=" .. tostring(revision)
            .. " x=" .. tostring(x)
            .. " y=" .. tostring(y)
            .. " z=" .. tostring(z)
            .. " approach=" .. tostring(args.approach == true)
            .. " expiresAt=" .. tostring(now + ttl),
        now
    )
end

function Internal.ResetZombiePursuitDirectives()
    ClientState.zombiePursuitDirectives = {}
    ClientState.zombiePursuitLogThrottle = {}
    ClientState.zombiePursuitLogCleanupAt = nil
end

Internal.RegisterServerCommand(Const.CMD_ZOMBIE_PURSUIT, receiveDirective)

return Internal
