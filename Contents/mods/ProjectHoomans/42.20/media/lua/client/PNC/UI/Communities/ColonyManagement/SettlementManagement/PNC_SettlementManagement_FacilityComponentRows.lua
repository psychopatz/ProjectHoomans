local Rows = {}

local function text(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= key and value or fallback
end

local function roleLabel(role)
    local labels = {
        ["sleep.bed"] = "SLEEPING SPOT",
        ["dining.table"] = "DINING TABLE",
        ["health.bed"] = "HOSPITAL BED",
        ["farm.field"] = "CULTIVATED FIELDS",
        ["work.research"] = "RESEARCH STATION",
        ["work.blueprint"] = "ARCHITECT BENCH",
        ["work.reverse"] = "LAB",
        ["work.craft"] = "CRAFT STATION",
        ["work.disassemble"] = "DISASSEMBLY STATION",
        ["water.spigot"] = "SPIGOT",
        ["water.tank"] = "WATER TANKS",
        ["water.catcher"] = "RAIN CATCHERS",
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
        return policy.DescribeCosts(costs)
    end
    local output = {}
    for _, cost in ipairs(costs or {}) do
        output[#output + 1] = tostring(cost.amount or 1) .. "x "
            .. tostring(cost.fullType or "Base.Money")
    end
    return table.concat(output, ", ")
end

local function componentDetail(facility, component)
    local detail
    if component.kind == "anchor" then
        detail = roleLabel(component.role) .. "  •  "
            .. tostring(component.x) .. ", " .. tostring(component.y)
            .. "  FLOOR " .. tostring(component.z)
    elseif component.kind == "abstract" then
        detail = "ABSTRACT UTILITY MODULE"
    else
        detail = tostring(component.tileCount or 0) .. " TILES  •  ZONED AREA"
    end
    local recipe = costText(facility, component.role)
    return recipe and recipe ~= "" and detail .. "  •  " .. recipe or detail
end

function Rows.Build(facility)
    local rows = {}
    local level = PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level)
    local roles = {}
    for role, _ in pairs(level and level.componentLimits or {}) do
        roles[#roles + 1] = role
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
        local componentAction = #assigned < maximum and {
            kind = limit.kind, role = role,
        } or nil
        local recipe = costText(facility, role)
        local detail = tostring(#assigned) .. " / " .. tostring(maximum)
        if recipe then detail = detail .. "  •  " .. recipe end
        rows[#rows + 1] = {
            key = role,
            label = roleLabel(role),
            iconPath = componentIconPath(role),
            detail = detail .. (#pending > 0 and "  BUILDING"
                or #assigned >= minimum and "  READY" or "  REQUIRED"),
            complete = #assigned >= minimum and #pending == 0,
            componentAction = #pending > 0 and nil or componentAction,
            actionLabel = limit.kind == "abstract"
                and text("UI_PNC_Facility_BuildModule", "BUILD")
                or text("UI_PNC_Facility_AssignInline", "ASSIGN"),
        }
        for index = 1, #assigned do
            local component = assigned[index]
            rows[#rows + 1] = {
                key = component.id,
                label = "- " .. roleLabel(role) .. " #" .. tostring(index),
                iconPath = componentIconPath(role),
                detail = componentDetail(facility, component),
                child = true,
                complete = true,
                componentAction = component.kind == "abstract" and nil or {
                    kind = component.kind, role = role,
                    componentId = component.id,
                },
                secondaryAction = {
                    kind = component.kind, role = role,
                    componentId = component.id, remove = true,
                },
                actionLabel = component.kind == "abstract"
                    and text("UI_PNC_Task_Deconstruct", "DECONSTRUCT")
                    or text("UI_PNC_Facility_EditInline", "MANAGE"),
                secondaryActionLabel = text(
                    "UI_PNC_Task_Deconstruct", "DECONSTRUCT"),
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
    return rows
end

return Rows
