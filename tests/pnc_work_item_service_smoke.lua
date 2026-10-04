local T = require "tests/support/test"

local leaseCalls = {}
PNC = {
    Inventory = {},
    Equipment = {
        AcquirePrimaryLease = function(record, owner, itemID)
            record.inventory.equipped.primary = itemID
            leaseCalls[#leaseCalls + 1] = "acquire:" .. owner
            return true, "acquired"
        end,
        ReleasePrimaryLease = function(_, owner)
            leaseCalls[#leaseCalls + 1] = "release:" .. owner
            return true, "released"
        end,
    },
}

T.load("ProjectHoomans", "shared", "PNC/Core/Jobs/PNC_JobRequirements.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Jobs/PNC_WorkItemService.lua")

PNC.WorkItemService.RegisterValidator("lumber_tool", function(_, item)
    local fullType = tostring(item.type or "")
    if string.find(string.lower(fullType), "axe", 1, true) == nil then
        return false, "tool_cannot_chop"
    end
    return tonumber(item.cond or 1) > 0
end)

local record = {
    inventory = {
        revision = 4,
        equipped = { primary = "hammer" },
        items = {
            hammer = { id = "hammer", type = "Base.Hammer" },
            axe = { id = "axe", type = "Base.Axe", cond = 10 },
        },
    },
    runtime = {},
}

local report = PNC.WorkItemService.Check(record, "LUMBER")
T.equal(report.ok, true, "axe satisfies lumber requirement")
T.equal(report.primary.id, "axe", "hammer rejected in favor of axe")

local ready, reason, ensured = PNC.WorkItemService.Ensure(
    record, "LUMBER", nil, { owner = "work:LUMBER" })
T.equal(ready, true, "work item ensured")
T.equal(reason, "work_item_ready", "work item ready reason")
T.equal(ensured.state, "HELD", "work item held")
T.equal(record.inventory.equipped.primary, "axe", "axe equipped")

record.inventory.items.axe.cond = 0
report = PNC.WorkItemService.Check(record, "LUMBER")
T.equal(report.ok, false, "broken axe rejected")
T.equal(report.state, "WAITING_FOR_WORK_ITEM", "broken tool wait state")

local released = PNC.WorkItemService.Release(record, "LUMBER")
T.equal(released, true, "work item released")
T.equal(record.runtime.workItems.LUMBER, nil, "work item runtime cleared")
T.equal(#leaseCalls, 2, "work item uses the lease boundary")

T.finish("pnc_work_item_service_smoke")
