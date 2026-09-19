-- Legacy receiver for server-selected zombie movement directives.
--
-- Multiplayer movement now uses the vanilla WorldSoundManager path. Keep the
-- command registered for compatibility, but discard packets without retaining
-- a per-zombie cache that no active controller consumes.

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local ClientState = PNC.Network.ClientState

-- Clear data left by a previous hot-loaded receiver version. New packets are
-- deliberately not stored while this route is retired.
ClientState.zombiePursuitDirectives = {}

local function diagnosticsIncrement(name)
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if diagnostics and diagnostics.Increment then
        diagnostics.Increment(name)
    end
end

local function discardDirective(args)
    if type(args) == "table" and args.active == true then
        diagnosticsIncrement("ZombieAggro.MPDirectiveIgnored")
    end
end

function Internal.ResetZombiePursuitDirectives()
    ClientState.zombiePursuitDirectives = {}
end

Internal.RegisterServerCommand(Const.CMD_ZOMBIE_PURSUIT, discardDirective)

return Internal
