if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CorpseHaulService = PNC.CorpseHaulService or {}
PNC.CorpseHaulService.Internal = PNC.CorpseHaulService.Internal or {}

local Service = PNC.CorpseHaulService
local Internal = Service.Internal

local Core = PNC.Core
local Lifecycle = PNC.BodyLifecycle
local CORPSE_HAUL_SCHEMA_VERSION = 1
local squareAt = Internal.squareAt
local forEachRegionTile = Internal.forEachRegionTile
local transmit = Internal.transmit
local clearCorpseHaulToken = Internal.clearCorpseHaulToken

function Service.EnsureCorpseHaulMarker(corpse, create)
    local data = corpse and corpse.getModData and corpse:getModData() or nil
    local hasMarker
    if not data then return nil, false end
    hasMarker = data.PNC_CorpseHaulVersion ~= nil
        or data.PNC_CorpseHaulToken ~= nil
        or data.PNC_CorpseHaulTaskId ~= nil
        or data.PNC_CorpseHaulCarriedBy ~= nil
    if hasMarker and tonumber(data.PNC_CorpseHaulVersion)
        ~= CORPSE_HAUL_SCHEMA_VERSION
    then
        data.PNC_CorpseHaulVersion = nil
        data.PNC_CorpseHaulToken = nil
        data.PNC_CorpseHaulTaskId = nil
        data.PNC_CorpseHaulCarriedBy = nil
        transmit(corpse)
        return data, true, "invalid_state"
    end
    if create == true then
        data.PNC_CorpseHaulVersion = CORPSE_HAUL_SCHEMA_VERSION
    end
    return data, false
end

function Service.GetCorpseToken(corpse, create)
    local data = Service.EnsureCorpseHaulMarker(corpse, create)
    local token
    if not data then return nil end
    token = data.PNC_CorpseHaulToken
    if token ~= nil and tostring(token) ~= "" then return tostring(token) end
    if create ~= true then return nil end
    token = Core.GenerateID("corpse_haul")
    data.PNC_CorpseHaulToken = token
    transmit(corpse)
    return token
end

function Service.IsEligibleCorpse(corpse)
    local item = corpse and corpse.getItem and corpse:getItem() or nil
    local fullType = item and item.getFullType and tostring(item:getFullType() or "") or ""
    if not corpse then return false end
    if corpse.isAnimal and corpse:isAnimal() == true then return false end
    if fullType == "Base.CorpseAnimal" then return false end
    -- forEachCorpse already restricts this object to the engine's corpse
    -- collection. The home-service check belongs to worker authorization, not
    -- corpse ownership: ordinary vanilla human corpses are valid haul targets.
    return true
end

function Service.GetCorpseAt(x, y, z, token, deathMarkerId)
    local square = squareAt(x, y, z)
    local found
    if not square or not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.forEachCorpse
    then return nil end
    Lifecycle.Internal.forEachCorpse(square, function(corpse)
        local candidateToken = Service.GetCorpseToken(corpse, false)
        local data = corpse and corpse.getModData
            and corpse:getModData() or nil
        local candidateMarker = data and (data.PNC_DeathMarkerID
            or data.PNC_UUID) or nil
        local tokenMatches = token == nil
            or tostring(candidateToken or "") == tostring(token)
        -- The haul token is authoritative for ordinary vanilla corpses. A
        -- lifecycle marker is an additional identity check when present, but
        -- older/untracked bodies may legitimately have no marker at all.
        local markerMatches = deathMarkerId == nil or candidateMarker == nil
            or tostring(candidateMarker or "") == tostring(deathMarkerId)
        if not found and Service.IsEligibleCorpse(corpse)
            and tokenMatches and markerMatches
        then
            found = corpse
        end
    end)
    return found
end

function Service.CountCorpsesInRegion(region)
    local total = 0
    local eligible = 0
    local cell = getCell and getCell() or nil
    if not cell or not cell.getGridSquare
        or not Lifecycle or not Lifecycle.Internal
        or not Lifecycle.Internal.forEachCorpse
    then
        return nil, nil
    end
    forEachRegionTile(region, function(x, y, z)
        local square = squareAt(x, y, z)
        if square then
            Lifecycle.Internal.forEachCorpse(square, function(corpse)
                total = total + 1
                if Service.IsEligibleCorpse(corpse) then
                    eligible = eligible + 1
                end
            end)
        end
    end)
    return total, eligible
end

function Service.GetSourceCorpseCounts(baseOrId)
    local base = type(baseOrId) == "table" and baseOrId
        or PNC.BaseService and PNC.BaseService.Get
            and PNC.BaseService.Get(baseOrId) or nil
    local configuration = Internal.configurationFor(base)
    local baseId = tostring(base and base.id or "")
    local now = Core.Now()
    local cached = Service.Runtime.countsByBase[baseId]
    local total
    local eligible
    if not configuration or not configuration.sourceRegion then
        return nil, nil
    end
    if cached and cached.revision == configuration.revision
        and now < cached.updatedAt + Service.CORPSE_COUNT_CACHE_MS
    then
        return cached.total, cached.eligible
    end
    total, eligible = Service.CountCorpsesInRegion(
        configuration.sourceRegion)
    Service.Runtime.countsByBase[baseId] = {
        revision = configuration.revision,
        total = total, eligible = eligible, updatedAt = now,
    }
    return total, eligible
end


return Service
