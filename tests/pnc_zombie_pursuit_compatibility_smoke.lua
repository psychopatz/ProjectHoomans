local T = require "tests/support/test"

local now = 1000
PNC = {
    Core = {
        Now = function() return now end,
    },
    Const = {
        ZOMBIE_NPC_AGGRO_LEASE_MS = 8000,
    },
    Registry = {},
    Stealth = {},
    Sandbox = {},
}

local zombie = {
    modData = {},
    getModData = function(self) return self.modData end,
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Zombies/PNC_ZombieAggro_State.lua"
)

local pursuit = PNC.ZombieAggro.Pursuit
local acquired, revision

acquired, revision = pursuit.TryAcquire(
    zombie, "ProjectHoomans", "Hoomans", "npc-1", now, 8000,
    100, "hoomans_npc"
)
T.truthy(acquired, "Hoomans should acquire an empty lease")
T.equal(revision, 1, "first lease revision")
T.equal(pursuit.GetLease(zombie, now).priority, 100,
    "Hoomans priority should be recorded")

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
