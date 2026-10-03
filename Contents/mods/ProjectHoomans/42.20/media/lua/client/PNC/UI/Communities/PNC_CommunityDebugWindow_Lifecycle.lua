local CommunityUI = PNC.CommunityDebugUI
local UI = PsychopatzCore.UI
local text = function(key)
    return getText and PNC.Translation.GetKey(key) or key
end
local selected = CommunityUI.Internal.selected

function ISPNCCommunityDebugWindow:prerender()
    local now = PNC.Core.Now()
    local received = tonumber(
        ClientState.lastCommunityDebugReceiveAt
    ) or 0
    local signature = self:selectionSignature()
    if received > (tonumber(self.lastReceiveAt) or 0) then
        self:refreshSnapshot()
        signature = self:selectionSignature()
    end
    if signature ~= self.requestedSignature then
        self.requestedSignature = signature
        self:requestSnapshot()
    elseif now - (tonumber(self.lastRequestAt) or 0)
        > 2500
    then
        self:requestSnapshot()
    end
    local community = selected(self.communities)
    local faction = selected(self.factions)
    local npc = selected(self.npcs)
    local selectedCommunity = community
        and community.community or nil
    local npcValue = npc and npc.npc or nil
    for index, button in ipairs(self.controls) do
        local internal = CONTROLS[index].id
        local enabled = internal == "refresh"
            or internal == "overlay"
            or internal == "validate"
            or internal == "repair_indexes"
            or internal == "next_supply"
        if internal == "create_settlement"
            or internal == "create_camp"
        then
            enabled = faction ~= nil
        elseif internal == "assign" then
            enabled = selectedCommunity ~= nil
                and npcValue ~= nil
                and npcValue.factionID
                    == selectedCommunity.factionID
                and npcValue.communityID == nil
        elseif internal == "transfer" then
            enabled = selectedCommunity ~= nil
                and npcValue ~= nil
                and npcValue.factionID
                    == selectedCommunity.factionID
                and npcValue.communityID ~= nil
                and npcValue.communityID
                    ~= selectedCommunity.id
        elseif internal == "remove"
            or internal == "leader"
            or internal == "role"
        then
            enabled = selectedCommunity ~= nil
                and npcValue ~= nil
                and npcValue.communityID
                    == selectedCommunity.id
        elseif internal == "set_home_to_npc" then
            enabled = selectedCommunity ~= nil
                and npcValue ~= nil
        elseif internal == "security_down"
            or internal == "security_up"
            or internal == "morale_down"
            or internal == "morale_up"
            or internal == "supply_add"
            or internal == "supply_remove"
            or internal == "archive"
            or internal == "destroy"
        then
            enabled = selectedCommunity ~= nil
        end
        button:setEnable(enabled)
    end
    PsychopatzWindow.prerender(self)
end

function ISPNCCommunityDebugWindow:render()
    PsychopatzWindow.render(self)
    if not self.layout then return end
    UI.DrawSectionTitle(
        self,
        text("UI_PNC_CommunitySectionCommunities"),
        self.layout.community.x,
        self.layout.community.y
            - Layout.Pixels(21, self.uiScale),
        self.layout.community.width
    )
    UI.DrawSectionTitle(
        self,
        text("UI_PNC_CommunitySectionFactions"),
        self.layout.faction.x,
        self.layout.faction.y
            - Layout.Pixels(21, self.uiScale),
        self.layout.faction.width
    )
    UI.DrawSectionTitle(
        self,
        text("UI_PNC_CommunitySectionNPCs"),
        self.layout.npc.x,
        self.layout.npc.y
            - Layout.Pixels(21, self.uiScale),
        self.layout.npc.width
    )
    UI.DrawSectionTitle(
        self,
        text("UI_PNC_CommunitySectionDetails"),
        self.layout.detail.x,
        self.layout.detail.y
            - Layout.Pixels(21, self.uiScale),
        self.layout.detail.width
    )
end

function ISPNCCommunityDebugWindow:close()
    self:setVisible(false)
    self:removeFromUIManager()
    CommunityUI.instance = nil
end

function ISPNCCommunityDebugWindow:new(
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

function CommunityUI.Open()
    local window = CommunityUI.instance
    if not PNC.Client or not PNC.Client.CanUseDebug
        or not PNC.Client.CanUseDebug()
    then
        return nil
    end
    if not window then
        local screenWidth = getCore and getCore()
            and getCore():getScreenWidth() or 1280
        local screenHeight = getCore and getCore()
            and getCore():getScreenHeight() or 800
        window = UI.NewWindow(ISPNCCommunityDebugWindow, {
            title = text("UI_PNC_CommunityInspectorTitle"),
            resizable = true,
            responsiveSpec = {
                width = math.min(1280, screenWidth - 24),
                height = math.min(800, screenHeight - 40),
                minWidth = 820,
                minHeight = 540,
                maxWidth = 1500,
                maxHeight = 960,
            },
        })
        window:initialise()
        window:instantiate()
        CommunityUI.instance = window
    end
    window:addToUIManager()
    window:setVisible(true)
    window:bringToTop()
    window:requestSnapshot()
    return window
end

function CommunityUI.Toggle()
    if CommunityUI.instance
        and CommunityUI.instance:getIsVisible()
    then
        CommunityUI.instance:close()
        return false
    end
    return CommunityUI.Open() ~= nil
end
