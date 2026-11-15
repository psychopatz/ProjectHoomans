-- Lumber abstract output delivery delegating to PNC.WorkOutputService.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/Production/PNC_WorkOutputService"

local Service = PNC.LumberService
local Internal = Service.Internal
local OutputService = PNC.WorkOutputService
local markDirty = Internal.MarkDirty
local outputEffectFor = Internal.OutputEffectFor

---Flushes pending abstract lumber yields via WorkOutputService.
Internal.FlushAbstractOutput = function(job, record)
    local output = job and job.pendingOutput
    if not output then return true end
    local effect = outputEffectFor(output)
    return OutputService.FlushAbstractDelivery(job, record, effect, nil, {
        deliveryTarget = "NPC_INVENTORY",
        reason = "lumber_abstract_output",
        markDirty = markDirty,
    })
end

return Service
