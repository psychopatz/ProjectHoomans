local PATCH_FILE =
    "Contents/mods/ProjectHoomans/42.20/media/lua/client/PNC/Patches/PNC_WashMedicalMaterialPatch.lua"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

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

dofile(PATCH_FILE)

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

assertEqual(originalPerformCount, 0,
    "replace-after-cleaning material bypasses vanilla clothing event")
assertEqual(basePerformCount, 1,
    "replace-after-cleaning material still leaves timed-action queue")
assertEqual(resetModelCount, 1, "medical material wash resets player model")
assertEqual(stoppedSoundCount, 1, "medical material wash stops sound")
assertEqual(jobDelta, 0, "medical material wash clears progress")

action.item = clothing
action:perform()
assertEqual(originalPerformCount, 1,
    "ordinary clothing wash retains vanilla clothing update path")

print("pnc_wash_medical_material_patch_smoke: ok")
