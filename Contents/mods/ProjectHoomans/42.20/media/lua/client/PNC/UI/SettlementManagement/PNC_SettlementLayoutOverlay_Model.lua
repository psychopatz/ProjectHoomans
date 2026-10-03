-- Settlement geometry layers and component marker projections.
local Overlay = PNC.SettlementLayoutOverlay
local Internal = Overlay.Internal
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local COLORS = Overlay.ZoneColors
local settlementKey = Internal.settlementKey
local facilityColor = Internal.facilityColor
local facilityZoneColor = Internal.facilityZoneColor
local facilitySourceColor = Internal.facilitySourceColor
local facilityZoneEnabled = Internal.facilityZoneEnabled
local facilityWorkZoneEnabled = Internal.facilityWorkZoneEnabled
local facilityLabel = Internal.facilityLabel
local componentName = Internal.componentName
local isDirectWorkstation = Internal.isDirectWorkstation
local pointRegion = Internal.pointRegion
local workstationApproachPoint = Internal.workstationApproachPoint
local addLayer = Internal.addLayer
local addMarker = Internal.addMarker
local regionCenter = Internal.regionCenter

function Overlay.BuildLayers(settlement, includeBase)
    local layers = {}
    if includeBase ~= false then
        addLayer(layers, settlement and settlement.geometry
            and settlement.geometry.region, COLORS.base, "base",
            settlement and settlement.id)
    end
    for _, facility in ipairs(settlement and settlement.facilities or {}) do
        local sourceColor = facilitySourceColor(facility)
        local color = facilityColor(facility, sourceColor)
        local zoneColor = facilityZoneColor(facility, sourceColor)
        local directWorkstation = isDirectWorkstation(facility)
        local workZoneEnabled = facilityWorkZoneEnabled(facility)
        local hasRegion = false
        if facilityZoneEnabled(facility) and facility.constructionRegion
            and not directWorkstation
        then
            addLayer(layers, facility.constructionRegion, zoneColor,
                "facility_zone", facility.id, "facility.zone",
                "zone:" .. tostring(facility.id), false)
        end
        for _, component in ipairs(facility.components or {}) do
            local workZone = component.role == "work.zone"
            if not workZone or workZoneEnabled then
                if component.kind == "region" then hasRegion = true end
                local approach = workstationApproachPoint(facility, component)
                local region = component.kind == "region" and component.region
                    or component.occupiedRegion
                    or pointRegion(component.x, component.y, component.z)
                local componentColor = workZone and COLORS.workZone
                    or component.kind == "anchor" and COLORS.anchor or color
                local layerKind = workZone and "work_zone"
                    or directWorkstation and component.kind == "anchor"
                    and (approach and "workstation_object" or "workstation")
                    or "facility"
                addLayer(layers, region, componentColor, layerKind,
                    facility.id, component.role, component.id,
                    component.kind == "region" and not workZone)
                if approach then
                    addLayer(layers,
                        pointRegion(approach.x, approach.y, approach.z),
                        COLORS.anchor, "workstation_approach", facility.id,
                        component.role, component.id)
                end
            end
        end
        -- Direct workstations have a one-tile construction footprint only so
        -- collision/revision infrastructure can remain shared. It is not a
        -- room and must not become a room-zone overlay or room marker.
        if not hasRegion and not directWorkstation
            and not facilityZoneEnabled(facility)
        then
            addLayer(layers, facility.constructionRegion, color,
                "facility", facility.id, "facility.footprint",
                "footprint:" .. tostring(facility.id))
        end
    end
    for _, node in ipairs(settlement and settlement.stockpileNodes or {}) do
        addLayer(layers, pointRegion(node.x, node.y, node.z),
            COLORS.stockpile, "stockpile", node.id, "stockpile.access")
    end
    return layers
end

