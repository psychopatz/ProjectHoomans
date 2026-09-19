local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

-- The layout tab is a Project Zomboid UI module.  Keep this contract test
-- deterministic by supplying only the engine surfaces needed while loading
-- the hub and its spokes.
package.loaded["ISUI/ISPanel"] = true
package.loaded["PsychopatzCore/UI/PsychopatzUI"] = true
package.loaded["PNC/UI/PuppetOpera/PNC_PuppetOperaAnchorGrid"] = true

ISPanel = {
    derive = function(_, name)
        local class = { Type = name }
        class.__index = class
        return class
    end,
    initialise = function() end,
    createChildren = function() end,
    render = function() end,
}
PsychopatzCore = {
    UI = {
        Layout = {
            Pixels = function(value) return value end,
            SetBounds = function(widget, x, y, width, height)
                if not widget then return end
                widget.bounds = {
                    x = x,
                    y = y,
                    width = width,
                    height = height,
                }
            end,
        },
        AddKeyValue = function() end,
    },
}
ISPNCPuppetOperaAnchorGrid = {}

PNC = {}
local LayoutTab = T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/PuppetOpera/PNC_PuppetOperaLayoutTab.lua"
)

T.equal(LayoutTab, ISPNCPuppetOperaLayoutTab,
    "layout tab hub did not preserve its public class identity")
T.truthy(PNC.PuppetOperaLayoutTabInternal,
    "layout tab spokes did not receive a shared private contract table")
T.truthy(type(PNC.PuppetOperaLayoutTabInternal.resizeRows) == "function"
    and type(PNC.PuppetOperaLayoutTabInternal.drawActorRow) == "function"
    and type(PNC.PuppetOperaLayoutTabInternal.drawLiveRow) == "function",
    "layout presentation row contracts were not installed")
T.truthy(type(PNC.PuppetOperaLayoutTabInternal.setLivePointerFromEvent)
    == "function"
    and type(PNC.PuppetOperaLayoutTabInternal.updateLiveDropPreview)
    == "function"
    and type(PNC.PuppetOperaLayoutTabInternal.finishLiveDrag)
    == "function",
    "live drag spokes did not install their private contracts")
T.truthy(type(PNC.PuppetOperaLayoutTabInternal.applyStackedLayout)
    == "function"
    and type(PNC.PuppetOperaLayoutTabInternal.applyWideLayout)
    == "function",
    "responsive geometry spokes did not install their private contracts")

local methods = {
    "initialise",
    "createChildren",
    "setContext",
    "refresh",
    "onAction",
    "render",
    "onResponsiveLayout",
    "setLivePointerFromEvent",
    "updateLiveDropPreview",
    "updateLiveDrag",
    "finishLiveDrag",
}
for _, method in ipairs(methods) do
    T.truthy(type(LayoutTab[method]) == "function",
        "layout tab public method was not installed: " .. method)
end

local dimensions = { width = 640, height = 600 }
local function responsiveWidget()
    return { items = {} }
end
local responsive = setmetatable({
    ownerWindow = { uiScale = 1 },
    actorList = responsiveWidget(),
    liveList = responsiveWidget(),
    details = responsiveWidget(),
    grid = responsiveWidget(),
    addButton = responsiveWidget(),
    removeButton = responsiveWidget(),
    getWidth = function() return dimensions.width end,
    getHeight = function() return dimensions.height end,
}, { __index = LayoutTab })

responsive:onResponsiveLayout()
T.truthy(responsive.stackedLayout,
    "narrow responsive layout did not select stacked geometry")
T.equal(responsive.actorList.bounds.x, 8,
    "stacked layout did not preserve the scaled left padding")
T.truthy(responsive.grid.bounds.height >= 100,
    "stacked layout did not enforce the minimum grid height")

dimensions.width = 1000
responsive:onResponsiveLayout()
T.falsy(responsive.stackedLayout,
    "wide responsive layout incorrectly selected stacked geometry")
T.truthy(responsive.grid.bounds.x > responsive.actorList.bounds.x,
    "wide layout did not place the grid after the actor column")
