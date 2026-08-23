local Scene = PNC.ConversationScene

function Scene.EnsureRegistered()
    local scenes = PNC.AnimationScenes
    if not scenes or not scenes.Register then
        return false, "animation_scenes_unavailable"
    end
    if scenes.Get and scenes.Get(Scene.ID) then return true end
    return scenes.Register(Scene.ID, {
        label = "Conversation Idle",
        description = "A subtle, blocking idle used while an NPC is talking.",
        category = "social",
        priority = 45,
        blocking = true,
        repeatMode = "loop",
        stepGapMs = 180,
        stepGapJitterMs = 220,
        steps = {
            {
                id = "shift_weight",
                bump = "ShiftWeight",
                durationMs = 2600,
            },
        },
        interrupts = {
            movement = false,
            combat = true,
            externalBump = true,
            abstract = true,
        },
    })
end