function Overlay.BuildMarkers(settlement)
    local markers = {}
    local totals, seen = {}, {}
    for _, facility in ipairs(settlement and settlement.facilities or {}) do
        local key = tostring(facility.definitionId or "")
        totals[key] = (totals[key] or 0) + 1
    end
    for _, facility in ipairs(settlement and settlement.facilities or {}) do
        local definitionKey = tostring(facility.definitionId or "")
        seen[definitionKey] = (seen[definitionKey] or 0) + 1
        local label = facilityLabel(facility, seen[definitionKey],
            totals[definitionKey])
        local hasRoom = false
        local hasWorkZone = false
        local directWorkstation = isDirectWorkstation(facility)
        local workZoneEnabled = facilityWorkZoneEnabled(facility)
        local zoneEnabled = facilityZoneEnabled(facility)
        local ordinals = {}
        for _, component in ipairs(facility.components or {}) do
            local role = tostring(component.role or "")
            ordinals[role] = (ordinals[role] or 0) + 1
            if role == "work.zone" and workZoneEnabled then
                hasWorkZone = true
                local point = component.kind == "region"
                    and regionCenter(component.region)
                    or { x = (tonumber(component.x) or 0) + 0.5,
                        y = (tonumber(component.y) or 0) + 0.5,
                        z = tonumber(component.z) or 0 }
                addMarker(markers, point, "work_zone", component.id,
                    component.role, 1)
                if markers[#markers] then
                    markers[#markers].label = componentName(
                        facility, component, nil, label)
                end
            elseif role ~= "work.zone" and component.kind == "region" then
                hasRoom = true
                addMarker(markers, regionCenter(component.region), "room",
                    facility.id, component.role, 1)
                if markers[#markers] then
                    markers[#markers].label = componentName(facility,
                        component, nil, label)
                end
            elseif role ~= "work.zone" and component.kind == "anchor" then
                local workstationMarker = directWorkstation
                    and component.managedByFacility == true
                local approach = workstationMarker
                    and workstationApproachPoint(facility, component) or nil
                addMarker(markers, {
                    x = approach and approach.x
                        or (tonumber(component.x) or 0) + 0.5,
                    y = approach and approach.y
                        or (tonumber(component.y) or 0) + 0.5,
                    z = approach and approach.z or tonumber(component.z) or 0,
                }, workstationMarker and "workstation" or "component",
                    component.id, component.role, 1)
                markers[#markers].label = workstationMarker
                    and label
                    or componentName(facility, component, ordinals[role])
            end
        end
        if not hasRoom and not directWorkstation
            and (zoneEnabled or not hasWorkZone)
        then
            addMarker(markers, regionCenter(facility.constructionRegion),
                "room", facility.id, "facility.footprint", 1)
            if markers[#markers] then markers[#markers].label = label end
        end
    end
    for _, node in ipairs(settlement and settlement.stockpileNodes or {}) do
        addMarker(markers, {
            x = (tonumber(node.x) or 0) + 0.5,
            y = (tonumber(node.y) or 0) + 0.5,
            z = tonumber(node.z) or 0,
        }, "component", node.id, "stockpile.access", 1)
        markers[#markers].label = componentName(nil, {
            role = "stockpile.access", kind = "anchor",
        }, 1)
    end
    return markers
end

function Overlay.SetSettlement(settlement)
    Overlay.settlementId = settlement and settlement.id or nil
    Overlay.revision = settlement and settlement.revision or nil
    Overlay.snapshotKey = settlementKey(settlement)
    Overlay.layers = Overlay.BuildLayers(settlement, true)
    Overlay.markers = Overlay.BuildMarkers(settlement)
end

function Overlay.SetEnabled(enabled)
    Overlay.enabled = enabled == true
    Overlay.restoreEnabled = Overlay.enabled
    return Overlay.enabled
end

function Overlay.Toggle(settlement)
    if settlement then Overlay.SetSettlement(settlement) end
    return Overlay.SetEnabled(not Overlay.enabled)
end

function Overlay.IsEnabled()
    return Overlay.enabled == true
end

function Overlay.SyncFromClientState()
    local state = PNC.Network and PNC.Network.ClientState or nil
    local snapshot = state and state.colonyManagement or nil
    local settlement = snapshot and snapshot.settlement or nil
    if not settlement then return false end

    local snapshotRevision = tonumber(state.colonyManagementRevision) or 0
    if Overlay.awaitingPostReset == true
        and snapshotRevision <= (tonumber(Overlay.resetRevision) or 0)
    then
        return false
    end

    if Overlay.snapshotKey ~= settlementKey(settlement)
        or Overlay.settlementId == nil
    then
        Overlay.SetSettlement(settlement)
    end
    if Overlay.awaitingPostReset == true then
        Overlay.awaitingPostReset = false
        if Overlay.restoreEnabled == true then
            Overlay.SetEnabled(true)
        end
    end
    return true
end

return Overlay
