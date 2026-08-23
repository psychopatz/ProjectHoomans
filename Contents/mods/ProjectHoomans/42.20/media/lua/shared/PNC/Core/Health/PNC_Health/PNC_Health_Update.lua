local Health = PNC.Health
local Internal = Health.Internal
local Const = PNC.Const

function Health.Update(record, zombie, now)
    local health = Health.Ensure(record)
    if record.alive == false then
        return
    end
    if PNC.NPCWounds and PNC.NPCWounds.Update then
        PNC.NPCWounds.Update(record, zombie, now)
        if record.alive == false then return end
    end
    if health.state == "incapacitated" then
        if (tonumber(health.current) or 0)
            >= (tonumber(Const.INCAPACITATED_RECOVERY_HP) or 5)
        then
            Health.ResumeFromIncapacitated(record, zombie, "bandage_healing")
            return
        end
        Internal.ApplyIncapacitatedLiveState(record, zombie)
        return
    end
    if (tonumber(health.reviveProtectionUntil) or 0) > 0
        and now >= (tonumber(health.reviveProtectionUntil) or 0)
    then
        health.reviveProtectionUntil = 0
    end
    if zombie then
        Internal.RefreshNormalLiveBuffer(record, zombie)
    end
end
