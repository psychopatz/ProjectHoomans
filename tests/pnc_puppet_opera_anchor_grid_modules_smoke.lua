local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

-- Load the PZ UI entry point against only the engine surfaces used by this
-- contract test.  The production class and all four spokes still load as one
-- public module, which keeps this test useful for load-order regressions.
package.loaded["ISUI/ISPanel"] = true
package.loaded["PsychopatzCore/UI/PsychopatzUI"] = true

ISPanel = {
    derive = function(_, name)
        local class = { Type = name }
        class.__index = class
        return class
    end,
    initialise = function() end,
    render = function() end,
}
PsychopatzCore = {
    UI = {
        Layout = {
            Ellipsize = function(value) return value end,
        },
    },
}
UIFont = { Small = "small" }
PNC = {
    Translation = {
        GetKey = function(_, fallback) return fallback end,
    },
}

local Grid = T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaAnchorGrid.lua"
)

T.equal(Grid, ISPNCPuppetOperaAnchorGrid,
    "anchor grid hub did not preserve its public class identity")
local presentation = PNC.PuppetOperaAnchorGridInternal
T.truthy(presentation and type(presentation.drawGridFrame) == "function"
    and type(presentation.drawActors) == "function"
    and type(presentation.drawOverlays) == "function",
    "anchor grid presentation spokes did not install their render contracts")
for _, method in ipairs({
    "initialise",
    "setModel",
    "geometry",
    "graphBounds",
    "containsGraphPoint",
    "cellAt",
    "cellPoint",
    "render",
    "onMouseDown",
    "updateDrag",
    "onMouseMove",
    "onMouseMoveOutside",
    "onMouseUp",
    "onMouseUpOutside",
}) do
    T.truthy(type(Grid[method]) == "function",
        "anchor grid spoke did not install method: " .. method)
end

local function makeGrid(model, ownerWindow)
    local value = {
        width = 720,
        height = 480,
        model = model,
        ownerWindow = ownerWindow,
        capture = nil,
        drawCalls = 0,
    }
    function value:getWidth() return self.width end
    function value:getHeight() return self.height end
    function value:setCapture(captured) self.capture = captured end
    function value:getMouseX() return 0 end
    function value:getMouseY() return 0 end
    function value:drawRect() self.drawCalls = self.drawCalls + 1 end
    function value:drawRectBorder() self.drawCalls = self.drawCalls + 1 end
    function value:drawText() self.drawCalls = self.drawCalls + 1 end
    function value:drawTextCentre() self.drawCalls = self.drawCalls + 1 end
    return setmetatable(value, { __index = Grid })
end

local actorAtOffset
local pendingActorID
local calls = {}
local model = {
    GetActorAtOffset = function(right, forward)
        calls.lookup = { right = right, forward = forward }
        return actorAtOffset
    end,
    GetPendingLiveActorID = function() return pendingActorID end,
    AddLiveActorToScene = function(actorID, right, forward, z)
        calls.add = {
            actorID = actorID,
            right = right,
            forward = forward,
            z = z,
        }
        return calls.addAccepted, calls.addReason
    end,
    SelectActor = function(actorID) calls.selected = actorID end,
    GetGridActors = function()
        return {{
            id = "actor-1",
            label = "Actor 1",
            right = 1,
            forward = 1,
            z = 3,
        }}
    end,
    SetActorAnchorOffset = function(actorID, right, forward, z)
        calls.anchor = {
            actorID = actorID,
            right = right,
            forward = forward,
            z = z,
        }
        return calls.anchorAccepted
    end,
}

local ownerCalls = {}
local ownerWindow = {
    setEditorStatus = function(_, reason, failed)
        ownerCalls.status = { reason = reason, failed = failed }
    end,
    refreshViews = function() ownerCalls.refreshes = (ownerCalls.refreshes or 0) + 1 end,
    requestPlacementPreview = function()
        ownerCalls.previews = (ownerCalls.previews or 0) + 1
    end,
}

local grid = makeGrid(model, ownerWindow)
grid:initialise()
T.truthy(grid.background, "grid lifecycle did not enable its background")
T.equal(grid.backgroundColor.a, 1,
    "grid lifecycle did not install its background color")
grid:setModel(model)

local presentationCalls = {}
local drawGridFrame = presentation.drawGridFrame
local drawActors = presentation.drawActors
local drawOverlays = presentation.drawOverlays
presentation.drawGridFrame = function(...)
    presentationCalls.frame = true
    return drawGridFrame(...)
end
presentation.drawActors = function(...)
    presentationCalls.actors = true
    return drawActors(...)
end
presentation.drawOverlays = function(...)
    presentationCalls.overlays = true
    return drawOverlays(...)
end

