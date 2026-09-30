PNC = PNC or {}
PNC.WorkDefinitions = PNC.WorkDefinitions or {}

local Definitions = PNC.WorkDefinitions

Definitions.OPERATION = {
    RESEARCH = "RESEARCH", CRAFT = "CRAFT", DISASSEMBLE = "DISASSEMBLE",
    CONSTRUCT = "CONSTRUCT", RECONSTRUCT = "RECONSTRUCT",
    DECONSTRUCT = "DECONSTRUCT",
    BUILD_OBJECT = "BUILD_OBJECT", READ_BOOK = "READ_BOOK",
    PROVISION_PICKUP = "PROVISION_PICKUP", CORPSE_HAUL = "CORPSE_HAUL",
    LUMBER = "LUMBER",
}

Definitions.STATUS = {
    QUEUED = "QUEUED", WAITING_FOR_WORKER = "WAITING_FOR_WORKER",
    CLAIMED = "CLAIMED", TRAVEL_TO_STOCKPILE = "TRAVEL_TO_STOCKPILE",
    TRAVEL_TO_STATION = "TRAVEL_TO_STATION",
    WORKING = "WORKING", WAITING_RESOURCE = "WAITING_RESOURCE",
    WAITING_FOR_WORLD = "WAITING_FOR_WORLD",
    WORLD_EFFECT_PENDING = "WORLD_EFFECT_PENDING",
    PAUSED = "PAUSED", BLOCKED = "BLOCKED", CANCELLING = "CANCELLING",
    CANCELLED = "CANCELLED", COMPLETED = "COMPLETED",
    FAILED = "FAILED",
}

Definitions.BALANCE = {
    baseRatePerSecond = 1,
    minSkillFactor = 1,
    skillBonusPerLevel = 0.08,
    maxElapsedSeconds = 10,
    schedulerCadenceMs = 1000,
    maxOrdersPerPass = 16,
    salvageBaseFraction = 0.35,
    salvageSkillFractionPerLevel = 0.025,
    salvageMaximumFraction = 0.65,
}

Definitions.JOB_BY_OPERATION = {
    RESEARCH = "Researcher",
    READ_BOOK = "Researcher",
    CRAFT = "WorkshopWorker",
    DISASSEMBLE = "WorkshopWorker",
    CONSTRUCT = "Constructor",
    RECONSTRUCT = "Constructor",
    DECONSTRUCT = "Constructor",
    BUILD_OBJECT = "Constructor",
    PROVISION_PICKUP = "Provisioner",
    CORPSE_HAUL = "CorpseHaul",
    LUMBER = "Lumber",
}

Definitions.CAPABILITY_BY_OPERATION = {
    RESEARCH = "work.research",
    CRAFT = "work.craft",
    -- Salvaging remains a separate operation/work type while sharing the
    -- same physical crafting station capability.
    DISASSEMBLE = "work.craft",
    READ_BOOK = "work.research",
    PROVISION_PICKUP = "work.provision",
    -- Corpse hauling has no facility station. The target provider supplies a
    -- world-object claim, while this capability keeps the operation visible
    -- to generic work/task consumers.
    CORPSE_HAUL = "storage.stockpile",
    -- Lumber claims a world object, while the tree ledger remains the
    -- authority for discovery, reservations, damage, and output.
    LUMBER = "work.lumber",
}

-- These operations own their progress clock. The generic scheduler must not
-- advance them as if they were ordinary station work.
Definitions.MANUAL_PROGRESS = {
    CORPSE_HAUL = true,
    LUMBER = true,
}

-- Operations in this table genuinely require a live body. Corpse hauling is
-- hybrid: visible workers use the physical path, while abstract workers
-- commit a durable world effect when their simulated progress ends.
Definitions.REQUIRES_LIVE = {}

Definitions.EXECUTION_POLICY = {
    CORPSE_HAUL = "HYBRID",
}

Definitions.WORLD_EFFECT_BY_OPERATION = {
    CORPSE_HAUL = "CORPSE_TRANSFER",
}

--[[
    Default work-location policy per operation.

    Research-family study is assigned at the base so it visibly starts at the
    research table, then keeps its order if the colonist wanders off:
    execution = REMOTE means the scheduler's "worker_left_home" branch does not
    fire, so the claim and the facility reservation survive and the abstract
    progress clock keeps running. With the inherited HOME/HOME default that same
    branch fired on every pass while the researcher was away - release the
    claim, drop the reservation, mark the repository dirty, push a SendHome
    command, re-find a worker, re-claim the station, repeat - which is the
    per-tick loop that stalled the server.

    returnHome = STAY: nobody is dragged back mid-task. The consequence is that
    an order queued while every colonist is away waits for one to come home
    (visible as WORKER_NOT_AT_HOME / NO_HOME_WORKER on the work order) instead
    of pulling a colonist from across the map.

    Lumber and corpse hauling pass their own policies at their call sites; this
    table covers the shared research queue in one place. Callers that pass an
    explicit locationPolicy still win.
]]
Definitions.LOCATION_POLICY_BY_OPERATION = {
    RESEARCH = { start = "HOME", execution = "REMOTE",
        returnHome = "STAY" },
    READ_BOOK = { start = "HOME", execution = "REMOTE",
        returnHome = "STAY" },
}

function Definitions.LocationPolicy(operation)
    return Definitions.LOCATION_POLICY_BY_OPERATION[tostring(operation or "")]
end

function Definitions.ExecutionPolicy(operation)
    operation = tostring(operation or "")
    local explicit = Definitions.EXECUTION_POLICY[operation]
    if explicit then return explicit end
    if Definitions.REQUIRES_LIVE[operation] then return "LIVE_ONLY" end
    return "ABSTRACT_SAFE"
end

return Definitions
