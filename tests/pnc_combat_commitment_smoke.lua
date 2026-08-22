local T = require "tests/support/test"

local FILE =
    T.path("ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_Behavior_Combat.lua")

local handApplications = 0
local attackPumps = 0
local movementHolds = 0
local keepActionActive = true

PNC = {
    Core = {
        Now = function() return 1000 end,
        LogRecordDebug = function() end,
    },
    Const = {},
    Combat = {
        Internal = {
            ATTACK_TIMINGS = {
                ranged = { duration = 620 },
            },
        },
        HasActiveAttack = function()
            return true
        end,
        PumpAttackAction = function(record)
            attackPumps = attackPumps + 1
            if not keepActionActive then
                record.runtime.attackAction = nil
                return false, "attack_finished"
            end
            return true, "attack_in_progress"
        end,
    },
    Equipment = {
        Describe = function()
            return {
                combatModeResolved = "melee",
                weaponStatus = "equipped_onehanded",
            }
        end,
        ApplyCombatState = function(_, _, attackMode)
            T.truthy(attackMode == true,
                "committed attack attempted to holster its weapon")
            handApplications = handApplications + 1
            return true
        end,
    },
    CombatTactics = {},
    BehaviorCommon = {
        HaltMovement = function()
            movementHolds = movementHolds + 1
        end,
        SetCombatDebug = function() end,
    },
    PathService = {},
}

T.load(FILE)

local record = {
    weaponMode = "melee",
    runtime = {
        attackAction = {
            finishAt = 1500,
        },
        -- A transiently empty target is the regression case: the committed
        -- action must still finish independently of fresh perception.
        target = nil,
    },
}

T.truthy(PNC.BehaviorCombat.TickCommittedAction(record, {}) == true,
    "committed attack did not retain behavior ownership")
T.truthy(handApplications == 1,
    "committed attack did not maintain combat hands")
T.truthy(attackPumps == 1,
    "committed attack was not pumped without a fresh target")
T.truthy(movementHolds == 1,
    "committed attack did not retain its movement hold")

keepActionActive = false
record.runtime.attackAction = {
    finishAt = 900,
}
T.truthy(PNC.BehaviorCombat.TickCommittedAction(record, {}) == false,
    "finished attack retained behavior ownership")
T.truthy(record.runtime.attackAction == nil,
    "finished attack was not cleared without a fresh target")
T.truthy(attackPumps == 2,
    "expired committed attack skipped its finish pump")

local behaviorSource = T.read(
    "ProjectHoomans", "shared", "PNC/Core/Behaviors/PNC_BehaviorSystem.lua"
)
local committedAt = T.truthy(string.find(
    behaviorSource,
    "Combat.TickCommittedAction(record, zombie)",
    1,
    true
))
local treatmentAt = T.truthy(string.find(
    behaviorSource,
    "Treatment.Tick(record, zombie, now)",
    1,
    true
))
T.truthy(committedAt < treatmentAt,
    "self-treatment can preempt a committed attack")
T.finish("pnc_combat_commitment_smoke")

T.finish("pnc_combat_commitment_smoke")
