-- Legacy receiver for server-selected zombie movement directives.
--
-- Multiplayer movement now uses the vanilla WorldSoundManager path. Keep this
-- receiver only so stale directives from an older loaded state can be safely
-- discarded; the client zombie controller no longer consumes them in MP.

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local ClientState = PNC.Network.ClientState

ClientState.zombiePursuitDirectives =
    ClientState.zombiePursuitDirectives or {}

local function diagnosticsIncrement(name)
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if diagnostics and diagnostics.Increment then
        diagnostics.Increment(name)
    end
end

local function acceptDirective(args)
    local directives = ClientState.zombiePursuitDirectives
    local zombieOnlineID
    local key
    local revision
    local existing
    local expiresAt
    if type(args) ~= "table" or args.zombieOnlineID == nil then
        return
    end
    zombieOnlineID = tonumber(args.zombieOnlineID)
    if zombieOnlineID == nil or zombieOnlineID < 0 then
        return
    end
    key = tostring(zombieOnlineID)
    revision = tonumber(args.revision) or 0
    existing = directives[key]
    if existing and revision < (tonumber(existing.revision) or 0) then
        diagnosticsIncrement("ZombieAggro.MPDirectiveStale")
        return
    end
    if args.active ~= true then
        directives[key] = nil
        diagnosticsIncrement("ZombieAggro.MPDirectiveCleared")
        return
    end
    expiresAt = tonumber(args.expiresAt)
    if expiresAt == nil then
        expiresAt = (PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0)
            + (tonumber(Const.ZOMBIE_NPC_DIRECTIVE_TTL_MS) or 1100)
    end
    directives[key] = {
        npcId = args.npcId ~= nil and tostring(args.npcId) or nil,
        x = tonumber(args.x),
        y = tonumber(args.y),
        z = tonumber(args.z),
        expiresAt = expiresAt,
        revision = revision,
    }
    diagnosticsIncrement("ZombieAggro.MPDirectiveReceived")
end

function Internal.ResetZombiePursuitDirectives()
    ClientState.zombiePursuitDirectives = {}
end

Internal.RegisterServerCommand(Const.CMD_ZOMBIE_PURSUIT, acceptDirective)

return Internal
