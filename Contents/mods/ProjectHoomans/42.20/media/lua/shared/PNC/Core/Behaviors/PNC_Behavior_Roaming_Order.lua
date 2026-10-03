-- Roaming order normalization provider.

PNC = PNC or {}
PNC.BehaviorRoaming = PNC.BehaviorRoaming or {}

local Roaming = PNC.BehaviorRoaming
local H = Roaming.Internal and Roaming.Internal.Order
if type(H) ~= "table" then return Roaming end

local Const = H.Const

local function normalizeOrder(record, spec)
    local pauseMinMs = math.max(0, tonumber(spec.pauseMinMs) or Const.ROAM_PAUSE_MIN_MS)
    local pauseMaxMs = math.max(pauseMinMs, tonumber(spec.pauseMaxMs) or Const.ROAM_PAUSE_MAX_MS)
    local roadBounds = type(spec.roadBounds) == "table"
        and spec.roadBounds or nil
    local shelterBounds = type(spec.shelterBounds) == "table"
        and spec.shelterBounds or nil
    return {
        kind = spec.kind == Const.ORDER_HOSTILE_ROAM
            and Const.ORDER_HOSTILE_ROAM or Const.ORDER_ROAM,
        roamMode = tostring(spec.roamMode or Const.ROAM_MODE_AREA),
        x = tonumber(spec.x) or record.anchorX,
        y = tonumber(spec.y) or record.anchorY,
        z = tonumber(spec.z) or record.anchorZ,
        radius = math.max(0.5, tonumber(spec.radius) or Const.ROAM_DEFAULT_RADIUS),
        targetRadius = math.max(1, tonumber(spec.targetRadius) or Const.ROAM_TARGET_RADIUS),
        reachedDistance = math.max(0.1, tonumber(spec.reachedDistance) or Const.ROAM_REACHED_DISTANCE),
        moveMode = tostring(spec.moveMode or "walk"),
        pauseMinMs = pauseMinMs,
        pauseMaxMs = pauseMaxMs,
        shelterSiteID = type(spec.shelterSiteID) == "string"
            and spec.shelterSiteID or nil,
        shelterBounds = shelterBounds and {
            minX = tonumber(shelterBounds.minX),
            minY = tonumber(shelterBounds.minY),
            maxX = tonumber(shelterBounds.maxX),
            maxY = tonumber(shelterBounds.maxY),
            minZ = tonumber(shelterBounds.minZ),
            maxZ = tonumber(shelterBounds.maxZ),
        } or nil,
        ambientMobile = spec.ambientMobile == true,
        ambientObjective = type(spec.ambientObjective) == "string"
            and spec.ambientObjective or nil,
        ambientSourceID = type(spec.ambientSourceID) == "string"
            and spec.ambientSourceID or nil,
        roadBounds = roadBounds and {
            minX = tonumber(roadBounds.minX),
            minY = tonumber(roadBounds.minY),
            maxX = tonumber(roadBounds.maxX),
            maxY = tonumber(roadBounds.maxY),
        } or nil,
    }
end

H.Normalize = normalizeOrder

return Roaming
