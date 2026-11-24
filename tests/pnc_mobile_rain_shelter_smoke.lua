local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER = T.path("ProjectHoomans", "server", "PNC/")

function isClient() return false end
function isServer() return true end

local currentRain = 0.0
local currentTemp = 18.0
local climateCalls = 0
function getClimateManager()
    climateCalls = climateCalls + 1
    return {
        getRainIntensity = function() return currentRain end,
        getTemperature = function() return currentTemp end,
    }
end

local fakeNowMs = 1000
PNC = {
    Core = { Now = function() return fakeNowMs end },
    Const = {
        ORDER_ROAM = "roam",
        ORDER_GUARD = "guard",
        ROAM_MODE_ROAD = "road",
        ROAM_MODE_SHELTER = "shelter",
        ROAM_TARGET_RADIUS = 12,
    },
    FactionConstants = {
        MOBILE_CONTROL_AMBIENT = "ambient",
        MOBILE_CONTROL_STRATEGIC = "strategic",
        MOBILE_ACTIVITY_TRAVELING_TO_SETTLEMENT = "traveling_to_settlement",
        MOBILE_AMBIENT_DAY = "day",
        MOBILE_AMBIENT_NIGHT = "night",
        MOBILE_AMBIENT_ROAD = "road",
        MOBILE_AMBIENT_SHELTER = "shelter",
        MOBILE_AMBIENT_DAY_START_HOUR = 6,
        MOBILE_AMBIENT_NIGHT_START_HOUR = 19,
        MOBILE_AMBIENT_CHECK_HOURS = 1,
        MOBILE_AMBIENT_OBJECTIVE_HOURS = 4,
        MOBILE_AMBIENT_RETRY_HOURS = 0.5,
    },
    DirectorConfig = {},
}

-- Load WeatherDressingService for its real hysteretic O(1) weather cache
T.load(SERVER .. "World/PNC_WeatherDressingService.lua")

