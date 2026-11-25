-- Unified Command-to-IR & Dialogue Bridge + GrammarJoin smoke test.
package.path = "./tests/?.lua;./tests/?/init.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua;" .. package.path

local T = require "support.test"

local simNow = 300000
local delivered = {}

local npc1 = { id = "npc_1", name = "Jarrod", alive = true }
local npc2 = { id = "npc_2", name = "Meghan", alive = true }
local npc3 = { id = "npc_3", name = "Rory", alive = true }
local player = { getDisplayName = function() return "Rick" end }

_G.PNC = {
    Core = { Now = function() return simNow end },
    Registry = {
        Get = function(id)
            if id == "npc_1" then return npc1 end
            if id == "npc_2" then return npc2 end
            if id == "npc_3" then return npc3 end
            return nil
        end,
    },
    Semantics = {
        SpeechTransport = {
            ResolveLine = function(rec, spec)
                return tostring(rec.id) .. ":" .. tostring(spec.poolID) .. ":" .. tostring(spec.role)
                    .. ":" .. tostring(spec.tokens["addressee.name"])
                    .. ":" .. tostring(spec.tokens["slot.target"]), { poolID = spec.poolID }
            end,
            Deliver = function(rec, at, opts)
                delivered[#delivered + 1] = { id = rec.id, at = at, text = opts.text, act = opts.act }
                return 1
            end,
        },
    },
}

local Grammar = require "PNC/ConvoEngine/GrammarJoin"
local Bridge = require "PNC/ConvoEngine/CommandIRBridge"

-- 1) GrammarJoin fixes missing-glyph em-dashes ("Good—nobody" -> "Good - nobody")
T.equal(Grammar.CleanSurface("Good\226\128\148nobody gets left behind."), "Good - nobody gets left behind.",
    "em-dash converted to PZ-font-safe ASCII dash with spaces")
T.equal(Grammar.CleanSurface("Hold on ,  please\226\128\166"), "Hold on, please...",
    "collapses extra spaces, punctuation spacing, and ellipsis")
T.equal(Grammar.FormatTargetWithArticle("garbage"), "the garbage", "adds definite article")
T.equal(Grammar.FormatTargetWithArticle("the campfire"), "the campfire", "preserves existing article")
T.equal(Grammar.FormatTargetWithArticle("there"), "there", "skips article for deictics")
T.equal(Grammar.JoinClause("Good", "nobody gets left behind."), "Good, nobody gets left behind.", "safe clause join")

-- 2) Command-to-IR normalization
local irInv = Bridge.BuildIRFromCommand("access_inventory", { source = "colonist_activities" })
T.equal(irInv.action, "OPEN_INVENTORY", "access_inventory maps to OPEN_INVENTORY")
T.equal(irInv.extensions.commandRole, "ack_inventory", "access_inventory role")

local irWait = Bridge.BuildIRFromCommand("wait_at", { target = "garbage", isGroup = true })
T.equal(irWait.action, "WAIT_AT", "wait_at maps to WAIT_AT")
T.equal(irWait.target, "the garbage", "target formatted with article")
T.equal(irWait.extensions.audienceScope.scope, "GROUP", "group scope preserved")

local irEmote = Bridge.BuildIRFromEmote("shhh")
T.equal(irEmote.action, "QUIET", "shhh emote maps to QUIET")
T.equal(irEmote.extensions.commandRole, "emote_shhh", "shhh role")

-- 3) Single-target command emits ConvoDSL line & anti-spam cooldown prevents rapid duplicates
delivered = {}
local n1 = Bridge.EmitCommandFeedback(player, "access_inventory", "npc_1", "accepted", { now = simNow })
T.equal(n1, 1, "access_inventory emits 1 reply")
T.truthy(string.find(delivered[1].text, "npc_1:semantic.command.ack:ack_inventory:Rick", 1, true) ~= nil,
    "delivered ack_inventory line")

local n1Dup = Bridge.EmitCommandFeedback(player, "access_inventory", "npc_1", "accepted", { now = simNow + 500 })
T.equal(n1Dup, 0, "anti-spam cooldown suppresses immediate duplicate")

-- 4) Group command caps responders to 2 and staggers delivery timestamps
delivered = {}
local nGrp = Bridge.EmitCommandFeedback(player, "corpse_haul", { npc1, npc2, npc3 }, "accepted", { now = simNow + 5000 })
T.equal(nGrp, 2, "group command caps responders to 2")
T.equal(delivered[2].at - delivered[1].at, 900, "second responder staggered by 900ms")

-- 5) Rejected command emits reject_generic with REFUSE act
delivered = {}
local nRej = Bridge.EmitCommandFeedback(player, "sleep", "npc_2", "rejected", { now = simNow + 10000 })
T.equal(nRej, 1, "rejected command emits rejection line")
T.equal(delivered[1].act, "REFUSE", "rejection uses REFUSE act")
T.truthy(string.find(delivered[1].text, "reject_generic", 1, true) ~= nil, "uses reject_generic role")

-- 6) Emote feedback routes through same pipeline
delivered = {}
local nEm = Bridge.EmitEmoteFeedback(player, "shhh", { npc3 }, { now = simNow + 15000 })
T.equal(nEm, 1, "emote feedback delivered")
T.truthy(string.find(delivered[1].text, "emote_shhh", 1, true) ~= nil, "uses emote_shhh role")

print("pnc_semantic_command_ir_bridge_smoke: OK")
