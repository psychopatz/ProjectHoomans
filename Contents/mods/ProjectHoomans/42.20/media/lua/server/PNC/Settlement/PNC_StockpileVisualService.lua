if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.StockpileVisualService = PNC.StockpileVisualService or {}

local Service = PNC.StockpileVisualService
local Repository = PNC.SettlementRepository
local Definitions = PNC.FacilityDefinitions
local World = require "PNC/Settlement/PNC_StockpileVisualService_World"
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"
local Pending = Service.Pending or {}
local PendingDueAt = Service.PendingDueAt or {}
local PointIndex = Service.PointIndex or {}
local FacilityPointKeys = Service.FacilityPointKeys or {}
local FacilityPoints = Service.FacilityPoints or {}
local PENDING_RETRY_MS = 5000
local pendingCount = 0
local nextRetryAt = Service.NextRetryAt

for _ in pairs(Pending) do pendingCount = pendingCount + 1 end

local function logInfo(message)
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo("[StockpileVisual] " .. tostring(message))
    end
end

local function logWarn(message)
    if PNC.Core and PNC.Core.LogWarn then
        PNC.Core.LogWarn("[StockpileVisual] " .. tostring(message))
    end
end

Service.Pending = Pending
Service.PendingDueAt = PendingDueAt
Service.PointIndex = PointIndex
Service.FacilityPointKeys = FacilityPointKeys
Service.FacilityPoints = FacilityPoints

local function isStockpile(facility)
    return facility and tostring(facility.definitionId or "") == "stockpile"
end

local function isBuilt(facility)
    return FacilityState.IsBuilt(facility)
end

