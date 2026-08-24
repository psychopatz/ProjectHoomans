if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Server = PNC.Server
local H = Server.Internal
local Core = PNC.Core
local Const = PNC.Const
local Registry = PNC.Registry
local BodyLifecycle = PNC.BodyLifecycle
local PlayerCharacterLifecycle = PNC.PlayerCharacterLifecycle
local CommandRouter = PNC.ServerCommandRouter or {
    Handle = function() return false end,
}

function H.OnClientCommand(module, command, player, args)
    if module ~= Const.MODULE then
        return
    end

    if CommandRouter.Handle(command, player, args) then
        return
    end
end

function H.OnServerStarted()
    Registry.Load()
    if PNC.NPCKnowledge and PNC.NPCKnowledge.Load then
        PNC.NPCKnowledge.Load()
    end
    if PNC.Factions and PNC.Factions.Load then
        PNC.Factions.Load()
    end
    if PNC.Communities and PNC.Communities.Load then
        PNC.Communities.Load()
    end
    if PNC.ColonyStorageRepository and PNC.ColonyStorageRepository.Load then
        PNC.ColonyStorageRepository.Load()
    end
    if PNC.AbstractWorldStore and PNC.AbstractWorldStore.Load then
        PNC.AbstractWorldStore.Load()
    end
    if PNC.WorldDirector and PNC.WorldDirector.Initialize then
        PNC.WorldDirector.Initialize(true)
    end
    if PNC.Factions
        and PNC.Factions
            .ReconcileTerritorialLooterFactions
    then
        PNC.Factions.ReconcileTerritorialLooterFactions()
    end
    if PlayerCharacterLifecycle
        and PlayerCharacterLifecycle.OnServerStarted
    then
        PlayerCharacterLifecycle.OnServerStarted(Core.Now())
    end
    if BodyLifecycle and BodyLifecycle.RunStartupBodyCleanupNow then
        BodyLifecycle.RunStartupBodyCleanupNow(
            Core.Now(),
            "server_started",
            true
        )
    end
    if PNC.CompanionVehicle and PNC.CompanionVehicle.AuditLoadedReservations then
        PNC.CompanionVehicle.AuditLoadedReservations(Core.Now(), true)
    end
    if BodyLifecycle and BodyLifecycle.AuditLoadedBodies then
        BodyLifecycle.AuditLoadedBodies(Core.Now(), true)
    end
    Core.LogInfo("PNC server started.")
end

local serverTick = Server.OnTick
if PNC.ProfilerIntegration and PNC.ProfilerIntegration.WrapServerTick then
    serverTick = PNC.ProfilerIntegration.WrapServerTick(serverTick)
    Server.OnTick = serverTick
end
Events.OnTick.Add(serverTick)
Events.OnClientCommand.Add(H.OnClientCommand)
Events.OnServerStarted.Add(H.OnServerStarted)
