PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Internal = Wounds.Internal
local Core = PNC.Core
local Settings = PNC.Sandbox

local function logInfection(record, eventName, status, reason, infection)
    if not Internal.LogInfectionDebug then return end
    infection = infection or record and record.health
        and record.health.body and record.health.body.infection or nil
    Internal.LogInfectionDebug(
        record,
        eventName,
        status,
        reason,
        infection and infection.stage,
        infection and infection.progress,
        infection and infection.fever
    )
end

local function hasAuthority()
    return Core and type(Core.IsAuthority) == "function"
        and Core.IsAuthority() == true
end

local function notAuthority(record, eventName)
    logInfection(record, eventName, "rejected", "not_authority")
    return false, "not_authority"
end

function Internal.Infect(record, partId, nowHour, force)
    if not hasAuthority() then
        return notAuthority(record, "apply")
    end
    local body = Wounds.Ensure(record)
    local chance = Settings.NPCZombieInfectionChance()
    if body.infection
        and (
            body.infection.active == true
            or body.infection.fatal == true
        )
    then
        logInfection(record, "apply", "rejected", "already_infected", body.infection)
        return false, "already_infected"
    end
    if force ~= true then
        if chance <= 0 then
            logInfection(record, "apply", "rejected", "disabled")
            return false, "disabled"
        end
        if Internal.RandomPercent() >= chance then
            logInfection(record, "apply", "rejected", "roll_failed")
            return false, "roll_failed"
        end
    end
    body.infection = {
        active = true,
        fatal = false,
        pendingFatal = false,
        sourcePart = partId,
        infectedAtWorldHour = nowHour,
        fatalAtWorldHour =
            nowHour + Settings.NPCInfectionMortalityHours(),
        reanimateAtWorldHour = 0,
        progress = 0,
        stage = "incubating",
        fever = 0,
        temperatureC = 37,
        lastUpdatedWorldHour = nowHour,
        lastDamageWorldHour = nowHour,
    }
    Internal.SetKnoxFever(record, 0)
    logInfection(record, "apply", "applied", "infected", body.infection)
    return true, "infected"
end

function Wounds.ForceInfection(record, partId)
    if not hasAuthority() then
        return notAuthority(record, "force")
    end
    local applied, reason = Internal.Infect(
        record,
        tostring(partId or Wounds.ChoosePartId()),
        Internal.WorldHour(),
        true
    )
    if applied and PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "infection")
    end
    return applied, reason
end

function Wounds.ClearInfection(record, source)
    if not hasAuthority() then
        return notAuthority(record, "clear")
    end
    if not record or record.alive == false then
        logInfection(record, "clear", "rejected", "invalid_target")
        return false, "invalid_target"
    end
    local body = Wounds.Ensure(record)
    local infection = body.infection
    if not infection
        or (
            infection.active ~= true
            and infection.fatal ~= true
            and infection.pendingFatal ~= true
        )
    then
        logInfection(record, "clear", "rejected", "not_infected", infection)
        return false, "not_infected"
    end
    body.infection = nil
    Internal.SetKnoxFever(record, 0)
    record.runtime = record.runtime or {}
    record.runtime.forceSyncEvent =
        tostring(source or "infection_cleared")
    if PNC.Registry and PNC.Registry.MarkDirty then
        PNC.Registry.MarkDirty(record, "infection")
    end
    logInfection(record, "clear", "applied", "infection_cleared")
    return true, "infection_cleared"
end

function Wounds.PrepareInfectionDeath(record)
    if not hasAuthority() then
        return notAuthority(record, "prepare_death")
    end
    local body = Wounds.Ensure(record)
    local infection = body.infection
    if not infection or infection.active ~= true then
        logInfection(record, "prepare_death", "rejected", "not_infected", infection)
        return false
    end
    infection.active = false
    infection.fatal = true
    infection.progress = 1
    infection.stage = "fatal"
    infection.fever = 100
    infection.temperatureC = 40.5
    Internal.SetKnoxFever(record, 1)
    infection.fatalAtWorldHour =
        tonumber(infection.fatalAtWorldHour)
        or Internal.WorldHour()
    infection.reanimateAtWorldHour = Internal.WorldHour()
    logInfection(record, "prepare_death", "applied", "fatal", infection)
    return true
end

function Wounds.TriggerInfectionDeath(record, zombie, reason)
    if not hasAuthority() then
        return notAuthority(record, "trigger_death")
    end
    local body = Wounds.Ensure(record)
    local infection = body.infection
    if not infection or infection.active ~= true then
        logInfection(record, "trigger_death", "rejected", "not_infected", infection)
        return false, "not_infected"
    end
    if not zombie then
        local newlyPending = infection.pendingFatal ~= true
        infection.pendingFatal = true
        Wounds.SetOverallHealth(
            record,
            math.max(1, tonumber(record.health.current) or 1)
        )
        record.health.current =
            math.max(1, tonumber(record.health.current) or 1)
        if newlyPending
            and PNC.Registry
            and PNC.Registry.MarkDirty
        then
            PNC.Registry.MarkDirty(record, "infection")
        end
        logInfection(record, "trigger_death", "pending", "awaiting_live_body", infection)
        return false, "awaiting_live_body"
    end
    Wounds.PrepareInfectionDeath(record)
    PNC.Health.Kill(
        record,
        zombie,
        reason or "zombie_infection"
    )
    logInfection(record, "trigger_death", "applied", "killed", infection)
    return true, "killed"
end

return Wounds
