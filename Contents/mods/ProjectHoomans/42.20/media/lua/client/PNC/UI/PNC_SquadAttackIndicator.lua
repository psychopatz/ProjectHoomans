-- Lightweight lower-left HUD indicator shown when one or more following
-- companions have attack disabled (Don't Attack mode).
require "ISUI/ISPanel"
require "PNC/Commands/PNC_CompanionTargetResolver"

PNC = PNC or {}
PNC.UI = PNC.UI or {}
PNC.UI.SquadAttackIndicator = PNC.UI.SquadAttackIndicator or {}

local Indicator = PNC.UI.SquadAttackIndicator
local Const = PNC.Const or {}
local Commands = PNC.CompanionCommands
local Resolver = PNC.CompanionTargetResolver
local Registry = PNC.Registry
local ClientState = PNC.Network and PNC.Network.ClientState or nil

local REFRESH_INTERVAL_MS = 250
local MARGIN_LEFT = 20
local MARGIN_BOTTOM = 24
local PAD_X = 10
local PAD_Y = 6
local ICON_SIZE = 20
local ICON_GAP = 8
local MIN_HEIGHT = 32
local ICON_PATH = "media/ui/Emotes/PNC_EmoteAttackNone.png"

local function nowMs()
    return (PNC.Core and PNC.Core.Now and PNC.Core.Now())
        or (getTimeInMillis and getTimeInMillis()) or 0
end

local function tr(key, fallback)
    local value = getText and PNC.Translation
        and PNC.Translation.GetKey and PNC.Translation.GetKey(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function screenHeight()
    local core = getCore and getCore() or nil
    if core and core.getScreenHeight then
        local h = tonumber(core:getScreenHeight())
        if h and h > 0 then return h end
    end
    return 720
end

local function isOwnedByPlayer(source, player)
    local authority = PNC.ClientCompanionAuthority
    if authority and type(authority.IsOwnedByPlayer) == "function"
        and authority.IsOwnedByPlayer(source, player) == true
    then
        return true
    end
    return Commands and Commands.IsOwnedByPlayer
        and Commands.IsOwnedByPlayer(source, player) == true or false
end

local function isFollowingSource(source)
    if type(source) ~= "table" then return false end
    local followKind = tostring(Const.ORDER_FOLLOW or "follow")
    local order = source.orderSpec
    if type(order) == "table" and tostring(order.kind or "") == followKind then
        return true
    end
    if tostring(source.orderKind or "") == followKind then
        return true
    end
    return false
end

local function isAttackDisabled(source)
    local noneType = tostring(Const.ATTACK_TYPE_NONE or "none")
    local current = Commands and Commands.GetCurrentAttackType
        and Commands.GetCurrentAttackType(source)
        or (source and source.attackType)
    return tostring(current or "") == noneType
end

local function countCandidate(seen, counts, player, source)
    local id = source and source.id and tostring(source.id) or nil
    if not id or seen[id] then return end
    if source.alive == false then return end
    if Commands and Commands.IsCompanion
        and Commands.IsCompanion(source) ~= true
    then
        return
    end
    if not isOwnedByPlayer(source, player) then return end
    if not isFollowingSource(source) then return end
    seen[id] = true
    counts.followers = counts.followers + 1
    if isAttackDisabled(source) then
        counts.disabled = counts.disabled + 1
    end
end

function Indicator.CountDisabledFollowers(player)
    local counts = { followers = 0, disabled = 0 }
    local seen = {}
    if not player or (player.isDead and player:isDead()) then
        return 0, 0
    end
    if Registry and Registry.ForEach then
        Registry.ForEach(function(record)
            countCandidate(seen, counts, player, record)
        end)
    end
    for _, snapshot in pairs(ClientState and ClientState.snapshots or {}) do
        countCandidate(seen, counts, player, snapshot)
    end
    if counts.followers == 0 and Resolver and Resolver.CollectNearbyCompanions then
        local nearby = Resolver.CollectNearbyCompanions(player) or {}
        for i = 1, #nearby do
            countCandidate(seen, counts, player, nearby[i] and nearby[i].source or nearby[i])
        end
    end
    return counts.disabled, counts.followers
end

function Indicator.FormatLabel(disabledCount)
    local base = tr("UI_PNC_SquadAttackDisabledIndicator", "SQUAD: DON'T ATTACK")
    if (tonumber(disabledCount) or 0) > 1 then
        return base .. " (" .. tostring(disabledCount) .. ")"
    end
    return base
end

local Panel = ISPanel:derive("PNCSquadAttackIndicatorPanel")

function Panel:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    o.backgroundColor = { r = 0.08, g = 0.06, b = 0.06, a = 0.84 }
    o.borderColor = { r = 0.88, g = 0.34, b = 0.24, a = 0.95 }
    o.moveWithMouse = false
    o.anchorLeft = true
    o.anchorRight = false
    o.anchorTop = false
    o.anchorBottom = true
    o.disabledCount = 0
    o.labelText = ""
    return o
end

function Panel:updateLayout(disabledCount)
    local text = Indicator.FormatLabel(disabledCount)
    local font = UIFont and UIFont.Small or nil
    local tm = getTextManager and getTextManager() or nil
    local textWidth = (tm and font and tm.MeasureStringX)
        and tm:MeasureStringX(font, text)
        or (#text * 7)
    local textHeight = (tm and font and tm.getFontHeight)
        and tm:getFontHeight(font)
        or 16
    local width = PAD_X + ICON_SIZE + ICON_GAP + math.ceil(textWidth) + PAD_X
    local height = math.max(MIN_HEIGHT, math.max(ICON_SIZE, textHeight) + (PAD_Y * 2))
    local x = MARGIN_LEFT
    local y = math.max(8, screenHeight() - height - MARGIN_BOTTOM)
    self.disabledCount = disabledCount
    self.labelText = text
    self:setX(x)
    self:setY(y)
    self:setWidth(width)
    self:setHeight(height)
end

function Panel:prerender()
    ISPanel.prerender(self)
    local icon = getTexture and getTexture(ICON_PATH) or nil
    local iconY = math.floor((self.height - ICON_SIZE) / 2)
    if icon and self.drawTextureScaled then
        self:drawTextureScaled(icon, PAD_X, iconY, ICON_SIZE, ICON_SIZE, 1, 1, 1, 1)
    end
    local font = UIFont and UIFont.Small or nil
    local tm = getTextManager and getTextManager() or nil
    local textHeight = (tm and font and tm.getFontHeight)
        and tm:getFontHeight(font)
        or 16
    local textY = math.floor((self.height - textHeight) / 2)
    if self.drawText then
        self:drawText(
            self.labelText or "",
            PAD_X + ICON_SIZE + ICON_GAP,
            textY,
            1.0,
            0.78,
            0.72,
            1.0,
            font
        )
    end
end

function Indicator.EnsurePanel()
    if Indicator.panel then return Indicator.panel end
    local panel = Panel:new(MARGIN_LEFT, 0, 180, MIN_HEIGHT)
    panel:initialise()
    panel:instantiate()
    if panel.setWantMouseEvents then panel:setWantMouseEvents(false) end
    panel:setVisible(false)
    if panel.addToUIManager then panel:addToUIManager() end
    Indicator.panel = panel
    return panel
end

function Indicator.Refresh(player)
    local activePlayer = player
        or (getSpecificPlayer and getSpecificPlayer(0))
        or (getPlayer and getPlayer())
        or nil
    local disabledCount = Indicator.CountDisabledFollowers(activePlayer)
    if disabledCount <= 0 then
        if Indicator.panel and Indicator.panel.setVisible then
            Indicator.panel:setVisible(false)
        end
        return false, 0
    end
    local panel = Indicator.EnsurePanel()
    panel:updateLayout(disabledCount)
    panel:setVisible(true)
    return true, disabledCount
end

function Indicator.OnTick()
    local now = nowMs()
    if now < (tonumber(Indicator._nextRefreshAt) or 0) then
        return
    end
    Indicator._nextRefreshAt = now + REFRESH_INTERVAL_MS
    Indicator.Refresh()
end

function Indicator.Install()
    if Events and Events.OnTick and not Indicator._tickRegistered then
        Events.OnTick.Add(Indicator.OnTick)
        Indicator._tickRegistered = true
    end
    if Events and Events.OnResolutionChange and not Indicator._resizeRegistered then
        Events.OnResolutionChange.Add(function()
            Indicator._nextRefreshAt = 0
            Indicator.Refresh()
        end)
        Indicator._resizeRegistered = true
    end
end

Indicator.Install()

return Indicator
