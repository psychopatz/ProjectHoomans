local T = require "tests/support/test"

local record = {
    id = "npc_backoff",
    alive = true,
    affiliation = { factionID = "colonists" },
    runtime = {},
}

PNC = {
    Core = { Now = function() return 12000 end },
    Registry = {
        Data = { [record.id] = record },
        Get = function(id)
            if tostring(id) == record.id then return record end
            return nil
        end,
    },
    ProvisionRuleRegistry = {
        Get = function(id)
            if id == "food" then return { id = id } end
            return nil
        end,
        List = function() return { { id = "food" } } end,
    },
    ProvisionEvaluator = {},
    SupplyMetrics = {
        Set = function() end,
        Increment = function() end,
    },
}

T.load(
    "ProjectHoomans",
    "server",
    "PNC/Provision/PNC_ProvisionScheduler.lua"
)

T.truthy(
    PNC.ProvisionScheduler.MarkDirty(record, "food", 5),
    "initial deferred provision rule"
)
PNC.ProvisionScheduler.LastAuditAt = 1
PNC.ProvisionScheduler.Audit(12000)
T.equal(
    PNC.ProvisionScheduler.Queue[1].readyAt,
    5,
    "periodic audit erased supply retry deadline"
)

PNC.ProvisionScheduler.MarkDirty(record, "food", 0)
T.equal(
    PNC.ProvisionScheduler.Queue[1].readyAt,
    0,
    "explicit dirty event did not wake deferred provision rule"
)

T.finish("pnc_provision_audit_backoff_smoke")
