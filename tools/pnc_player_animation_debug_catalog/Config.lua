local Provider = {}

function Provider.build(arguments)
    local pzRoot = arguments and arguments[1] or os.getenv("PZ_ROOT")
    assert(pzRoot and pzRoot ~= "", "missing Project Zomboid root argument")
    pzRoot = string.gsub(pzRoot, "/+$", "")

    local outputPath = arguments and arguments[2]
        or "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Debug/"
            .. "PNC_PlayerAnimationDebugCatalog.lua"
    local modRoot = arguments and arguments[3]
        or os.getenv("PNC_MOD_ROOT") or "Contents/mods/ProjectHoomans"
    local commonRoot = modRoot .. "/common"

    return {
        pzRoot = pzRoot,
        outputPath = outputPath,
        modRoot = modRoot,
        commonRoot = commonRoot,
        bridgeRoot = commonRoot .. "/media/AnimSets/player/actions",
        bridgeMediaRoot = "media/AnimSets/player/actions/",
        emoteBridgeRoot = commonRoot .. "/media/AnimSets/player/emote",
        emoteBridgeMediaRoot = "media/AnimSets/player/emote/",
        sourceSpecs = {
            {
                id = "native_actions",
                source = "player_native",
                folder = "actions",
                statePrefix = "player/actions",
                sourceRoot = pzRoot .. "/media/AnimSets/player/actions",
                mediaRoot = "media/AnimSets/player/actions/",
                minDepth = 1,
            },
            {
                id = "native_emotes",
                source = "player_native",
                folder = "emote",
                statePrefix = "player/emote",
                sourceRoot = pzRoot .. "/media/AnimSets/player/emote",
                mediaRoot = "media/AnimSets/player/emote/",
                minDepth = 1,
            },
            {
                id = "mod_player",
                source = "player_mod",
                statePrefix = "player",
                sourceRoot = commonRoot .. "/media/AnimSets/player",
                mediaRoot = "media/AnimSets/player/",
                minDepth = 2,
            },
            {
                id = "mod_zombie",
                source = "zombie",
                statePrefix = "zombie",
                sourceRoot = commonRoot .. "/media/AnimSets/zombie",
                mediaRoot = "media/AnimSets/zombie/",
                minDepth = 2,
            },
        },
    }
end

return Provider
