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
    id = "pnc.settings",
    source = "ProjectHoomans",
    order = 210,
    title = "Project Hoomans Settings",
    description = "Configure persistent NPC overlays and client presentation settings.",
    available = function()
        return PNC and PNC.Settings and PNC.Settings.Toggle
    end,
    action = function()
        PNC.Settings.Toggle()
    end,
})
