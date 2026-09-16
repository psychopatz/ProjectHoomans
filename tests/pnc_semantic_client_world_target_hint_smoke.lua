local T = require "tests/support/test"
T.addPackagePaths()

PsychopatzCore = {}
PNC = { Semantics = {} }

local object = {
    getObjectName = function() return "IsoObject" end,
    getName = function() return nil end,
    getSpriteName = function() return "trashcontainers_01_16" end,
    getSprite = function()
        return { getName = function() return "trashcontainers_01_16" end }
    end,
}
local clutterObjectA = {
    getObjectName = function() return "IsoObject" end,
    getName = function() return "unrelated furniture" end,
    getSpriteName = function() return "furniture_misc_01_0" end,
}
local clutterObjectB = {
    getObjectName = function() return "IsoObject" end,
    getName = function() return "unrelated furniture" end,
    getSpriteName = function() return "furniture_misc_01_1" end,
}
local squareLookups = 0
local square = {
    getX = function() return 4 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getObjects = function()
        return {
            size = function() return 1 end,
            get = function(_, index) return index == 0 and object or nil end,
        }
    end,
}
local clutterSquareA = {
    getX = function() return -11 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getObjects = function() return { clutterObjectA } end,
}
local clutterSquareB = {
    getX = function() return -10 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getObjects = function() return { clutterObjectB } end,
}
local cell = {
    getGridSquare = function(_, x, y, z)
        squareLookups = squareLookups + 1
        if x == -11 and y == 0 and z == 0 then return clutterSquareA end
        if x == -10 and y == 0 and z == 0 then return clutterSquareB end
        return x == 4 and y == 0 and z == 0 and square or nil
    end,
}
local origin = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local now = 100
local scans = 0

getCell = function()
    scans = scans + 1
    return cell
end
getTimeInMillis = function() return now end

local Hints = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticWorldTargetHints.lua"
)

local hint, reason = Hints.Resolve({
    kind = "phrase",
    text = "bin",
    unresolved = true,
}, { origin = origin })
T.truthy(hint, "a loaded recycle-bin sprite is found for the word bin")
T.equal(reason, nil, "a confident client target has no failure reason")
T.equal(hint.kind, "recycle_bin", "the client returns the canonical target kind")
T.equal(hint.x, 4, "the client returns only the object position")
T.equal(hint.y, 0, "the client returns the object position y")
T.truthy(hint.score >= 0.9, "an exact target alias receives high confidence")
T.falsy(hint.object, "a Java object is not included in the client hint")
T.falsy(hint.square, "a Java square is not included in the client hint")
local firstSquareLookups = squareLookups

local typoHint, typoReason = Hints.Resolve({
    kind = "phrase",
    text = "recycel bin",
    unresolved = true,
}, { origin = origin })
T.truthy(typoHint, "a bounded spelling correction finds the same object")
T.equal(typoReason, nil, "a corrected object phrase remains actionable")
T.equal(typoHint.kind, "recycle_bin",
    "a corrected phrase uses the canonical world-target kind")
T.equal(squareLookups, firstSquareLookups,
    "different phrases reuse the short-lived loaded-cell observation cache")

local cached = Hints.Resolve({
    kind = "phrase",
    text = "bin",
    unresolved = true,
}, { origin = origin })
T.equal(cached.x, 4, "repeated target lookup returns the cached primitive")
T.equal(scans, 2, "each distinct phrase is scanned once and exact repeats are cached")

local boundedHint, boundedReason = Hints.Resolve({
    kind = "phrase",
    text = "bin",
    unresolved = true,
}, { origin = origin }, { maxObjects = 2, cacheMs = 0 })
T.truthy(boundedHint,
    "nearby targets are found even when the bounded scan sees distant clutter")
T.equal(boundedReason, nil, "a bounded nearest-first scan remains actionable")
T.equal(boundedHint.x, 4, "nearest-first scanning reaches the nearby bin")

local unavailable, unavailableReason = Hints.Resolve({
    kind = "phrase",
    text = "tree",
    unresolved = true,
}, { origin = origin })
T.falsy(unavailable, "unknown world vocabulary does not invent a target")
T.equal(unavailableReason, "target_profile_unavailable",
    "unknown world vocabulary reports a safe reason")

local captured
PNC.Registry = {
    GetLiveZombie = function() return origin end,
}
PNC.Semantics.CommandAdapter = {
    Dispatch = function() return { status = "unmapped" } end,
}
PNC.Semantics.TaskAdapter = {
    Dispatch = function(actionIntent)
        captured = actionIntent
        return {
            status = "accepted",
            accepted = true,
            request = { requestID = "task:1" },
        }
    end,
}
PNC.Semantics.DialogueInput = { Internal = {} }
local Input = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Semantics/PNC_SemanticDialogueInput_Actions.lua"
)
local dispatched = Input.Internal.DispatchAction({
    spec = {
        npcID = "npc:alice",
        context = { player = origin },
    },
    session = {
        conversationID = "conversation:1",
        characterUUID = "player:1",
    },
}, {
    sequence = "turn:1",
    ir = { normalizedText = "wait at the bin", confidence = 0.96 },
    decision = {
        actionIntent = {
            intent = "REQUEST",
            action = "WAIT_AT",
            target = {
                kind = "phrase",
                text = "bin",
                unresolved = true,
            },
        },
    },
}, "wait at the bin")
T.equal(dispatched.status, "accepted",
    "the semantic action remains on the normal task transport")
T.truthy(captured and captured.target and captured.target.clientHint,
    "the client hint is attached at the action boundary")
T.equal(captured.target.clientHint.kind, "recycle_bin",
    "the attached hint preserves the canonical target kind")

T.finish("pnc_semantic_client_world_target_hint_smoke")
