-- Regression test: combat callout audience isolation & solo fallback.
-- Ensures hostile and non-allied NPCs NEVER address the player (e.g. never
-- yelling "Cover me, Psycho!" while reloading), only address actual squadmates
-- on their own team, and emit NO addressee name when alone.

local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = {
    Const = {
        TACTICAL_CLASS_HOSTILE = "hostile",
        PRESENCE_LIVE = "live",
        ORDER_FOLLOW = "follow",
    },
}

local playerObj = {
    isDead = function() return false end,
    getX = function() return 10 end,
    getY = function() return 10 end,
    getZ = function() return 0 end,
    getUsername = function() return "Psycho" end,
    getDisplayName = function() return "Psycho" end,
    getDescriptor = function()
        return { getForename = function() return "Psycho" end }
    end,
}

PNC.Core = {
    Now = function() return 10000 end,
    DistanceSq = function(x1, y1, x2, y2)
        local dx, dy = (x2 - x1), (y2 - y1)
        return dx * dx + dy * dy
    end,
    ForEachPlayer = function(fn) fn(playerObj) end,
}

local TokenFormatter = T.load("ProjectHoomans", "shared", "PNC/ConvoEngine/TokenFormatter.lua")
local Audience = T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticAudienceContext.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Perception/PNC_Perception/AllyThreatEligibility.lua")
T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Context.lua")
T.load("ProjectHoomans", "server", "PNC/Semantics/PNC_SemanticCombatTargetCallouts_Situations.lua")

local S = PNC.Semantics.CombatTargetCallouts
local I = PNC.Semantics.CombatTargetCalloutsInternal

-- Stub delivery and semantic line resolver to capture exact tokens & rendered text.
local capturedCalls = {}
S.ResolveSemanticLine = function(speaker, eventType, act, tCls, ref, _, toks, opts)
    local raw = "Reloading! Cover me, {addressee.name}!"
    local rendered = TokenFormatter.Format(raw, toks or {})
    capturedCalls[#capturedCalls + 1] = {
        speakerId = speaker.id,
        role = opts and opts.replyRole,
        addresseeToken = toks and toks["addressee.name"],
        rendered = rendered,
    }
    return rendered, { realizationID = "test.reload", presentationClass = "BARK" }
end
S.DeliverBark = function() return 1 end

local hostileSolo = {
    id = "raider_1",
    name = "Dante",
    alive = true,
    isHostile = true,
    tacticalClass = "hostile",
    activeBehavior = "hostile",
    x = 12, y = 10, z = 0,
    runtime = {},
}
local hostileMate = {
    id = "raider_2",
    name = "Vance",
    alive = true,
    isHostile = true,
    tacticalClass = "hostile",
    activeBehavior = "hostile",
    x = 14, y = 10, z = 0,
    runtime = {},
}
local neutralStranger = {
    id = "stranger_1",
    name = "Jordan",
    alive = true,
    isHostile = false,
    x = 12, y = 11, z = 0,
    runtime = {},
}
local companionAlly = {
    id = "comp_1",
    name = "Mara",
    alive = true,
    recruited = true,
    ownerUsername = "Psycho",
    x = 12, y = 12, z = 0,
    runtime = {},
}

-- 1) Solo hostile NPC near player "Psycho": no squadmates in registry.
PNC.Registry = { Data = { raider_1 = hostileSolo } }
PNC.SpatialIndex = { QueryNPCs = function() return { hostileSolo } end }

T.equal(I.FindLeastThreatenedHelper(hostileSolo, 16, 10000), nil,
    "solo hostile NPC must NOT pick nearby player as helper")
T.equal(I.FindNearbyPlayerAddressee(hostileSolo, 16), nil,
    "solo hostile NPC must NOT pick nearby player as addressee")
local idleHelper = I.FindIdleBystanderHelper(hostileSolo, 16, 10000)
T.equal(idleHelper, nil,
    "solo hostile NPC must NOT pick nearby player as idle bystander")

