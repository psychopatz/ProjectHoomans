-- Smoke test: Dynamic Trading role isolation, compositional contextual greetings,
-- 2-second interruptible speaker-switch handoff with log preservation/resume,
-- and standardized red Goodbye / close-as-goodbye controller.

local repoRoot = "/home/psychopatz/Zomboid/Workshop/ProjectHoomans"
local coreRoot = "/home/psychopatz/Zomboid/Workshop/psychopatzCore"
local dtRoot = "/home/psychopatz/Zomboid/Workshop/DynamicTrading"

package.path = table.concat({
    repoRoot .. "/Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua",
    repoRoot .. "/Contents/mods/ProjectHoomans/42.20/media/lua/client/?.lua",
    repoRoot .. "/Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua",
    repoRoot .. "/Contents/mods/ProjectHoomans/common/media/lua/shared/?.lua",
    repoRoot .. "/Contents/mods/ProjectHoomans/common/media/lua/client/?.lua",
    repoRoot .. "/Contents/mods/ProjectHoomans/common/media/lua/server/?.lua",
    coreRoot .. "/Contents/mods/PsychopatzCore/common/media/lua/shared/?.lua",
    coreRoot .. "/Contents/mods/PsychopatzCore/common/media/lua/client/?.lua",
    dtRoot .. "/Contents/mods/DTCommon/42.20/media/lua/shared/?.lua",
    dtRoot .. "/Contents/mods/DTCommon/42.20/media/lua/client/?.lua",
    package.path,
}, ";")

local function assertTrue(cond, msg)
    if not cond then error("ASSERTION FAILED: " .. tostring(msg)) end
end

-- Stub minimal PZ/Core globals
_G.getTextOrNull = function() return nil end
_G.getTimestampMs = function() return 10000 end
_G.PsychopatzCore = _G.PsychopatzCore or {
    Conversation = {
        Text = {
            Resolve = function(payload, fb)
                if type(payload) == "table" then return payload.fallback or payload.text or fb or "" end
                return tostring(payload or fb or "")
            end,
            RegisterFallback = function() end,
        },
        Registry = {
            RegisterBlock = function() end,
            RegisterCategory = function() end,
        },
    },
}

-- 1. Dynamic Trading isolation check
_G.PNC = _G.PNC or {}
_G.PNC.Factions = {
    IsPlayerFaction = function(fid) return fid == "patz_fellowship" end,
}
_G.DynamicTrading = {
    Traders = {
        GetByNPC = function(id)
            -- Even if a trader record exists for an NPC ID, non-traders must be rejected!
            return { id = "trader_" .. tostring(id), npcID = id, active = true }
        end,
    },
}

-- Verify DTCommon_TraderConversation.CanOpenNPC rejects colonists/companions/looters/player-faction
local dtConvSrc = assert(io.open(dtRoot .. "/Contents/mods/DTCommon/42.20/media/lua/client/DTCommon/DTCommon_TraderConversation.lua", "r")):read("*a")
assertTrue(dtConvSrc:find("isNonTraderEntry", 1, true) ~= nil, "DTCommon_TraderConversation must guard against non-trader entries")
assertTrue(dtConvSrc:find("next_person", 1, true) == nil, "DTCommon_TraderConversation must not emit next_person in RESPONSE CHANNEL")
assertTrue(dtConvSrc:find('semanticRole = "farewell"', 1, true) ~= nil, "DTCommon_TraderConversation goodbye must carry semanticRole=farewell")

local dtPackSrc = assert(io.open(dtRoot .. "/Contents/mods/DTCommon/42.20/media/lua/shared/DTCommon/DTCommon_SemanticPack.lua", "r")):read("*a")
local dtBlockCount = 0
local dtGatedCount = 0
for _ in dtPackSrc:gmatch('blockID = "dt_block_') do dtBlockCount = dtBlockCount + 1 end
if dtBlockCount == 0 then
    for _ in dtPackSrc:gmatch('"dt_block_[%w_]+"') do dtBlockCount = dtBlockCount + 1 end
