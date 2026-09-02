if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local CORPSE_HAUL_ZONES_OVERLAP = "CORPSE_HAUL_ZONES_OVERLAP"

local function configuredRegion(region)
    if type(region) ~= "table" or not GridRegion.normalize
        or not GridRegion.countTiles
    then return nil end
    local normalized = GridRegion.normalize(region)
    return GridRegion.countTiles(normalized) > 0 and normalized or nil
end

local function configurationFor(base)
    local raw = base and base.corpseHaul
    if type(raw) ~= "table" then return nil end
    return {
        sourceRegion = configuredRegion(raw.sourceRegion),
        destinationRegion = configuredRegion(raw.destinationRegion),
        revision = tonumber(raw.revision) or 0,
    }
end

function Service.GetConfiguration(baseOrId)
    local base = type(baseOrId) == "table" and baseOrId
        or PNC.BaseService and PNC.BaseService.Get
            and PNC.BaseService.Get(baseOrId) or nil
    local configuration = configurationFor(base)
    if not configuration then return nil end
    return PNC.Core and PNC.Core.DeepCopy
        and PNC.Core.DeepCopy(configuration) or configuration
end

local function validateConfiguredRegion(region)
    if not GridRegion.validate or not GridRegion.countTiles then
        return nil, "REGION_VALIDATION_UNAVAILABLE"
    end
    local valid, reason, normalized = GridRegion.validate(region)
    if not valid then return nil, reason end
    local tileCount = GridRegion.countTiles(normalized)
    if tileCount > Service.MAX_CONFIGURED_REGION_TILES then
        return nil, "REGION_CAPACITY_EXCEEDED"
    end
    if GridRegion.isConnected and not GridRegion.isConnected(normalized, 4) then
        return nil, "REGION_DISCONNECTED"
    end
    return normalized
end

function Service.SetConfiguration(player, args)
    args = type(args) == "table" and args or {}
    local base = PNC.BaseService and PNC.BaseService.Get
        and PNC.BaseService.Get(args.baseId) or nil
    local permissions = PNC.BaseValidationService
    local source, destination
    local reason
    if not base then return false, "BASE_NOT_FOUND" end
    if not permissions or not permissions.CanUse
        or permissions.CanUse(player, base) ~= true
    then return false, "NO_PERMISSION" end
    source, reason = validateConfiguredRegion(args.sourceRegion)
    if not source then return false, reason end
    destination, reason = validateConfiguredRegion(args.destinationRegion)
    if not destination then return false, reason end
    if type(GridRegion.intersects) ~= "function" then
        return false, "REGION_VALIDATION_UNAVAILABLE"
    end
    if GridRegion.intersects(source, destination) then
        return false, CORPSE_HAUL_ZONES_OVERLAP
    end
    base.corpseHaul = {
        schemaVersion = 1,
        sourceRegion = source,
        destinationRegion = destination,
        revision = (tonumber(base.corpseHaul and base.corpseHaul.revision) or 0) + 1,
    }
    Service.Runtime.countsByBase[tostring(base.id)] = nil
    base.revision = (tonumber(base.revision) or 0) + 1
    if PNC.SettlementRepository and PNC.SettlementRepository.MarkDirty then
        PNC.SettlementRepository.MarkDirty()
    end
    if PNC.SettlementRepository and PNC.SettlementRepository.Save then
        PNC.SettlementRepository.Save()
    end
    return true, "CORPSE_HAUL_ZONES_SAVED", {
        baseId = base.id,
        corpseHaul = Service.GetConfiguration(base),
    }
end

function Service.ClearConfiguration(player, args)
    args = type(args) == "table" and args or {}
    local base = PNC.BaseService and PNC.BaseService.Get
        and PNC.BaseService.Get(args.baseId) or nil
    local permissions = PNC.BaseValidationService
    if not base then return false, "BASE_NOT_FOUND" end
    if not permissions or not permissions.CanUse
        or permissions.CanUse(player, base) ~= true
    then return false, "NO_PERMISSION" end
    if not base.corpseHaul then
        return false, "CORPSE_HAUL_NOT_CONFIGURED"
    end
    base.corpseHaul = nil
    Service.Runtime.countsByBase[tostring(base.id)] = nil
    base.revision = (tonumber(base.revision) or 0) + 1
    if PNC.SettlementRepository and PNC.SettlementRepository.MarkDirty then
        PNC.SettlementRepository.MarkDirty()
    end
    if PNC.SettlementRepository and PNC.SettlementRepository.Save then
        PNC.SettlementRepository.Save()
    end
    return true, "CORPSE_HAUL_ZONES_CLEARED", { baseId = base.id }
end

Internal.configurationFor = configurationFor

return Service
