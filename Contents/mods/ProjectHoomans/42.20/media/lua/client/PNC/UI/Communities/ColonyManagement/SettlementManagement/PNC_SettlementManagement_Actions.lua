local Territory = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_TerritoryActions"
local Facility = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_FacilityActions"
local BuildModal = require "PNC/UI/Communities/ColonyManagement/PNC_FacilityBuildModal"
local LayoutOverlay = require "PNC/UI/Communities/ColonyManagement/PNC_SettlementLayoutOverlay"
local Support = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_SelectorSupport"
local Fishing = require "PNC/UI/Communities/ColonyManagement/SettlementManagement/PNC_SettlementManagement_FishingActions"

local Actions = {}

Actions.NextAnchorRole = Facility.NextAnchorRole
Actions.AnchorLabel = Facility.AnchorLabel
Actions.AnchorAssignLabel = Facility.AnchorAssignLabel
Actions.AreaRole = Facility.AreaRole

function Actions.HandleComponent(window, action, facility)
    if not facility or type(action) ~= "table" then return false end
    if action.kind == "set_room_capacity" then
        local CapacityModal = require "PNC/UI/Communities/ColonyManagement/PNC_FacilityCapacityModal"
        return CapacityModal.Open(window, facility) ~= false
    end
    if action.kind == "open_stockpile" then
        local storage = window.snapshot and window.snapshot.storage
        local access = storage and storage.access or nil
        if not storage or not storage.storageId or not access
            or access.hasStockpile ~= true
        then return false end
        local StorageUI = require "PNC/UI/Communities/PNC_ColonyStorageWindow"
        local storageWindow = StorageUI.Open()
        if storageWindow and window.close then window:close() end
        return storageWindow ~= nil
    end
    if action.kind == "stockpile_move" and action.componentId then
        return Facility.BeginArea(window, facility, "storage.stockpile",
            action.componentId)
    end
    if action.kind == "resume_work" and action.workOrderId then
        PNC.Client.RequestColonyAction("work_resume", {
            workOrderId = action.workOrderId,
        })
        Support.ApplyLocalResult(window)
        return true
    end
    if action.kind == "cancel_work" and action.workOrderId then
        local ConfirmModal = require "PNC/UI/Factions/PNC_FactionMemberModal"
        ConfirmModal.Open({
            title = Support.Tr("UI_PNC_Work_CancelConstructionTitle",
                "Cancel Construction"),
            message = Support.Tr("UI_PNC_Work_CancelConstructionMessage",
                "Cancel this construction project?"),
            detail = Support.Tr("UI_PNC_Work_CancelConstructionDetail",
                "Supplied materials are refunded from the remaining work fraction.")
                .. (action.refundPercent and "  "
                    .. tostring(action.refundPercent) .. "% "
                    .. Support.Tr("UI_PNC_Work_Refundable", "RECOVERABLE")
                    or ""),
            confirmLabel = Support.Tr("UI_PNC_Work_CancelConstruction",
                "CANCEL CONSTRUCTION"),
            danger = true,
            context = { workOrderId = action.workOrderId },
            onConfirm = function(context)
                PNC.Client.RequestColonyAction("work_cancel", {
                    workOrderId = context.workOrderId,
                })
                Support.ApplyLocalResult(window)
            end,
        })
        return true
    end
    if action.remove == true and action.componentId then
        PNC.Client.RequestRemoveFacilityComponent({
            facilityId = facility.id,
            expectedRevision = facility.revision,
            componentId = action.componentId,
        })
        Support.ApplyLocalResult(window)
        return true
    end
    if action.kind == "farm_plot_crop" and action.componentId then
        return Facility.BeginCrop(window, facility, action.componentId)
    end
    if action.kind == "region" then
        return Facility.BeginArea(window, facility, action.role,
            action.componentId)
    end
    if action.kind == "anchor" then
        Facility.BeginPoint(window, "facility_anchor", facility,
            action.role, action.componentId)
        return true
    end
    if action.kind == "abstract" then
        PNC.Client.RequestSetFacilityComponent({
            facilityId = facility.id,
            expectedRevision = facility.revision,
            component = { kind = "abstract", role = action.role },
        })
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
    if action == "fishing_zone" then return Fishing.Begin(window) end
    if action == "build_facility" then
        BuildModal.Open(settlement, function(definitionId)
            return Facility.BeginBuild(window, definitionId)
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
    elseif not facility then
        return false
    elseif action == "facility_area" then
        return Facility.BeginArea(window, facility)
    elseif action == "facility_anchor" then
        Facility.BeginPoint(window, "facility_anchor", facility); return true
    elseif action == "facility_upgrade" then
        PNC.Client.RequestUpgradeFacility({ facilityId = facility.id,
            expectedRevision = facility.revision })
    elseif action == "facility_cancel_construction" then
        local ConfirmModal = require "PNC/UI/Factions/PNC_FactionMemberModal"
        local task = facility.activeTask
        if task and task.id then
            ConfirmModal.Open({
                title = Support.Tr("UI_PNC_Work_CancelConstructionTitle",
                    "Cancel Construction"),
                message = Support.Tr("UI_PNC_Work_CancelConstructionMessage",
                    "Cancel this construction project?"),
                detail = Support.Tr("UI_PNC_Work_CancelConstructionDetail",
                    "Supplied materials are refunded from the remaining work fraction.")
                    .. (task.refundPercent and "  "
                        .. tostring(task.refundPercent) .. "% "
                        .. Support.Tr("UI_PNC_Work_Refundable", "RECOVERABLE")
                        or ""),
                confirmLabel = Support.Tr("UI_PNC_Work_CancelConstruction",
                    "CANCEL CONSTRUCTION"),
                danger = true,
                context = { workOrderId = task.id },
                onConfirm = function(context)
                    PNC.Client.RequestColonyAction("work_cancel", {
                        workOrderId = context.workOrderId,
                    })
                    Support.ApplyLocalResult(window)
                end,
            })
        end
        return true
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
