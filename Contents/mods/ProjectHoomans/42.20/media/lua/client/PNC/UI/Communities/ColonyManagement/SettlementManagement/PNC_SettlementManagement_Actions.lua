local Territory = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_TerritoryActions"
local Facility = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_FacilityActions"
local BuildModal = require "PNC/UI/Communities/ColonyManagement/PNC_FacilityBuildModal"
local LayoutOverlay = require "PNC/UI/Communities/ColonyManagement/PNC_SettlementLayoutOverlay"
local Support = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"

local Actions = {}

Actions.NextAnchorRole = Facility.NextAnchorRole
Actions.AnchorLabel = Facility.AnchorLabel
Actions.AnchorAssignLabel = Facility.AnchorAssignLabel
Actions.AreaRole = Facility.AreaRole

function Actions.HandleComponent(window, action, facility)
    if not facility or type(action) ~= "table" then return false end
    if action.kind == "region" then
        return Facility.BeginArea(window, facility, action.role,
            action.componentId)
    end
    if action.kind == "anchor" then
        if action.groupEdit == true then
            return Facility.BeginAnchorGroup(window, facility, action.role)
        end
        Facility.BeginPoint(window, "facility_anchor", facility,
            action.role, action.componentId)
        return true
    end
    if action.kind == "abstract" then
        if action.remove == true and action.componentId then
            PNC.Client.RequestRemoveFacilityComponent({
                facilityId = facility.id,
                expectedRevision = facility.revision,
                componentId = action.componentId,
            })
        else
            PNC.Client.RequestSetFacilityComponent({
                facilityId = facility.id,
                expectedRevision = facility.revision,
                component = { kind = "abstract", role = action.role },
            })
        end
        Support.ApplyLocalResult(window)
        return true
    end
    return false
end

function Actions.Handle(window, action, facility)
    local settlement = window.snapshot and window.snapshot.settlement
    if action == "claim" then Territory.Begin(window, "create"); return true end
    if not settlement then return false end
    if action == "expand" then Territory.Begin(window, "expand"); return true end
    if action == "shrink" then Territory.Begin(window, "shrink"); return true end
    if action == "overlay" then LayoutOverlay.Toggle(settlement); return true end
    if action == "build_facility" then
        BuildModal.Open(settlement, function(definitionId)
            Facility.BeginBuild(window, definitionId)
        end, window.snapshot and window.snapshot.storage,
            window.snapshot and window.snapshot.research)
        return true
    end
    if action == "barricade" then
        PNC.Client.RequestBuildBarricade({ baseId = settlement.id,
            expectedRevision = settlement.revision })
    elseif action == "hq" then
        PNC.Client.RequestUpgradeHQ({ baseId = settlement.id,
            expectedRevision = settlement.revision })
    elseif action == "storage" then
        PNC.Client.RequestColonyAction("storage_upgrade", {
            storageId = window.snapshot and window.snapshot.storage
                and window.snapshot.storage.storageId,
        })
    elseif action == "stockpile" then
        Facility.BeginPoint(window, "stockpile"); return true
    elseif not facility then
        return false
    elseif action == "facility_area" then
        return Facility.BeginArea(window, facility)
    elseif action == "facility_anchor" then
        Facility.BeginPoint(window, "facility_anchor", facility); return true
    elseif action == "facility_upgrade" then
        PNC.Client.RequestUpgradeFacility({ facilityId = facility.id,
            expectedRevision = facility.revision })
    elseif action == "facility_destroy" then
        PNC.Client.RequestDestroyFacility({ facilityId = facility.id,
            expectedRevision = facility.revision })
    else
        return false
    end
    Support.ApplyLocalResult(window)
    return true
end

return Actions