local releasedReasons = {}
PNC.AmbientVisitService = {
    IsActive = function() return true end,
    ReleaseMobileShelter = function(rec, reason)
        releasedReasons[#releasedReasons + 1] = { id = rec.id, reason = reason }
        return true
    end,
}

local neutralMember = { id = "neutral_1", alive = true }
PNC.Registry = {
    Get = function(id)
        if id == "neutral_1" then return neutralMember end
        return nil
    end,
}

local roadCalls = 0
local shelterCalls = 0
local H = {
    Internal = {
        AmbientTargets = {
            beginDiagnosticTiming = function() return nil, nil end,
            endDiagnosticTiming = function() end,
            finite = function(v, fb) return tonumber(v) or fb end,
            shelterTargetIsLocal = function() return true end,
        },
        ambientOwnershipSnapshot = function() return {} end,
        updateMobile = function(faction, patch)
            for k, v in pairs(patch) do faction.mobile[k] = v end
            return faction
        end,
        memberRecords = function() return { neutralMember } end,
    },
    FindRoadTarget = function()
        roadCalls = roadCalls + 1
        return { kind = "road", x = 100, y = 100, z = 0, radius = 10 }
    end,
    FindShelterTarget = function()
        shelterCalls = shelterCalls + 1
        return {
            kind = "building",
            siteID = "shelter_bldg_1",
            x = 120, y = 120, z = 0,
            bounds = { minX = 115, minY = 115, maxX = 125, maxY = 125, minZ = 0, maxZ = 0 },
        }
    end,
    IsValidShelterSite = function() return true end,
    SyncAbstractObjective = function() end,
    RepairMobileOrders = function() end,
}
PNC.MobileGroupDirectorInternal = H

T.load(SERVER .. "Director/MobileGroupDirector/PNC_MobileGroupDirector_Ambient_Objective.lua")

-- Re-bind stubs after loading Ambient_Objective and before loading Ambient_Refresh.
H.Internal.updateMobile = function(faction, patch)
    for k, v in pairs(patch) do faction.mobile[k] = v end
    return faction
end
H.FindRoadTarget = function()
    roadCalls = roadCalls + 1
    return { kind = "road", x = 100, y = 100, z = 0, radius = 10 }
end
H.FindShelterTarget = function()
    shelterCalls = shelterCalls + 1
    return {
        kind = "building",
        siteID = "shelter_bldg_1",
        x = 120, y = 120, z = 0,
        bounds = { minX = 115, minY = 115, maxX = 125, maxY = 125, minZ = 0, maxZ = 0 },
    }
end
H.PlayerOwnershipSnapshot = function() return {} end
H.IsValidShelterSite = function() return true end
H.SyncAbstractObjective = function() end
H.RepairMobileOrders = function() end

T.load(SERVER .. "Director/MobileGroupDirector/PNC_MobileGroupDirector_Ambient_Refresh.lua")

local faction = {
    id = "neutral_group_1",
    archetypeID = "neutral",
    memberIDs = { neutral_1 = true },
    mobile = {
        controlMode = "ambient",
        revision = 1,
        ambient = {},
    },
}

-- 1. Daytime dry -> road roaming
currentRain = 0.0
fakeNowMs = 10000
PNC.WeatherDressingService.NextSampleAt = 0
local ctxDry = { ambientTargetSelectionBudget = 2 }
faction = H.RefreshAmbient(faction, 12.0, ctxDry)
T.equal(faction.mobile.ambient.objective, "road", "dry daytime neutral group takes road objective")
T.equal(faction.mobile.ambient.rainShelter, false, "rainShelter flag is false when dry")

-- 2. Daytime heavy rain (>= 0.25) -> switches to existing shelter pipeline
currentRain = 0.40
fakeNowMs = 30000
PNC.WeatherDressingService.NextSampleAt = 0
local ctxRain = { ambientTargetSelectionBudget = 2 }
local callsBefore = climateCalls
faction = H.RefreshAmbient(faction, 12.2, ctxRain)
T.equal(faction.mobile.ambient.objective, "shelter", "raining daytime neutral group seeks shelter")
T.equal(faction.mobile.ambient.rainShelter, true, "marks shelter as rain-driven")
T.equal(shelterCalls, 1, "reuses existing FindShelterTarget")
T.equal(ctxRain.rainShelterActive, true, "caches rain state on pump context")
-- Second call with same pump context makes zero extra ClimateManager calls
H.IsRainShelterActive(ctxRain)
T.equal(climateCalls, callsBefore + 1, "context cache avoids repeated ClimateManager calls")

-- 3. Hysteresis: light drizzle (0.18 > 0.12) keeps neutral group sheltered without flapping
currentRain = 0.18
fakeNowMs = 50000
PNC.WeatherDressingService.NextSampleAt = 0
local ctxDrizzle = { ambientTargetSelectionBudget = 2 }
faction = H.RefreshAmbient(faction, 12.5, ctxDrizzle)
T.equal(faction.mobile.ambient.objective, "shelter", "hysteresis keeps group sheltered in lingering drizzle")

-- 4. Rain stops during daytime -> releases shelter cleanly with weather_cleared reason and resumes road
releasedReasons = {}
currentRain = 0.0
fakeNowMs = 70000
PNC.WeatherDressingService.NextSampleAt = 0
local ctxClear = { ambientTargetSelectionBudget = 2 }
faction = H.RefreshAmbient(faction, 13.0, ctxClear)
T.equal(faction.mobile.ambient.objective, "road", "resumes road roaming once rain stops")
T.equal(#releasedReasons, 1, "releases mobile shelter lease when rain clears")
T.equal(releasedReasons[1].reason, "mobile_shelter_weather_cleared", "records weather_cleared release reason")

-- 5. Nighttime dry still shelters as before
currentRain = 0.0
fakeNowMs = 90000
PNC.WeatherDressingService.NextSampleAt = 0
local ctxNight = { ambientTargetSelectionBudget = 2 }
faction = H.RefreshAmbient(faction, 21.0, ctxNight)
T.equal(faction.mobile.ambient.objective, "shelter", "dry nighttime still uses shelter objective")
T.equal(faction.mobile.ambient.rainShelter, false, "nighttime dry shelter is not flagged as rainShelter")

T.finish("pnc_mobile_rain_shelter_smoke")
