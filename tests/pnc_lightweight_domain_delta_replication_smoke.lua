local T = require "tests/support/test"

T.addPackagePaths()

local now = 10000
local function deepCopy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for k, v in pairs(value) do out[k] = deepCopy(v) end
    return out
end

local modernPlayer = {
    getUsername = function() return "ModernClient" end,
    getOnlineID = function() return 11 end,
    getX = function() return 100 end,
    getY = function() return 100 end,
    getZ = function() return 0 end,
}
local legacyPlayer = {
    getUsername = function() return "LegacyClient" end,
    getOnlineID = function() return 12 end,
    getX = function() return 102 end,
    getY = function() return 100 end,
    getZ = function() return 0 end,
}
local clients = { modernPlayer, legacyPlayer }
local sentToServer = {}
local sentToClients = {}
local clientHandlers = {}
local appearanceRollCalls = 0
local skillsSnapshotCalls = 0
local inventorySummaryCalls = 0

local npc = {
    id = "npc_l3_1",
    name = "Doyle",
    identitySeed = 4242,
    tacticalClass = "neutral",
    weaponMode = "melee",
    attackType = "auto",
    alive = true,
    persist = true,
    recruited = false,
    x = 101,
    y = 101,
    z = 0,
    presenceState = "live",
    presenceRevision = 1,
    liveBodyOnlineID = 777,
    health = { current = 85, max = 100, state = "normal", body = { wounds = {}, parts = {} } },
    stamina = { current = 90, max = 100, baseMax = 100, state = "normal" },
    equipment = {
        primaryFullType = "Base.Axe",
        worn = { Hat = "Base.Hat_Beany" },
        attached = {},
    },
    hostility = { players = "neutral", zombies = "hostile" },
    runtime = { appearanceCache = { hairModel = "Short" }, target = { kind = "zombie" } },
}

local coreIdSerial = 0
PNC = {
    Core = {
        Now = function() return now end,
        GenerateID = function(prefix)
            coreIdSerial = coreIdSerial + 1
            return tostring(prefix or "id") .. "_" .. tostring(coreIdSerial)
        end,
        IsAuthority = function() return true end,
        DeepCopy = deepCopy,
        ShallowCopy = function(t)
            local o = {}
            for k, v in pairs(t or {}) do o[k] = v end
            return o
        end,
        LogWarn = function() end,
        Distance = function(x1, y1, x2, y2)
            return math.sqrt((x1 - x2)^2 + (y1 - y2)^2)
        end,
        ForEachPlayer = function(cb)
            for _, p in ipairs(clients) do cb(p) end
        end,
    },
    Registry = {
        Data = { npc_l3_1 = npc },
        Get = function(id) return id == npc.id and npc or nil end,
        ForEach = function(cb) cb(npc) end,
    },
    SpatialIndex = {
        QueryNPCs = function() return { npc } end,
    },
    Skills = {
        BuildSnapshot = function()
            skillsSnapshotCalls = skillsSnapshotCalls + 1
            return { Axe = 4 }
        end,
    },
    Inventory = {
        BuildSummaryPayload = function()
            inventorySummaryCalls = inventorySummaryCalls + 1
            return { revision = 1, itemCount = 2 }
        end,
    },
    Client = {
        Internal = {
            GetPlayer = function() return modernPlayer end,
            RegisterServerCommand = function(cmd, cb)
                clientHandlers[cmd] = cb
            end,
            RequestID = function(prefix)
                return tostring(prefix or "req") .. "_1"
            end,
        },
    },
    KnowledgeInterest = {
        CollectNPCIDs = function() return {} end,
    },
}

