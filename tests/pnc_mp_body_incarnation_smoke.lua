local T = require "tests/support/test"
T.addPackagePaths()
PNC = {
    Core = { GenerateID = function() return "body_same_clock_random" end },
    Const = { BODY_TAG_VERSION = 1, BODY_SHELL_VERSION = 1,
        BODY_SHELL_CARRIER_VERSION = 1, BODY_SHELL_OUTFIT = "PNCShellCarrier" },
    BodyLifecycle = { Internal = { mark = function() end } },
}
isServer = function() return true end
T.load("ProjectHoomans", "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_LiveBodies.lua")
local L = PNC.BodyLifecycle
L.RefreshLiveBodyIdentity = function() end
local function body()
    local md = {}
    return { getModData = function() return md end }
end
local r = { id = "npc_a", runtime = { bodyLease = "provider_or_saved" } }
local first = body()
local a = L.StampLiveBody(r, first)
T.truthy(a ~= "provider_or_saved", "new MP shell cannot reuse saved lease")
T.equal(L.StampLiveBody(r, first), a, "same shell remains stable")
r.runtime.bodyLease = "provider_or_saved"
T.equal(L.StampLiveBody(r, first), a, "provider projection cannot change shell token")
local second = body()
local b = L.StampLiveBody(r, second)
T.truthy(b ~= a, "shell replacement rotates lease even with constant ID generator")
T.equal(first:getModData().PNC_BodyLease, a, "old shell retains stale lease")
T.equal(second:getModData().PNC_BodyLease, b)
r.runtime.bodyLease = nil
local c = L.StampLiveBody(r, second)
T.truthy(c ~= b, "released and recycled object gets new incarnation")
isServer = function() return false end
r.runtime.bodyLease = "sp_restored_lease"
T.equal(L.StampLiveBody(r, body()), "sp_restored_lease", "SP restoration unchanged")
isServer = function() return true end
PNC.Const.PRESENCE_LIVE, PNC.Const.PRESENCE_ABSTRACT = "live", "abstract"
local shell = body()
shell.getOnlineID = function() return 77 end
local lease = L.StampLiveBody(r, shell)
r.presenceState = "live"
local notified = {}
PNC.Network = { BroadcastBodyRemoval = function(id, instance, online, reason, token)
    notified[#notified+1] = { id=id, online=online, lease=token }
end }
local reg = { LiveByID = { [r.id] = shell } }
L.Internal.registry = function() return reg end
L.Internal.matchesRecordBody = function() return true end
L.Internal.isBodyAttached = function() return true end
L.Internal.removeZombie = function() return false end
T.equal(L.RemoveLiveBody(r, shell, "retry"), false)
T.equal(#notified, 0, "failed physical removal cannot retire client binding")
T.equal(r.runtime.bodyLease, lease, "failed removal retains authority")
L.Internal.removeZombie = function()
    shell:getModData().PNC_BodyLease = nil
    return true
end
T.truthy(L.RemoveLiveBody(r, shell, "abstract"))
T.equal(#notified, 1)
T.equal(notified[1].lease, lease, "removal captures lease before engine mutation")
T.equal(notified[1].online, 77)
T.equal(r.runtime.bodyLease, nil, "verified removal clears incarnation")
return T.finish("pnc_mp_body_incarnation_smoke")
