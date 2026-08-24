local T = require "tests/support/test"

local ROOT =
    T.path("ProjectHoomans", "root", "")
local api = T.read(
    ROOT .. "shared/PNC/Core/API/PNC_API.lua"
) .. T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/API/PNC_API/DebugCommands.lua"
)
local serverRoute = T.read(
    ROOT .. "server/PNC/Networking/Handlers/"
        .. "PNC_ServerLegacyDebugCommandHandler.lua"
) .. T.read(
    ROOT .. "server/PNC/Networking/Handlers/"
        .. "ServerLegacyDebugCommandHandler/"
        .. "PNC_ServerLegacyDebugCommandHandler_ApiActions.lua"
)
local context = T.read(
    ROOT
        .. "client/PNC/UI/Context/Providers/"
        .. "PNC_ContextProvider_Debug.lua"
)
local window = T.read(
    ROOT
        .. "client/PNC/UI/"
        .. "PNC_AnimationSceneDebugWindow.lua"
)

local actions = {
    "animation_scene_play",
    "animation_scene_pool_step",
    "animation_scene_pool_start",
    "animation_scene_stop",
}

for _, action in ipairs(actions) do
    T.truthy(string.find(api, action, 1, true),
        "API route missing " .. action)
    T.truthy(string.find(serverRoute, action, 1, true),
        "server route missing " .. action)
    T.truthy(string.find(window, action, 1, true),
        "scene lab route missing " .. action)
end

T.truthy(string.find(
    context,
    "Animation Scene Lab",
    1,
    true
), "NPC context menu does not expose scene lab")
T.truthy(string.find(
    window,
    "PNC.AnimationScenes.List()",
    1,
    true
), "scene lab is not driven by the live registry")
T.finish("pnc_animation_scene_debug_routes_smoke")
