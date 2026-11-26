-- Built-in Puppet Opera scene definitions.
-- The parent module owns normalization, validation, and the public registry.
PNC = PNC or {}
PNC.Choreography = PNC.Choreography or {}

local Registry = PNC.Choreography.Blueprints
if type(Registry) ~= "table" or type(Registry.Register) ~= "function" then
    return false
end

local defaultBlueprint = {
    id = "social.kiss_test",
    version = 2,
    legacy = true,
    labelKey = "UI_PNC_Choreography_KissTest",
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
            disableCollision = true,
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
            allowOverlap = true,
            searchRadius = 3,
            interactionDistance = 0.55,
            movementStopDistance = 0.20,
            arrivalTolerance = 0.20,
            anchors = anchors,
        },
        beats = {
            {
                id = "kiss",
                durationMs = 900,
                disableCollision = true,
                synchronization = "arrival_and_start_barrier",
                tracks = tracks,
            },
        },
        triggers = {
            {
                event = "social_kiss",
                priority = 50,
                cooldownSec = 60,
                filters = { minAffinity = 50 },
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

-- Showcase v3 Blueprint 1: NPC-to-NPC Incapacitated Teammate Carry
Registry.Register("rescue.carry_incapacitated_npc", {
    id = "rescue.carry_incapacitated_npc",
    version = 3,
    definitionType = "opera",
    sceneType = "npc_rescue_carry",
    label = "Rescue Carry (Incapacitated NPC)",
    description = "Rescuer lifts and carries an incapacitated teammate using tethered locomotive beats and emergency combat drop.",
    actors = {
        actor_1 = {
            kind = "nearby_live_npc",
            allowedKinds = { "nearby_live_npc" },
            required = true,
            anchor = "carrier",
            label = "Carrier",
            allowedInitialStates = { "standing" },
        },
        actor_2 = {
            kind = "nearby_live_npc",
            allowedKinds = { "nearby_live_npc" },
            required = true,
            anchor = "passenger",
            label = "Incapacitated Teammate",
            stationary = true,
            allowedInitialStates = { "incapacitated", "standing" },
            coupling = {
                attachTo = "actor_1",
                offsetRight = 0,
                offsetForward = 0,
                offsetZ = 0,
                facingMode = "match",
                disableCollision = true,
                groundedCheck = false,
                blockVaulting = true,
                abstractCoMove = true,
            },
        },
    },
    anchorFrame = {
        origin = "target_actor",
        originActor = "actor_2",
        orientation = "lead_facing",
        tolerance = 0.75,
        allowOverlap = true,
        searchRadius = 3,
        movementStopDistance = 0.35,
        arrivalTolerance = 0.55,
        anchors = {
            carrier = { right = 0, forward = -0.45, z = 0, faceTarget = "actor_2" },
            passenger = { right = 0, forward = 0, z = 0, faceTarget = "actor_1" },
        },
    },
    beats = {
        {
            id = "lift",
            durationMs = 700,
            mode = "timed",
            phaseLock = "leader_track",
            tetherActive = true,
            disableCollision = true,
            interruptPolicy = "emergency_drop",
            tracks = {
                actor_1 = {
                    route = "anim_vars",
                    style = "carry_shoulder",
                    role = "Carrier",
                    phase = "lift",
                    clip = "PNC_CarryShoulderLift",
                },
                actor_2 = {
                    route = "anim_vars",
                    style = "carry_shoulder",
                    role = "Passenger",
                    phase = "lift",
                    clip = "PNC_CarriedShoulderLift",
                },
            },
        },
        {
            id = "carry",
            durationMs = 2000,
            mode = "locomotive",
            phaseLock = "leader_track",
            tetherActive = true,
            disableCollision = true,
            interruptPolicy = "emergency_drop",
            tracks = {
                actor_1 = {
                    route = "anim_vars",
                    style = "carry_shoulder",
                    role = "Carrier",
                    phase = "carry",
                    clip = "PNC_CarryShoulderWalk",
                },
                actor_2 = {
                    route = "anim_vars",
                    style = "carry_shoulder",
                    role = "Passenger",
                    phase = "carry",
                    clip = "PNC_CarriedShoulderWalk",
                },
            },
        },
        {
            id = "lower",
            durationMs = 600,
            mode = "timed",
            phaseLock = "leader_track",
            tetherActive = true,
            disableCollision = true,
            interruptPolicy = "emergency_drop",
            tracks = {
                actor_1 = {
                    route = "anim_vars",
                    style = "carry_shoulder",
                    role = "Carrier",
                    phase = "lower",
                    clip = "PNC_CarryShoulderLower",
                },
                actor_2 = {
                    route = "anim_vars",
                    style = "carry_shoulder",
                    role = "Passenger",
                    phase = "lower",
                    clip = "PNC_CarriedShoulderLower",
                },
            },
        },
    },
    triggers = {
        {
            event = "teammate_incapacitated",
            priority = 90,
            cooldownSec = 10,
            filters = { sameFaction = true, allowPlayer = false },
        },
    },
    playback = { defaultMode = "once", allowLoop = false, gapMs = 100 },
})

-- Showcase v3 Blueprint 2: Holding Hands (Grounded Side-by-Side Locomotive)
Registry.Register("social.hold_hands", {
    id = "social.hold_hands",
    version = 3,
    definitionType = "opera",
    sceneType = "social_handhold",
    label = "Hold Hands Walk",
    description = "Two actors walk side-by-side with grounded collision validation and phase-locked handhold animation.",
    actors = {
        actor_1 = {
            allowedKinds = { "local_player", "nearby_live_npc" },
            required = true,
            anchor = "left",
            label = "Leader",
        },
        actor_2 = {
            allowedKinds = { "local_player", "nearby_live_npc" },
            required = true,
            anchor = "right",
            label = "Partner",
            coupling = {
                attachTo = "actor_1",
                offsetRight = 0.55,
                offsetForward = 0,
                offsetZ = 0,
                facingMode = "match",
                disableCollision = true,
                groundedCheck = true,
                blockVaulting = true,
                abstractCoMove = true,
            },
        },
    },
    anchorFrame = {
        origin = "lead_actor",
        orientation = "lead_facing",
        tolerance = 0.75,
        allowOverlap = true,
        anchors = {
            left = { right = 0, forward = 0, z = 0, faceTarget = "actor_2" },
            right = { right = 0.55, forward = 0, z = 0, faceTarget = "actor_1" },
        },
    },
    beats = {
        {
            id = "walk_together",
            durationMs = 1500,
            mode = "locomotive",
            phaseLock = "leader_track",
            tetherActive = true,
            tracks = {
                actor_1 = {
                    byKind = {
                        local_player = {
                            route = "anim_vars",
                            style = "carry_handhold",
                            role = "Carrier",
                            phase = "carry",
                            clip = "PNC_CarryHandholdWalk",
                        },
                        nearby_live_npc = {
                            route = "anim_vars",
                            style = "carry_handhold",
                            role = "Carrier",
                            phase = "carry",
                            clip = "PNC_CarryHandholdWalk",
                        },
                    },
                },
                actor_2 = {
                    byKind = {
                        local_player = {
                            route = "anim_vars",
                            style = "carry_handhold",
                            role = "Passenger",
                            phase = "carry",
                            clip = "PNC_CarriedHandholdWalk",
                        },
                        nearby_live_npc = {
                            route = "anim_vars",
                            style = "carry_handhold",
                            role = "Passenger",
                            phase = "carry",
                            clip = "PNC_CarriedHandholdWalk",
                        },
                    },
                },
            },
        },
    },
    triggers = {
        {
            event = "escort_handhold",
            priority = 60,
            cooldownSec = 30,
            filters = { minAffinity = 40 },
        },
    },
    playback = { defaultMode = "loop", allowLoop = true, gapMs = 100 },
})

-- Showcase v3 Blueprint 3: Partner Dance (Sustained Phase-Locked Loop)
Registry.Register("social.dance_pair", {
    id = "social.dance_pair",
    version = 3,
    definitionType = "opera",
    sceneType = "social_dance",
    label = "Partner Dance",
    description = "Two actors face each other at sub-tile spacing and loop a phase-locked partner dance.",
    actors = {
        actor_1 = {
            allowedKinds = { "local_player", "nearby_live_npc" },
            required = true,
            anchor = "left",
            label = "Dancer 1",
        },
        actor_2 = {
            allowedKinds = { "local_player", "nearby_live_npc" },
            required = true,
            anchor = "right",
            label = "Dancer 2",
        },
    },
    anchorFrame = {
        origin = "lead_actor",
        orientation = "lead_facing",
        tolerance = 0.75,
        allowOverlap = true,
        anchors = {
            left = { right = -0.30, forward = 0, z = 0, faceTarget = "actor_2" },
            right = { right = 0.30, forward = 0, z = 0, faceTarget = "actor_1" },
        },
    },
    beats = {
        {
            id = "dance_loop",
            durationMs = 2400,
            mode = "sustained",
            phaseLock = "server_clock",
            disableCollision = true,
            tracks = {
                actor_1 = {
                    byKind = {
                        local_player = {
                            route = "anim_vars",
                            style = "partner_dance",
                            role = "Lead",
                            phase = "loop",
                            clip = "PNC_DanceLead",
                        },
                        nearby_live_npc = {
                            route = "anim_vars",
                            style = "partner_dance",
                            role = "Lead",
                            phase = "loop",
                            clip = "PNC_DanceLead",
                        },
                    },
                },
                actor_2 = {
                    byKind = {
                        local_player = {
                            route = "anim_vars",
                            style = "partner_dance",
                            role = "Follow",
                            phase = "loop",
                            clip = "PNC_DanceFollow",
                        },
                        nearby_live_npc = {
                            route = "anim_vars",
                            style = "partner_dance",
                            role = "Follow",
                            phase = "loop",
                            clip = "PNC_DanceFollow",
                        },
                    },
                },
            },
        },
    },
    triggers = {
        {
            event = "camp_dance",
            priority = 55,
            cooldownSec = 120,
            filters = { sameFaction = true },
        },
    },
    playback = { defaultMode = "loop", allowLoop = true, gapMs = 150 },
})

return true

