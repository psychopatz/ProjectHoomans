local Rows = {}

local function text(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= key and value or fallback
end

local function roleLabel(role)
    local labels = {
        ["sleep.bed"] = "BED",
        ["dining.table"] = "DINING TABLE",
        ["health.bed"] = "HOSPITAL BED",
        ["growing.plot"] = "GROWING PLOT",
        ["work.research"] = "RESEARCH TABLE",
        ["work.blueprint"] = "RESEARCH TABLE",
        ["work.reverse"] = "RESEARCH TABLE",
        ["work.craft"] = "CRAFT STATION",
        ["work.disassemble"] = "DISASSEMBLY STATION",
        ["work.zone"] = "WORK AREA",
        ["water.spigot"] = "SPIGOT",
        ["water.tank"] = "WATER TANKS",
        ["water.catcher"] = "RAIN CATCHERS",
        ["storage.stockpile"] = text(
            "UI_PNC_Stockpile_Area", "STOCKPILE AREA"),
    }
    return labels[role] or string.upper(string.gsub(role, "[%.]", " "))
end

local function componentIconPath(role)
    local definitions = PNC and PNC.FacilityDefinitions or nil
    return definitions and definitions.GetComponentIconPath
        and definitions.GetComponentIconPath(role) or nil
end

local function costText(facility, role)
    local definitions = PNC and PNC.FacilityDefinitions or nil
    if not definitions or not definitions.GetComponentCosts then return nil end
    local costs = definitions.GetComponentCosts(
        facility.definitionId, facility.level, role)
    local policy = PNC.FacilityComponentPolicy
    if policy and policy.DescribeCosts then
        local description = policy.DescribeCosts(costs)
        return description ~= "" and description or nil
    end
    local output = {}
    for _, cost in ipairs(costs or {}) do
        output[#output + 1] = tostring(cost.amount or 1) .. "x "
            .. tostring(cost.fullType or "Base.Money")
    end
    return #output > 0 and table.concat(output, ", ") or nil
end

local function componentDetail(facility, component)
    local detail
    if component.kind == "discovered" then
        detail = roleLabel(component.role) .. " | "
            .. tostring(component.x or "?") .. ", "
            .. tostring(component.y or "?")
        if component.available == false then
            detail = detail .. " | " .. text(
                "UI_PNC_Facility_ResourceUnavailable", "UNAVAILABLE")
        else
            detail = detail .. " | " .. text(
                "UI_PNC_Facility_ResourceAvailable", "AVAILABLE")
        end
    elseif component.kind == "anchor" then
        detail = roleLabel(component.role) .. " | "
            .. tostring(component.x) .. ", " .. tostring(component.y)
            .. " | FLOOR " .. tostring(component.z)
    elseif component.kind == "abstract" then
        detail = "ABSTRACT UTILITY MODULE"
    else
        detail = tostring(component.width or "?") .. " x "
            .. tostring(component.height or "?") .. " | "
            .. tostring(component.tileCount or 0) .. " TILES"
        if component.role == "growing.plot" and component.desiredCrop then
            local crop = PNC.FarmingCatalog and PNC.FarmingCatalog.Get
                and PNC.FarmingCatalog.Get(component.desiredCrop) or nil
            detail = detail .. " | CROP " .. tostring(crop
                and crop.displayName or component.desiredCrop)
        elseif component.role == "growing.plot" then
            detail = detail .. " | NO CROP ASSIGNED"
        end
        if component.status then detail = detail .. " | " .. component.status end
    end
    local recipe = costText(facility, component.role)
    return recipe and recipe ~= "" and detail .. " | " .. recipe or detail
end

local function stockpileRows(facility, storage)
    local rows = {}
    local access = storage and storage.access or {}
    local capacity = tonumber(storage and storage.capacity) or 0
    local used = tonumber(storage and storage.usedWeight) or 0
    local free = tonumber(storage and storage.freeWeight)
        or math.max(0, capacity - used)
    local available = storage and storage.storageId
        and access.hasStockpile == true
    local writable = available and access.writable == true
    rows[#rows + 1] = {
        key = "stockpile_capacity",
        label = text("UI_PNC_Storage_Capacity", "TOTAL CAPACITY"),
        iconPath = componentIconPath("storage.stockpile"),
        detail = string.format("%.1f / %.1f | %.1f ", used, capacity, free)
            .. text("UI_PNC_Storage_Free", "FREE")
            .. (writable and " | "
                .. text("UI_PNC_Storage_ManageReady", "MANAGE READY")
                or " | " .. text("UI_PNC_Storage_RemoteView",
                    "REMOTE VIEW")),
        complete = available,
        componentAction = available and { kind = "open_stockpile" } or nil,
        actionLabel = text("UI_PNC_Stockpile_OpenStorage", "OPEN STORAGE"),
    }
    for index = 1, #(facility.components or {}) do
        local component = facility.components[index]
        if component.role == "storage.stockpile" then
            rows[#rows + 1] = {
                key = component.id,
                label = "- " .. roleLabel(component.role),
                iconPath = componentIconPath(component.role),
                detail = componentDetail(facility, component),
                child = true,
                complete = true,
                componentAction = {
                    kind = "stockpile_move",
                    role = component.role,
                    componentId = component.id,
                },
                actionLabel = text("UI_PNC_Facility_Move", "MOVE"),
            }
        end
    end
    for index = 1, #(facility.components or {}) do
        local component = facility.components[index]
        if component.role == "work.zone" then
            rows[#rows + 1] = {
                key = component.id,
                label = "- " .. roleLabel(component.role),
                iconPath = componentIconPath(component.role),
                detail = componentDetail(facility, component),
                child = true,
                complete = true,
                componentAction = {
                    kind = component.kind, role = component.role,
                    componentId = component.id,
                },
                actionLabel = text("UI_PNC_Facility_EditInline", "MANAGE"),
            }
        end
    end
    return rows
end

function Rows.Build(facility, storage)
    if facility.definitionId == "stockpile" then
        return stockpileRows(facility, storage)
    end
    local rows = {}
    local level = PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level)
    local roles = {}
    for role, limit in pairs(level and level.componentLimits or {}) do
        if not limit.legacy then roles[#roles + 1] = role end
    end
    table.sort(roles)
    for roleIndex = 1, #roles do
        local role = roles[roleIndex]
        local limit = level.componentLimits[role]
        local assigned, pending = {}, {}
        for index = 1, #(facility.components or {}) do
            local component = facility.components[index]
            if component.role == role then assigned[#assigned + 1] = component end
        end
        for index = 1, #(facility.pendingComponents or {}) do
            local component = facility.pendingComponents[index]
            if component.role == role then pending[#pending + 1] = component end
        end
        local minimum = tonumber(limit.minCount) or 0
        local maximum = tonumber(limit.maxCount) or math.max(1, minimum)
        local managed = limit.managed == true
        local componentAction = not managed and #assigned < maximum and {
            kind = limit.kind, role = role,
        } or nil
        local recipe = costText(facility, role)
        local detail = tostring(#assigned) .. " / " .. tostring(maximum)
        if recipe then detail = detail .. " | " .. recipe end
        rows[#rows + 1] = {
            key = role,
            label = roleLabel(role),
            iconPath = componentIconPath(role),
            detail = detail .. (#pending > 0 and "  BUILDING"
                or #assigned >= minimum and "  READY" or "  REQUIRED"),
            complete = #assigned >= minimum and #pending == 0,
            componentAction = #pending > 0 and nil or componentAction,
            actionLabel = managed and text("UI_PNC_Facility_BuiltIn",
                "BUILT-IN") or limit.kind == "abstract"
                and text("UI_PNC_Facility_BuildModule", "BUILD")
                or text("UI_PNC_Facility_AssignInline", "ASSIGN"),
        }
        for index = 1, #assigned do
            local component = assigned[index]
            local childAction, childSecondary, childActionLabel
            if not managed then
                if component.kind ~= "abstract" then
                    if role == "growing.plot" then
                        childAction = { kind = "farm_plot_crop", role = role,
                            componentId = component.id }
                    else
                        childAction = { kind = component.kind, role = role,
                            componentId = component.id }
                    end
                end
                childSecondary = role ~= "work.zone" and {
                    kind = component.kind, role = role,
                    componentId = component.id, remove = true } or nil
                childActionLabel = component.kind == "abstract"
                    and text("UI_PNC_Task_Deconstruct", "DECONSTRUCT")
                    or role == "growing.plot" and text(
                        "UI_PNC_Farming_ChangeSeeds", "CHANGE SEEDS")
                    or text("UI_PNC_Facility_EditInline", "MANAGE")
            else
                childActionLabel = text("UI_PNC_Facility_BuiltIn", "BUILT-IN")
            end
            rows[#rows + 1] = {
                key = component.id,
                label = "- " .. roleLabel(role) .. " #" .. tostring(index),
                iconPath = componentIconPath(role),
                detail = componentDetail(facility, component),
                child = true,
                complete = true,
                componentAction = childAction,
                secondaryAction = childSecondary,
                actionLabel = childActionLabel,
                secondaryActionLabel = not managed and role ~= "work.zone" and text(
                    "UI_PNC_Task_Deconstruct", "DECONSTRUCT") or nil,
            }
        end
        for index = 1, #pending do
            local component = pending[index]
            rows[#rows + 1] = {
                key = "pending:" .. tostring(component.id or role),
                label = "- " .. roleLabel(role) .. " #" .. tostring(index)
                    .. " (QUEUED)",
                iconPath = componentIconPath(role),
                detail = componentDetail(facility, component),
                child = true,
                complete = false,
            }
        end
    end
    local profile = facility.roomProfile
    if profile then
        local bedCount = tonumber(profile.bedCount)
            or tonumber(profile.resourceCounts
                and profile.resourceCounts["sleep.bed"]) or 0
        local scanStatus = tostring(profile.scanStatus or "UNKNOWN")
        local scanReady = scanStatus == "READY"
        local configuredCapacity = tonumber(profile.capacityOverride)
        local effectiveCapacity = tonumber(profile.capacity) or bedCount
        local capacityDetail = configuredCapacity
            and tostring(configuredCapacity) .. " "
                .. text("UI_PNC_Facility_Sleepers", "SLEEPERS")
            or text("UI_PNC_Facility_CapacityAutomatic", "AUTO") .. " | "
                .. tostring(effectiveCapacity) .. " "
                .. text("UI_PNC_Facility_Sleepers", "SLEEPERS")
        rows[#rows + 1] = {
            key = "room_capacity",
            label = text("UI_PNC_Facility_Capacity", "CAPACITY"),
            detail = capacityDetail,
            complete = true,
            componentAction = { kind = "set_room_capacity" },
            actionLabel = text("UI_PNC_Facility_SetCapacity", "SET"),
        }
        rows[#rows + 1] = {
            key = "discovered:sleep.bed",
            label = text("UI_PNC_Facility_Beds", "BEDS"),
            iconPath = componentIconPath("sleep.bed"),
            detail = tostring(bedCount) .. " | " .. (scanReady
                and text("UI_PNC_Facility_ResourceScanReady", "SCANNED")
                or scanStatus),
            complete = scanReady,
        }
        local discovered = {}
        for index = 1, #(facility.discoveredComponents or {}) do
            local component = facility.discoveredComponents[index]
            if component.role == "sleep.bed" then
                discovered[#discovered + 1] = component
            end
        end
        for index = 1, #discovered do
            local component = discovered[index]
            rows[#rows + 1] = {
                key = component.resourceKey or "discovered:bed:" .. tostring(index),
                label = "- " .. text("UI_PNC_Facility_Bed", "BED")
                    .. " #" .. tostring(index),
                iconPath = componentIconPath("sleep.bed"),
                detail = componentDetail(facility, component),
                child = true,
                complete = component.available ~= false,
            }
        end
        if bedCount == 0 and scanReady then
            rows[#rows + 1] = {
                key = "discovered:floor",
                label = "- " .. text("UI_PNC_Facility_FloorSleeping",
                    "FLOOR SLEEPING"),
                detail = text("UI_PNC_Facility_FloorSleepingHelp",
                    "No bed detected; sleeping uses the room floor."),
                child = true,
                complete = scanReady,
            }
        end
    end
    return rows
end

return Rows
