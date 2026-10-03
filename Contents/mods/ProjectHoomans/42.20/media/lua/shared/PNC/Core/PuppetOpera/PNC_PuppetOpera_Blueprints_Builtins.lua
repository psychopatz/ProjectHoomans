-- Built-in Puppet Opera scene definitions.
-- The parent module owns normalization, validation, and the public registry.
PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}

local Registry = PNC.PuppetOpera.Blueprints
if type(Registry) ~= "table" or type(Registry.Register) ~= "function" then
    return false
end

local defaultBlueprint = {
    id = "social.kiss_test",
    version = 2,
    legacy = true,
    labelKey = "UI_PNC_PuppetOpera_KissTest",
    description = "Two actors walk to opposing anchors and play a synchronized social beat.",
    actors = {
        actor_1 = {
            allowedKinds = { "local_player", "nearby_live_npc" },
            required = true,
            anchor = "left",
            label = "Actor 1",
        },
        actor_2 = {
            allowedKinds = { "local_player", "nearby_live_npc" },
            required = true,
            anchor = "right",
            label = "Actor 2",
        },
    },
    anchorFrame = {
        origin = "server_player_relative",
        orientation = "player_facing",
        tolerance = 0.75,
        anchors = {
            left = {
                right = -1,
                forward = 0,
                z = 0,
                faceTarget = "actor_2",
            },
            right = {
                right = 1,
                forward = 0,
                z = 0,
                faceTarget = "actor_1",
            },
        },
    },
    beats = {
        {
            id = "kiss",
            durationMs = 900,
            synchronization = "arrival_and_start_barrier",
            tracks = {
                actor_1 = {
                    byKind = {
                        local_player = {
                            route = "player_action",
                            catalog = "player",
                            entryId = "player.player_native.RemoveBush.RemoveBush",
                            action = "RemoveBush",
                            animation = "Bob_Shove",
                        },
                        nearby_live_npc = {
                            route = "zombie_bump",
                            catalog = "npc",
                            entryId = "npc.bumped.PNC_Anim_WaveHi.PNC_Anim_WaveHi",
                            bump = "PNC_WaveHi",
                            animation = "Bob_EmoteWaveHi",
                            nonCombat = true,
                        },
                    },
                },
                actor_2 = {
                    byKind = {
                        local_player = {
                            route = "player_action",
                            catalog = "player",
                            entryId = "player.player_native.RemoveBush.RemoveBush",
                            action = "RemoveBush",
                            animation = "Bob_Shove",
                        },
                        nearby_live_npc = {
                            route = "zombie_bump",
                            catalog = "npc",
                            entryId = "npc.bumped.PNC_Anim_WaveHi.PNC_Anim_WaveHi",
                            bump = "PNC_WaveHi",
                            animation = "Bob_EmoteWaveHi",
                            nonCombat = true,
                        },
                    },
                },
            },
        },
    },
    playback = {
        defaultMode = "once",
        allowLoop = true,
        gapMs = 250,
    },
}

Registry.Definitions = Registry.Definitions or {}
Registry.Register(defaultBlueprint.id, defaultBlueprint)

local function dedicatedKissBlueprint(id, label, sceneType, actorKinds)
    local tracks = {}
    local actorDefinitions = {}
    local anchors = {
        left = {
            right = 0,
            forward = 0,
            z = 0,
            faceTarget = "actor_2",
        },
        right = {
            right = 1,
            forward = 0,
            z = 0,
            faceTarget = "actor_1",
        },
    }
    for index, actorKind in ipairs(actorKinds) do
        local actorID = "actor_" .. tostring(index)
        local anchor = index == 1 and "left" or "right"
        actorDefinitions[actorID] = {
            kind = actorKind,
            allowedKinds = { actorKind },
            required = true,
            anchor = anchor,
            label = "Actor " .. tostring(index),
        }
        if actorKind == "local_player" then
            tracks[actorID] = {
                route = "player_emote",
                mode = "emote",
                catalog = "player",
                entryId = "player.player_native.wavehi.wavehi",
                emote = "wavehi",
                animation = "Bob_EmoteWaveHi",
            }
        else
            tracks[actorID] = {
                route = "zombie_bump",
                catalog = "npc",
                entryId = "npc.bumped.PNC_Anim_WaveHi.PNC_Anim_WaveHi",
                bump = "PNC_WaveHi",
                animation = "Bob_EmoteWaveHi",
                nonCombat = true,
            }
        end
    end
    return {
        id = id,
        version = 1,
        definitionType = "opera",
        sceneType = sceneType,
        label = label,
        description = "Dedicated two-actor kiss scene with explicit actor routes.",
        actors = actorDefinitions,
        anchorFrame = {
            origin = "server_player_relative",
            orientation = "player_facing",
            tolerance = 0.75,
            interactionDistance = 0.55,
            movementStopDistance = 0.20,
            arrivalTolerance = 0.20,
            anchors = anchors,
        },
        beats = {
            {
                id = "kiss",
                durationMs = 900,
                synchronization = "arrival_and_start_barrier",
                tracks = tracks,
            },
        },
        playback = {
            defaultMode = "once",
            allowLoop = true,
            gapMs = 250,
        },
    }
end

local playerNPCKiss = dedicatedKissBlueprint(
    "social.kiss_player_npc",
    "Player and NPC Kiss",
    "player_npc_kiss",
    { "local_player", "nearby_live_npc" }
)
local npcNPCKiss = dedicatedKissBlueprint(
    "social.kiss_npc_npc",
    "NPC and NPC Kiss",
    "npc_npc_kiss",
    { "nearby_live_npc", "nearby_live_npc" }
)
Registry.Register(playerNPCKiss.id, playerNPCKiss)
Registry.Register(npcNPCKiss.id, npcNPCKiss)

return true

