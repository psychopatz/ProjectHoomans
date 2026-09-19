-- Debug authorization, roster, and unique-NPC request transport.
PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

function Client.CanUseDebug()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local coreDebug = PsychopatzCore and PsychopatzCore.Debug
    if not coreDebug or type(coreDebug.CanUse) ~= "function" then
        local ok, loaded = pcall(require, "PsychopatzCore/Debug/PsychopatzDebug")
        if ok then coreDebug = loaded end
    end
    return coreDebug and coreDebug.CanUse
        and coreDebug.CanUse(player) == true or false
end

function Client.RequestDebugRoster(forceAudit)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local diagnostics = {}
    if not Client.CanUseDebug() then
        ClientState.debugAuthorized = false
        ClientState.debugRoster = {}
        return false
    end
    ClientState.lastDebugRosterRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(player, Const.MODULE,
                Const.CMD_DEBUG_ROSTER_REQUEST,
                { audit = forceAudit == true })
            return true
        end
        return false
    end
    if PNC.BodyLifecycle and PNC.BodyLifecycle.AuditLoadedBodies then
        -- The monitor is also available in single-player, where there may be
        -- no remote server request to drive corpse cleanup. The audit owns its
        -- own throttling, so ordinary refreshes safely keep markers current.
        PNC.BodyLifecycle.AuditLoadedBodies(Core.Now(), forceAudit == true)
    end
    if PNC.BodyLifecycle and PNC.BodyLifecycle.BuildDebugRoster then
        diagnostics = PNC.BodyLifecycle.BuildDebugRoster()
    end
    ClientState.debugRoster = diagnostics
    ClientState.debugAuthorized = true
    ClientState.debugAudit = PNC.BodyLifecycle and PNC.BodyLifecycle.LastAudit or {}
    return true
end

function Client.RequestUniqueNPCDebug()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not Client.CanUseDebug() then
        ClientState.uniqueNPCDebugAuthorized = false
        ClientState.uniqueNPCDebug = nil
        ClientState.uniqueNPCDebugReason = "not_authorized"
        return false
    end
    ClientState.lastUniqueNPCDebugRequestAt = Core.Now()
    if Core.IsClientOnly and Core.IsClientOnly() then
        if player and sendClientCommand then
            sendClientCommand(
                player,
                Const.MODULE,
                Const.CMD_UNIQUE_NPC_DEBUG_REQUEST,
                {}
            )
            return true
        end
        return false
    end
    if PNC.UniqueNPCRegistry
        and PNC.UniqueNPCRegistry.BuildDebugSnapshot
    then
        local snapshot, reason = PNC.UniqueNPCRegistry.BuildDebugSnapshot()
        ClientState.uniqueNPCDebugAuthorized = snapshot ~= nil
        ClientState.uniqueNPCDebug = snapshot
        ClientState.uniqueNPCDebugReason = reason
        ClientState.lastUniqueNPCDebugReceiveAt = Core.Now()
        return snapshot ~= nil
    end
    ClientState.uniqueNPCDebugAuthorized = false
    ClientState.uniqueNPCDebug = nil
    ClientState.uniqueNPCDebugReason = "unique_registry_unavailable"
    return false
end

return Client
