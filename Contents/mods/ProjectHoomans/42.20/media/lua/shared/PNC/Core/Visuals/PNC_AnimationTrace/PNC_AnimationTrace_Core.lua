PNC = PNC or {}
PNC.AnimationTrace = PNC.AnimationTrace or {}

local Trace = PNC.AnimationTrace
local Internal = Trace.Internal or {}
Trace.Internal = Internal

Internal.MAX_SAMPLES = 48
Internal.ACTION_HANDOFF_GRACE_MS = 180
Internal.autoDumped = Internal.autoDumped or {}
Internal.byBody = Internal.byBody or setmetatable({}, { __mode = "k" })
Internal.byNPC = Internal.byNPC or {}
Internal.sequence = tonumber(Internal.sequence) or 0
Trace.forceEnabled = Trace.forceEnabled == true

function Internal.NowMillis(now)
    return tonumber(now)
        or PNC.Core and PNC.Core.Now and PNC.Core.Now()
        or 0
end

return Trace
