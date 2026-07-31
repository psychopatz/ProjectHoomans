require "ISUI/ISPanel"
require "ISUI/ISButton"

PNC = PNC or {}
PNC.FactionTollUI = PNC.FactionTollUI or {}

local TollUI = PNC.FactionTollUI
local Const = PNC.Const

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key
        and value or fallback
end

ISPNCFactionTollWindow = ISPanel:derive(
    "ISPNCFactionTollWindow"
)

function ISPNCFactionTollWindow:initialise()
    ISPanel.initialise(self)
end

function ISPNCFactionTollWindow:createChildren()
    ISPanel.createChildren(self)
    local buttonWidth = 126
    local gap = 10
    local total = buttonWidth * 3 + gap * 2
    local x = math.floor((self.width - total) / 2)
    local labels = {
        {
            id = "pay",
            text = tr(
                "UI_PNC_TollPay",
                "Pay"
            ) .. " $" .. tostring(self.demand.amount or 0),
        },
        {
            id = "leave",
            text = tr(
                "UI_PNC_TollLeave",
                "Leave Area"
            ),
        },
        {
            id = "refuse",
            text = tr(
                "UI_PNC_TollRefuse",
                "Refuse"
            ),
        },
    }
    for index, definition in ipairs(labels) do
        local button = ISButton:new(
            x + (index - 1) * (buttonWidth + gap),
            self.height - 46,
            buttonWidth,
            28,
            definition.text,
            self,
            ISPNCFactionTollWindow.onChoice
        )
        button.internal = definition.id
        button:initialise()
        button:instantiate()
        if definition.id == "pay" then
            button.backgroundColor = {
                r = 0.04, g = 0.34, b = 0.15, a = 0.94,
            }
        elseif definition.id == "refuse" then
            button.backgroundColor = {
                r = 0.46, g = 0.06, b = 0.04, a = 0.94,
            }
        end
        self:addChild(button)
    end
end

function ISPNCFactionTollWindow:onChoice(button)
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or nil
    if player and sendClientCommand then
        sendClientCommand(
            player,
            Const.MODULE,
            Const.CMD_FACTION_TOLL_RESPONSE,
            {
                demandID = self.demand.demandID,
                response = button.internal,
            }
        )
    end
    self:close()
end

function ISPNCFactionTollWindow:prerender()
    ISPanel.prerender(self)
    self:drawRect(
        0, 0, self.width, self.height,
        0.97, 0.025, 0.025, 0.028
    )
    self:drawRectBorder(
        0, 0, self.width, self.height,
        0.98, 0.72, 0.14, 0.10
    )
    self:drawTextCentre(
        tr("UI_PNC_TollTitle", "Looter Toll"),
        self.width / 2,
        16,
        0.96, 0.72, 0.20, 1,
        UIFont.Medium
    )
    self:drawTextCentre(
        tostring(self.demand.factionName or "Looters"),
        self.width / 2,
        48,
        0.92, 0.92, 0.92, 1,
        UIFont.Small
    )
    self:drawTextCentre(
        tostring(
            self.demand.communityName or ""
        ),
        self.width / 2,
        68,
        0.66, 0.70, 0.73, 1,
        UIFont.Small
    )
    self:drawTextCentre(
        tr(
            "UI_PNC_TollDemand",
            "Pay the toll to enter, leave, or face the faction."
        ),
        self.width / 2,
        98,
        0.88, 0.88, 0.88, 1,
        UIFont.Small
    )
    self:drawTextCentre(
        "$" .. tostring(self.demand.amount or 0),
        self.width / 2,
        124,
        1, 0.48, 0.30, 1,
        UIFont.Large
    )
end

function ISPNCFactionTollWindow:close()
    if self.setCapture then self:setCapture(false) end
    self:setVisible(false)
    self:removeFromUIManager()
    if TollUI.instance == self then
        TollUI.instance = nil
    end
end

function ISPNCFactionTollWindow:new(
    x,
    y,
    width,
    height,
    demand
)
    local object = ISPanel:new(x, y, width, height)
    setmetatable(object, self)
    self.__index = self
    object.demand = demand or {}
    object.background = false
    object.moveWithMouse = true
    return object
end

function TollUI.Open(demand)
    if TollUI.instance then TollUI.instance:close() end
    local width = 450
    local height = 210
    local screenWidth = getCore and getCore()
        and getCore():getScreenWidth() or 1280
    local screenHeight = getCore and getCore()
        and getCore():getScreenHeight() or 720
    local window = ISPNCFactionTollWindow:new(
        math.floor((screenWidth - width) / 2),
        math.floor((screenHeight - height) / 2),
        width,
        height,
        demand
    )
    window:initialise()
    window:instantiate()
    window:addToUIManager()
    if window.setAlwaysOnTop then
        window:setAlwaysOnTop(true)
    end
    if window.setCapture then window:setCapture(true) end
    window:bringToTop()
    TollUI.instance = window
    return window
end

local function resultMessage(args)
    local reasons = {
        toll_paid = tr(
            "UI_PNC_TollPaid",
            "Toll paid. This faction will tolerate you for 24 hours."
        ),
        toll_refused_war = tr(
            "UI_PNC_TollWar",
            "Toll refused. The faction is now at war with you."
        ),
        toll_deferred = tr(
            "UI_PNC_TollDeferred",
            "Leave the settlement radius within about one minute."
        ),
        toll_departure_ignored_war = tr(
            "UI_PNC_TollDepartureIgnored",
            "You remained inside. The faction is now at war with you."
        ),
        insufficient_money = tr(
            "UI_PNC_TollInsufficient",
            "You do not have enough cash."
        ),
        demand_expired = tr(
            "UI_PNC_TollExpired",
            "The toll demand expired."
        ),
    }
    return reasons[args.reason]
        or tostring(args.reason or "Toll response rejected.")
end

function TollUI.HandleServerMessage(args)
    args = type(args) == "table" and args or {}
    if args.kind == "demand" then
        TollUI.Open(args)
        return
    end
    if args.kind ~= "result" then return end
    local player = getSpecificPlayer and getSpecificPlayer(0)
        or nil
    local message = resultMessage(args)
    if player and player.setHaloNote then
        if args.ok == true then
            player:setHaloNote(message, 80, 220, 100, 300)
        else
            player:setHaloNote(message, 255, 80, 60, 300)
        end
    end
    if args.reopen == true then
        TollUI.Open({
            demandID = args.demandID,
            factionID = args.factionID,
            factionName = args.factionName,
            communityName = args.communityName,
            amount = args.amount,
        })
    end
end

return TollUI
