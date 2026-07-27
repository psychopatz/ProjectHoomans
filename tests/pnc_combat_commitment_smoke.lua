local FILE =
    "Contents/mods/ProjectHoomans/42.19/media/lua/shared/PNC/Core/Behaviors/PNC_Behavior_Combat.lua"

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
            assert(attackMode == true,
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

dofile(FILE)

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

assert(PNC.BehaviorCombat.TickCommittedAction(record, {}) == true,
    "committed attack did not retain behavior ownership")
assert(handApplications == 1,
    "committed attack did not maintain combat hands")
assert(attackPumps == 1,
    "committed attack was not pumped without a fresh target")
assert(movementHolds == 1,
    "committed attack did not retain its movement hold")

keepActionActive = false
record.runtime.attackAction = {
    finishAt = 900,
}
assert(PNC.BehaviorCombat.TickCommittedAction(record, {}) == false,
    "finished attack retained behavior ownership")
assert(record.runtime.attackAction == nil,
    "finished attack was not cleared without a fresh target")
assert(attackPumps == 2,
    "expired committed attack skipped its finish pump")

print("pnc_combat_commitment_smoke: ok")