local function pointFromRegion(region)
    local zKeys = {}
    for z in pairs(region and region.levels or {}) do
        zKeys[#zKeys + 1] = z
    end
    table.sort(zKeys, function(a, b) return tonumber(a) < tonumber(b) end)
    for _, z in ipairs(zKeys) do
        local level = region.levels[z]
        local yKeys = {}
        for y in pairs(level and level.rows or {}) do
            yKeys[#yKeys + 1] = y
        end
        table.sort(yKeys, function(a, b) return tonumber(a) < tonumber(b) end)
        for _, y in ipairs(yKeys) do
            local spans = level.rows[y]
            if spans and spans[1] ~= nil then
                return { x = tonumber(spans[1]), y = tonumber(y),
                    z = tonumber(z) }
            end
        end
    end
    return nil
end

local function stockpilePoint(facility)
    local componentIds = {}
    for componentId, present in pairs(facility and facility.componentIds or {}) do
        if present == true then componentIds[#componentIds + 1] = componentId end
    end
    table.sort(componentIds, function(a, b) return tostring(a) < tostring(b) end)
    for _, componentId in ipairs(componentIds) do
        local component = Repository.GetComponent(componentId)
        if component and component.role == "storage.stockpile"
            and component.region
        then
            return pointFromRegion(component.region)
        end
    end
    return pointFromRegion(facility and facility.constructionRegion)
end

local function tierSpec(level)
    local definition = Definitions and Definitions.Get
        and Definitions.Get("stockpile") or nil
    local visual = definition and definition.visual or nil
    local tiers = visual and visual.tiers or nil
    local requested = math.max(1, math.floor(tonumber(level) or 1))
    local selectedTier, selected
    for tier, spec in pairs(tiers or {}) do
        local number = tonumber(tier)
        if number and number <= requested
            and (not selectedTier or number > selectedTier)
        then
            selectedTier, selected = number, spec
        end
    end
    if not selected then return nil end
    return selected, selectedTier, visual.mode or "nonrotatable"
end

function Service.GetVisualSpec(level, rotation)
    local spec, selectedTier, mode = tierSpec(level)
    if not spec then return nil end
    if mode == "rotatable" then
        local sprites = spec.sprites or {}
        local index = math.floor(tonumber(rotation) or 1)
        index = math.max(1, math.min(4, index))
        return { mode = mode, tier = selectedTier,
            sprite = sprites[index] or sprites[1],
            objectType = spec.objectType or "isoobject",
            north = spec.north == true }
    end
    local sprites = spec.sprites or {}
    return { mode = mode, tier = selectedTier,
        sprite = spec.sprite or sprites[1],
        objectType = spec.objectType or "isoobject",
        north = spec.north == true }
end

local function samePoint(a, b)
    return a and b and tonumber(a.x) == tonumber(b.x)
        and tonumber(a.y) == tonumber(b.y)
        and tonumber(a.z) == tonumber(b.z)
end

local function pointKey(point)
    if not point or point.x == nil or point.y == nil or point.z == nil then
        return nil
    end
    return tostring(point.x) .. ":" .. tostring(point.y) .. ":"
        .. tostring(point.z)
end

local function unindexFacilityPoint(facilityId)
    local key = FacilityPointKeys[tostring(facilityId or "")]
    if key then
        local facilities = PointIndex[key]
        if facilities then
            facilities[tostring(facilityId)] = nil
            local empty = true
            for _ in pairs(facilities) do
                empty = false
                break
            end
            if empty then PointIndex[key] = nil end
        end
    end
    FacilityPointKeys[tostring(facilityId or "")] = nil
    FacilityPoints[tostring(facilityId or "")] = nil
end

local function indexFacilityPoint(facilityId, point)
    local id = tostring(facilityId or "")
    if id == "" then return end
    local key = pointKey(point)
    if not key then
        unindexFacilityPoint(id)
        return
    end
    if FacilityPointKeys[id] ~= key then
        unindexFacilityPoint(id)
        PointIndex[key] = PointIndex[key] or {}
        PointIndex[key][id] = true
        FacilityPointKeys[id] = key
    end
    FacilityPoints[id] = point
end

local function nowMs()
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or nil
    return tonumber(now) or 0
end

local function setPending(facilityId, pending)
    local key = tostring(facilityId or "")
    if key == "" then return end
    if pending and not Pending[key] then
        Pending[key] = true
        pendingCount = pendingCount + 1
        PendingDueAt[key] = 0
        nextRetryAt = 0
    elseif not pending and Pending[key] then
        Pending[key] = nil
        pendingCount = math.max(0, pendingCount - 1)
        PendingDueAt[key] = nil
        if pendingCount == 0 then nextRetryAt = nil end
    end
end

local function deferPending(facilityId)
    local now = nowMs()
    local due = now > 0 and now + PENDING_RETRY_MS or 0
    local key = tostring(facilityId or "")
    PendingDueAt[key] = due
    nextRetryAt = due
end

local function pendingRetryDue()
    if pendingCount <= 0 then return false end
    local now = nowMs()
    return now <= 0 or nextRetryAt == nil or now >= nextRetryAt
end

function Service.Apply(facility, previousPoint, loadedSquare, pointOverride)
    if not isStockpile(facility) then return false, "NOT_STOCKPILE" end
    if not isBuilt(facility) then return false, "STOCKPILE_NOT_BUILT" end
    local point = pointOverride or stockpilePoint(facility)
    local spec = Service.GetVisualSpec(facility.level)
    if not point or not spec or not spec.sprite then
        setPending(facility.id, true)
        return false, "STOCKPILE_VISUAL_TARGET_UNAVAILABLE"
    end
    indexFacilityPoint(facility.id, point)
    local oldPoint = previousPoint or facility.stockpileVisual
    if oldPoint and not samePoint(oldPoint, point) then
        local oldSquare = World.SquareAt(oldPoint)
        if oldSquare then World.RemoveAt(oldSquare, facility.id) end
    end
    local square = loadedSquare
    if square and not World.SquareMatchesPoint(square, point) then
        square = nil
    end
    square = square or World.SquareAt(point)
    if not square then
        setPending(facility.id, true)
        return false, "STOCKPILE_VISUAL_WORLD_UNAVAILABLE"
    end
    local existing = World.MatchingVisual(square, facility.id, spec)
    if existing then
        facility.stockpileVisual = { x = point.x, y = point.y, z = point.z,
            tier = spec.tier, sprite = spec.sprite, mode = spec.mode }
        setPending(facility.id, false)
        return true, existing
    end
    World.RemoveAt(square, facility.id)
    local added, result = World.AddObject(square, facility, spec, point)
    if not added then
        setPending(facility.id, true)
        return false, result
    end
    logInfo("applied facility=" .. tostring(facility.id)
        .. " level=" .. tostring(facility.level)
        .. " tier=" .. tostring(spec.tier)
        .. " sprite=" .. tostring(spec.sprite)
        .. " point=" .. tostring(point.x) .. "," .. tostring(point.y)
        .. "," .. tostring(point.z))
    facility.stockpileVisual = { x = point.x, y = point.y, z = point.z,
        tier = spec.tier, sprite = spec.sprite, mode = spec.mode }
    Repository.MarkDirty()
    setPending(facility.id, false)
    return true, result
end

function Service.Remove(facility)
    if not facility then return false, "FACILITY_NOT_FOUND" end
    local points = {}
    if facility.stockpileVisual then points[#points + 1] = facility.stockpileVisual end
    local target = stockpilePoint(facility)
    if target and not samePoint(target, points[1]) then points[#points + 1] = target end
    local removed = true
    for _, point in ipairs(points) do
        local square = World.SquareAt(point)
        if square and not World.RemoveAt(square, facility.id) then removed = false end
    end
    facility.stockpileVisual = nil
    setPending(facility.id, false)
    unindexFacilityPoint(facility.id)
    if removed then Repository.MarkDirty() end
    return removed
end

function Service.Reconcile()
    if Repository.Load then Repository.Load() end
    PointIndex = {}
    FacilityPointKeys = {}
    FacilityPoints = {}
    Service.PointIndex = PointIndex
    Service.FacilityPointKeys = FacilityPointKeys
    Service.FacilityPoints = FacilityPoints
    local total, built, applied, failed = 0, 0, 0, 0
    for _, facility in pairs(Repository.State and Repository.State.facilities or {}) do
        if isStockpile(facility) then
            total = total + 1
            if isBuilt(facility) then
                built = built + 1
                local ok, reason = Service.Apply(facility)
                if ok then
                    applied = applied + 1
                else
                    failed = failed + 1
                    logWarn("apply_failed facility=" .. tostring(facility.id)
                        .. " level=" .. tostring(facility.level)
                        .. " state=" .. tostring(facility.constructionState)
                        .. " reason=" .. tostring(reason))
                end
            end
        end
    end
    Service.StartupReconciled = true
    logInfo("reconcile facilities=" .. tostring(total)
        .. " built=" .. tostring(built)
        .. " applied=" .. tostring(applied)
        .. " failed=" .. tostring(failed))
end

function Service.RepairLoadedSquare(square)
    if Repository.Loaded ~= true or not Service.StartupReconciled then
        return false
    end
    local key = World.SquareKey(square)
    local candidates = key and PointIndex[key] or nil
    if not candidates then return false end
    local repaired = false
    for facilityId in pairs(candidates) do
        local facility = Repository.GetFacility(facilityId)
        if facility and isStockpile(facility) and isBuilt(facility) then
            local ok = Service.Apply(facility, nil, square,
                FacilityPoints[tostring(facilityId)])
            if ok then
                repaired = true
            else
                deferPending(facilityId)
            end
        else
            setPending(facilityId, false)
            unindexFacilityPoint(facilityId)
        end
    end
    return repaired
end

local function retryPending()
    if Repository.Loaded ~= true then return end
    if not Service.StartupReconciled then
        Service.Reconcile()
        return
    end
    if not pendingRetryDue() then return end
    for facilityId in pairs(Pending) do
        local facility = Repository.GetFacility(facilityId)
        if facility and isStockpile(facility) and isBuilt(facility) then
            local ok = Service.Apply(facility, nil, nil,
                FacilityPoints[tostring(facilityId)])
            if not ok then
                deferPending(facilityId)
            end
        else
            setPending(facilityId, false)
            unindexFacilityPoint(facilityId)
        end
    end
    if pendingCount > 0 then
        local now = nowMs()
        nextRetryAt = now > 0 and now + PENDING_RETRY_MS or 0
    end
    Service.NextRetryAt = nextRetryAt
end

local function markVisualRemoved(object)
    local facilityId = World.OwnedFacilityId(object)
    if facilityId then setPending(facilityId, true) end
end

if Events and Events.OnInitGlobalModData and not Service.InitHookRegistered then
    Events.OnInitGlobalModData.Add(function() Service.Reconcile() end)
    Service.InitHookRegistered = true
end
if Events and Events.OnGameStart and not Service.StartHookRegistered then
    Events.OnGameStart.Add(function() Service.Reconcile() end)
    Service.StartHookRegistered = true
end
if Events and Events.LoadGridsquare and not Service.LoadSquareHookRegistered then
    Events.LoadGridsquare.Add(Service.RepairLoadedSquare)
    Service.LoadSquareHookRegistered = true
end
if Events and Events.OnObjectAboutToBeRemoved
    and not Service.ObjectRemoveHookRegistered
then
    Events.OnObjectAboutToBeRemoved.Add(markVisualRemoved)
    Service.ObjectRemoveHookRegistered = true
end
if Events and Events.OnTick and not Service.TickHookRegistered then
    Events.OnTick.Add(retryPending)
    Service.TickHookRegistered = true
end

return Service
