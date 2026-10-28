local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
})

local published
local neutralized
local health = 0.1
local dead = false
local victim = {
    isDead = function() return dead end,
    getHealth = function() return health end,
    setHealth = function(_, value) health = value end,
    Kill = function() dead = true; health = 0 end,
    getOnlineID = function() return 77 end,
    getPersistentOutfitID = function() return 88 end,
    getTarget = function() return nil end,
    getX = function() return 10 end,
    getY = function() return 20 end,
    getZ = function() return 0 end,
}
getCell = function()
    return { getFakeZombieForHit = function() return {} end }
end

PNC = {
    CombatResolution = {},
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
    Registry = {
        FindRecordByZombie = function() return nil end,
    },
    SocialEventHooks = {
        WorldAgeHours = function() return 42 end,
        OnThreatNeutralized = function(spec)
            neutralized = spec
            return true
        end,
    },
    Semantics = {
        EngineEvents = {
            Publish = function(eventType, payload)
                published = { eventType = eventType, payload = payload }
                return true
            end,
        },
    },
}

local Resolution = T.load(
    "ProjectHoomans", "shared",
    "PNC/Core/Combat/CombatResolution/PNC_CombatResolution_Zombie.lua"
)

local ok = Resolution.ApplyZombieDamage(
    { id = "killer", x = 9, y = 20, z = 0 },
    nil,
    { kind = "zombie", zombieId = "threat-77", worldObject = victim },
    { attackType = "melee", amount = 20 }
)
T.truthy(ok, "npc zombie damage applied")
T.truthy(dead, "test zombie was killed")
T.truthy(neutralized, "existing encounter neutralization still runs")
T.equal(neutralized.actorKey, "npc:killer", "encounter actor is npc")
T.truthy(published, "npc kill published semantic engine event")
T.equal(published.eventType, "engine:zombie_killed", "shared kill event type")
T.equal(published.payload.actorKind, "npc", "npc actor kind")
T.equal(published.payload.actorKey, "npc:killer", "npc actor key")
T.equal(published.payload.zombieKey, "threat-77", "stable threat key")
T.equal(published.payload.source, "npc_combat_resolution", "authoritative source")

T.finish("pnc_npc_zombie_kill_semantic_event_smoke")