T.truthy(responsive.details.bounds.x > responsive.grid.bounds.x,
    "wide layout did not place details after the grid")

local status
local captureState
local instance = setmetatable({
    liveDragPending = true,
    liveDragging = true,
    liveDragActorID = "npc-malformed-drop",
    liveList = {
        setCapture = function(_, value)
            captureState = value
        end,
    },
    ownerWindow = {
        setEditorStatus = function(_, reason, failed)
            status = { reason = reason, failed = failed }
        end,
        refreshViews = function() end,
    },
}, { __index = LayoutTab })

T.truthy(instance:finishLiveDrag(nil, nil, nil),
    "malformed live drop did not terminate cleanly")
T.equal(status.reason, "live_actor_drop_outside_grid",
    "malformed live drop did not expose the stable failure reason")
T.truthy(status.failed, "malformed live drop was not marked as failed")
T.falsy(instance.liveDragPending,
    "malformed live drop left drag state pending")
T.falsy(captureState, "malformed live drop did not release list capture")

local unavailableStatus
local unavailable = setmetatable({
    liveDragPending = true,
    liveDragging = true,
    liveDragActorID = "npc-missing-model",
    liveList = {
        setCapture = function() end,
        getAbsoluteX = function() return 100 end,
        getAbsoluteY = function() return 200 end,
    },
    grid = {
        getAbsoluteX = function() return 100 end,
        getAbsoluteY = function() return 200 end,
        containsGraphPoint = function() return true end,
        cellAt = function() return 1, 1 end,
    },
    ownerWindow = {
        setEditorStatus = function(_, reason, failed)
            unavailableStatus = { reason = reason, failed = failed }
        end,
    },
}, { __index = LayoutTab })

T.truthy(unavailable:finishLiveDrag(unavailable.liveList, 10, 10),
    "missing model drop did not terminate cleanly")
T.equal(unavailableStatus.reason, "live_actor_model_unavailable",
    "missing model drop did not expose a bounded failure reason")
T.truthy(unavailableStatus.failed,
    "missing model drop was not marked as failed")

local routed
local validStatus
local valid = setmetatable({
    liveDragPending = true,
    liveDragging = true,
    liveDragActorID = "npc-valid-drop",
    liveList = {
        setCapture = function() end,
        getAbsoluteX = function() return 100 end,
        getAbsoluteY = function() return 200 end,
    },
    grid = {
        getAbsoluteX = function() return 100 end,
        getAbsoluteY = function() return 200 end,
        containsGraphPoint = function(_, x, y)
            return x >= 0 and y >= 0 and x < 100 and y < 100
        end,
        cellAt = function() return 2, 3 end,
    },
    model = {
        GetActorAtOffset = function() return nil end,
        GetSelectedActorID = function() return "actor-selected" end,
        AddLiveActorToScene = function(actorID, right, forward, z, targetID)
            routed = {
                actorID = actorID,
                right = right,
                forward = forward,
                z = z,
                targetID = targetID,
            }
            return true, "live_actor_added_to_scene"
        end,
    },
    ownerWindow = {
        setEditorStatus = function(_, reason, failed)
            validStatus = { reason = reason, failed = failed }
        end,
        refreshViews = function() end,
    },
}, { __index = LayoutTab })

T.truthy(valid:finishLiveDrag(valid.liveList, 10, 10),
    "valid live drop did not complete")
T.equal(routed.actorID, "npc-valid-drop",
    "valid live drop did not route its actor identifier")
T.equal(routed.right, 2, "valid live drop lost its right offset")
T.equal(routed.forward, 3, "valid live drop lost its forward offset")
T.equal(routed.targetID, "actor-selected",
    "valid live drop lost the selected target actor")
T.equal(validStatus.reason, "live_actor_added_to_scene",
    "valid live drop did not preserve success status")
T.falsy(validStatus.failed, "valid live drop was marked as failed")

return T.finish("pnc_puppet_opera_layout_tab_modules_smoke")
