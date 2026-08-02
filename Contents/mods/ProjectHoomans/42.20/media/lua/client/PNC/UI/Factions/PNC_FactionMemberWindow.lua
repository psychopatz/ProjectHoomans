require "PsychopatzCore/UI/PsychopatzUI"
require "PNC/UI/Factions/PNC_FactionEmblemRenderer"
require "PNC/UI/Factions/PNC_FactionMemberModal"
require "PNC/Knowledge/PNC_NPCIdentityPresentation"

PNC = PNC or {}
PNC.FactionMemberUI = PNC.FactionMemberUI or {}

local MemberUI = PNC.FactionMemberUI
local Modal = PNC.FactionMemberModal
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Identity = PNC.NPCIdentityPresentation

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key
        and value or fallback
end

local function drawMember(list, y, entry, alternate)
    local item = entry.item
    UI.DrawListSelection(
        list,
        y,
        list.itemheight,
        list.selected == entry.index,
        alternate
    )
    local textColor = Theme.colors.text
    local muted = Theme.colors.textMuted
    list:drawText(
        Layout.Ellipsize(
            item.label,
            UIFont.Small,
            list:getWidth() - 20
        ),
        10,
        y + 5,
        textColor.r,
        textColor.g,
        textColor.b,
        textColor.a,
        UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(
            item.detail or "",
            UIFont.Small,
            list:getWidth() - 20
        ),
        10,
        y + 24,
        muted.r,
        muted.g,
        muted.b,
        muted.a,
        UIFont.Small
    )
    return y + list.itemheight
end

local CONTROLS = {
    {
        id = "refresh",
        label = "Refresh",
        variant = "quiet",
    },
    {
        id = "add_player",
        label = "Add Selected Player",
        variant = "success",
    },
    {
        id = "transfer_leadership",
        label = "Transfer Leadership",
        variant = "default",
    },
    {
        id = "banish_player",
        label = "Banish Player",
        variant = "danger",
    },
    {
        id = "follow",
        label = "NPC: Follow",
        variant = "success",
    },
    {
        id = "stay",
        label = "NPC: Stay",
        variant = "quiet",
    },
    {
        id = "attack_auto",
        label = "NPC: Auto Attack",
        variant = "default",
    },
    {
        id = "attack_none",
        label = "NPC: Hold Fire",
        variant = "danger",
    },
    {
        id = "all_follow",
        label = "All: Follow",
        variant = "success",
    },
    {
        id = "all_stay",
        label = "All: Stay",
        variant = "quiet",
    },
}

ISPNCFactionMemberWindow =
    PsychopatzWindow:derive("ISPNCFactionMemberWindow")

function ISPNCFactionMemberWindow:initialise()
    PsychopatzWindow.initialise(self)
end

function ISPNCFactionMemberWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.playerMembers = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawMember,
    })
    self.availablePlayers = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawMember,
    })
    self.npcMembers = UI.CreateList(self, {
        itemHeight = Layout.Pixels(44, self.uiScale),
        doDrawItem = drawMember,
    })
    self.controls = {}
    for _, definition in ipairs(CONTROLS) do
        self.controls[#self.controls + 1] =
            UI.CreateButton(self, {
                id = definition.id,
                title = definition.label,
                target = self,
                onclick =
                    ISPNCFactionMemberWindow.onAction,
                variant = definition.variant,
            })
    end
    self:requestResponsiveLayout(true)
    self:requestSnapshot()
end

function ISPNCFactionMemberWindow:onResponsiveLayout()
    local rect = self:getContentRect({
        top = 54,
        bottom = 12,
    })
    local controls = Layout.Flow(
        self.controls,
        {
            x = rect.x,
            y = rect.y,
            width = rect.width,
        },
        {
            scale = self.uiScale,
            minWidth = 96,
        }
    )
    local top = controls.bottom
        + Layout.Pixels(30, self.uiScale)
    local height = math.max(
        120,
        rect.y + rect.height - top
    )
    local gap = Layout.Pixels(9, self.uiScale)
    local firstWidth = math.floor(
        (rect.width - gap * 2) * 0.28
    )
    local secondWidth = firstWidth
    local thirdWidth =
        rect.width - firstWidth - secondWidth - gap * 2
    self.layout = {
        players = {
            x = rect.x,
            y = top,
            width = firstWidth,
            height = height,
        },
        available = {
            x = rect.x + firstWidth + gap,
            y = top,
            width = secondWidth,
            height = height,
        },
        npcs = {
            x = rect.x + firstWidth + secondWidth
                + gap * 2,
            y = top,
            width = thirdWidth,
            height = height,
        },
    }
    for widget, bounds in pairs({
        [self.playerMembers] = self.layout.players,
        [self.availablePlayers] = self.layout.available,
        [self.npcMembers] = self.layout.npcs,
    }) do
        Layout.SetBounds(
            widget,
            bounds.x,
            bounds.y,
            bounds.width,
            bounds.height
        )
    end
end

local function selectedItem(list)
    local entry = list and list:getItem()
    return entry and entry.item or nil
end

local function restoreSelection(list, id)
    if not id then return end
    for index, entry in ipairs(list.items or {}) do
        if entry.item and entry.item.id == id then
            list.selected = index
            return
        end
    end
end

function ISPNCFactionMemberWindow:requestSnapshot()
    if PNC.Client and PNC.Client.RequestFactionMembers then
        PNC.Client.RequestFactionMembers()
    end
    self.lastRequestAt = PNC.Core.Now()
end

function ISPNCFactionMemberWindow:refreshSnapshot()
    local oldPlayer = selectedItem(self.playerMembers)
    local oldAvailable = selectedItem(self.availablePlayers)
    local oldNPC = selectedItem(self.npcMembers)
    local snapshot = ClientState.factionMembers or {}

    self.playerMembers:clear()
    for _, member in ipairs(snapshot.playerMembers or {}) do
        local label = member.displayName
        if member.leader then label = label .. " [LEADER]" end
        self.playerMembers:addItem(label, {
            id = member.key,
            key = member.key,
            label = label,
            detail = tostring(member.accountIdentity)
                .. " / "
                .. (member.online and "online" or "offline"),
            member = member,
        })
    end
    restoreSelection(
        self.playerMembers,
        oldPlayer and oldPlayer.id
    )

    self.availablePlayers:clear()
    for _, member in ipairs(
        snapshot.availablePlayers or {}
    ) do
        self.availablePlayers:addItem(
            member.displayName,
            {
                id = member.key,
                key = member.key,
                label = member.displayName,
                detail = tostring(member.accountIdentity)
                    .. " / online",
                member = member,
            }
        )
    end
    restoreSelection(
        self.availablePlayers,
        oldAvailable and oldAvailable.id
    )

    self.npcMembers:clear()
    for _, member in ipairs(snapshot.npcMembers or {}) do
        local label = Identity.GetName(member)
        self.npcMembers:addItem(label, {
            id = member.id,
            label = label,
            detail = tostring(member.role)
                .. " / " .. tostring(member.rank)
                .. " / " .. tostring(member.presenceState),
            member = member,
        })
    end
    restoreSelection(
        self.npcMembers,
        oldNPC and oldNPC.id
    )

    self.lastReceiveAt = tonumber(
        ClientState.lastFactionMembersReceiveAt
    ) or PNC.Core.Now()
end

function ISPNCFactionMemberWindow:confirmPlayerAction(
    action,
    item
)
    local labels = {
        add_player = {
            title = tr(
                "UI_PNC_FactionMemberAddTitle",
                "Add Player to Faction"
            ),
            message = "Add " .. tostring(item.label)
                .. " as a faction member?",
            confirm = tr(
                "UI_PNC_FactionMemberAdd",
                "Add Player"
            ),
        },
        transfer_leadership = {
            title = tr(
                "UI_PNC_FactionMemberTransferTitle",
                "Transfer Faction Leadership"
            ),
            message = "Make " .. tostring(item.label)
                .. " the faction's only leader?",
            detail = "You will remain a faction member.",
            confirm = tr(
                "UI_PNC_FactionMemberTransfer",
                "Transfer"
            ),
        },
        banish_player = {
            title = tr(
                "UI_PNC_FactionMemberBanishTitle",
                "Banish Faction Member"
            ),
            message = "Remove " .. tostring(item.label)
                .. " from this faction?",
            detail = "They immediately lose access to faction NPC commands.",
            confirm = tr(
                "UI_PNC_FactionMemberBanish",
                "Banish"
            ),
            danger = true,
        },
    }
    local definition = labels[action]
    if not definition then return end
    Modal.Open({
        title = definition.title,
        message = definition.message,
        detail = definition.detail,
        confirmLabel = definition.confirm,
        danger = definition.danger,
        context = {
            action = action,
            playerKey = item.key,
        },
        onConfirm = function(context)
            PNC.Client.SendFactionMemberAction(
                context.action,
                context.playerKey
            )
        end,
    })
end

function ISPNCFactionMemberWindow:onAction(button)
    local action = button and button.internal or ""
    if action == "refresh" then
        self:requestSnapshot()
        return
    end
    if action == "add_player" then
        local item = selectedItem(self.availablePlayers)
        if item then self:confirmPlayerAction(action, item) end
        return
    end
    if action == "transfer_leadership"
        or action == "banish_player"
    then
        local item = selectedItem(self.playerMembers)
        if item then self:confirmPlayerAction(action, item) end
        return
    end
    local npc = selectedItem(self.npcMembers)
    if action == "all_follow" then
        PNC.Client.SendCompanionCommand(
            "follow",
            nil,
            "group"
        )
    elseif action == "all_stay" then
        PNC.Client.SendCompanionCommand(
            "stay",
            nil,
            "group"
        )
    elseif npc then
        PNC.Client.SendCompanionCommand(
            action,
            npc.id,
            "member_window"
        )
    end
end

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

return MemberUI
