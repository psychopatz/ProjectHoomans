local MemberUI = PNC.FactionMemberUI
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Layout = UI.Layout
local selectedItem = MemberUI.Internal.selectedItem
local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end
local CONTROLS = MemberUI.Internal.Controls

function ISPNCFactionMemberWindow:prerender()
    local now = PNC.Core.Now()
    local received = tonumber(
        ClientState.lastFactionMembersReceiveAt
    ) or 0
    if received > (tonumber(self.lastReceiveAt) or 0) then
        self:refreshSnapshot()
    end
    if now - (tonumber(self.lastRequestAt) or 0) > 2500 then
        self:requestSnapshot()
    end
    local snapshot = ClientState.factionMembers or {}
    local selectedPlayer = selectedItem(self.playerMembers)
    local selectedAvailable =
        selectedItem(self.availablePlayers)
    local selectedNPC = selectedItem(self.npcMembers)
    for index, button in ipairs(self.controls) do
        local action = CONTROLS[index].id
        local enabled = action == "refresh"
        if action == "add_player" then
            enabled = snapshot.canManage == true
                and selectedAvailable ~= nil
        elseif action == "transfer_leadership" then
            enabled = snapshot.canManage == true
                and selectedPlayer ~= nil
                and selectedPlayer.key
                    ~= snapshot.currentPlayerKey
        elseif action == "banish_player" then
            enabled = snapshot.canManage == true
                and selectedPlayer ~= nil
                and selectedPlayer.key
                    ~= snapshot.currentPlayerKey
        elseif action == "follow"
            or action == "stay"
            or action == "attack_auto"
            or action == "attack_none"
        then
            enabled = selectedNPC ~= nil
        elseif action == "all_follow"
            or action == "all_stay"
        then
            enabled = #(snapshot.npcMembers or {}) > 0
        end
        button:setEnable(enabled)
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCFactionMemberWindow:render()
    PsychopatzWindow.render(self)
    local snapshot = ClientState.factionMembers or {}
    local faction = snapshot.faction
    local title = faction and faction.name
        or tr(
            "UI_PNC_FactionMemberNoFaction",
            "No player faction"
        )
    if faction and faction.emblem
        and PNC.FactionEmblemRenderer
    then
        PNC.FactionEmblemRenderer.Draw(
            self,
            faction.emblem,
            18,
            42,
            24,
            { alpha = 0.96 }
        )
    end
    self:drawText(
        title,
        faction and 52 or 18,
        45,
        0.88, 0.92, 0.90, 1,
        UIFont.Medium
    )
    local actionResult = snapshot.actionResult
    if actionResult then
        self:drawTextRight(
            tostring(
                actionResult.ok and actionResult.action
                    or actionResult.reason
            ),
            self.width - 20,
            49,
            actionResult.ok and 0.30 or 0.94,
            actionResult.ok and 0.86 or 0.40,
            actionResult.ok and 0.48 or 0.32,
            1,
            UIFont.Small
        )
    end
    if not self.layout then return end
    UI.DrawSectionTitle(
        self,
        tr(
            "UI_PNC_FactionMemberPlayers",
            "Player members"
        ),
        self.layout.players.x,
        self.layout.players.y
            - Layout.Pixels(21, self.uiScale),
        self.layout.players.width
    )
    UI.DrawSectionTitle(
        self,
        tr(
            "UI_PNC_FactionMemberAvailable",
            "Online players available to add"
        ),
        self.layout.available.x,
        self.layout.available.y
            - Layout.Pixels(21, self.uiScale),
        self.layout.available.width
    )
    UI.DrawSectionTitle(
        self,
        tr(
            "UI_PNC_FactionMemberNPCs",
            "Faction NPCs and quick commands"
        ),
        self.layout.npcs.x,
        self.layout.npcs.y
            - Layout.Pixels(21, self.uiScale),
        self.layout.npcs.width
    )
end

function ISPNCFactionMemberWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    MemberUI.instance = nil
end

function ISPNCFactionMemberWindow:new(
    x,
    y,
    width,
    height,
    options
)
    local object = PsychopatzWindow:new(
        x, y, width, height, options
    )
    setmetatable(object, self)
    self.__index = self
    return object
end

function MemberUI.Open()
    local window = MemberUI.instance
    if not window then
        local screenWidth = getCore and getCore()
            and getCore():getScreenWidth() or 1280
        local screenHeight = getCore and getCore()
            and getCore():getScreenHeight() or 800
        window = UI.NewWindow(
            ISPNCFactionMemberWindow,
            {
                title = tr(
                    "UI_PNC_FactionMemberWindowTitle",
                    "Faction Members and Commands"
                ),
                resizable = true,
                responsiveSpec = {
                    width = math.min(
                        1040,
                        screenWidth - 36
                    ),
                    height = math.min(
                        680,
                        screenHeight - 56
                    ),
                    minWidth = 780,
                    minHeight = 500,
                    maxWidth = 1280,
                    maxHeight = 900,
                },
            }
        )
        window:initialise()
        window:instantiate()
        MemberUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function MemberUI.Toggle()
    local window = MemberUI.instance
    if window and window:getIsVisible() then
        window:close()
        return nil
    end
    return MemberUI.Open()
end
