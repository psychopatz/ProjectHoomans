-- Faction debug window control catalog.


PNC = PNC or {}
PNC.FactionDebugUI = PNC.FactionDebugUI or {}

local FactionUI = PNC.FactionDebugUI
local Internal = FactionUI.Internal or {}
FactionUI.Internal = Internal
local function views(first, second)
    local values = {}
    if first then values[first] = true end
    if second then values[second] = true end
    return values
end

local CONTROLS = {
    { id = "refresh", titleKey = "UI_PNC_MonitorRefresh", variant = "quiet" },
    { id = "overlay", titleKey = "UI_PNC_FactionToggleOverlay", variant = "quiet" },
    { id = "view_overview", titleKey = "UI_PNC_FactionViewOverview", variant = "quiet" },
    { id = "view_mobile", titleKey = "UI_PNC_FactionViewMobile", variant = "warning" },
    { id = "view_diplomacy", titleKey = "UI_PNC_FactionViewDiplomacy", variant = "quiet" },
    { id = "view_members", titleKey = "UI_PNC_FactionViewMembers", variant = "quiet" },
    { id = "view_diagnostics", titleKey = "UI_PNC_FactionViewDiagnostics", variant = "quiet" },
    { id = "mobile_filter_all", titleKey = "UI_PNC_FactionMobileFilterAll", variant = "selected", views = views("mobile") },
    { id = "mobile_filter_staging", titleKey = "UI_PNC_FactionMobileFilterStaging", variant = "quiet", views = views("mobile") },
    { id = "mobile_filter_player", titleKey = "UI_PNC_FactionMobileFilterPlayer", variant = "quiet", views = views("mobile") },
    { id = "mobile_filter_ai", titleKey = "UI_PNC_FactionMobileFilterAI", variant = "quiet", views = views("mobile") },
    { id = "mobile_filter_street", titleKey = "UI_PNC_FactionMobileFilterStreet", variant = "quiet", views = views("mobile") },
    { id = "create_player_faction", titleKey = "UI_PNC_FactionCreatePlayer", variant = "success", views = views("overview") },
    { id = "edit_emblem", titleKey = "UI_PNC_FactionEditEmblem", variant = "default", views = views("overview") },
    { id = "create_settler", titleKey = "UI_PNC_FactionCreateSettler", variant = "success", views = views("overview") },
    { id = "create_looter", titleKey = "UI_PNC_FactionCreateLooter", variant = "danger", views = views("overview") },
    { id = "create_looter_group", titleKey = "UI_PNC_FactionCreateLooterGroup", variant = "danger", views = views("overview") },
    { id = "create_ambient_looter_group", titleKey = "UI_PNC_FactionCreateAmbientLooterGroup", variant = "warning", views = views("overview") },
    { id = "create_strategic_looter_group", titleKey = "UI_PNC_FactionCreateStrategicLooterGroup", variant = "danger", views = views("overview") },
    { id = "create_trader", titleKey = "UI_PNC_FactionCreateTrader", variant = "default", views = views("overview") },
    { id = "create_refugee", titleKey = "UI_PNC_FactionCreateRefugee", variant = "default", views = views("overview") },
    { id = "create_mobile_road_group", titleKey = "UI_PNC_FactionCreateMobileRoadGroup", variant = "warning", views = views("mobile") },
    { id = "create_mobile_player_route_group", titleKey = "UI_PNC_FactionCreateMobilePlayerRouteGroup", variant = "danger", views = views("mobile") },
    { id = "create_mobile_ai_route_group", titleKey = "UI_PNC_FactionCreateMobileAIRouteGroup", variant = "warning", views = views("mobile") },
    { id = "generate_group", titleKey = "UI_PNC_FactionGenerateGroup", variant = "success", views = views("overview") },
    { id = "mobile_control_mode", titleKey = "UI_PNC_FactionMobileControlMode", variant = "quiet", views = views("mobile") },
    { id = "mobile_path_mode", titleKey = "UI_PNC_FactionMobilePathMode", variant = "quiet", views = views("mobile") },
    { id = "mobile_refresh", titleKey = "UI_PNC_FactionMobileRefresh", variant = "quiet", views = views("mobile") },
    { id = "mobile_relocate", titleKey = "UI_PNC_FactionMobileRelocate", variant = "quiet", views = views("mobile") },
    { id = "force_mobile_road", titleKey = "UI_PNC_FactionForceMobileRoad", variant = "warning", views = views("mobile") },
    { id = "force_mobile_departure", titleKey = "UI_PNC_FactionForceMobileDeparture", variant = "danger", views = views("mobile") },
    { id = "force_mobile_arrival", titleKey = "UI_PNC_FactionForceMobileArrival", variant = "quiet", views = views("mobile") },
    { id = "repair_mobile_travel", titleKey = "UI_PNC_FactionRepairMobileTravel", variant = "quiet", views = views("mobile") },
    { id = "roll_mobile_departures", titleKey = "UI_PNC_FactionRollMobileDepartures", variant = "success", views = views("mobile") },
    { id = "population_label", titleKey = "UI_PNC_FactionGroupSize", variant = "quiet", views = views("overview", "mobile") },
    { id = "presence_mode", titleKey = "UI_PNC_FactionPresenceMode", variant = "quiet", views = views("overview", "mobile") },
    { id = "archive", titleKey = "UI_PNC_FactionArchive", variant = "danger", views = views("overview") },
    { id = "assign", titleKey = "UI_PNC_FactionAssignNPC", variant = "success", views = views("members") },
    { id = "manage_player_members", titleKey = "UI_PNC_FactionManageMembers", variant = "success", views = views("members") },
    { id = "transfer", titleKey = "UI_PNC_FactionTransferNPC", variant = "default", views = views("members") },
    { id = "remove", titleKey = "UI_PNC_FactionRemoveNPC", variant = "danger", views = views("members") },
    { id = "leader", titleKey = "UI_PNC_FactionSetLeader", variant = "default", views = views("members") },
    { id = "role", titleKey = "UI_PNC_FactionNextRole", variant = "quiet", views = views("members") },
    { id = "rank", titleKey = "UI_PNC_FactionNextRank", variant = "quiet", views = views("members") },
    { id = "war", titleKey = "UI_PNC_FactionDeclareWar", variant = "danger", views = views("diplomacy") },
    { id = "truce", titleKey = "UI_PNC_FactionStartTruce", variant = "quiet", views = views("diplomacy") },
    { id = "peace", titleKey = "UI_PNC_FactionMakePeace", variant = "success", views = views("diplomacy") },
    { id = "alliance", titleKey = "UI_PNC_FactionFormAlliance", variant = "success", views = views("diplomacy") },
    { id = "break_alliance", titleKey = "UI_PNC_FactionBreakAlliance", variant = "danger", views = views("diplomacy") },
    { id = "incident_minor", titleKey = "UI_PNC_FactionMinorAttack", variant = "quiet", views = views("diplomacy") },
    { id = "incident_severe", titleKey = "UI_PNC_FactionSevereAttack", variant = "danger", views = views("diplomacy") },
    { id = "incident_killed", titleKey = "UI_PNC_FactionMemberKilled", variant = "danger", views = views("diplomacy") },
    { id = "incident_rescue", titleKey = "UI_PNC_FactionMemberRescued", variant = "success", views = views("diplomacy") },
    { id = "recalculate", titleKey = "UI_PNC_FactionRecalculate", variant = "quiet", views = views("diplomacy") },
    { id = "check_relation", titleKey = "UI_PNC_FactionCheckRelation", variant = "quiet", views = views("diplomacy", "diagnostics") },
    { id = "reconcile_treaty", titleKey = "UI_PNC_FactionReconcileTreaty", variant = "quiet", views = views("diplomacy", "diagnostics") },
    { id = "telemetry_toggle", titleKey = "UI_PNC_FactionEnableTelemetry", variant = "success", views = views("diagnostics") },
    { id = "telemetry_clear", titleKey = "UI_PNC_FactionClearTelemetry", variant = "danger", views = views("diagnostics") },
    { id = "next_scenario", titleKey = "UI_PNC_FactionNextScenario", variant = "quiet", views = views("diagnostics") },
    { id = "run_scenario", titleKey = "UI_PNC_FactionRunScenario", variant = "success", views = views("diagnostics") },
    { id = "check_registry", titleKey = "UI_PNC_FactionCheckRegistry", variant = "quiet", views = views("diagnostics") },
    { id = "repair_indexes", titleKey = "UI_PNC_FactionRepairIndexes", variant = "danger", views = views("diagnostics") },
    { id = "export_snapshot", titleKey = "UI_PNC_FactionExportSnapshot", variant = "default", views = views("diagnostics") },
}

local MOBILE_FILTER_CONTROL_MAP = {
    mobile_filter_all = "all",
    mobile_filter_staging = "staging",
    mobile_filter_player = "player_colony",
    mobile_filter_ai = "ai_settlement",
    mobile_filter_street = "street_roaming",
}

Internal.Controls = CONTROLS
Internal.MobileFilterControlMap = MOBILE_FILTER_CONTROL_MAP
