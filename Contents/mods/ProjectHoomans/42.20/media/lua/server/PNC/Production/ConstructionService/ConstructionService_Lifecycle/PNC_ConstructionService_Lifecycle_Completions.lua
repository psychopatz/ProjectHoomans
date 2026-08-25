if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ConstructionService = PNC.ConstructionService or {}
PNC.ConstructionService.Internal =
    PNC.ConstructionService.Internal or {}

local Service = PNC.ConstructionService
local Internal = Service.Internal
Internal.LifecycleInternal = Internal.LifecycleInternal or {}
local H = Internal.LifecycleInternal

local function workstationSprite(definition, placement)
    local sprite = placement and placement.sprite or definition and definition.sprite
    if sprite and tostring(sprite) ~= "" then return tostring(sprite) end
    local manager = SpriteConfigManager
    if manager and type(manager.GetObjectInfo) == "function"
        and definition and definition.entityScript
    then
        local ok, info = pcall(manager.GetObjectInfo,
            definition.entityScript)
        if ok and info and type(info.getMainSpriteNameUI) == "function" then
            local spriteOk, value = pcall(info.getMainSpriteNameUI, info)
            if spriteOk and value and tostring(value) ~= "" then
                return tostring(value)
            end
        end
    end
    return nil
end

local function placeDirectWorkstation(facility)
    local placement = facility and facility.workstationPlacement or nil
    if not placement or placement.placed == true then return true end
    local definition = PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.Get
        and PNC.FacilityDefinitions.Get(facility.definitionId) or nil
    local script = placement.entityScript
        or definition and definition.entityScript
    if not script then return false, "WORKSTATION_ENTITY_SCRIPT_MISSING" end
    if type(getCell) ~= "function" then
        return false, "WORKSTATION_WORLD_UNAVAILABLE"
    end
    local cellOk, cell = pcall(getCell)
    local square = cellOk and cell and cell.getGridSquare
        and cell:getGridSquare(tonumber(placement.x) or 0,
            tonumber(placement.y) or 0, tonumber(placement.z) or 0) or nil
    if not square or type(square.addWorkstationEntity) ~= "function" then
        return false, "WORKSTATION_WORLD_UNAVAILABLE"
    end
    local sprite = workstationSprite(definition, placement)
    if not sprite then return false, "WORKSTATION_SPRITE_UNAVAILABLE" end
    local ok, entity = pcall(square.addWorkstationEntity, square, script, sprite)
    if not ok or not entity then
        return false, "WORKSTATION_WORLD_PLACEMENT_FAILED"
    end
    placement.placed = true
    placement.sprite = sprite
    placement.entityScript = script
    PNC.SettlementRepository.MarkDirty()
    return true
end

H.PlaceDirectWorkstation = placeDirectWorkstation

function H.CompleteBuild(order)
    local ok, reason = PNC.WorkInputService.Commit(order,
        "construction_material_consumption")
    if not ok then return false, reason end
    local facility = PNC.SettlementRepository.GetFacility(
        order.payload and order.payload.facilityId)
    if not facility then return false, "FACILITY_NOT_FOUND" end
    local definition = PNC.FacilityDefinitions
        and PNC.FacilityDefinitions.Get
        and PNC.FacilityDefinitions.Get(facility.definitionId) or nil
    if definition and definition.directWorkstation == true then
        local placed, placementReason = placeDirectWorkstation(facility)
        if not placed then return false, placementReason end
    end
    facility.constructionState = "BUILT"
    facility.constructionWorkOrderId = nil
    PNC.FacilityService.RefreshState(facility)
    return true
end

function H.CompleteDeconstruct(order)
    return PNC.FacilityService.FinalizeDestroy(
        order.payload and order.payload.facilityId)
end

function H.CompleteReconstruct(order)
    local payload = order.payload or {}
    local change = payload.change or {}
    if change.action ~= "remove" then
        local ok, reason = PNC.WorkInputService.Commit(order,
            "component_construction_material_consumption")
        if not ok then return false, reason end
    end
    if change.action == "remove" then
        local ok, reason = PNC.FacilityService.FinalizeRemoveComponent(
            payload.facilityId, change.componentId)
        if not ok then return false, reason end
        local products = {}
        for _, cost in ipairs(payload.refundRequirements or {}) do
            local quantity = math.floor((tonumber(cost.amount) or 0)
                * (tonumber(payload.refundPercent) or 0) / 100 + 0.5)
            if quantity > 0 then products[#products + 1] = {
                fullType = cost.fullType, quantity = quantity } end
        end
        if #products > 0 then
            local refunded, refundReason =
                PNC.ColonyStorageService.DepositProductionItems(
                    payload.storageId, products, nil, order.id,
                    "component_deconstruction_refund")
            if not refunded then return false, refundReason end
        end
        return true, "ComponentRemoved"
    end
    if change.action == "replace_role" then
        return PNC.FacilityService.FinalizeReplaceAnchorRole(
            payload.facilityId, change.role, change.anchors)
    end
    if change.action == "upgrade" then
        local facility = PNC.SettlementRepository.GetFacility(payload.facilityId)
        local ok, reason = PNC.FacilityService.FinalizeUpgrade(
            payload.facilityId, change.targetLevel)
        if not ok then return false, reason end
        if facility and facility.definitionId == "stockpile"
            and PNC.ColonyStorageService.SetTierForSettlement
        then
            local upgraded, storageReason =
                PNC.ColonyStorageService.SetTierForSettlement(
                    order.colonyId, change.targetLevel)
            if not upgraded then return false, storageReason end
        end
        return true, reason
    end
    return PNC.FacilityService.FinalizeSetComponent(
        payload.facilityId, change.component)
end

return Service
