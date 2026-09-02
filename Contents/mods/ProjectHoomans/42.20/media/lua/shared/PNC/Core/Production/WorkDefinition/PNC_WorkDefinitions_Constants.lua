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

Definitions.REQUIRES_LIVE = {
    -- Corpse hauling uses a live NPC for physical movement and the Lua
    -- interaction sequence; it cannot be completed by the abstract path.
    CORPSE_HAUL = true,
}

return Definitions
