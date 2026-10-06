-- Project Hoomans performance diagnostic setting provider.
-- This module owns registration and startup hydration of debug toggles.
PNC = PNC or {}
PNC.PerformanceScalingDiagnostics =
    PNC.PerformanceScalingDiagnostics or {}

local Diagnostics = PNC.PerformanceScalingDiagnostics
if type(Diagnostics) ~= "table" then return false end

local PERFORMANCE_SETTING_ID = "ProjectHoomans.PerformanceDiagnostics"
local SEATING_AUDIT_SETTING_ID = "ProjectHoomans.SeatingAudit"
local SLEEP_AUDIT_SETTING_ID = "ProjectHoomans.SleepAudit"
local FIREARM_AUDIT_SETTING_ID = "ProjectHoomans.FirearmEffectsAudit"
local FOLLOWER_PRESENCE_AUDIT_SETTING_ID =
    "ProjectHoomans.FollowerPresenceAudit"
local FOLLOWER_ABANDONMENT_AUDIT_SETTING_ID =
    "ProjectHoomans.FollowerAbandonmentAudit"
local INVENTORY_AUDIT_SETTING_ID = "ProjectHoomans.InventoryAudit"
local NEEDS_AUDIT_SETTING_ID = "ProjectHoomans.NeedsAudit"
local ZOMBIE_AGGRO_AUDIT_SETTING_ID = "ProjectHoomans.ZombieAggroAudit"
local NPC_THREAT_AUDIT_SETTING_ID = "ProjectHoomans.NPCThreatAudit"
local NETWORK_PAYLOAD_AUDIT_SETTING_ID = "ProjectHoomans.NetworkPayloadAudit"
local BUILD_AUDIT_SETTING_ID = "ProjectHoomans.BuildAudit"
local NATIVE_HANDOFF_AUDIT_SETTING_ID =
    "ProjectHoomans.NativeHandoffAudit"
local PRESENCE_TRAVERSAL_AUDIT_SETTING_ID =
    "ProjectHoomans.PresenceTraversalAudit"
