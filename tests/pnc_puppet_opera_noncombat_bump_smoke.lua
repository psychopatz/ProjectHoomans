local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
})

local now = 1000
local finishCalls = 0

PNC = {
    Core = {
        Now = function() return now end,
    },
    Animation = {
        IsCombatBumpActionActive = function(body)
            return body:getModData().combat == true
        end,
        FinishBump = function()
            finishCalls = finishCalls + 1
        end,
    },
}

local Override = T.load(
    "ProjectHoomans",
    "server",
    "PNC/PuppetOpera/PNC_PuppetOpera_OverrideAdapter.lua"
)

local body = {
    actionState = "bumped",
    modData = {
        PNC_BumpActionLease = true,
        PNC_BumpRequestedType = "PNC_WaveHi",
    },
}
function body:getActionStateName() return self.actionState end
function body:getModData() return self.modData end
function body:isDead() return false end
function body:getVehicle() return nil end
function body:isSeatedInVehicle() return false end

local record = { id = "noncombat-bump", runtime = {} }
local ready, info = Override.GetReadiness(record, body, {
    sessionId = "opera-1",
})
T.truthy(ready, "managed non-combat bump was still rejected")
T.truthy(info and info.bumpReplaceable,
    "readiness did not identify the replaceable bump")

local acquired, reason = Override.Acquire(
    { sessionId = "opera-1", ownerId = "tester" },
    { record = record, body = body }
)
T.truthy(acquired, reason or "Opera could not acquire a non-combat bump")
T.equal(finishCalls, 1,
    "Opera did not finish the previous non-combat bump before acquiring")

record.runtime.puppetOperaOverride = nil
body.modData.combat = true
local blocked, blockedReason = Override.GetReadiness(record, body, {
    sessionId = "opera-2",
})
T.truthy(blocked,
    "managed Puppet bump was still blocked by the combat classifier")
T.truthy(blockedReason and blockedReason.bumpReplaceable,
    "managed Puppet bump did not remain replaceable when combat metadata was present")

return T.finish("pnc_puppet_opera_noncombat_bump_smoke")
