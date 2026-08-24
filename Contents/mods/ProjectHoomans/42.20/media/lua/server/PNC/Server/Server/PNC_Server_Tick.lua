if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Server = PNC.Server
local H = Server.Internal
local Core = PNC.Core

function Server.OnTick()
    local now = Core.Now()
    local due = H.PrepareTick(now)
    local i
    for i = 1, #due do
        H.ProcessRecord(due[i], now)
    end
    H.FinishTick(now)
end
