-- Aggregate snapshot and camp-policy rows for perception debug.
PNC = PNC or {}
PNC.PerceptionDebug = PNC.PerceptionDebug or {}

local Model = PNC.PerceptionDebug.Model or {}
PNC.PerceptionDebug.Model = Model
local Internal = Model.Internal
    or require "PNC/UI/PerceptionDebug/PNC_PerceptionDebug_ModelInternal"

local text = Internal.Text
local listText = Internal.ListText
local addLine = Internal.AddLine

local function resultTone(status)
    status = string.upper(tostring(status or ""))
    if status == "ACCEPTED" then return "success" end
    if status == "REJECTED" then return "danger" end
    if status == "PENDING" then return "warning" end
    return "muted"
end

local function addCampResult(rows, label, result)
    local hint
    local details
    if type(result) ~= "table" then return end
    addLine(rows, label, result.status or "UNKNOWN",
        resultTone(result.status))
    addLine(rows, "result reason", result.reason or "none",
        result.status == "REJECTED" and "danger" or "muted")
    if result.requestID then
        addLine(rows, "request ID", result.requestID)
    end
    hint = result.hint
    if type(hint) == "table" then
        addLine(rows, "hint source", hint.source or "none")
        addLine(rows, "hint scope", hint.scope or result.scope or "none")
        addLine(rows, "hint label", hint.label or hint.roomType or "none")
        addLine(rows, "hint site / campfire ID",
            hint.siteID or hint.campfireID or "none")
    end
    details = result.details
    if type(details) == "table" then
        addLine(rows, "authority route", details.route or "none")
        addLine(rows, "placement mode", details.placementMode or "none")
        addLine(rows, "placement state",
            details.placementState or "none")
        addLine(rows, "accepted / inspected",
            tostring(details.acceptedCount or 0) .. " / "
                .. tostring(details.targetCount or 0))
        if details.activeNPCID then
            addLine(rows, "active mover", details.activeNPCID)
        end
        if type(details.site) == "table" then
            addLine(rows, "authority site",
                details.site.label or details.site.roomType
                    or details.site.scope or "none")
        end
        if type(details.targets) == "table" then
            for index = 1, math.min(#details.targets, 32) do
                local target = details.targets[index]
                if type(target) == "table" and target.npcID then
                    addLine(rows, "target " .. tostring(target.npcID),
                        tostring(target.state or "unknown") .. " / "
                            .. tostring(target.reason or "none"))
                end
            end
        end
    end
end

function Model.Summary(snapshot)
    snapshot = snapshot or {}
    local sitting = 0
    local sleeping = 0
    local activeWater = 0
    local water = 0
    local camps = 0
    local rooms = 0
    for index = 1, #(snapshot.objects or {}) do
        local facts = snapshot.objects[index].facts or {}
        if facts.validSitting then sitting = sitting + 1 end
        if facts.validSleeping then sleeping = sleeping + 1 end
        if facts.waterDetected then
            water = water + 1
            if facts.waterState == "ACTIVE" then activeWater = activeWater + 1 end
        end
        if facts.isCampfire then camps = camps + 1 end
        if facts.indoor then rooms = rooms + 1 end
    end
    for index = 1, #(snapshot.zones or {}) do
        if snapshot.zones[index].kind == "room" then rooms = rooms + 1 end
    end
    local scan = snapshot.diagnostics and snapshot.diagnostics.scan or {}
    return {
        status = Internal.DisplayValue(snapshot.status or "UNAVAILABLE"),
        reason = text(snapshot.reason or ""),
        objects = #(snapshot.objects or {}),
        sitting = sitting,
        sleeping = sleeping,
        water = water,
        activeWater = activeWater,
        camps = camps,
        rooms = rooms,
        inspected = tonumber(scan.inspectedObjectCount)
            or tonumber(scan.objectCount) or 0,
        candidates = tonumber(scan.objectCount) or 0,
        rejected = tonumber(scan.rejectedObjectCount) or 0,
        truncated = scan.truncated == true,
        serverRequests = snapshot.diagnostics
            and snapshot.diagnostics.serverRequests or 0,
    }
end

function Model.CampPreviewRows(snapshot)
    local rows = {}
    local preview = snapshot and snapshot.campPreview or nil
    local diagnostics = snapshot and snapshot.diagnostics
        and snapshot.diagnostics.campCommand or nil
    if not preview then
        addLine(rows, "camp policy", "room then campfire", "muted")
        addLine(rows, "preview", "unavailable", "warning")
        if type(diagnostics) == "table" then
            addLine(rows, "last camp attempt",
                diagnostics.last and diagnostics.last.status or "none",
                resultTone(diagnostics.last and diagnostics.last.status))
            addCampResult(rows, "client result", diagnostics.client)
            addCampResult(rows, "server result", diagnostics.server)
        end
        return rows
    end
    addLine(rows, "camp policy", preview.policy or "room then campfire")
    addLine(rows, "preview result", preview.status or "UNKNOWN",
        preview.status == "SAFE" and "success"
            or preview.status == "UNSAFE" and "danger" or "warning")
    addLine(rows, "source", preview.source or "none")
    addLine(rows, "scope", preview.scope or "none")
    addLine(rows, "label", preview.label or "none")
    addLine(rows, "room type", preview.roomType or "none")
    addLine(rows, "reason", preview.reason or "none",
        preview.reason and "warning" or "muted")
    addLine(rows, "site / campfire id", preview.siteID or preview.campfireID
        or "none")
    if type(diagnostics) == "table" then
        addLine(rows, "last camp attempt",
            diagnostics.last and diagnostics.last.status or "none",
            resultTone(diagnostics.last and diagnostics.last.status))
        addCampResult(rows, "client result", diagnostics.client)
        addCampResult(rows, "server result", diagnostics.server)
    end
    return rows
end

return Model
