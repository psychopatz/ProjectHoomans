local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

local now = 2000
local worldHours = 8
local sceneDefinitions = {}
local requestedScenes = {}
local releasedReservations = {}
local reservedByResource = {}
local preparedSleep = 0
local clearedSleep = 0

local function distance(x1, y1, x2, y2)
    local dx = (x2 or 0) - (x1 or 0)
    local dy = (y2 or 0) - (y1 or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function sceneRequest(record, _, sceneId)
    record.runtime.animationScene = { id = sceneId }
    requestedScenes[#requestedScenes + 1] = sceneId
    return true, record.runtime.animationScene
end

local function newRecord(id, seed)
    return {
        id = id,
        identitySeed = seed,
        alive = true,
        presenceState = "live",
        health = { state = "normal", recentDamageUntil = 0 },
        runtime = {
            roaming = { phase = "idle", idleSince = 0 },
        },
        orderSpec = { kind = "roam", roamMode = "area" },
    }
end

local function newBody(x, y)
    local body = { x = x, y = y, z = 0 }
    function body:getX() return self.x end
    function body:getY() return self.y end
    function body:getZ() return self.z end
    return body
end

PNC = {
    Const = { ORDER_ROAM = "roam", PRESENCE_LIVE = "live" },
    Core = {
        Now = function() return now end,
        IsAuthority = function() return true end,
        Distance = distance,
    },
    Identity = {
        Range = function(seed, _, low, high)
            if tostring(seed) == "seed_a" then return low end
            return high
        end,
        Verifier = {
            IsCompanion = function() return false end,
            IsColonyOwnedNPC = function() return false end,
        },
    },
    BehaviorCommon = {
        ClearCombatTarget = function(record) record.runtime.target = nil end,
        HaltMovement = function() end,
        MoveRecord = function(record, _, x, y, z)
            record.lastMove = { x = x, y = y, z = z }
        end,
    },
    AnimationScenes = {
        Register = function(id, definition)
            definition.id = id
            sceneDefinitions[id] = definition
        end,
        Get = function(id) return sceneDefinitions[id] end,
        Request = sceneRequest,
        Interrupt = function(record)
            record.runtime.animationScene = nil
            return true
        end,
        Internal = {
            ClearScene = function(record)
                record.runtime.animationScene = nil
                return true
            end,
        },
    },
    FacilityResources = {
        GetDetector = function(id)
            if id == "bed" then
                return {
                    matches = function(_, object) return object.bed == true end,
                    describe = function(_, object)
                        return {
                            resourceKey = "bed:11:20:0",
                            resourceKind = "sleep_surface",
                            sleepSurface = "bed",
                            sleepPriority = 100,
                            object = object,
                            originX = 11, originY = 20, originZ = 0,
                        }
                    end,
                }
            end
            return {
                matches = function(_, object) return object.sofa == true end,
                describe = function(_, object)
                    return {
                        resourceKey = "sofa:10:21:0",
                        resourceKind = "sleep_surface",
                        sleepSurface = "sofa",
                        sleepPriority = 50,
                        object = object,
                        originX = 10, originY = 21, originZ = 0,
                    }
                end,
            }
        end,
        CopyDescriptor = function(resource)
            return {
                resourceKey = resource.resourceKey,
                resourceKind = resource.resourceKind,
                sleepSurface = resource.sleepSurface,
                originX = resource.originX,
                originY = resource.originY,
                originZ = resource.originZ,
            }
        end,
    },
    FacilityInteractionTargets = {
        ResolveResource = function(resource)
            return { {
                x = resource.sleepSurface == "bed" and 11 or 10,
                y = resource.sleepSurface == "bed" and 20 or 21,
                z = 0,
                interactionX = resource.sleepSurface == "bed" and 11.5 or 10.5,
                interactionY = resource.sleepSurface == "bed" and 20.5 or 21.5,
                interactionZ = 0,
                sleepSurface = resource.sleepSurface,
                sleepFacing = "S",
                validSpot = true,
            } }
        end,
    },
    FacilityReservations = {
        ByResource = reservedByResource,
        ReserveResource = function(_, resource, npcID, purpose)
            local reservation = {
                id = "reservation:" .. tostring(npcID),
                resourceKey = resource.resourceKey,
                purpose = purpose,
            }
            reservedByResource[resource.resourceKey] = reservation.id
            return true, reservation
        end,
        Release = function(id, reason)
            releasedReservations[#releasedReservations + 1] = {
                id = id, reason = reason,
            }
            for key, value in pairs(reservedByResource) do
                if value == id then reservedByResource[key] = nil end
            end
            return true
        end,
    },
    FacilityJobs = {
        Sleep = {
            PrepareSleepSurface = function(_, _, runtime)
                runtime.sleepSurfaceEntered = true
                preparedSleep = preparedSleep + 1
                return true
            end,
            ClearSleepSurface = function(_, _, runtime)
                runtime.sleepSurfaceEntered = false
                clearedSleep = clearedSleep + 1
            end,
            ResetPath = function() end,
            RestorePosition = function() end,
        },
    },
    SleepRuntime = { LiveObjects = {} },
    LiveBodyControl = {
        SetAuthoritativePosition = function(body, x, y, z)
            body.x, body.y, body.z = x, y, z
        end,
        StabilizePresentationBody = function() end,
    },
}

local bed = { bed = true }
local sofa = { sofa = true }
getCell = function()
    return {
        getGridSquare = function(_, x, y)
            if x == 11 and y == 20 then
                return { getObjects = function() return { bed } end }
            end
            if x == 10 and y == 21 then
                return { getObjects = function() return { sofa } end }
            end
            return nil
        end,
    }
end

local Scenes = T.load("ProjectHoomans", "shared",
    "PNC/Core/Visuals/PNC_AnimationSceneDefinitions.lua")
local Ambient = T.load("ProjectHoomans", "server",
    "PNC/Settlement/FacilityJobs/PNC_RoamAmbientService.lua")
Ambient.GetWorldAgeHours = function() return worldHours end

T.truthy(Scenes.Get("ambient.roam.eat"),
    "ambient eating scene was not registered")
T.truthy(Scenes.Get("ambient.roam.drink"),
    "ambient drinking scene was not registered")
T.equal(Scenes.Get("ambient.roam.sleep.bed").steps[1].bump, "SleepBed",
    "ambient bed sleep uses the bed sleep bump")
T.equal(Scenes.Get("ambient.roam.eat").steps[1].bump, "Eat",
    "ambient eating scene uses the eating bump")

local recordA = newRecord("ambient_a", "seed_a")
local recordB = newRecord("ambient_b", "seed_b")
local planA = Ambient.GetActionPlan(recordA, 8.0)
local planB = Ambient.GetActionPlan(recordB, 9.0)
T.truthy(planA and planA.action == "eat",
    "seeded breakfast plan was not available")
T.truthy(planB and planB.action == "eat",
    "positive-offset breakfast plan was not available")
T.truthy(planA.scheduledAt ~= planB.scheduledAt,
    "identity seeds did not stagger breakfast times")

worldHours = 8.0
local bodyA = newBody(10, 20)
T.truthy(Ambient.TryStart(recordA, bodyA, recordA.orderSpec,
    recordA.runtime.roaming, now),
    "idle unowned roamer did not start visual eating")
T.equal(recordA.runtime.roamAmbient.action, "eat",
    "visual eating did not create ambient runtime state")
T.equal(recordA.activeJob, nil,
    "ambient eating unexpectedly claimed a gameplay job")
T.equal(recordA.inventory, nil,
    "ambient eating created or consumed inventory state")
T.equal(#requestedScenes, 1,
    "ambient eating did not request exactly one scene")
T.equal(requestedScenes[1], "ambient.roam.eat",
    "ambient eating requested the wrong scene")

Ambient.Stop(recordA, bodyA, "test_complete")
now = 40000
recordA.runtime.target = { kind = "zombie" }
T.falsy(Ambient.TryStart(recordA, bodyA, recordA.orderSpec,
    recordA.runtime.roaming, now),
    "combat target did not block ambient eating")
recordA.runtime.target = nil

worldHours = 22.0
now = 100000
local recordSleep = newRecord("ambient_sleep", "seed_a")
local bodySleep = newBody(10, 20)
T.truthy(Ambient.TryStart(recordSleep, bodySleep, recordSleep.orderSpec,
    recordSleep.runtime.roaming, now),
    "night-time roamer did not acquire a nearby sleep surface")
T.equal(recordSleep.runtime.roamAmbient.action, "sleep",
    "night-time ambience selected the wrong action")
T.equal(recordSleep.runtime.roamAmbient.sleepSurface, "bed",
    "bed did not outrank the nearby sofa")
T.truthy(recordSleep.runtime.roamAmbient.reservationId,
    "sleep surface was not reserved")
T.equal(recordSleep.runtime.animationScene, nil,
    "sleep scene started before the NPC reached the approach point")

bodySleep.x = 11
Ambient.Tick(recordSleep, bodySleep, now + 1000)
T.equal(recordSleep.runtime.roamAmbient.phase, "SLEEPING",
    "sleep surface arrival did not start the sleep scene")
T.equal(recordSleep.runtime.animationScene.id,
    "ambient.roam.sleep.bed",
    "sleep selected the wrong presentation scene")
T.equal(preparedSleep, 1,
    "sleep surface was not prepared exactly once")

recordSleep.runtime.animationScene = nil
Ambient.OnSceneStopped(recordSleep, bodySleep,
    { id = "ambient.roam.sleep.bed" }, "test_complete")
T.equal(recordSleep.runtime.roamAmbient, nil,
    "sleep scene cleanup left ambient state behind")
T.equal(recordSleep.runtime.animationScene, nil,
    "sleep scene cleanup left the animation scene behind")
T.equal(clearedSleep, 1,
    "sleep surface cleanup did not run")
T.equal(reservedByResource["bed:11:20:0"], nil,
    "sleep reservation was not released")
T.equal(#releasedReservations, 1,
    "sleep cleanup released the wrong number of reservations")

T.finish("pnc_roam_ambient_smoke")
