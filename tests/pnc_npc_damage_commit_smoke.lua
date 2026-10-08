local T = require "tests/support/test"

T.addPackagePaths()

local now = 1000
local authority = true
local dirty = {}

PNC = {
    Core = {
        Now = function() return now end,
        IsAuthority = function() return authority end,
        Clamp = function(value, minimum, maximum)
            return math.max(minimum, math.min(maximum, value))
        end,
    },
    Const = {
        DEFAULT_HP_MAX = 100,
        RECENT_DAMAGE_SHOW_MS = 4000,
        DEBUG_COMBAT_HOLD_MS = 1000,
        INCAPACITATED_GRACE_MS = 1000,
    },
    Sandbox = {
        CanZombieTargetRecord = function() return true end,
    },
    Registry = {
        MarkDirty = function(record, domain)
            dirty[record.id] = domain
        end,
    },
    Health = { Internal = {} },
    NPCWounds = { Internal = {} },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Health/PNC_Health/PNC_Health_LiveState.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Health/PNC_Health/PNC_Health_Damage.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Definitions.lua"
)

PNC.NPCWounds.Ensure = function(record)
    local health = PNC.Health.Ensure(record)
    return health.body
end
PNC.NPCWounds.Recalculate = function() end
PNC.NPCWounds.HasActiveInfection = function() return false end
PNC.NPCWounds.Internal.Events = { emit = function() end }
PNC.NPCWounds.Internal.EventTypes = { NPC_WOUNDED = "npc_wounded" }

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Mutation.lua"
)

local function makeRecord(id)
    return {
        id = id,
        alive = true,
        presenceState = "live",
        runtime = {},
        health = {
            current = 100,
            max = 100,
            state = "normal",
            downedAt = 0,
        },
    }
end

local function liveBody()
    return { isDead = function() return false end }
end

local function deadBody()
    return { isDead = function() return true end }
end

local target = makeRecord("hostile")
local applied, detail = PNC.NPCWounds.ApplyCombatDamage(
    target,
    liveBody(),
    {
        amount = 10,
        partId = "Torso_Upper",
        type = "combat_melee",
        woundType = "scratch",
        attackerKind = "npc",
        attackerID = "follower",
    }
)
T.truthy(applied, "NPC melee damage reaches the health writer")
T.equal(target.health.current, 90, "NPC melee damage reduces target HP")
T.equal(detail.outcome, "wounded", "accepted damage returns a wound outcome")
T.equal(detail.healthState, "normal", "accepted damage reports health state")
T.truthy(target.health.body.wounds.Torso_Upper,
    "accepted damage creates the corresponding wound")

target = makeRecord("ranged_target")
applied, detail = PNC.NPCWounds.ApplyCombatDamage(
    target,
    liveBody(),
    {
        amount = 12,
        partId = "Torso_Upper",
        type = "combat_ranged",
        attackType = "ranged",
        attackKind = "ranged",
        woundType = "laceration",
        weaponFullType = "Base.Pistol",
        attackerKind = "npc",
        attackerID = "shooter",
    }
)
T.truthy(applied, "ranged NPC damage reaches the same authority writer")
T.equal(detail.woundType, "bullet",
    "ranged damage is normalized to a bullet at the wound boundary")
T.equal(target.health.body.wounds.Torso_Upper.type, "bullet",
    "ranged wound storage keeps the bullet type")

target = makeRecord("dead_body_target")
applied, detail = PNC.NPCWounds.ApplyCombatDamage(
    target,
    deadBody(),
    { amount = 10, partId = "Torso_Upper", attackerKind = "npc" }
)
T.falsy(applied, "dead engine body rejects NPC damage")
T.equal(detail.reason, "dead_body", "dead body rejection is preserved")

target = makeRecord("downed_target")
target.health.state = "incapacitated"
target.health.downedAt = now
applied, detail = PNC.NPCWounds.ApplyCombatDamage(
    target,
    liveBody(),
    { amount = 10, partId = "Torso_Upper", attackerKind = "npc" }
)
T.falsy(applied, "incapacitated grace rejects immediate follow-up damage")
T.equal(detail.reason, "incapacitated_grace",
    "incapacitated grace rejection is preserved")

authority = false
target = makeRecord("client_target")
applied, detail = PNC.NPCWounds.ApplyCombatDamage(
    target,
    liveBody(),
    { amount = 10, partId = "Torso_Upper", attackerKind = "npc" }
)
T.falsy(applied, "non-authority cannot mutate NPC health")
T.equal(detail.reason, "not_authority",
    "authority rejection is preserved")

T.finish("pnc_npc_damage_commit_smoke")