local function initializeCentralDebugSettings()
    local settings = PsychopatzCore and PsychopatzCore.DebugSettings
    if not settings or type(settings.Register) ~= "function" then
        pcall(require, "PsychopatzCore/Debug/PsychopatzDebugSettings")
        settings = PsychopatzCore and PsychopatzCore.DebugSettings
    end
    if not settings or type(settings.Register) ~= "function" then return end
    settings.Register({
        id = PERFORMANCE_SETTING_ID,
        source = "Project Hoomans",
        order = 50,
        title = "Performance scaling diagnostics",
        description = "Enables counters, gauges, sampled timings, and summaries.",
        -- This is an existing diagnostic surface. Preserve its current
        -- behavior for existing installs; new diagnostic registrations should
        -- normally use defaultEnabled = false.
        defaultEnabled = true,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.Enabled = enabled == true
            Diagnostics.TimingEnabled = Diagnostics.Enabled
            Diagnostics.RuntimeLogEnabled = Diagnostics.Enabled
        end,
    })
    settings.Register({
        id = SEATING_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 100,
        title = "Seating state audit",
        description = "Captures seating reservations, entry, movement, scenes, and cleanup.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.SeatingAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = SLEEP_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 102,
        title = "Sleep state audit",
        description = "Captures sleep targeting, bed entry, scene handoff, cleanup, and client replication.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.SleepAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = FIREARM_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 105,
        title = "Firearm effects audit",
        description = "Logs each NPC shot through authority, network, audio, light, tracer, and draw stages.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.FirearmAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = FOLLOWER_PRESENCE_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 110,
        title = "Follower presence audit",
        description = "Logs abstract/live follower transitions and movement.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.FollowerPresenceAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = FOLLOWER_ABANDONMENT_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 120,
        title = "Follower abandonment audit",
        description = "Logs follow combat departure and return commentary.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.FollowerAbandonmentAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = INVENTORY_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 130,
        title = "Inventory state audit",
        description = "Logs authoritative inventory mutations and client synchronization.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.InventoryAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = NEEDS_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 135,
        title = "Needs state audit",
        description = "Logs hunger, thirst, fatigue, and other individual need changes.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.NeedsAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = ZOMBIE_AGGRO_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 140,
        title = "Zombie aggro audit",
        description = "Logs zombie target selection, pursuit, bites, and multiplayer directives.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.ZombieAggroAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = NPC_THREAT_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 145,
        title = "NPC threat audit",
        description = "Logs NPC zombie alerting, target retention, group propagation, and combat handoff.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.NPCThreatAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = NETWORK_PAYLOAD_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 150,
        title = "Network payload audit",
        description = "Logs estimated bytes per section for every guarded server payload.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.NetworkPayloadAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = BUILD_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 155,
        title = "Build pipeline audit",
        description = "Traces every facility build from click through placement, request, material consumption and queueing.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.BuildAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = NATIVE_HANDOFF_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 160,
        title = "Native locomotion handoff audit",
        description = "Traces native path publication, WalkToward re-entry, and same-frame owner repairs.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.NativeHandoffAuditEnabled = enabled == true
        end,
    })
    settings.Register({
        id = PRESENCE_TRAVERSAL_AUDIT_SETTING_ID,
        source = "Project Hoomans",
        order = 165,
        title = "Presence and traversal audit",
        description = "Traces live/abstract handoff, body leases, unloaded chunks, and bounded movement recovery for every NPC.",
        defaultEnabled = false,
        runtimeMutable = true,
        apply = function(enabled)
            Diagnostics.PresenceTraversalAuditEnabled = enabled == true
        end,
    })
    Diagnostics.Enabled = settings.IsEnabled(PERFORMANCE_SETTING_ID) == true
    Diagnostics.TimingEnabled = Diagnostics.Enabled
        and Diagnostics.TimingEnabled ~= false
    Diagnostics.RuntimeLogEnabled = Diagnostics.Enabled
        and Diagnostics.RuntimeLogEnabled ~= false
    -- The registry applies these cheap diagnostic gates at startup or
    -- after an explicit Debug Settings Apply action. Direct callers can still
    -- use SetSeatingAuditEnabled as a temporary emergency runtime override.
    Diagnostics.SeatingAuditEnabled = settings.IsEnabled(
        SEATING_AUDIT_SETTING_ID) == true
    Diagnostics.SleepAuditEnabled = settings.IsEnabled(
        SLEEP_AUDIT_SETTING_ID) == true
    Diagnostics.FirearmAuditEnabled = settings.IsEnabled(
        FIREARM_AUDIT_SETTING_ID) == true
    Diagnostics.FollowerPresenceAuditEnabled = settings.IsEnabled(
        FOLLOWER_PRESENCE_AUDIT_SETTING_ID) == true
    Diagnostics.FollowerAbandonmentAuditEnabled = settings.IsEnabled(
        FOLLOWER_ABANDONMENT_AUDIT_SETTING_ID) == true
    Diagnostics.InventoryAuditEnabled = settings.IsEnabled(
        INVENTORY_AUDIT_SETTING_ID) == true
    Diagnostics.NeedsAuditEnabled = settings.IsEnabled(
        NEEDS_AUDIT_SETTING_ID) == true
    Diagnostics.ZombieAggroAuditEnabled = settings.IsEnabled(
        ZOMBIE_AGGRO_AUDIT_SETTING_ID) == true
    Diagnostics.NPCThreatAuditEnabled = settings.IsEnabled(
        NPC_THREAT_AUDIT_SETTING_ID) == true
    Diagnostics.NetworkPayloadAuditEnabled = settings.IsEnabled(
        NETWORK_PAYLOAD_AUDIT_SETTING_ID) == true
    Diagnostics.BuildAuditEnabled = settings.IsEnabled(
        BUILD_AUDIT_SETTING_ID) == true
    Diagnostics.NativeHandoffAuditEnabled = settings.IsEnabled(
        NATIVE_HANDOFF_AUDIT_SETTING_ID) == true
    Diagnostics.PresenceTraversalAuditEnabled = settings.IsEnabled(
        PRESENCE_TRAVERSAL_AUDIT_SETTING_ID) == true
end

initializeCentralDebugSettings()

return true
