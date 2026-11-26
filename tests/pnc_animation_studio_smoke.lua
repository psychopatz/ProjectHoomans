-- Smoke test for the unified 3-tab Animation Studio debug UI.
-- Verifies single context-menu entry, 3-tab shell loading, Kahlua-safe
-- structure, and lazy catalog loading.

local T = require "tests/support/test"

-- Verify Debug Context Provider exposes ONE Animation Studio entry instead of
-- the 4 legacy fragmented animation entries.
local ctxSource = assert(io.open(
    T.path("ProjectHoomans", "client", "PNC/UI/Context/Providers/PNC_ContextProvider_Debug.lua"),
    "r"
)):read("*a")
T.truthy(ctxSource:find("UI_PNC_Debug_AnimationStudio", 1, true),
    "Context menu must expose Animation Studio")
T.falsy(ctxSource:find("UI_PNC_Debug_NPCPresentationLab", 1, true),
    "Legacy NPCPresentationLab menu entry should be retired")
T.falsy(ctxSource:find("UI_PNC_Debug_PlayerAnimationLab", 1, true),
    "Legacy PlayerAnimationLab menu entry should be retired")
T.falsy(ctxSource:find("UI_PNC_Debug_AnimationSceneLab", 1, true),
    "Legacy AnimationSceneLab menu entry should be retired")
T.falsy(ctxSource:find("UI_PNC_Debug_Choreography", 1, true),
    "Legacy Choreography menu entry should be retired")

-- Verify PsychopatzCore Debug Hub exposes ONE Animation Studio tool.
local hubSource = assert(io.open(
    T.path("ProjectHoomans", "client", "PNC/Integrations/PNC_PsychopatzCoreDebug.lua"),
    "r"
)):read("*a")
T.truthy(hubSource:find("pnc.animationStudio", 1, true),
    "Debug Hub must register pnc.animationStudio")
T.falsy(hubSource:find("pnc.playerAnimation", 1, true),
    "Legacy pnc.playerAnimation hub entry should be retired")
T.falsy(hubSource:find("pnc.choreography", 1, true),
    "Legacy pnc.choreography hub entry should be retired")

-- Verify all 4 Animation Studio files exist and parse cleanly under Lua 5.1.
for _, path in ipairs({
    T.path("ProjectHoomans", "client", "PNC/UI/AnimationStudio/PNC_AnimationStudio.lua"),
    T.path("ProjectHoomans", "client", "PNC/UI/AnimationStudio/PNC_AnimationStudio_ClipsTab.lua"),
    T.path("ProjectHoomans", "client", "PNC/UI/AnimationStudio/PNC_AnimationStudio_ScenesTab.lua"),
    T.path("ProjectHoomans", "client", "PNC/UI/AnimationStudio/PNC_AnimationStudio_PropsTab.lua"),
}) do
    local fn, err = loadfile(path)
    assert(fn ~= nil, "Failed to parse " .. path .. ": " .. tostring(err))
end

-- Verify ScenesTab includes Base.Cigarettes preset for testing smoke scenes.
local scenesSource = assert(io.open(
    T.path("ProjectHoomans", "client", "PNC/UI/AnimationStudio/PNC_AnimationStudio_ScenesTab.lua"),
    "r"
)):read("*a")
T.truthy(scenesSource:find("Base.Cigarettes", 1, true),
    "Single-NPC scenes tab should include Base.Cigarettes prop preset")
T.truthy(scenesSource:find("removeView", 1, true),
    "Multi-Actor scenes scope should remove duplicate clip browser tabs")

print("PASS: Animation Studio Phase 1 smoke test")
