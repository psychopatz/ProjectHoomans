PNC = PNC or {}
PNC.Const = PNC.Const or {}

local Const = PNC.Const

Const.CLIENT_INTERP_BASE_MS = 150
Const.CLIENT_INTERP_MOVE_MIN_MS = 200
Const.CLIENT_INTERP_STALE_MS = 2200
Const.CLIENT_INTERP_SNAP_DISTANCE = 5.0
Const.CLIENT_FACING_REASSERT_MS = 220
Const.CLIENT_LOCOMOTION_FACING_MS = 40
Const.CLIENT_BODY_SCAN_MS = 750
Const.CLIENT_BODY_SCAN_UNRESOLVED_MS = 200
Const.CLIENT_LOCAL_SNAPSHOT_SCAN_MS = 50
Const.CLIENT_LOCAL_SNAPSHOT_ATTACK_MS = 50
Const.CLIENT_LOCAL_SNAPSHOT_MOVE_MS = 150
Const.CLIENT_LOCAL_SNAPSHOT_IDLE_MS = 500
Const.CLIENT_LOCAL_SNAPSHOT_ABSTRACT_MS = 2000
Const.CLIENT_LOCAL_VISUAL_MAINTAIN_MS = 250
-- Remote clients receive engine-owned IsoZombie movement separately from
-- these roster snapshots. Keep presentation responsive without replaying
-- the full visual reconciliation on every render tick.
Const.CLIENT_REMOTE_SNAPSHOT_ACTIVE_MS = 100
Const.CLIENT_REMOTE_SNAPSHOT_MOVE_MS = 150
Const.CLIENT_REMOTE_SNAPSHOT_IDLE_MS = 500
Const.CLIENT_REMOTE_FACING_MOVE_MS = 100
Const.CLIENT_REMOTE_FACING_IDLE_MS = 220
Const.CLIENT_REMOTE_NATIVE_BIND_MS = 250
Const.CLIENT_REMOTE_STATE_PRUNE_MS = 5000
Const.BODY_AUDIT_INTERVAL_MS = 250
-- A live shell must stay square-less this long before presence treats its body
-- as lost. Removal and virtualization are permanent, but a transient
-- square-less frame must not abstract the record or arm a husk reap.
Const.BODY_LOST_GRACE_MS = 400
Const.CORPSE_AUDIT_INTERVAL_MS = 1000
Const.CORPSE_AUDIT_BATCH_SIZE = 12
Const.CORPSE_REANIMATE_RETRY_MAX = 3
Const.CORPSE_REANIMATE_RETRY_MS = 2000
Const.BODY_TAG_VERSION = 1
Const.BODY_SHELL_VERSION = 1
Const.BODY_SHELL_RESPAWN_DELAY_MS = 50
Const.BODY_SHELL_MAINTENANCE_MS = 1000
Const.BODY_SHELL_STARTUP_PASSES = 3
--[[
    Husk lifecycle budget.

    A live shell that leaves the loaded world is virtualized by the engine into
    an anonymous population record: only position, direction, persistent outfit
    id and a handful of state booleans are persisted, so PNC ModData (PNC_UUID,
    PNC_BodyLease) is destroyed. The ledger remembers where that happened and
    the reaper deletes the husk when the population manager hands it back as a
    real body. Entries are bounded per entry, per record and in total so a
    pathological presence loop cannot grow the save.
]]
Const.HUSK_LEDGER_MODDATA_KEY = "PNC_HuskLedger"
Const.HUSK_LEDGER_LAYOUT_VERSION = 2
Const.HUSK_LEDGER_MAX_ENTRIES = 48
Const.HUSK_LEDGER_MAX_PER_RECORD = 2
-- Long enough that a husk in an area the player revisits days later is still reaped.
Const.HUSK_LEDGER_TTL_HOURS = 168
Const.HUSK_LEDGER_MATCH_RADIUS = 2.0
Const.HUSK_REAP_MAX_ATTEMPTS = 4
Const.HUSK_REAP_PUMP_INTERVAL_MS = 250
Const.HUSK_REAP_SWEEP_INTERVAL_MS = 1000
Const.HUSK_REAP_PENDING_MAX = 32
-- Expiry/eviction and persistence run at most this often; the removal pump
-- keeps its own faster cadence.
Const.HUSK_LEDGER_EXPIRY_INTERVAL_MS = 1000
-- Debug surfaces (console report and the World Effects window) stay bounded so
-- a multiplayer snapshot request remains a small payload.
Const.HUSK_DEBUG_MAX_ENTRIES = 12
Const.HUSK_DEBUG_MAX_OUTFITS = 8
-- The engine picks a shell outfit id per call, so the learned set accumulates
-- across sessions. Bound it so the persisted diagnostics cannot grow forever.
Const.HUSK_LEDGER_MAX_SHELL_OUTFITS = 32
-- IsoWorld.getZombiesDisabled() is a Java call on the hot zombie-spawn path;
-- cache it for this long.
Const.ZOMBIE_SPAWN_DISABLED_CACHE_MS = 1000
Const.BITE_RELEASE_TIMEOUT_MS = 650
Const.INVENTORY_OPLOG_MAX = 32
Const.ROSTER_CHUNK_SIZE = 50
Const.ROSTER_DELTA_INTERVAL_MS = 10000
Const.INTEREST_REFRESH_MS = 1000
Const.INTEREST_ENTER_DISTANCE = 48
Const.INTEREST_LEAVE_DISTANCE = 56
Const.CHARACTER_DETAIL_DISTANCE = 5
