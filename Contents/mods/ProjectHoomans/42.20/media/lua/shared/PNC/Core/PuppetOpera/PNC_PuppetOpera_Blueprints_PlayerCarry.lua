-- Built-in Puppet Opera blueprints for all 6 paired carry/assist interactions:
-- Princess Carry, Piggyback, Shoulder Carry, Hold Hands, Back Drag, and
-- Support Injured Partner.
--
-- Driven exclusively by Project Hoomans' native `PNC_Anim*` AnimSet variables
-- and `PNC_Carry*` / `PNC_Carried*` clips under `common/media/anims_X/Bob/PNC_Carry`
-- and `common/media/AnimSets/{player,zombie}/*`, so zero external mods are
-- required and there are no AnimVar conflicts with other mods.

PNC = PNC or {}
PNC.PuppetOpera = PNC.PuppetOpera or {}
PNC.PuppetOpera.Blueprints = PNC.PuppetOpera.Blueprints or {}

local Registry = PNC.PuppetOpera.Blueprints

local function operaCarryTrack(style, role, phase, clip)
    return {
        route = "anim_vars",
        style = "carry_" .. style,
        role = role,
        phase = phase,
        clip = clip,
    }
end

local function registerCarryVariant(spec, isNPCCarrier)
    local style = spec.style
    local idPrefix = isNPCCarrier and "carry_npc." or "carry."
    local labelPrefix = isNPCCarrier and "NPC Carry: " or "Carry: "
    local carrierKind = isNPCCarrier and "nearby_live_npc" or "local_player"
    local carrierAllowed = isNPCCarrier
        and { "nearby_live_npc" }
        or { "local_player" }
    Registry.Register(idPrefix .. style, {
        id = idPrefix .. style,
        version = 3,
        definitionType = "opera",
        sceneType = "pnc_carry_" .. style,
        label = labelPrefix .. spec.label,
        description = spec.description,
        actors = {
            actor_1 = {
                kind = carrierKind,
                allowedKinds = carrierAllowed,
                required = true,
                anchor = "carrier",
                label = isNPCCarrier and "Carrier NPC" or "Carrier",
                allowedInitialStates = { "standing" },
            },
            actor_2 = {
                kind = "nearby_live_npc",
                allowedKinds = { "nearby_live_npc" },
                required = true,
                anchor = "passenger",
                label = spec.partnerLabel or "Partner",
                stationary = true,
                allowedInitialStates = spec.allowDowned
                    and { "standing", "incapacitated" }
                    or { "standing" },
                coupling = {
                    attachTo = "actor_1",
                    offsetRight = spec.offsetRight or 0,
                    offsetForward = spec.offsetForward or 0,
                    offsetZ = 0,
                    facingMode = "match",
                    disableCollision = true,
                    groundedCheck = spec.grounded == true,
                    blockVaulting = true,
                    abstractCoMove = true,
                },
            },
        },
        anchorFrame = {
            origin = "target_actor",
            originActor = "actor_2",
            orientation = "player_facing",
            tolerance = 0.75,
            allowOverlap = true,
            searchRadius = 3,
            movementStopDistance = 0.30,
            arrivalTolerance = 0.45,
            anchors = {
                carrier = {
                    right = -(spec.anchorRight or 0),
                    forward = -(spec.anchorForward or 0),
                    z = 0,
                    faceTarget = "actor_2",
                },
                passenger = {
                    right = 0,
                    forward = 0,
                    z = 0,
                    faceTarget = "actor_1",
                },
            },
        },
        beats = {
            {
                id = "lift",
                durationMs = 1800,
                mode = "timed",
                phaseLock = "leader_track",
                tetherActive = true,
                disableCollision = true,
                interruptPolicy = spec.interruptPolicy or "emergency_drop",
                tracks = {
                    actor_1 = operaCarryTrack(style, "Carrier", "lift",
                        spec.liftCarrierClip),
                    actor_2 = operaCarryTrack(style, "Passenger", "lift",
                        spec.liftPassengerClip),
                },
            },
            {
                id = "carry",
                durationMs = 3000,
                mode = "locomotive",
                phaseLock = "leader_track",
                tetherActive = true,
                disableCollision = true,
                interruptPolicy = spec.interruptPolicy or "emergency_drop",
                tracks = {
                    actor_1 = operaCarryTrack(style, "Carrier", "carry",
                        spec.carryClip),
                    actor_2 = operaCarryTrack(style, "Passenger", "carry",
                        spec.passengerClip),
                },
            },
            {
                id = "lower",
                durationMs = 1600,
                mode = "timed",
                phaseLock = "leader_track",
                tetherActive = true,
                disableCollision = true,
                interruptPolicy = spec.interruptPolicy or "emergency_drop",
                tracks = {
                    actor_1 = operaCarryTrack(style, "Carrier", "lower",
                        spec.lowerCarrierClip),
                    actor_2 = operaCarryTrack(style, "Passenger", "lower",
                        spec.lowerPassengerClip),
                },
            },
        },
        playback = {
            defaultMode = "once",
            allowLoop = true,
            gapMs = 0,
        },
    })
