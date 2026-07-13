local ok = pcall(require, "PsychopatzLib/UI/PsychopatzDebugHubWindow")
if not ok or not (PsychopatzLib and PsychopatzLib.DebugHub) then
    return
end

PsychopatzLib.DebugHub.RegisterTool({
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
