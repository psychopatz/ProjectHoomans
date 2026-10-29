local T = require "tests/support/test"
T.addPackagePaths()
local B = require "PNC/PresenceSync/PNC_MultiplayerBodyBinding_Client"
local c = B.NewClient()
local held = {}
for n=1,10000 do
    held[n] = {}
    c.Observe(held[n], n, 0)
    c.Receive({protocol=1,session="s",revision=n,npcId="npc"..n,
        operation="bind",incarnation="lease"..n,onlineId=n}, 0)
end
local entries, observed = c.Counts()
T.equal(entries, 512, "binding capacity under sustained unique input")
T.equal(observed, 512, "observation capacity under sustained zombie input")
c.Sweep(10001)
entries, observed = c.Counts()
T.equal(entries, 0, "TTL drains bounded entries")
T.equal(observed, 0, "TTL drains bounded observations")
local sources = {
    T.read("ProjectHoomans", "shared", "PNC/Core/Networking/PNC_MultiplayerBodyBinding.lua"),
    T.read("ProjectHoomans", "client", "PNC/PresenceSync/PNC_MultiplayerBodyBinding_Client.lua"),
    T.read("ProjectHoomans", "client", "PNC/PresenceSync/PNC_MultiplayerBodyBinding_Runtime.lua"),
}
for _, source in ipairs(sources) do
    for _, forbidden in ipairs({"getZombieList", "Registry.ForEach", "ModData.getOrCreate", "ModData.add"}) do
        T.falsy(source:find(forbidden, 1, true), "binding seam must not scan world or create persistence: "..forbidden)
    end
    T.falsy(source:find('require "ProjectALife', 1, true), "reference mod cannot become a dependency")
end
PNC.Const = { PRESENCE_LIVE="live", NETWORK_PAYLOAD_BUDGET_BYTES=2048 }
PNC.Core = { GenerateID=function() return "session_1793296844_123456" end }
isServer = function() return true end
local md = {PNC_NPC=true,PNC_UUID="npc_budget",PNC_BodyKind="live",PNC_BodyLease="body_1793296844_123456_123"}
PNC.Registry = {GetLiveZombie=function() return {
    getModData=function() return md end, getOnlineID=function() return 50 end,
} end}
local message = B.Build({id="npc_budget",alive=true,presenceState="live",runtime={bodyLease=md.PNC_BodyLease}})
local Budget = T.load("ProjectHoomans", "shared",
    "PNC/Core/Networking/PNC_Network_Server/PNC_Network_Server_Budget.lua")
T.truthy(Budget.Estimate({bodyBinding=message}, 2048) <= 2048,
    "actual binding descriptor remains small under existing payload estimator")
return T.finish("pnc_mp_body_binding_bounds_smoke")
