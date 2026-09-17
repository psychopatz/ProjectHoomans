-- Object labels, detail rows, and hover tooltip rows for perception debug.
PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}

local Model = PNC.PerceptionDebug.Model or {}
PNC.PerceptionDebug.Model = Model
local Internal = Model.Internal
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_ModelInternal"

local text = Internal.Text
local listText = Internal.ListText
local yesNo = Internal.YesNo
local addLine = Internal.AddLine

function Model.ObjectLabel(object, settings)
    settings = type(settings) == "table" and settings or {}
    local facts = object and object.facts or {}
    local parts = {}
    if settings.showObjectNames ~= false then
        local native = facts.nativeName or facts.displayName or facts.objectName
        if native and native ~= "" then parts[#parts + 1] = text(native) end
    end
    if settings.showSemanticNames ~= false then
        local semantic = facts.semanticName or facts.commandName
        if semantic and semantic ~= "" then
            parts[#parts + 1] = "[" .. text(semantic) .. "]"
        end
    end
    if settings.showUsage == true and type(facts.usage) == "table"
        and #facts.usage > 0
    then
        parts[#parts + 1] = "{" .. listText(facts.usage) .. "}"
    end
    if settings.showJobs == true and type(facts.jobs) == "table"
        and #facts.jobs > 0
    then
        parts[#parts + 1] = "<" .. listText(facts.jobs) .. ">"
    end
    if #parts == 0 then return nil end
    return table.concat(parts, " ")
end

function Model.ObjectRows(snapshot, settings)
    local rows = {}
    settings = type(settings) == "table" and settings or {}
    for index = 1, #(snapshot and snapshot.objects or {}) do
        local object = snapshot.objects[index]
        local facts = object.facts or {}
        if settings.showUnknownObjects == true
            or facts.semanticName
            or facts.validSitting == true
            or facts.validSleeping == true
            or facts.waterDetected == true
            or facts.isCampfire == true
            or facts.indoor == true
        then
            rows[#rows + 1] = {
                id = object.objectKey or object.targetID or index,
                label = Model.ObjectLabel(object, settings)
                    or Internal.Translate(
                        "UI_PNC_PerceptionDebug_Value_WorldObject",
                        "world object"),
                object = object,
                detail = listText(facts.usage,
                    listText(facts.semanticKinds, "unclassified")),
            }
        end
    end
    table.sort(rows, function(left, right)
        return text(left.id) < text(right.id)
    end)
    return rows
end

function Model.DetailRows(object, settings)
    local rows = {}
    settings = type(settings) == "table" and settings or {}
    if not object then
        addLine(rows, "selection", Internal.Translate(
            "UI_PNC_PerceptionDebug_Value_SelectObject",
            "Hover or select an observed object"), "muted")
        return rows
    end
    local facts = object.facts or {}
    local metadata = object.metadata or {}
    addLine(rows, "native name", facts.nativeName or "unknown")
    addLine(rows, "NPC command name", facts.semanticName
        or facts.commandName or "none", facts.semanticName and "success" or "warning")
    addLine(rows, "semantic kinds", listText(facts.semanticKinds))
    addLine(rows, "object / sprite", text(metadata.objectName or "-")
        .. " / " .. text(metadata.spriteName or "-"))
    addLine(rows, "usage", listText(facts.usage))
    addLine(rows, "valid sitting object", yesNo(facts.validSitting),
        facts.validSitting and "success" or "muted")
    if facts.validSitting then
        addLine(rows, "sitting seats", facts.sittingCount or "unknown")
        addLine(rows, "sitting validation", facts.sittingValidation or "unknown")
    end
    addLine(rows, "valid sleeping object", yesNo(facts.validSleeping),
        facts.validSleeping and "success" or "muted")
    if facts.validSleeping then
        addLine(rows, "sleep surface", facts.sleepingSurface or "unknown")
    end
    if facts.waterDetected then
        addLine(rows, "water state", facts.waterState or "UNKNOWN",
            facts.waterState == "ACTIVE" and "success"
                or facts.waterState == "DEPLETED" and "warning" or "danger")
        addLine(rows, "water amount", facts.waterAmount or "unknown")
        addLine(rows, "drink / fill", yesNo(facts.validDrinking) .. " / "
            .. yesNo(facts.validWaterFill))
    end
    addLine(rows, "jobs / capabilities", listText(facts.jobs,
        listText(facts.capabilities)))
    local room = facts.room or {}
    if facts.indoor then
        addLine(rows, "room", facts.roomLabel or "room", "success")
        addLine(rows, "room type", room.roomType or "unclassified")
        addLine(rows, "room identity", text(room.buildingID or "-")
            .. " / " .. text(room.roomID or "-"))
    end
    if facts.validCampZone then
        if facts.isCampfire then
            addLine(rows, "camp zone", Internal.Format(
                "UI_PNC_PerceptionDebug_Value_ValidCampZone",
                "VALID / radius %1", facts.campfireRadius or 16), "success")
        else
            addLine(rows, "camp zone", Internal.Format(
                "UI_PNC_PerceptionDebug_Value_ValidRoomCampZone",
                "VALID / room %1",
                Internal.DisplayValue(facts.roomLabel or "room")), "success")
        end
    end
    addLine(rows, "position", string.format("%.2f, %.2f, %.0f",
        tonumber(object.x) or 0, tonumber(object.y) or 0,
        tonumber(object.z) or 0))
    addLine(rows, "object key", object.objectKey or object.targetID or "-")
    addLine(rows, "resource key", object.resourceKey or "-")
    if type(facts.diagnostics) == "table" and #facts.diagnostics > 0 then
        addLine(rows, "diagnostics", listText(facts.diagnostics), "warning")
    end
    return rows
end

function Model.TooltipLines(object, settings)
    settings = type(settings) == "table" and settings or {}
    local lines = {}
    if not object then return lines end
    local facts = object.facts or {}
    local label = Model.ObjectLabel(object, settings)
        or Internal.Translate("UI_PNC_PerceptionDebug_Value_WorldObject",
            "world object")
    lines[#lines + 1] = label
    if settings.showObjectNames ~= false then
        lines[#lines + 1] = Internal.Format(
            "UI_PNC_PerceptionDebug_Tooltip_Native", "native: %1",
            text(facts.nativeName or "unknown"))
    end
    if settings.showSemanticNames ~= false then
        lines[#lines + 1] = Internal.Format(
            "UI_PNC_PerceptionDebug_Tooltip_NPCName", "NPC name: %1",
            text(facts.semanticName or facts.commandName or "none"))
    end
    if settings.showUsage ~= false then
        lines[#lines + 1] = Internal.Format(
            "UI_PNC_PerceptionDebug_Tooltip_Usage", "usage: %1",
            listText(facts.usage))
    end
    if settings.showJobs ~= false then
        lines[#lines + 1] = Internal.Format(
            "UI_PNC_PerceptionDebug_Tooltip_Jobs", "jobs: %1",
            listText(facts.jobs, listText(facts.capabilities)))
    end
    if facts.waterDetected then
        lines[#lines + 1] = Internal.Format(
            "UI_PNC_PerceptionDebug_Tooltip_Water", "water: %1",
            text(facts.waterState or "UNKNOWN"))
    end
    if facts.indoor then
        lines[#lines + 1] = Internal.Format(
            "UI_PNC_PerceptionDebug_Tooltip_Room", "room: %1",
            text(facts.roomLabel or "room"))
    end
    if facts.validSitting then
        lines[#lines + 1] = Internal.Translate(
            "UI_PNC_PerceptionDebug_Tooltip_ValidSitting",
            "valid sitting object")
    end
    if facts.validSleeping then
        lines[#lines + 1] = Internal.Format(
            "UI_PNC_PerceptionDebug_Tooltip_ValidSleeping",
            "valid sleeping object: %1",
            Internal.DisplayValue(facts.sleepingSurface or "surface"))
    end
    if facts.validCampZone then
        if facts.isCampfire then
            lines[#lines + 1] = Internal.Format(
                "UI_PNC_PerceptionDebug_Tooltip_ValidCampZone",
                "valid camp zone: radius %1", facts.campfireRadius or 16)
        else
            lines[#lines + 1] = Internal.Format(
                "UI_PNC_PerceptionDebug_Tooltip_ValidRoomCampZone",
                "valid camp zone: room %1",
                Internal.DisplayValue(facts.roomLabel or "room"))
        end
    end
    lines[#lines + 1] = Internal.Format(
        "UI_PNC_PerceptionDebug_Tooltip_Position",
        "position: %.2f, %.2f, %.0f", tonumber(object.x) or 0,
        tonumber(object.y) or 0, tonumber(object.z) or 0)
    return lines
end

return Model
