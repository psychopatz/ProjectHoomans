if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Server = PNC.Server
local H = Server.Internal
local Core = PNC.Core

function Server.OnTick()
    local clockOK, now = H.SafePhase("server_tick.clock", Core.Now)
    if not clockOK then return end

    local prepareOK, due = H.SafePhase("server_tick.prepare", H.PrepareTick,
        nil, now)
    if not prepareOK or type(due) ~= "table" then due = {} end
    local i
    for i = 1, #due do
        local record = due[i]
        H.SafePhase("server_tick.process_record", H.ProcessRecord, {
            npcId = record and record.id or "unknown",
        }, record, now)
    end
    H.SafePhase("server_tick.finish", H.FinishTick, nil, now)
end
