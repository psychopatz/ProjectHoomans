PNC = PNC or {}
PNC.FakeLocomotion = PNC.FakeLocomotion or {}
PNC.FakeLocomotion.Internal = PNC.FakeLocomotion.Internal or {}

local FakeLocomotion = PNC.FakeLocomotion
local Internal = FakeLocomotion.Internal
local LiveBodyControl = PNC.LiveBodyControl

function FakeLocomotion.PrepareBody(zombie, lane, now)
    local resolvedMode = lane and lane.resolvedMode
        or lane and lane.mode
        or "walk"
    local profile = Internal.ResolveProfile(lane, resolvedMode)
    if not zombie then return end
    if LiveBodyControl and LiveBodyControl.MaintainHumanizedBody then
        LiveBodyControl.MaintainHumanizedBody(zombie, now, false, false)
    elseif LiveBodyControl and LiveBodyControl.ApplyHumanizedBodyFlags then
        LiveBodyControl.ApplyHumanizedBodyFlags(zombie)
    end
    if LiveBodyControl and LiveBodyControl.TrySilenceEmitter then
        LiveBodyControl.TrySilenceEmitter(zombie, lane, now)
    end
    if zombie.setRunning then
        zombie:setRunning(profile and profile.isRunning == true)
    end
    if LiveBodyControl and LiveBodyControl.SetManagedBodyUseless then
        LiveBodyControl.SetManagedBodyUseless(zombie, true)
    end
end

return FakeLocomotion
