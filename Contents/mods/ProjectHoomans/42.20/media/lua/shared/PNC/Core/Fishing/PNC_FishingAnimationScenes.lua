-- Live fishing presentation. Simulation and inventory mutation remain owned
-- by the server fishing service; this scene only drives the NPC pose.

PNC = PNC or {}

local Scenes = PNC.AnimationScenes
if not Scenes or not Scenes.Register then return false end

local function tr(key)
    return getText and getText(key) or key
end

Scenes.Register("fishing.cast", {
    label = tr("UI_PNC_FishingScene_Cast"),
    description = tr("UI_PNC_FishingScene_CastDescription"),
    category = "fishing",
    priority = 40,
    repeatMode = "loop",
    blocking = false,
    steps = {
        { id = "cast_idle", bump = "FishingSpearIdle", durationMs = 0 },
    },
    interrupts = {
        movement = true,
        combat = true,
        externalBump = true,
        abstract = true,
    },
    onTick = function(record, zombie)
        local order = record and record.orderSpec or nil
        local fishing = record and record.runtime
            and record.runtime.fishing or nil
        if not order or tostring(order.kind or "") ~= "fishing"
            or not fishing or not zombie
        then
            return false
        end
        if zombie.faceLocationF and fishing.waterX and fishing.waterY then
            pcall(zombie.faceLocationF, zombie,
                fishing.waterX, fishing.waterY)
        end
        return true
    end,
})

return true