end
for _ in dtPackSrc:gmatch('capabilitiesRequired = { TRADE_CAPABILITY }') do dtGatedCount = dtGatedCount + 1 end
assertTrue(dtBlockCount >= 7, "Expected >= 7 DT semantic blocks, found " .. tostring(dtBlockCount))
assertTrue(dtGatedCount >= dtBlockCount, "Every DT greeting/rumor/farewell block must require TRADE_CAPABILITY (" .. tostring(dtGatedCount) .. "/" .. tostring(dtBlockCount) .. ")")

-- 2. Compositional dynamic greetings across roles, family bonds, age bands & states
local SwitchCtrl = require "PNC/ConvoEngine/Dialogue/ConversationSwitchAndFarewell"
assertTrue(type(SwitchCtrl) == "table", "ConversationSwitchAndFarewell should load cleanly")

local function greetFor(actor, extraCtx, salt)
    local line, poolID = SwitchCtrl.ResolveOpeningLine(nil, actor, { id = "player", name = "Patz" }, extraCtx, salt)
    assertTrue(poolID == "semantic.greeting", "Fresh opening must use semantic.greeting")
    assertTrue(type(line) == "string" and #line > 0, "Greeting must be non-empty for " .. tostring(salt))
    assertTrue(line:find("{", 1, true) == nil, "Greeting must have no unresolved tokens: " .. tostring(line))
    return line
end

local gLover = greetFor({ id = "n1", name = "Elena", npcType = "colonist", familyRole = "lover" }, {}, "lover")
local gDad = greetFor({ id = "n2", name = "Marcus", npcType = "colonist", familyRole = "father" }, {}, "dad")
local gTrader = greetFor({ id = "n3", name = "Vance", npcType = "trader", isTrader = true }, {}, "trader")
local gColonistWork = greetFor({ id = "n4", name = "Joe Mello", npcType = "colonist", colonist = true }, { ["state.job"] = "carpentry", working = true }, "col_work")
local gLooter = greetFor({ id = "n5", name = "Rico", npcType = "looter" }, {}, "looter")

assertTrue(gLover ~= gTrader, "Lover greeting should differ from trader greeting")
assertTrue(gDad ~= gLooter, "Dad greeting should differ from looter greeting")
assertTrue(gColonistWork ~= gTrader, "Colonist greeting should differ from trader greeting")
assertTrue(gTrader:lower():find("trade") ~= nil or gTrader:lower():find("stock") ~= nil or gTrader:lower():find("deal") ~= nil or gTrader:lower():find("pack") ~= nil or gTrader:lower():find("browse") ~= nil,
    "Trader greeting should feel trader-specific: " .. gTrader)

-- 3. 2-second speaker-switch handoff with per-actor log preservation & resume
SwitchCtrl.Reset()
local actorA = { id = "npc_joe", name = "Joe Mello", npcType = "colonist", colonist = true }
local actorB = { id = "npc_fran", name = "Fran", npcType = "companion", isCompanion = true }
local roster = { actorA, actorB }
local activeIdx = 1

local view = {
    session = { npcID = actorA.id },
    messages = {
        { speaker = "Joe Mello", text = gColonistWork },
        { speaker = "YOU", text = "How is the wall coming along?" },
    },
    appendMessage = function(self, speaker, text)
        self.messages[#self.messages + 1] = { speaker = speaker, text = text }
    end,
    getMessages = function(self) return self.messages end,
    setMessages = function(self, msgs) self.messages = msgs end,
}

local okSw, statusSw = SwitchCtrl.RequestSpeakerSwitch(view, 1, {
    roster = roster,
    currentIndex = activeIdx,
    partner = { id = "player", name = "Patz" },
    now = 10000,
    delayMs = 2000,
    applySwitch = function(_, toIndex) activeIdx = toIndex end,
})
assertTrue(okSw == true and statusSw == "handoff_scheduled", "First click must schedule 2s handoff")
assertTrue(activeIdx == 1, "Speaker must NOT switch before 2s elapses")
assertTrue(#view.messages == 4, "Pause-switch say + NPC ack must be appended to log before switching (got " .. tostring(#view.messages) .. ")")

-- Tick at +1500ms: still waiting
assertTrue(SwitchCtrl.TickPendingSwitches(11500) == 0, "Must not execute switch at 1500ms")
assertTrue(activeIdx == 1, "Still on Actor A at 1500ms")

-- Tick at +2000ms: executes switch to Actor B
assertTrue(SwitchCtrl.TickPendingSwitches(12000) == 1, "Must execute switch at 2000ms")
assertTrue(activeIdx == 2, "Must now be on Actor B")
assertTrue(view.session.pausedActors["npc_joe"] == true, "Actor A must be marked paused")
assertTrue(#view.session.historyByActor["npc_joe"] == 4, "Actor A's 4-message log must be saved")
assertTrue(#view.messages == 1, "Actor B's fresh log must start with Actor B's greeting")

-- Switch back to Actor A and verify double-click immediate jump + log restore + resume line
local okBack1, statusBack1 = SwitchCtrl.RequestSpeakerSwitch(view, -1, {
    roster = roster,
    currentIndex = activeIdx,
    partner = { id = "player", name = "Patz" },
    now = 13000,
    delayMs = 2000,
    applySwitch = function(_, toIndex) activeIdx = toIndex end,
})
assertTrue(okBack1 == true and statusBack1 == "handoff_scheduled", "Switch back should schedule handoff")

-- Immediate second click interrupts 2s timer and jumps right away
local okBack2, statusBack2 = SwitchCtrl.RequestSpeakerSwitch(view, -1, {
    roster = roster,
    currentIndex = activeIdx,
    partner = { id = "player", name = "Patz" },
    now = 13200,
    applySwitch = function(_, toIndex) activeIdx = toIndex end,
})
assertTrue(okBack2 == true and statusBack2 == "switched_immediate", "Second click during 2s delay must jump immediately")
assertTrue(activeIdx == 1, "Must be back on Actor A")
assertTrue(#view.messages == 5, "Actor A's 4 saved messages + 1 resume line must be present (got " .. tostring(#view.messages) .. ")")
assertTrue(view.messages[2].text == "How is the wall coming along?", "Actor A's prior conversation must be preserved")
assertTrue(view.session.pausedActors["npc_joe"] == nil, "Paused flag clears after resuming Actor A")

-- 4. Standardized Red Goodbye + Close-as-Goodbye idempotency
local fw = SwitchCtrl.ResolveFarewell(actorA, { id = "player", name = "Patz" }, {}, "bye_test")
assertTrue(fw.choiceSpec.semanticRole == "farewell", "Farewell choice must have semanticRole=farewell")
assertTrue(fw.choiceSpec.isFarewell == true, "Farewell choice must have isFarewell=true")
assertTrue(fw.choiceSpec.variant == "danger", "Farewell choice must have variant=danger (red)")
assertTrue(type(fw.playerLine) == "string" and #fw.playerLine > 0, "Dynamic farewell player line required")
assertTrue(type(fw.npcReply) == "string" and #fw.npcReply > 0, "Dynamic farewell NPC reply required")

-- Schedule a switch, then close via X (TriggerStandardizedGoodbye) -> must cancel switch, emit farewell once, and call closeFn
SwitchCtrl.RequestSpeakerSwitch(view, 1, {
    roster = roster,
    currentIndex = 1,
    now = 15000,
    delayMs = 2000,
    applySwitch = function(_, toIndex) activeIdx = toIndex end,
})
local closeCount = 0
local msgsBeforeClose = #view.messages
local okClose1 = SwitchCtrl.TriggerStandardizedGoodbye(view, function() closeCount = closeCount + 1 end, {
    actor = actorA,
    salt = "close_x",
})
assertTrue(okClose1 == true and closeCount == 1, "First standardized close must invoke closeFn")
assertTrue(#view.messages == msgsBeforeClose + 2, "Standardized close must append player+NPC farewell lines")
assertTrue(view.session.pendingSpeakerSwitch == nil, "Standardized close must cancel any pending speaker switch")
assertTrue(SwitchCtrl.TickPendingSwitches(20000) == 0, "Cancelled switch must never fire after close")

-- Second call is idempotent (no duplicate farewell lines)
local okClose2, closeStatus2 = SwitchCtrl.TriggerStandardizedGoodbye(view, function() closeCount = closeCount + 1 end, {
    actor = actorA,
    salt = "close_x",
})
assertTrue(okClose2 == true and closeStatus2 == "already_triggered", "Second close must be idempotent")
assertTrue(#view.messages == msgsBeforeClose + 2, "Idempotent close must not duplicate farewell lines")

print("PASS pnc_role_isolation_switch_and_farewell_smoke")
