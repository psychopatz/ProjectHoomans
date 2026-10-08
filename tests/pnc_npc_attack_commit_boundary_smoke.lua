local T = require "tests/support/test"

local detail = {
    outcome = "authorization_rejected",
    reason = "npc_target_not_allowed",
}
local applyCalls = 0

PNC = {
    Core = {
        IsAuthority = function() return true end,
    },
    Const = {
        MELEE_RANGE = 1.3,
    },
    Combat = {
        Internal = {
            AttackExecution = {},
        },
    },
    CombatResolution = {},
    CombatUnarmed = {},
    Perception = {},
    Skills = {
        AddXP = function() end,
    },
    Stamina = {
        SpendAttack = function() end,
    },
}

local records = {
    hostile = {
        id = "hostile",
        alive = true,
        x = 2,
        y = 0,
        z = 0,
    },
}
PNC.Registry = {
    Get = function(id) return records[id] end,
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/AttackExecution/PNC_AttackExecution_Targeting.lua"
)

local targetRef = PNC.Combat.Internal.AttackExecution.captureTargetRef({
    kind = "npc",
    id = "hostile",
    x = 2,
    y = 0,
    z = 0,
    groupAlert = true,
    ownerDefense = true,
    alertSequence = 17,
    alertRadius = 8,
    alertOnly = false,
    immediateSelfDefense = true,
})
local resolvedTarget =
    PNC.Combat.Internal.AttackExecution.resolveActionTarget(targetRef)

T.truthy(resolvedTarget, "NPC target resolves from the committed reference")
T.truthy(resolvedTarget.groupAlert,
    "committed reference keeps group-alert evidence")
T.truthy(resolvedTarget.ownerDefense,
    "committed reference keeps owner-defense evidence")
T.equal(resolvedTarget.alertSequence, 17,
    "committed reference keeps the alert sequence")
T.truthy(resolvedTarget.immediateSelfDefense,
    "committed reference keeps immediate self-defense evidence")

local Resolution = PNC.CombatResolution
local Internal = PNC.Combat.Internal
local AttackExecution = Internal.AttackExecution
local record = { id = "attacker", runtime = {} }

Internal.resolveWeaponItem = function() return nil end
AttackExecution.applyWeaponWear = function() end
Resolution.ApplyTargetDamage = function()
    applyCalls = applyCalls + 1
    return false, "npc_damage_rejected", detail
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Combat/AttackExecution/PNC_AttackExecution_HitResolution.lua"
)

local applied, reason, returnedDetail =
    Internal.applyAttackActionHit(
        record,
        {},
        {
            attackType = "melee",
            attackKind = "melee",
            damage = 8,
            skillID = "Axe",
        },
        resolvedTarget
    )
T.falsy(applied, "rejected NPC melee hit remains rejected")
T.equal(reason, "npc_damage_rejected",
    "NPC melee hit keeps the stable rejection reason")
T.equal(returnedDetail, detail,
    "NPC melee hit preserves the detailed damage result")

Resolution.ApplyTargetDamage = function()
    applyCalls = applyCalls + 1
    return true, "hit_npc", { outcome = "wounded", damage = 12 }
end
local rangedApplied, rangedReason, rangedDetail =
    Internal.applyAttackActionHit(
        record,
        {},
        {
            attackType = "ranged",
            attackKind = "ranged",
            ammoConsumed = true,
            damage = 12,
            skillID = "Aiming",
        },
        resolvedTarget
    )
T.truthy(rangedApplied, "NPC ranged hit reaches the damage resolver")
T.equal(rangedReason, "hit_npc",
    "NPC ranged hit keeps the applied reason")
T.equal(rangedDetail.outcome, "wounded",
    "NPC ranged hit preserves the detailed damage result")
T.equal(applyCalls, 2, "both NPC attack lanes call the damage resolver")

T.finish("pnc_npc_attack_commit_boundary_smoke")
