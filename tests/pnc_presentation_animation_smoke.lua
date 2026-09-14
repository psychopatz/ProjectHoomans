local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Visuals/PNC_PresentationAnimations.lua"
)

local now = 1000
local requests = {}

PNC = {
    Const = { PRESENCE_LIVE = "live" },
    Core = { Now = function() return now end },
    AnimationScenes = {
        Request = function(record, body, sceneID, options)
            requests[#requests + 1] = {
                record = record,
                body = body,
                sceneID = sceneID,
                options = options,
            }
            return true, { id = sceneID }
        end,
    },
    LiveBodyControl = {
        GetActionStateName = function(body)
            return body.actionState or ""
        end,
        IsPresentationCombatActive = function(record)
            return record.combat == true
        end,
        IsSeated = function(record)
            return record.seated == true
        end,
        IsSleeping = function(record)
            return record.sleeping == true
        end,
    },
}

local Presentation = T.load(FILE)
local body = {
    getModData = function()
        return {}
    end,
    isDead = function()
        return false
    end,
}

local function record(extra)
    local value = {
        id = "npc-1",
        alive = true,
        presenceState = "live",
        health = { state = "normal" },
        runtime = {},
    }
    for key, item in pairs(extra or {}) do value[key] = item end
    return value
end

local idle = record()
local started, result = Presentation.Request(
    idle,
    body,
    "greeting.wavehi",
    { now = now, eventID = "message-1" }
)
T.truthy(started, "idle NPC did not accept the presentation reaction")
T.equal(result.id, "social.reaction.wavehi",
    "presentation reaction selected the wrong scene")
T.equal(requests[1].options.durationMs, 2200,
    "presentation reaction did not carry its bounded duration")

local duplicate, duplicateReason = Presentation.Request(
    idle,
    body,
    "greeting.wavehi",
    { now = now, eventID = "message-1" }
)
T.falsy(duplicate, "the same delivered message was presented twice")
T.equal(duplicateReason, "duplicate_event",
    "duplicate presentation did not report its reason")
T.equal(#requests, 1, "duplicate presentation reached the scene arbiter")

local rejected = {
    { record({ runtime = { pathing = { phase = "active" } } }), "movement",
      "moving NPC was not protected" },
    { record({ combat = true }), "combat", "combat NPC was not protected" },
    { record({ seated = true }), "seated", "seated NPC was not protected" },
    { record({ sleeping = true }), "sleeping", "sleeping NPC was not protected" },
    { record({ runtime = { facilityActivity = { kind = "craft" } } }),
      "facility_activity", "facility activity was not protected" },
}
for index = 1, #rejected do
    local item = rejected[index]
    local accepted, reason = Presentation.Request(
        item[1],
        body,
        "greeting.wavehi",
        { now = now, eventID = "rejected-" .. tostring(index) }
    )
    T.falsy(accepted, item[3])
    T.equal(reason, item[2], item[3] .. " reported the wrong reason")
end

body.actionState = "attack"
local attacking, attackReason = Presentation.Request(
    record(),
    body,
    "greeting.wavehi",
    { now = now, eventID = "attack-1" }
)
T.falsy(attacking, "attacking NPC was not protected")
T.equal(attackReason, "action_state",
    "attacking NPC reported the wrong protection reason")

T.finish("pnc_presentation_animation_smoke")
