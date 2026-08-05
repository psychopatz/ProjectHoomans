local function readAll(path)
    local file = assert(io.open(path, "r"))
    local contents = file:read("*a")
    file:close()
    return contents
end

local ROOT =
    "Contents/mods/ProjectHoomans/42.20/media/lua/"
local api = readAll(
    ROOT .. "shared/PNC/Core/API/PNC_API.lua"
)
local server = readAll(
    ROOT .. "server/PNC/PNC_Server.lua"
)
local context = readAll(
    ROOT
        .. "client/PNC/UI/Context/Providers/"
        .. "PNC_ContextProvider_Debug.lua"
)
local window = readAll(
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
    assert(string.find(api, action, 1, true),
        "API route missing " .. action)
    assert(string.find(server, action, 1, true),
        "server route missing " .. action)
    assert(string.find(window, action, 1, true),
        "scene lab route missing " .. action)
end

assert(string.find(
    context,
    "Animation Scene Lab",
    1,
    true
), "NPC context menu does not expose scene lab")
assert(string.find(
    window,
    "PNC.AnimationScenes.List()",
    1,
    true
), "scene lab is not driven by the live registry")

print("pnc_animation_scene_debug_routes_smoke: ok")
