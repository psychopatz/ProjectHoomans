local T = require "tests/support/test"

local PATCH_FILE =
    T.path("ProjectHoomans", "client", "PNC/Patches/PNC_WashMedicalMaterialPatch.lua")

local basePerformCount = 0
local originalPerformCount = 0
local resetModelCount = 0
local stoppedSoundCount = 0
local jobDelta

ISBaseTimedAction = {
    perform = function()
        basePerformCount = basePerformCount + 1
    end,
}
ISWashClothing = {
    perform = function()
        originalPerformCount = originalPerformCount + 1
    end,
}

package.preload["TimedActions/ISBaseTimedAction"] = function()
    return ISBaseTimedAction
end
package.preload["TimedActions/ISWashClothing"] = function()
    return ISWashClothing
end

instanceof = function()
    return false
end

T.load(PATCH_FILE)

local character = {
    resetModel = function()
        resetModelCount = resetModelCount + 1
    end,
}
local dirtyRag = {
    getItemAfterCleaning = function()
        return "Base.RippedSheets"
    end,
    setJobDelta = function(_, value)
        jobDelta = value
    end,
}
local clothing = {
    getItemAfterCleaning = function()
        return nil
    end,
}
local action = {
    item = dirtyRag,
    sink = {},
    character = character,
    stopSound = function()
        stoppedSoundCount = stoppedSoundCount + 1
    end,
}

setmetatable(action, { __index = ISWashClothing })
action:perform()

T.equal(originalPerformCount, 0,
    "replace-after-cleaning material bypasses vanilla clothing event")
T.equal(basePerformCount, 1,
    "replace-after-cleaning material still leaves timed-action queue")
T.equal(resetModelCount, 1, "medical material wash resets player model")
T.equal(stoppedSoundCount, 1, "medical material wash stops sound")
T.equal(jobDelta, 0, "medical material wash clears progress")

action.item = clothing
action:perform()
T.equal(originalPerformCount, 1,
    "ordinary clothing wash retains vanilla clothing update path")
T.finish("pnc_wash_medical_material_patch_smoke")

T.finish("pnc_wash_medical_material_patch_smoke")