Events = { OnDisconnect = { Add = function() end } }
isServer = function() return true end
isClient = function() return false end
sendServerCommand = function(player, _, command, args)
    sentToClients[#sentToClients + 1] = { player = player, command = command, args = args }
end
sendClientCommand = function(player, _, command, args)
    sentToServer[#sentToServer + 1] = { player = player, command = command, args = args }
end

require "PNC/Core/Base/PNC_Constants"
require "PNC/Core/Identity/PNC_Identity"
require "PNC/Core/Identity/PNC_Identity_Portrait"

PNC.Identity.GetCharacterSummary = function(record)
    return {
        identitySeed = record.identitySeed,
        displayName = record.name,
        archetypeID = "core.survivor",
        archetypeLabel = "Survivor",
        isFemale = false,
        survivor = {},
    }
end
PNC.Identity.RollAppearance = function(record)
    appearanceRollCalls = appearanceRollCalls + 1
    return record.runtime.appearanceCache
end

package.preload["PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldActorMap"] = function()
    return {}
end

require "PNC/Core/Networking/PNC_Network"
require "PNC/Networking/PNC_ServerCommandRouter"
require "PNC/Networking/Handlers/PNC_ServerCharacterReplicationCommandHandler"
require "PNC/Networking/PNC_ClientRosterCommands"
require "PNC/Networking/ClientRequests/PNC_ClientRequests_Bootstrap"

local Net = PNC.Network
local Const = PNC.Const
local Router = PNC.ServerCommandRouter
local Client = PNC.Client

-- 1. Verify full event classification table & unrelated-domain exclusion on every delta builder.
local expectedKinds = {
    tick = "presence",
    position_recovery = "presence",
    grounded_recovery = "presence",
    body_online_id = "presence",
    animation_scene = "presence",
    combat_damage = "combat_damage",
    damage = "combat_damage",
    player_damage = "combat_damage",
    zombie_bite = "combat_damage",
    attack_start = "combat_state",
    attack_hit = "combat_state",
    attack_finish = "combat_state",
    reload_finished = "combat_state",
    weapon_restore_ranged = "combat_state",
    weapon_fallback_melee = "combat_state",
    weapon_fallback_shove = "combat_state",
    weapon_mode = "combat_state",
    hostility = "combat_state",
    npc_wound = "health_wounds",
    self_bandaged = "health_wounds",
    bandaged = "health_wounds",
    medical_care_started = "health_wounds",
    medical_care_treating = "health_wounds",
    medical_care_ended = "health_wounds",
    infection_mild = "health_wounds",
    heal = "health_wounds",
    equipment = "equipment",
    equipment_changed = "equipment",
    equipment_visuals = "equipment",
    interest_enter = "full",
    spawn = "full",
    materialize = "full",
    death = "full",
    gap_repair = "full",
    reconnect = "full",
    fallback = "full",
}
for evName, expectedKind in pairs(expectedKinds) do
    T.equal(Net.ResolveEventDeltaKind(evName), expectedKind,
        "wrong deltaKind mapping for event " .. tostring(evName))
end

-- Check unrelated heavy domains are NOT built or emitted for narrow events.
appearanceRollCalls = 0
skillsSnapshotCalls = 0
inventorySummaryCalls = 0

for _, evName in ipairs({
    "attack_start", "reload_finished", "weapon_restore_ranged",
    "combat_damage", "npc_wound", "medical_care_treating",
    "self_bandaged", "equipment_changed", "position_recovery",
}) do
    local delta = Net.BuildDomainDelta(npc, Net.ResolveEventDeltaKind(evName), true)
    T.truthy(delta ~= nil, "narrow delta built for " .. evName)
    T.equal(delta.appearance, nil, evName .. " must not include appearance")
    T.equal(delta.skillLevels, nil, evName .. " must not include skillLevels")
    T.equal(delta.inventorySummary, nil, evName .. " must not include inventorySummary")
    T.equal(delta.vanillaTraits, nil, evName .. " must not include vanillaTraits")
    T.equal(delta.travel, nil, evName .. " must not include travel")
end
T.equal(appearanceRollCalls, 0, "narrow deltas must never roll full appearance")
T.equal(skillsSnapshotCalls, 0, "narrow deltas must never build skillLevels")
T.equal(inventorySummaryCalls, 0, "narrow deltas must never build inventorySummary")

-- Reset record replica metadata before wire session.
npc.runtime.domainRevisions = nil
npc.runtime.replicaIncarnation = nil
npc.runtime.replicaSequence = 0

-- 2. Negotiate mixed capabilities: modernPlayer supports P1-P4 + domain deltas; legacyPlayer disables domain deltas.
sentToClients = {}
Router.Handle(Const.CMD_FULL_SYNC_REQUEST, modernPlayer, {
    domainDeltaProtocol = Const.DOMAIN_DELTA_PROTOCOL,
    portraitProtocol = Const.ROSTER_PORTRAIT_PROTOCOL,
})
T.equal(#sentToClients, 3, "modern join sends begin/chunk/end")
for _, pkt in ipairs(sentToClients) do
    clientHandlers[pkt.command](pkt.args)
end

sentToClients = {}
Router.Handle(Const.CMD_FULL_SYNC_REQUEST, legacyPlayer, {
    domainDeltaProtocol = 0,
})
T.equal(#sentToClients, 3, "legacy join sends begin/chunk/end")

-- Enter interest for both players -> initial baseline "full" snapshot stamped with replicaIncarnation & domainRevisions.
sentToClients = {}
Net.RefreshInterestSets(11000)
T.equal(#sentToClients, 2, "both modern & legacy enter interest")
for _, pkt in ipairs(sentToClients) do
    if pkt.player == modernPlayer then
        T.equal(pkt.args.snapshot.deltaKind, "full", "interest_enter sends full baseline")
        T.truthy(pkt.args.snapshot.portraitRef ~= nil, "modern interest_enter preserves lean portraitRef")
        T.equal(pkt.args.snapshot.portrait, nil, "modern interest_enter omits inline portrait")
        clientHandlers[pkt.command](pkt.args)
    else
        T.truthy(pkt.args.snapshot.portrait ~= nil, "legacy interest_enter keeps inline portrait")
    end
end

local modernBaseline = assert(Net.ClientState.snapshots.npc_l3_1)
T.equal(modernBaseline.skillLevels.Axe, 4, "interest_enter established detailed skill baseline on client")

-- 3. Mixed-capability narrow mutation broadcast:
--    modernPlayer receives narrow combat_state delta + portraitRef (no skills/appearance rebuild),
--    legacyPlayer receives full fallback snapshot + inline portrait!
npc.weaponMode = "ranged"
npc.equipment.primaryFullType = "Base.Shotgun"
sentToClients = {}
local fullBeforeMixed = tonumber(Net.Metrics.fullSnapshots) or 0
local fallbackBeforeMixed = tonumber(Net.Metrics.fallbackSnapshots) or 0
local combatStateBeforeMixed = tonumber(Net.Metrics.combatStateDeltas) or 0

Net.BroadcastRecord(npc, "weapon_restore_ranged")

T.equal(#sentToClients, 2, "broadcast reaches both modern & legacy recipients")
local modMsg, legMsg
for _, pkt in ipairs(sentToClients) do
    if pkt.player == modernPlayer then modMsg = pkt.args else legMsg = pkt.args end
end
T.truthy(modMsg and legMsg)
T.equal(modMsg.snapshot.deltaKind, "combat_state", "modern client receives narrow combat_state delta")
T.equal(modMsg.snapshot.domainRevision, 1, "first combat_state delta is rev 1")
T.equal(modMsg.snapshot.skillLevels, nil, "modern narrow delta omits skillLevels")
T.equal(legMsg.snapshot.deltaKind, "full", "legacy client receives full fallback snapshot")
T.truthy(legMsg.snapshot.portrait ~= nil, "legacy fallback preserves inline portrait")
T.equal(Net.Metrics.combatStateDeltas, combatStateBeforeMixed + 1, "server built 1 combat_state delta")
T.equal(Net.Metrics.fallbackSnapshots, fallbackBeforeMixed + 1, "server built 1 fallback snapshot for legacy")

-- Apply modern combat_state rev 1 -> merges weaponMode without clobbering existing skillLevels baseline!
clientHandlers[Const.CMD_SYNC_RECORD](modMsg)
T.equal(Net.ClientState.snapshots.npc_l3_1.weaponMode, "ranged", "modern client updated weaponMode from delta")
T.equal(Net.ClientState.snapshots.npc_l3_1.skillLevels.Axe, 4, "merge preserved baseline skillLevels")
T.equal(Net.ClientState.domainRevisions.npc_l3_1.domains.combat_state, 1, "client recorded domain rev 1")

-- 4. Duplicate/stale domain delta is ignored cleanly.
local gapsBefore = Net.ClientState.revisionGapsDetected
npc.weaponMode = "stale_should_not_apply"
local staleCopy = deepCopy(modMsg.snapshot)
staleCopy.weaponMode = "stale_should_not_apply"
staleCopy.domainRevision = 1
clientHandlers[Const.CMD_SYNC_RECORD]({ event = "weapon_restore_ranged", snapshot = staleCopy })
T.equal(Net.ClientState.snapshots.npc_l3_1.weaponMode, "ranged", "stale rev<=1 ignored")
T.equal(Net.ClientState.revisionGapsDetected, gapsBefore, "stale delta did not count as gap")
npc.weaponMode = "ranged"

-- 5. Revision gap injection: skip rev 2 on the wire and deliver rev 3!
now = now + 2000
local skippedRev2 = Net.BuildDomainDelta(npc, "combat_state", true) -- rev 2 on server
T.equal(skippedRev2.domainRevision, 2)
-- Mutate HP/equipment on server too so repair snapshot proves full-current convergence!
npc.health.current = 60
npc.weaponMode = "melee"
local rev3Delta = Net.BuildDomainDelta(npc, "combat_state", true) -- rev 3 (base=2 > client last=1)
T.equal(rev3Delta.domainRevision, 3)

sentToServer = {}
local gapsBeforeInject = Net.ClientState.revisionGapsDetected
clientHandlers[Const.CMD_SYNC_RECORD]({
    event = "attack_start",
    snapshot = rev3Delta,
})
T.equal(Net.ClientState.revisionGapsDetected, gapsBeforeInject + 1, "client detected combat_state gap (1 -> 3)")
T.equal(#sentToServer, 1, "client emitted exactly 1 RequestRecordRepair")
T.equal(sentToServer[1].command, Const.CMD_REQUEST_RECORD_REPAIR)
T.equal(sentToServer[1].args.id, "npc_l3_1")
T.equal(sentToServer[1].args.reason, "gap_repair")

-- Route repair request through real ServerCommandRouter -> targeted full snapshot ONLY to modernPlayer!
sentToClients = {}
Router.Handle(sentToServer[1].command, modernPlayer, sentToServer[1].args)
T.equal(#sentToClients, 1, "repair response targets only requesting client")
T.equal(sentToClients[1].player, modernPlayer)
T.equal(sentToClients[1].args.snapshot.deltaKind, "full", "repair delivers full snapshot")
T.equal(sentToClients[1].args.snapshot.domainRevisions.combat_state, 3, "repair aligns domain revision")

clientHandlers[sentToClients[1].command](sentToClients[1].args)
T.equal(Net.ClientState.snapshots.npc_l3_1.hpCurrent, 60, "repair converged out-of-band HP update")
T.equal(Net.ClientState.snapshots.npc_l3_1.weaponMode, "melee", "repair converged weaponMode")
T.equal(Net.ClientState.domainRevisions.npc_l3_1.domains.combat_state, 3, "client domain revision aligned to 3")

-- 6. Unsupported delta kind / protocol fallback triggers safe repair and does not corrupt state.
now = now + 2000
sentToServer = {}
local unsupportedBefore = Net.ClientState.unsupportedDeltas
clientHandlers[Const.CMD_SYNC_RECORD]({
    event = "future_event",
    snapshot = {
        id = "npc_l3_1",
        deltaKind = "future_unknown_v99",
        weaponMode = "corrupted",
    },
})
T.equal(Net.ClientState.unsupportedDeltas, unsupportedBefore + 1, "unsupported delta detected")
T.equal(Net.ClientState.snapshots.npc_l3_1.weaponMode, "melee", "unsupported delta did not mutate client state")
T.equal(#sentToServer, 1)
T.equal(sentToServer[1].args.reason, "unsupported_delta")

-- 7. Equipment narrow delta updates equipment + portraitRef cleanly (NPCReplicationScaling P1-P4 preserved).
now = now + 2000
npc.equipment.worn.Hat = "Base.Hat_Helmet"
sentToClients = {}
local eqBefore = Net.Metrics.equipmentDeltas
Net.BroadcastRecord(npc, "equipment_changed")
T.equal(Net.Metrics.equipmentDeltas, eqBefore + 1, "equipment_changed routed to equipment delta")
local eqMod
for _, pkt in ipairs(sentToClients) do
    if pkt.player == modernPlayer then eqMod = pkt.args end
end
T.equal(eqMod.snapshot.deltaKind, "equipment")
T.equal(eqMod.snapshot.equipmentSummary.worn.Hat, "Base.Hat_Helmet")
T.truthy(eqMod.snapshot.portraitRef ~= nil, "equipment delta keeps lean portraitRef")
clientHandlers[Const.CMD_SYNC_RECORD](eqMod)
T.equal(Net.ClientState.snapshots.npc_l3_1.equipmentSummary.worn.Hat, "Base.Hat_Helmet",
    "client applied equipment delta cleanly")

-- 8. Removal clears client domain revision tracking.
clientHandlers[Const.CMD_REMOVE_RECORD]({ id = "npc_l3_1", revision = 999, reason = "test_remove" })
T.equal(Net.ClientState.snapshots.npc_l3_1, nil)
T.equal(Net.ClientState.domainRevisions.npc_l3_1, nil, "removal cleared client domain revision tracking")

T.finish("pnc_lightweight_domain_delta_replication_smoke")
