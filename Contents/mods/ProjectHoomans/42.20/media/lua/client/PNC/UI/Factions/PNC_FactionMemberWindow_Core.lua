local MemberUI = PNC.FactionMemberUI
local ClientState = PNC.Network.ClientState
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Identity = PNC.NPCIdentityPresentation
local CONTROLS = MemberUI.Internal.Controls
local selectedItem = MemberUI.Internal.selectedItem

local function tr(key, fallback)
    local value = getText and PNC.Translation.GetKey(key) or nil
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