end

local function registerCarryBlueprint(spec)
    registerCarryVariant(spec, false)
    registerCarryVariant(spec, true)
end

registerCarryBlueprint({
    style = "princess",
    label = "Princess Carry",
    description = "Cradle carry a partner in both arms (lift, walk/idle, lower).",
    partnerLabel = "Carried Partner",
    grounded = false,
    allowDowned = true,
    anchorForward = 0.65,
    offsetRight = 0,
    offsetForward = 0,
    liftCarrierClip = "PNC_CarryLift",
    liftPassengerClip = "PNC_CarriedLift",
    carryClip = "PNC_CarryWalk",
    passengerClip = "PNC_CarriedWalk",
    lowerCarrierClip = "PNC_CarryLower",
    lowerPassengerClip = "PNC_CarriedLower",
})

registerCarryBlueprint({
    style = "piggyback",
    label = "Piggyback",
    description = "Carry a partner on your back with locomotive tether.",
    partnerLabel = "Passenger",
    grounded = false,
    allowDowned = true,
    anchorForward = -0.70,
    offsetRight = 0,
    offsetForward = 0,
    liftCarrierClip = "PNC_CarryPiggybackLift",
    liftPassengerClip = "PNC_CarriedPiggybackLift",
    carryClip = "PNC_CarryPiggybackWalk",
    passengerClip = "PNC_CarriedPiggybackWalk",
    lowerCarrierClip = "PNC_CarryPiggybackLower",
    lowerPassengerClip = "PNC_CarriedPiggybackLower",
})

registerCarryBlueprint({
    style = "shoulder",
    label = "Shoulder Carry",
    description = "Fireman/shoulder carry a partner (supports injured/downed rescue).",
    partnerLabel = "Carried Partner",
    grounded = false,
    allowDowned = true,
    anchorForward = 0.65,
    offsetRight = 0,
    offsetForward = 0,
    liftCarrierClip = "PNC_CarryShoulderLift",
    liftPassengerClip = "PNC_CarriedShoulderLift",
    carryClip = "PNC_CarryShoulderWalk",
    passengerClip = "PNC_CarriedShoulderWalk",
    lowerCarrierClip = "PNC_CarryShoulderLower",
    lowerPassengerClip = "PNC_CarriedShoulderLower",
})

registerCarryBlueprint({
    style = "handhold",
    label = "Hold Hands",
    description = "Walk side-by-side holding hands (grounded, 0.63-tile spacing).",
    partnerLabel = "Companion",
    grounded = true,
    allowDowned = false,
    anchorRight = -0.63,
    offsetRight = -0.63,
    offsetForward = 0,
    liftCarrierClip = "PNC_CarryHandholdLift",
    liftPassengerClip = "PNC_CarriedHandholdLift",
    carryClip = "PNC_CarryHandholdWalk",
    passengerClip = "PNC_CarriedHandholdWalk",
    lowerCarrierClip = "PNC_CarryHandholdLower",
    lowerPassengerClip = "PNC_CarriedHandholdLower",
    interruptPolicy = "clean_release",
})

registerCarryBlueprint({
    style = "drag",
    label = "Back Drag",
    description = "Drag a downed or incapacitated survivor backward to safety.",
    partnerLabel = "Dragged Survivor",
    grounded = false,
    allowDowned = true,
    stationary = true,
    anchorForward = -0.48,
    offsetRight = 0,
    offsetForward = -0.48,
    liftCarrierClip = "PNC_CarryDragLift",
    liftPassengerClip = "PNC_CarriedDragLift",
    carryClip = "PNC_CarryDragWalk",
    passengerClip = "PNC_CarriedDragWalk",
    lowerCarrierClip = "PNC_CarryDragLower",
    lowerPassengerClip = "PNC_CarriedDragLower",
})

registerCarryBlueprint({
    style = "assist",
    label = "Support Injured Partner",
    description = "Walk side-by-side supporting an injured partner's arm (0.42-tile spacing).",
    partnerLabel = "Injured Partner",
    grounded = true,
    allowDowned = false,
    anchorRight = -0.42,
    offsetRight = -0.42,
    offsetForward = 0,
    liftCarrierClip = "PNC_CarryAssistLift",
    liftPassengerClip = "PNC_CarriedAssistLift",
    carryClip = "PNC_CarryAssistWalk",
    passengerClip = "PNC_CarriedAssistWalk",
    lowerCarrierClip = "PNC_CarryAssistLower",
    lowerPassengerClip = "PNC_CarriedAssistLower",
})

return Registry
