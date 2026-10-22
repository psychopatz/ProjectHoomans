if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Adapter = PNC.WorldKnowledge
if not Adapter or Adapter._serverInstalled then return end
Adapter._serverInstalled = true

local function wrap(target, name, after)
    local original = target and target[name]
    if type(original) ~= "function" then return false end
    target[name] = function(...)
        local results = { original(...) }
        pcall(after, results, ...)
        return results[1], results[2], results[3], results[4]
    end
    return true
end

wrap(PNC.SocialEventHooks, "ObserveZombieHorde", function(results, record, count, _, at, source)
    if results[1] == true then Adapter.PublishZombiePressure(record, count, source, at) end
end)

wrap(PNC.Health, "Kill", function(results, record, _, reason, damageEvent)
    if results[1] == true then Adapter.PublishDeath(record, damageEvent, reason) end
end)

wrap(PNC.FactionIncidentService, "AddIncident", function(results, actorID, victimID, incidentType, spec)
    if results[1] == true then
        Adapter.PublishIncident(actorID, victimID, incidentType, results[3], spec and spec.worldAgeHours)
    end
end)

wrap(PNC.Factions, "Destroy", function(results, factionID, reason, at)
    if results[1] == true then Adapter.PublishFactionStatus(factionID, "destroyed", reason, at) end
end)

local Internal = PNC.Factions and PNC.Factions.Internal
wrap(Internal, "mutateTreaty", function(results, firstID, secondID, incidentType, options)
    if results[1] == true then
        Adapter.PublishIncident(firstID, secondID, incidentType, { relation = results[3] }, options and options.worldAgeHours)
    end
end)

if type(Events) == "table" and Events.OnSave and type(Events.OnSave.Add) == "function" then
    Events.OnSave.Add(Adapter.Save)
end
Adapter.Load()

return Adapter
