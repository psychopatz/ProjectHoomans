PNC = PNC or {}
PNC.Const = PNC.Const or {}

local Const = PNC.Const

Const.TICK_LIVE_HOT_MS = 100
Const.TICK_LIVE_WARM_MS = 250
Const.TICK_LIVE_COLD_MS = 1000
Const.TICK_ABSTRACT_MS = 3000
-- A sleep wake transaction that cannot finish (for example an abstract record
-- with no body to release) must not gate every behavior tick forever. After the
-- transaction deadline plus this slack the pending flag is cleared and reported.
Const.SLEEP_WAKE_HARD_TIMEOUT_MS = 30000
Const.TICK_ABSTRACT_FAR_MS = 15000
Const.TICK_ABSTRACT_DORMANT_MS = 60000
Const.SCHEDULER_MAX_RECORDS_PER_TICK = 24
Const.SERVER_TICK_RECORD_BUDGET_MS = 10
Const.SIMULATION_LIVE_IDLE_MS = 1000
Const.SIMULATION_VITALS_HOT_MS = 250
Const.SIMULATION_VITALS_LIVE_MS = 1000
Const.SIMULATION_VITALS_ABSTRACT_MS = 5000
-- Inventory revision changes invalidate this immediately. Keep the periodic
-- skill/encumbrance fallback longer than the one-second live-vitals cadence,
-- otherwise every Stamina.Update call defeats the cache.
Const.STAMINA_DERIVED_REFRESH_MS = 5000
Const.SIMULATION_PRESENCE_LIVE_MS = 500
Const.SIMULATION_PRESENCE_ABSTRACT_MS = 3000
Const.SIMULATION_PATH_HOT_MS = 50
Const.SIMULATION_PATH_MOVING_MS = 100
Const.SIMULATION_PATH_IDLE_MS = 500
Const.LIVE_POSITION_SAFETY_REFRESH_MS = 1000

Const.MATERIALIZE_DISTANCE = 28
Const.ABSTRACT_DISTANCE = 40
-- Hard physical-carrier safety fence. No forceLive/combat/order exception may
-- keep a managed IsoZombie beyond this radius from every player: PZ can feed
-- an IsoZombie in an unloading chunk into ZombiePopulationManager before PNC
-- receives any Lua unload callback. Keep this no larger than ABSTRACT_DISTANCE.
Const.LIVE_BODY_RETIRE_DISTANCE = 40
-- In local SP/splitscreen, remain one chunk inside the actual IsoChunkMap edge
-- so even small/debug chunk maps retire PNC shells before native unload.
Const.LIVE_BODY_CHUNK_MARGIN = 8
-- Independent of per-NPC AI cadence. A player in a vehicle can cross the hard
-- envelope faster than an idle NPC's one-second think/presence schedule.
Const.LIVE_BODY_SAFETY_SWEEP_MS = 100
Const.ABSTRACT_NEAR_DISTANCE = 80
Const.PRESENCE_INTEREST_REFRESH_MS = 250
Const.MATERIALIZE_MAX_PER_TICK = 2
Const.CORE_PROMOTE_MAX_PER_REFRESH = 4
Const.CORE_DEMOTE_GRACE_MS = 2000
Const.CORE_DEMOTE_PUMP_MS = 1000
Const.CORE_DEMOTE_MAX_PER_PUMP = 8
Const.PERSISTENCE_PUMP_INTERVAL_MS = 3000
Const.PERSISTENCE_PUMP_MAX_RECORDS = 1
Const.PERSISTENCE_CHECKPOINT_INTERVAL_MS = 5000
Const.PERSISTENCE_CHECKPOINT_MAX_RECORDS = 8
Const.PERSISTENCE_RETRY_BASE_MS = 1000
Const.PERSISTENCE_RETRY_MAX_MS = 30000
Const.PERSISTENCE_RETRY_MAX_ATTEMPTS = 5
Const.MATERIALIZE_CHUNK_SETTLE_MS = 1000
Const.MATERIALIZE_CHUNK_RETRY_MS = 250
Const.MATERIALIZE_NEIGHBOR_RADIUS = 1
Const.MATERIALIZE_SAFE_RADIUS = 8
Const.LIVE_BODY_MAX_GLOBAL = 32
Const.LIVE_BODY_MAX_PER_PLAYER = 20
Const.LIVE_BODY_ADMISSION_RETRY_MS = 1000
Const.SPATIAL_CELL_SIZE = 16
Const.SPATIAL_REBUILD_MS = 200
Const.WORLD_CENSUS_REFRESH_MS = 100
Const.WORLD_CENSUS_IDLE_REFRESH_MS = 1000
Const.WORLD_CENSUS_LOOKUP_REFRESH_MS = 250
Const.ZOMBIE_AGGRO_ACTIVE_REFRESH_MS = 250
Const.ZOMBIE_AGGRO_ACTIVE_TTL_MS = 1500
Const.ZOMBIE_AGGRO_MAX_PER_TICK = 24
Const.ZOMBIE_AGGRO_PATH_REQUESTS_PER_TICK = 4
-- Strategic jobs can each be bounded internally yet still align on the same
-- world-time frame. Spread due jobs across frames to prevent aggregate hitches.
Const.SCHEDULER_MAX_JOBS_PER_TICK = 1
Const.PERCEPTION_FRAME_MS = 200
Const.PERCEPTION_FRAME_MOVE_TOLERANCE = 0.5
Const.PERCEPTION_LOS_MAX_CANDIDATES = 6
-- All NPC-facing spatial zombie reads pass through PNC.Perception. Keep the
-- shared candidate cache short-lived and bounded so it reduces duplicate
-- scans without becoming a second world-state index.
Const.PERCEPTION_CANDIDATE_CACHE_MS = 100
Const.PERCEPTION_CANDIDATE_CACHE_MAX = 128
Const.COMPANION_OWNER_THREAT_CACHE_MS = 100
Const.STEALTH_DISCOVERY_CACHE_MS = 200
Const.STEALTH_INDICATOR_UPDATE_MS = 200
Const.STEALTH_INDICATOR_HEARTBEAT_MS = 1000
Const.STEALTH_INDICATOR_TIMEOUT_MS = 1500
