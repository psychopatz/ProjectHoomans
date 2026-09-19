-- Optional semantic world-target diagnostics projection.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.WorldTargetCatalog
    or require "PNC/Semantics/PNC_SemanticWorldTargetCatalog"
local Diagnostics = PNC.Semantics.SemanticDiagnostics
local HintDiagnostics = {}

function HintDiagnostics.Record(query, profile, originX, originY, originZ, radius,
    candidates, objectCount, hint, reason, observationStats)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return
    end
    local top = candidates and candidates[1] or nil
    local second = candidates and candidates[2] or nil
    Diagnostics.Record("semantic.world_target.client_hint", {
        query = query,
        requestedKind = profile and profile.kind or nil,
        originX = originX,
        originY = originY,
        originZ = originZ,
        radius = radius,
        inspectedObjects = objectCount,
        observationCacheHit = observationStats
            and observationStats.cached == true or false,
        observationScanTruncated = observationStats
            and observationStats.truncated == true or false,
        observationMaxObjects = observationStats
            and observationStats.maxObjects or nil,
        candidates = candidates and #candidates or 0,
        topKind = top and top.kind or nil,
        topLabel = top and top.label or nil,
        topX = top and top.x or nil,
        topY = top and top.y or nil,
        topScore = top and top.score or nil,
        secondScore = second and second.score or nil,
        status = hint and "attached" or "not_attached",
        reason = reason,
    }, {
        dedupeKey = "world_target|" .. Catalog.Normalize(query or "") .. "|"
            .. tostring(profile and profile.kind or "") .. "|"
            .. tostring(hint and "attached" or "not_attached") .. "|"
            .. tostring(reason or ""),
        consoleIntervalMs = 1000,
    })
end


return HintDiagnostics
