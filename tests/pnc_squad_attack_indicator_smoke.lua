local T = require "tests/support/test"
T.addPackagePaths()

local screenH = 1080
local addedToUI = 0

local FakePanel = {}
FakePanel.__index = FakePanel
function FakePanel:derive()
    local cls = {}
    cls.__index = cls
    setmetatable(cls, { __index = self })
    return cls
end
function FakePanel:new(x, y, w, h)
    return setmetatable({
        x = x, y = y, width = w, height = h, visible = false,
    }, self)
end
function FakePanel:initialise() end
function FakePanel:instantiate() end
function FakePanel:setWantMouseEvents(v) self.wantMouse = v end
function FakePanel:setVisible(v) self.visible = v end
function FakePanel:addToUIManager() addedToUI = addedToUI + 1 end
function FakePanel:setX(v) self.x = v end
function FakePanel:setY(v) self.y = v end
function FakePanel:setWidth(v) self.width = v end
function FakePanel:setHeight(v) self.height = v end
function FakePanel:prerender() end

ISPanel = FakePanel
UIFont = { Small = "Small" }
getCore = function() return { getScreenHeight = function() return screenH end } end
getTextManager = function()
    return {
        MeasureStringX = function(_, _, text) return #tostring(text or "") * 8 end,
        getFontHeight = function() return 16 end,
    }
end

package.preload["ISUI/ISPanel"] = function() return ISPanel end
package.preload["PNC/Commands/PNC_CompanionTargetResolver"] = function() return {} end

local records = {
    {
        id = "f1",
        alive = true,
        recruited = true,
        ownerUsername = "alice",
        attackType = "auto",
        orderSpec = { kind = "follow" },
    },
    {
        id = "f2",
        alive = true,
        recruited = true,
        ownerUsername = "alice",
        attackType = "auto",
        orderSpec = { kind = "follow" },
    },
}

local player = {
    getUsername = function() return "alice" end,
    isDead = function() return false end,
}

PNC = {
    Const = {
        ORDER_FOLLOW = "follow",
        ATTACK_TYPE_NONE = "none",
    },
    Core = { Now = function() return 1000 end },
    CompanionCommands = {
        IsCompanion = function(r) return r and r.recruited == true end,
        IsOwnedByPlayer = function(r, p)
            return r and p and r.ownerUsername == p:getUsername()
        end,
        GetCurrentAttackType = function(r) return r and r.attackType or "auto" end,
    },
    Registry = {
        ForEach = function(fn)
            for i = 1, #records do fn(records[i]) end
        end,
    },
}

T.load("ProjectHoomans", "client", "PNC/UI/PNC_SquadAttackIndicator.lua")
local Indicator = PNC.UI.SquadAttackIndicator

local visible, count = Indicator.Refresh(player)
T.falsy(visible, "indicator stays hidden when squad attack is enabled")
T.equal(count, 0, "disabled follower count is zero initially")
T.equal(addedToUI, 0, "panel is not mounted when hidden")

records[1].attackType = "none"
visible, count = Indicator.Refresh(player)
T.truthy(visible, "indicator shows when a follower has attack disabled")
T.equal(count, 1, "single disabled follower counted")
T.truthy(Indicator.panel.visible, "panel is visible")
T.equal(Indicator.panel.x, 20, "indicator anchored at lower-left x")
T.truthy(Indicator.panel.y > screenH - 100, "indicator anchored at lower-left y")
T.equal(Indicator.panel.labelText, "SQUAD: DON'T ATTACK", "single-follower label")

records[2].attackType = "none"
visible, count = Indicator.Refresh(player)
T.truthy(visible, "indicator stays visible for multiple followers")
T.equal(count, 2, "two disabled followers counted")
T.equal(Indicator.panel.labelText, "SQUAD: DON'T ATTACK (2)", "multi-follower count label")

records[1].attackType = "auto"
records[2].attackType = "auto"
visible, count = Indicator.Refresh(player)
T.falsy(visible, "indicator hides once attack is re-enabled")
T.falsy(Indicator.panel.visible, "panel hidden again")

T.finish("pnc_squad_attack_indicator_smoke")
