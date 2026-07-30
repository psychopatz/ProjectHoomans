local ok = pcall(require, "PsychopatzCore/UI/PsychopatzDebugHubWindow")
if not ok or not (PsychopatzCore and PsychopatzCore.DebugHub) then
    return
end

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.npcMonitor",
    source = "ProjectHoomans",
    order = 200,
    title = "PNC NPC Monitor",
    description = "Inspect NPC lifecycle, authority, presence, combat, and runtime bodies.",
    available = function()
        return PNC
            and PNC.NPCMonitor
            and PNC.NPCMonitor.Toggle
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function()
        PNC.NPCMonitor.Toggle()
    end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.relationships",
    source = "ProjectHoomans",
    order = 210,
    title = "PNC Relationship Inspector",
    description = "Inspect directed social data and trigger guarded test events.",
    available = function()
        return PNC
            and PNC.RelationshipDebugUI
            and PNC.RelationshipDebugUI.Toggle
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function()
        PNC.RelationshipDebugUI.Toggle()
    end,
})

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.factions",
    source = "ProjectHoomans",
    order = 220,
    title = getText and getText("UI_PNC_FactionInspectorTitle")
        or "UI_PNC_FactionInspectorTitle",
    description = "Inspect persistent organizations, affiliations, roles, ranks, and leadership.",
    available = function()
        return PNC
            and PNC.FactionDebugUI
            and PNC.FactionDebugUI.Toggle
            and PNC.Client
            and PNC.Client.CanUseDebug
            and PNC.Client.CanUseDebug()
    end,
    action = function()
        PNC.FactionDebugUI.Toggle()
    end,
})

-- Project Hoomans settings belong to the standard in-game settings registry.
-- Remove the old debug-hub launcher as well when this file is hot-reloaded.
PsychopatzCore.DebugHub.UnregisterTool("pnc.settings")