local cell, centerX, centerY = grid:geometry()
T.equal(cell, 25, "grid geometry changed its baseline cell size")
T.equal(centerX, 360, "grid geometry changed its horizontal origin")
T.equal(centerY, 250, "grid geometry changed its vertical origin")
local left, top, right, bottom = grid:graphBounds()
T.near(left, 147.5, 0.001, "grid bounds left edge changed")
T.near(top, 37.5, 0.001, "grid bounds top edge changed")
T.near(right, 572.5, 0.001, "grid bounds right edge changed")
T.near(bottom, 462.5, 0.001, "grid bounds bottom edge changed")
T.truthy(grid:containsGraphPoint(left, top),
    "grid rejected its inclusive graph origin")
T.falsy(grid:containsGraphPoint(right, top),
    "grid accepted its exclusive right edge")
T.falsy(grid:containsGraphPoint("not-a-number", top),
    "grid accepted malformed graph input")
local originX, originY = grid:cellPoint(0, 0)
T.equal(originX, centerX, "grid origin cell changed horizontally")
T.equal(originY, centerY, "grid origin cell changed vertically")
local maxX, maxY = grid:cellPoint(8, -8)
local maxRight, maxForward = grid:cellAt(maxX, maxY)
T.equal(maxRight, 8, "grid lost its positive right clamp")
T.equal(maxForward, -8, "grid lost its negative forward clamp")

grid:render()
T.truthy(grid.drawCalls > 0, "grid presentation did not render any surface")
T.truthy(presentationCalls.frame,
    "render coordinator did not dispatch the grid frame spoke")
T.truthy(presentationCalls.actors,
    "render coordinator did not dispatch the actor spoke")
T.truthy(presentationCalls.overlays,
    "render coordinator did not dispatch the overlay spoke")

-- Empty-cell placement is routed through the model and preserves the stable
-- status and refresh/preview callbacks used by the layout tab.
pendingActorID = "live-1"
calls.addAccepted = true
calls.addReason = "live_actor_added_to_scene"
local placeX, placeY = grid:cellPoint(2, -1)
T.truthy(grid:onMouseDown(placeX, placeY),
    "accepted pending live actor was not placed")
T.equal(calls.add.actorID, "live-1",
    "pending placement lost its actor identifier")
T.equal(calls.add.right, 2, "pending placement lost its right offset")
T.equal(calls.add.forward, -1, "pending placement lost its forward offset")
T.equal(ownerCalls.status.reason, "live_actor_added_to_scene",
    "accepted placement changed its stable status")
T.falsy(ownerCalls.status.failed, "accepted placement was marked as failed")
T.equal(ownerCalls.previews, 1,
    "accepted placement did not request a preview refresh")

-- Rejected/duplicate placement must remain bounded and user-readable.
ownerCalls.status = nil
ownerCalls.previews = 0
calls.addAccepted = false
calls.addReason = "live_actor_already_present"
T.falsy(grid:onMouseDown(placeX, placeY),
    "rejected pending placement was reported as accepted")
T.equal(ownerCalls.status.reason, "live_actor_already_present",
    "rejected placement lost its model reason")
T.truthy(ownerCalls.status.failed,
    "rejected placement was not marked as failed")
T.equal(ownerCalls.previews, 0,
    "rejected placement triggered a preview refresh")

-- Selecting a resident actor starts capture; a successful drag routes the
-- authoritative anchor mutation and releases capture on mouse-up-outside.
pendingActorID = nil
actorAtOffset = { id = "actor-1" }
local selectX, selectY = grid:cellPoint(1, 1)
T.truthy(grid:onMouseDown(selectX, selectY),
    "resident actor was not selected for dragging")
T.equal(calls.selected, "actor-1", "selection lost the actor identifier")
T.truthy(grid.capture, "resident selection did not capture the pointer")
calls.anchorAccepted = true
T.truthy(grid:onMouseMoveOutside(cell, 0),
    "drag outside callback did not remain consumed")
T.equal(calls.anchor.actorID, "actor-1",
    "drag lost the selected actor identifier")
T.equal(calls.anchor.right, 2, "drag lost its right offset")
T.equal(calls.anchor.forward, 1, "drag lost its forward offset")
T.equal(calls.anchor.z, 3, "drag lost the actor height")
T.truthy(grid:onMouseUpOutside(), "mouse-up-outside did not complete cleanup")
T.falsy(grid.capture, "mouse-up-outside did not release pointer capture")
T.truthy(ownerCalls.previews > 0,
    "successful drag did not request a placement preview")

-- Outside clicks and stale/missing model contracts must fail safely without
-- invoking authoritative mutation.
local addBefore = calls.add
T.falsy(grid:onMouseDown(left - 1, top),
    "outside click was accepted by the grid")
local stale = makeGrid({ GetActorAtOffset = function() return nil end }, ownerWindow)
stale.dragActorID = "actor-stale"
T.truthy(stale:updateDrag(originX, originY),
    "stale drag did not remain safely consumed")
T.equal(calls.add, addBefore,
    "stale drag unexpectedly changed placement state")
local empty = makeGrid(nil, ownerWindow)
T.falsy(empty:onMouseDown(originX, originY),
    "missing model was not rejected safely")

return T.finish("pnc_puppet_opera_anchor_grid_modules_smoke")
