-- Bounded client-side repair for human identity fields on remote IsoZombie
-- replicas. Clothing/equipment remain server-owned.

PNC = PNC or {}
PNC.Visuals = PNC.Visuals or {}

local Visuals = PNC.Visuals
local Core = PNC.Core
local NEXT_CHECK_AT = setmetatable({}, { __mode = "k" })
local CHECK_INTERVAL_MS = 250

function Visuals.ReplicaHumanAppearanceMatches(
    zombie,
    appearance,
    isFemale
)
    local humanVisual
    if not zombie or not appearance then return false end
    if zombie.isFemale
        and zombie:isFemale() ~= (isFemale == true)
    then
        return false
    end
    humanVisual = zombie.getHumanVisual
        and zombie:getHumanVisual() or nil
    if not humanVisual then return false end
    if appearance.skinTexture
        and humanVisual.getSkinTexture
        and tostring(humanVisual:getSkinTexture())
            ~= tostring(appearance.skinTexture)
    then
        return false
    end
    if appearance.hairModel
        and humanVisual.getHairModel
        and tostring(humanVisual:getHairModel())
            ~= tostring(appearance.hairModel)
    then
        return false
    end
    if appearance.beardModel
        and humanVisual.getBeardModel
        and tostring(humanVisual:getBeardModel())
            ~= tostring(appearance.beardModel)
    then
        return false
    end
    return true
end

function Visuals.RepairReplicaHumanAppearance(
    zombie,
    appearance,
    isFemale,
    now
)
    local nextAt
    if not zombie or not appearance then
        return false, "missing_body_or_appearance"
    end
    now = tonumber(now)
        or (Core and Core.Now and Core.Now() or 0)
    nextAt = tonumber(NEXT_CHECK_AT[zombie]) or 0
    if now < nextAt then
        return false, "throttled"
    end
    NEXT_CHECK_AT[zombie] = now + CHECK_INTERVAL_MS
    if Visuals.ReplicaHumanAppearanceMatches(
        zombie,
        appearance,
        isFemale
    ) then
        return false, "current"
    end
    Visuals.MaintainHumanAppearance(
        zombie,
        appearance,
        isFemale,
        true
    )
    return true, "repaired"
end

return Visuals
