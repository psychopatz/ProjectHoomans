local T = require "tests/support/test"

local FILE = T.path(
    "ProjectHoomans",
    "client",
    "PNC/UI/Nameplates/PNC_NameplateFirearmAnchor.lua"
)

local now = 1000
local lineCount = 0
local textCount = 0
local body = {}
local manager = {
    playerIndex = 0,
    x = 100,
    y = 20,
}

function manager:drawLine2()
    lineCount = lineCount + 1
end

function manager:drawText()
    textCount = textCount + 1
end

getTimeInMillis = function() return now end
getCore = function()
    return {
        getZoom = function() return 2 end,
    }
end
UIFont = { Small = {} }
Events = nil
PNC = {}

T.load(FILE)

local Anchor = PNC.NameplateFirearmAnchor
Anchor.Config.sideOffset = 18
local cache = Anchor.Update(
    body,
    "npc_anchor",
    0,
    manager.x,
    manager.y,
    2,
    300,
    400,
    300,
    500,
    10,
    20,
    0
)
T.truthy(cache, "nameplate anchor cached")
local renderX, renderY = Anchor.GetRenderMuzzle(body, "npc_anchor")
T.truthy(
    math.abs(renderX - 783.9006) < 0.1,
    "cached muzzle render X includes the side-relative offset"
)
T.truthy(
    math.abs(renderY - 920.0498) < 0.1,
    "cached muzzle render Y includes the shoulder and side offsets"
)
local debugState = Anchor.GetDebugState(body, "npc_anchor")
T.equal(debugState.status, "LIVE", "coordinate inspector reports a fresh cache")
T.equal(debugState.nameplateX, 300, "coordinate inspector reports nameplate X")
T.equal(debugState.worldY, 20, "coordinate inspector reports world Y")
T.equal(Anchor.AdjustOffset("x", 4), 4,
    "coordinate inspector can adjust direct X offset")
T.equal(Anchor.FlipSide(), -1,
    "coordinate inspector can flip the hand-side direction")
Anchor.ResetOffsets()
T.equal(Anchor.GetConfig().sideOffset, 18,
    "coordinate inspector restores default offsets")

T.truthy(Anchor.SetTarget(body, "npc_anchor", 0), "anchor target selected")
T.truthy(
    Anchor.Render(
        manager,
        body,
        "npc_anchor",
        300,
        400,
        300,
        500,
        10,
        20,
        0
    ),
    "selected anchor rendered"
)
T.truthy(lineCount >= 4, "anchor probe draws reference lines")
T.truthy(textCount >= 4, "anchor probe draws relative coordinates")
T.falsy(Anchor.ToggleTarget(body, "npc_anchor", 0), "anchor target toggled off")
T.falsy(Anchor.IsTarget(body, "npc_anchor"), "anchor target cleared")

now = now + 1001
T.falsy(Anchor.Get(body, "npc_anchor"), "stale anchor is not reused")
T.finish("pnc_firearm_anchor_smoke")
