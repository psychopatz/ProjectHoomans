local ok = pcall(require, "PsychopatzCore/UI/PsychopatzDebugHubWindow")
if not ok or not (PsychopatzCore and PsychopatzCore.DebugHub) then
    return
end

PsychopatzCore.DebugHub.RegisterTool({
    id = "pnc.npcMonitor",
    source = "PsychopatzNPC-Core",
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
