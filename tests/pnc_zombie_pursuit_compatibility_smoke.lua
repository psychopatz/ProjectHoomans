local T = require "tests/support/test"

local now = 1000
PNC = {
    Core = {
        Now = function() return now end,
        IsManagedNPCBody = function(body)
            return body and body.hoomans == true
        end,
    },
    Const = {
        ZOMBIE_NPC_AGGRO_LEASE_MS = 8000,
        ZOMBIE_NPC_COMMIT_RADIUS = 14.0,
    },
    Registry = {},
    Stealth = {},
    Sandbox = {},
    Compatibility = {
        ActorOwnership = {
            GetForeignOwner = function(body)
                return body and body.foreignOwner or nil
            end,
        },
    },
}

local zombie = {
    modData = {},
    target = nil,
    attackedBy = nil,
    getModData = function(self) return self.modData end,
    getTarget = function(self) return self.target end,
    getAttackedBy = function(self) return self.attackedBy end,
    getActionStateName = function() return "idle" end,
    setTarget = function(self, value) self.target = value end,
    setVariable = function(self, key, value)
        self.variables = self.variables or {}
        self.variables[key] = value
    end,
}

local player = {}
instanceof = function(value, className)
    return className == "IsoPlayer" and value == player
end

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Zombies/PNC_ZombieAggro_State.lua"
)

local pursuit = PNC.ZombieAggro.Pursuit
local targeting = PNC.ZombieAggro.Internal
local acquired, revision

T.truthy(
    targeting.shouldPreferNPCOverPlayer(14 * 14, 2 * 2),
    "an eligible NPC inside the bounded commit radius should beat a closer player"
)
T.falsy(
    targeting.shouldPreferNPCOverPlayer(15 * 15, 2 * 2),
    "an NPC outside the bounded commit radius should not silently override the player"
)

acquired, revision = pursuit.TryAcquire(
    zombie, "ProjectHoomans", "Hoomans", "npc-1", now, 8000,
    100, "hoomans_npc"
)
T.truthy(acquired, "Hoomans should acquire an empty lease")
T.equal(revision, 1, "first lease revision")
T.equal(pursuit.GetLease(zombie, now).priority, 100,
    "Hoomans priority should be recorded")
T.truthy(
    pursuit.CanWriteNative(zombie, "ProjectHoomans", now, 100),
    "the active Hoomans owner may write its native control lane"
)

zombie.target = player
T.truthy(
    pursuit.CanWriteNative(zombie, "ProjectHoomans", now, 100),
    "an idle player target must not block NPC pursuit"
)
T.falsy(
    targeting.ShouldYieldToNativePlayerAttack(zombie, now),
    "an idle player target must not claim the vanilla combat lane"
)
zombie.actionState = "attack"
zombie.getActionStateName = function(self) return self.actionState or "idle" end
T.falsy(
    pursuit.CanWriteNative(zombie, "ProjectHoomans", now, 100),
    "Hoomans must yield once vanilla enters its player attack state"
)
T.truthy(
    targeting.ShouldYieldToNativePlayerAttack(zombie, now),
    "an active native player attack should claim the vanilla combat lane"
)
zombie.actionState = "lunge-network"
T.truthy(
    targeting.ShouldYieldToNativePlayerAttack(zombie, now),
    "a network lunge should claim the vanilla combat lane"
)
T.truthy(
    targeting.BeginNativePlayerHandoff(
        zombie, player, now, "test_player_handoff"
    ),
    "native player handoff should complete"
)
T.equal(zombie.target, player,
    "native player handoff must preserve the player target")
T.equal(zombie.variables.NoLungeAttack, false,
    "native player handoff must restore vanilla lunge control")
T.falsy(
    pursuit.GetLease(zombie, now),
    "native player handoff must release the Hoomans pursuit lease"
)
zombie.target = nil
zombie.actionState = "idle"
targeting.ShouldYieldToNativePlayerAttack(zombie, now + 1)
acquired = pursuit.TryAcquire(
    zombie, "ProjectHoomans", "Hoomans", "npc-1b", now, 8000,
    100, "hoomans_npc"
)
T.truthy(acquired,
    "Hoomans should reacquire its lease after the native player handoff")

zombie.target = { foreignOwner = "Bandits" }
T.equal(
    pursuit.GetNativeTargetOwner(zombie),
    "Bandits",
    "foreign native targets should identify their provider"
)
T.falsy(
    pursuit.CanWriteNative(zombie, "ProjectHoomans", now, 100),
    "Hoomans must not replace a foreign native target"
)
T.falsy(
    targeting.clearZombieTarget(zombie),
    "Hoomans must not clear a foreign native target"
)
T.equal(
    zombie.target.foreignOwner,
    "Bandits",
    "foreign native target must remain untouched"
)
zombie.target = nil
zombie.attackedBy = { foreignOwner = "ProjectALifeNPCs" }
T.equal(
    pursuit.GetNativeTargetOwner(zombie),
    "ProjectALifeNPCs",
    "foreign attackedBy state should also identify its provider"
)
T.falsy(
    pursuit.CanWriteNative(zombie, "ProjectHoomans", now, 100),
    "Hoomans must not clear a foreign attackedBy state"
)
zombie.attackedBy = nil

acquired = pursuit.TryAcquire(
    zombie, "Bandits", "Bandits", "bandit-1", now, 8000,
    60, "bandit_npc"
)
T.falsy(acquired, "Bandits must yield to an active Hoomans lease")
T.truthy(pursuit.ShouldYield(zombie, "Bandits", now, 60),
    "Bandits should observe the Hoomans lease")
T.falsy(pursuit.ShouldYield(zombie, "ProjectHoomans", now, 100),
    "Hoomans should keep its higher-priority lease")

now = 10001
acquired, revision = pursuit.TryAcquire(
    zombie, "Bandits", "Bandits", "bandit-1", now, 8000,
    60, "bandit_npc"
)
T.truthy(acquired, "Bandits should acquire after lease expiry")
T.equal(revision, 1, "replacement lease revision after expiry reset")
T.equal(pursuit.GetLease(zombie, now).owner, "Bandits",
    "Bandits should own the replacement lease")

acquired, revision = pursuit.TryAcquire(
    zombie, "ProjectHoomans", "Hoomans", "npc-2", now, 8000,
    100, "hoomans_npc"
)
T.truthy(acquired, "Hoomans should preempt a lower-priority Bandits lease")
T.equal(revision, 2, "priority preemption revision")

T.falsy(pursuit.Release(zombie, "Bandits"),
    "a foreign owner must not release the active lease")
T.truthy(pursuit.Release(zombie, "ProjectHoomans"),
    "the active owner should release its lease")
T.falsy(pursuit.GetLease(zombie, now), "released lease should be absent")

acquired = pursuit.TryAcquire(
    zombie, "ProjectHoomans", "Hoomans", "npc-3", now, 8000,
    100, "hoomans_npc"
)
T.truthy(acquired, "Hoomans should reacquire after release")
acquired = pursuit.TryAcquire(
    zombie, "Bandits", "Bandits", "bandit-2", now, 8000,
    110, "bandit_npc_bite"
)
T.truthy(acquired, "an active Bandits bite may finish before handoff")
T.truthy(pursuit.ShouldYield(zombie, "ProjectHoomans", now, 100),
    "Hoomans should yield during the protected Bandits bite")

T.finish("pnc_zombie_pursuit_compatibility_smoke")