capturedCalls = {}
local spokeSolo = S.TryEmitReloadCallout(hostileSolo, { kind = "player", x = 10, y = 10, z = 0 }, 10000, "test:solo")
T.equal(spokeSolo, true, "solo hostile reload callout still emits")
T.equal(#capturedCalls, 1, "one callout captured")
T.equal(capturedCalls[1].addresseeToken, "",
    "solo hostile reload callout passes empty addressee.name (no 'Psycho', 'everyone', or 'friend')")
T.equal(capturedCalls[1].rendered, "Reloading! Cover me!",
    "solo hostile reload callout collapses cleanly with NO name at all")
T.falsy(string.find(capturedCalls[1].rendered, "Psycho", 1, true),
    "solo hostile reload callout never leaks player name")

-- 2) Hostile NPC with a fellow hostile squadmate ("Vance") near player "Psycho":
PNC.Registry = { Data = { raider_1 = hostileSolo, raider_2 = hostileMate } }
PNC.SpatialIndex = { QueryNPCs = function() return { hostileSolo, hostileMate } end }

local hostileHelper = I.FindLeastThreatenedHelper(hostileSolo, 16, 20000)
T.truthy(hostileHelper ~= nil and hostileHelper.isPlayer == false,
    "hostile NPC with squadmate picks squadmate, not player")
T.equal(hostileHelper.id, "raider_2", "hostile NPC picks fellow hostile squadmate Vance")

capturedCalls = {}
local spokeSquad = S.TryEmitReloadCallout(hostileSolo, { kind = "player", x = 10, y = 10, z = 0 }, 20000, "test:squad")
T.equal(spokeSquad, true, "squad hostile reload callout emits")
T.equal(capturedCalls[1].addresseeToken, "Vance",
    "hostile NPC addresses fellow hostile squadmate Vance")
T.equal(capturedCalls[1].rendered, "Reloading! Cover me, Vance!",
    "hostile NPC asks squadmate Vance to cover, never player Psycho")

-- 3) Neutral unrelated stranger near player "Psycho":
PNC.Registry = { Data = { stranger_1 = neutralStranger } }
PNC.SpatialIndex = { QueryNPCs = function() return { neutralStranger } end }
T.equal(I.FindLeastThreatenedHelper(neutralStranger, 16, 30000), nil,
    "unrelated neutral stranger must NOT ask player Psycho for combat cover")

-- 4) Recruited companion near player "Psycho":
PNC.Registry = { Data = { comp_1 = companionAlly } }
PNC.SpatialIndex = { QueryNPCs = function() return { companionAlly } end }
local compHelper = I.FindLeastThreatenedHelper(companionAlly, 16, 40000)
T.truthy(compHelper ~= nil and compHelper.isPlayer == true,
    "recruited companion DOES pick allied player Psycho as helper")
T.equal(compHelper.name, "Psycho", "companion resolves player name Psycho")

capturedCalls = {}
local spokeComp = S.TryEmitReloadCallout(companionAlly, { kind = "zombie", x = 15, y = 12, z = 0 }, 40000, "test:comp")
T.equal(spokeComp, true, "companion reload callout emits")
T.equal(capturedCalls[1].rendered, "Reloading! Cover me, Psycho!",
    "companion legitimately asks allied player Psycho to cover")

-- 5) AudienceContext hostility matrix: all hostility variants exclude the player.
local hostileVariants = {
    { id = "h1", isHostile = true },
    { id = "h2", tacticalClass = "hostile" },
    { id = "h3", activeBehavior = "hostile" },
    { id = "h4", hostility = { mode = "hostile" } },
    { id = "h5", hostility = { attackPlayers = true } },
    { id = "h6", runtime = { hostileToPlayer = true } },
    { id = "h7", runtime = { target = { kind = "player" } } },
}
for _, npc in ipairs(hostileVariants) do
    T.equal(Audience.IsHostileToPlayer(npc, playerObj), true,
        "IsHostileToPlayer detects hostility for " .. npc.id)
    T.equal(Audience.CanAddressPlayerAsAlly(npc, playerObj, { requireAlly = true }), false,
        "CanAddressPlayerAsAlly rejects hostile " .. npc.id)
    local aud = Audience.Resolve(npc, { { id = "player", name = "Psycho", isPlayer = true, player = playerObj } }, {
        includeNearbyPlayer = true,
        requireAlly = true,
    })
    T.equal(aud.includesPlayer, false, "Audience.Resolve excludes player for hostile " .. npc.id)
    T.equal(aud.label, "", "Audience.Resolve returns empty label when hostile has no allies")
end

T.finish("pnc_combat_callout_audience_isolation_smoke")
