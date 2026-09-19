PNC = PNC or {}
PNC.AnimationTrace = PNC.AnimationTrace or {}

local Trace = PNC.AnimationTrace
local Internal = Trace.Internal or {}
Trace.Internal = Internal

Internal.MAX_SAMPLES = 48
Internal.MAX_RETAINED_TRACES = 64
Internal.MAX_AUTO_DUMP_KEYS = 256
Internal.ACTION_HANDOFF_GRACE_MS = 180
if type(Internal.autoDumpOrder) ~= "table" then
    -- Older versions retained only the map, which could grow without bound.
    Internal.autoDumped = {}
    Internal.autoDumpOrder = {}
    Internal.autoDumpOrderNext = 1
    Internal.autoDumpOrderCount = 0
else
    Internal.autoDumped = Internal.autoDumped or {}
    Internal.autoDumpOrderNext =
        tonumber(Internal.autoDumpOrderNext) or 1
    Internal.autoDumpOrderCount =
        tonumber(Internal.autoDumpOrderCount) or 0
end
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
