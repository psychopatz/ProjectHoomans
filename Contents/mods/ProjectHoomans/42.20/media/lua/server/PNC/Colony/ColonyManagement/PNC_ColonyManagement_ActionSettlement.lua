if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyManagement = PNC.ColonyManagement or {}
PNC.ColonyManagement.Internal = PNC.ColonyManagement.Internal or {}

local Management = PNC.ColonyManagement
local Internal = Management.Internal
local Definitions = PNC.NeedsDefinitions


local rememberSettlementResult = Internal.rememberSettlementResult

function Internal.handleSettlementAction(player, args, action)
    local settlementActions = {
        base_create = PNC.BaseService and PNC.BaseService.Create,
        base_expand = PNC.BaseService and PNC.BaseService.Expand,
        base_shrink = PNC.BaseService and PNC.BaseService.Shrink,
        barricade_build = PNC.BaseService and PNC.BaseService.BuildBarricade,
        hq_upgrade = PNC.BaseService and PNC.BaseService.UpgradeHQ,
        facility_create = PNC.FacilityService and PNC.FacilityService.Create,
        facility_upgrade = PNC.FacilityService and PNC.FacilityService.Upgrade,
        facility_capacity_set = PNC.FacilityService
            and PNC.FacilityService.SetCapacity,
        facility_debug_get_materials = PNC.FacilityService
            and PNC.FacilityService.DebugGrantMaterials,
        facility_component_set = PNC.FacilityService
            and PNC.FacilityService.SetComponent,
        farm_plot_crop = PNC.FarmingService
            and PNC.FarmingService.SetDesiredCrop,
        farm_plot_policy = PNC.FarmingService
            and PNC.FarmingService.SetPolicy,
        farm_plot_debug = PNC.FarmingService
            and PNC.FarmingService.DebugPlot,
        facility_anchor_role_replace = PNC.FacilityService
            and PNC.FacilityService.ReplaceAnchorRole,
        facility_component_remove = PNC.FacilityService
            and PNC.FacilityService.RemoveComponent,
        facility_destroy = PNC.FacilityService
            and PNC.FacilityService.Destroy,
        stockpile_node_create = PNC.StockpileAccessService
            and PNC.StockpileAccessService.Create,
        stockpile_node_remove = PNC.StockpileAccessService
            and PNC.StockpileAccessService.Remove,
    }
    local handler = settlementActions[action]
    if not handler then return nil end
    local cached = args.requestId
        and Management.SettlementResults[tostring(args.requestId)] or nil
    local details
    local ok
    local reason
    if cached then
        details = PNC.Core.DeepCopy(cached)
        ok, reason = cached.ok, cached.reason
    else
        details = handler(player, args)
        ok, reason = details and details.ok == true, details and details.reason
        if ok and PNC.SettlementRepository
            and PNC.SettlementRepository.Save
        then
            PNC.SettlementRepository.Save()
        end
        if args.requestId then
            rememberSettlementResult(args.requestId, details)
        end
    end
    return { ok = ok, reason = reason, details = details }
end

return Management
