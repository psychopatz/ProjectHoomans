require "PsychopatzCore/UI/PsychopatzUI"
require "ISUI/ISScrollingListBox"
require "PsychopatzCore/Radio/PC_RadioDeviceState"
local StorageJournal = require
    "PNC/Core/Colony/Storage/PNC_ColonyStorageJournal"
local StorageActivityPresentation = require
    "PNC/UI/Communities/PNC_ColonyStorageActivityPresentation"

PNC = PNC or {}
PNC.ColonyJournalUI = PNC.ColonyJournalUI or {}

local JournalUI = PNC.ColonyJournalUI
local UI = PsychopatzCore.UI
local Theme = UI.Theme
local Layout = UI.Layout
local Protocol = PNC.ColonyJournalProtocol
local RadioDeviceState = PsychopatzCore.RadioDeviceState
local RadioImageAnimation = PsychopatzCore.RadioImageAnimation
local Options = require "PsychopatzCore/UI/PsychopatzCommandHubOptions"
local WidgetWindow = UI.WidgetWindow

local function tr(key, fallback)
    local value = getText and getText(key) or nil
    return value and value ~= "" and value ~= key and value or fallback
end

local function state()
    return PNC.Network and PNC.Network.ClientState or {}
end

local function humanize(value)
    value = tostring(value or "")
    value = string.gsub(value, "^projecthoomans%.", "")
    value = string.gsub(value, "_", " ")
    value = string.gsub(value, "(%l)(%u)", "%1 %2")
    value = string.gsub(value, "^%l", string.upper)
    return value ~= "" and value or "Unknown"
end

local function itemName(value)
    value = tostring(value or "")
    if value == "" then return "Unknown item" end
    if getItemNameFromFullType and string.find(value, ".", 1, true) then
        local translated = getItemNameFromFullType(value)
        if translated and translated ~= "" then return translated end
    end
    return string.match(value, "%.[^.]+$")
        and string.match(value, "%.[^.]+$"):sub(2) or value
end

local function timeLabel(worldMinute)
    worldMinute = math.max(0, math.floor(tonumber(worldMinute) or 0))
    local day = math.floor(worldMinute / 1440) + 1
    local minuteOfDay = worldMinute % 1440
    return string.format("D%d %02d:%02d", day,
        math.floor(minuteOfDay / 60), minuteOfDay % 60)
end

local function storageMessage(code, args)
    local operation
    if tonumber(code) == 1 then
        operation = StorageJournal.OPERATION.STORE
    elseif tonumber(code) == 2 then
        operation = StorageJournal.OPERATION.TAKE
    else
        return "Recorded storage event"
    end
    local fields = StorageJournal.FIELD
    local formatted = StorageActivityPresentation.Row({
        [fields.OPERATION] = operation,
        [fields.ACTOR] = tostring(args[1] or ""),
        [fields.TYPE_ID] = tonumber(args[2]) or args[2],
        [fields.QUANTITY] = tonumber(args[3]) or 0,
        [fields.REASON] = args[4],
    })
    return formatted and formatted.message or "Recorded storage event"
end

local function npcMessage(code, args)
    code = tonumber(code) or 0
    if code == 3 then
        return string.format("Ate %s (+%s%%)", itemName(args[1]),
            tostring(math.floor((tonumber(args[2]) or 0) * 100 + 0.5)))
    elseif code == 4 then
        return string.format("Drank %s (+%s%%)", itemName(args[1]),
            tostring(math.floor((tonumber(args[2]) or 0) * 100 + 0.5)))
    elseif code == 5 then
        return string.format("%s: %s -> %s", humanize(args[1]),
            humanize(args[2]), humanize(args[3]))
    elseif code == 6 then
        return tostring(args[2]) == "true"
            and "Critical need damage became lethal"
            or "Critical need damage reached the health floor"
    elseif code == 7 then
        return string.format("Weight: %s -> %s (%s kg)", humanize(args[1]),
            humanize(args[2]), tostring(args[3] or "?"))
    elseif code == 8 then
        return string.format("Reached %s level %s", humanize(args[1]),
            tostring(args[2] or "?"))
    elseif code == 9 then
        return string.format("Wounded: %s on %s (%s damage)",
            humanize(args[2]), humanize(args[1]), tostring(args[3] or "?"))
    end
    return "Recorded event: " .. humanize(Protocol.EventType(code) or "unknown")
end

local function rowModel(row)
    if type(row) ~= "table" then return nil end
    local source = tonumber(row[3]) or 0
    local code = tonumber(row[4]) or 0
    local args = { row[7], row[8], row[9], row[10] }
    local subject = tostring(row[6] or "")
    if subject == "" then subject = tostring(row[5] or "Unknown") end
    local isStorage = source == Protocol.SOURCE_STORAGE
    return {
        sequence = tonumber(row[1]) or 0,
        time = timeLabel(row[2]),
        subject = subject,
        sourceLabel = isStorage
            and tr("UI_PNC_ColonyJournal_Storage", "STORAGE")
            or tr("UI_PNC_ColonyJournal_NPC", "NPC"),
        sourceColor = isStorage and "accent" or "success",
        message = isStorage
            and storageMessage(code, args) or npcMessage(code, args),
    }
end

local function drawRow(list, y, entry, alternate)
    local row = rowModel(entry.item)
    if not row then return y + list.itemheight end
    local latest = entry.index == 1
    UI.DrawListSelection(list, y, list.itemheight, latest, alternate)
    local badgeWidth = UI.DrawBadge(list, row.sourceLabel,
        list:getWidth() - 8, y + 5, row.sourceColor)
    list:drawText(row.time, 8, y + 5,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    local subjectX = 88
    local subjectWidth = math.max(80, list:getWidth() - subjectX
        - badgeWidth - 18)
    list:drawText(Layout.Ellipsize(row.subject, UIFont.Small,
        subjectWidth), subjectX, y + 5,
        Theme.colors.text.r, Theme.colors.text.g,
        Theme.colors.text.b, Theme.colors.text.a, UIFont.Small)
    list:drawText(Layout.Ellipsize(row.message, UIFont.Small,
        list:getWidth() - 16), 8, y + 25,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    if latest then
        local accent = Theme.colors.accent
        list:drawRect(0, y + list.itemheight - 2, list:getWidth(), 2,
            0.75, accent.r, accent.g, accent.b)
    end
    return y + list.itemheight
end

ISPNCColonyJournalWindow = PsychopatzWindow:derive(
    "ISPNCColonyJournalWindow")

function ISPNCColonyJournalWindow:initialise()
    PsychopatzWindow.initialise(self)
    Options.ApplyOpacity(self, Options.GetOpacity())
end

function ISPNCColonyJournalWindow:createChildren()
    PsychopatzWindow.createChildren(self)
    self.list = UI.CreateList(self, {
        itemHeight = Layout.Pixels(56, self.uiScale),
        doDrawItem = drawRow,
    })
    self.headerHeight = Layout.Pixels(56, self.uiScale)
    self.headerGap = Layout.Pixels(8, self.uiScale)
    self.lastRevision = -1
    self.lastRequestAt = 0
    self.lastRadioCheckAt = 0
    self.radioActive = false
    self.radioImageAnimation = RadioImageAnimation
        and RadioImageAnimation.New({
            offPath = "media/ui/Radio/Signal_found/2.png",
            searchPrefix = "media/ui/Radio/Signal_search/",
            frameCount = 5,
            frameDuration = 200,
        }) or nil
    self.rowCount = 0
    self.lastContentOpacitySignature = nil
    self:requestResponsiveLayout(true)
    self:refreshRows()
    self:applyContentStyle()
    if WidgetWindow then
        WidgetWindow.Install(self, {
            id = "pnc-colony-journal-widget",
            onDetachedChanged = function()
                local controller = PNC.CommandHub
                    and PNC.CommandHub.ChildController
                if controller and controller.SyncPositions then
                    controller.SyncPositions()
                end
            end,
        })
    end
end

function ISPNCColonyJournalWindow:applyContentStyle()
    local signature = Options.GetContentOpacitySignature()
    if self.lastContentOpacitySignature == signature then return end
    -- Keep the journal body just above the window opacity, matching the
    -- Work list while preserving the world visibility of the outer panel.
    Options.ApplySurfaceOpacity(self.list, "detail")
    self.contentOpacity = Options.GetContentOpacity("detail")
    self.lastContentOpacitySignature = signature
end

function ISPNCColonyJournalWindow:onResponsiveLayout()
    local rect = self:getContentRect({ top = 28, bottom = 12 })
    self.headerRect = {
        x = rect.x, y = rect.y, width = rect.width,
        height = self.headerHeight or Layout.Pixels(56, self.uiScale),
    }
    local listY = rect.y + self.headerRect.height + (self.headerGap or 8)
    Layout.SetBounds(self.list, rect.x, listY, rect.width,
        math.max(1, rect.height - self.headerRect.height
            - (self.headerGap or 8)))
end

function ISPNCColonyJournalWindow:refreshRows()
    local current = state()
    local journal = current.colonyJournal or {}
    self.list:clear()
    for _, row in ipairs(journal.rows or {}) do
        self.list:addItem(tostring(row[1] or ""), row)
    end
    self.list:setYScroll(0)
    self.list.smoothScrollY = nil
    self.list.smoothScrollTargetY = nil
    self.rowCount = #(journal.rows or {})
    self.lastSyncAt = tonumber(journal.lastSyncAt)
    self.lastRevision = tonumber(current.colonyJournalRevision) or 0
end

function ISPNCColonyJournalWindow:checkRadio(now)
    if now - (tonumber(self.lastRadioCheckAt) or 0) < 500 then return end
    self.lastRadioCheckAt = now
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    self.radioActive = RadioDeviceState.FindActivePlayerDevice(player) ~= nil
end

function ISPNCColonyJournalWindow:requestJournal(now)
    if not self.radioActive then return end
    if now - (tonumber(self.lastRequestAt) or 0) < 2000 then return end
    if PNC.Client and PNC.Client.RequestColonyJournal then
        PNC.Client.RequestColonyJournal(nil, 32)
        self.lastRequestAt = now
    end
end

function ISPNCColonyJournalWindow:prerender()
    if self.owner and self.owner.getIsVisible
        and not self.owner:getIsVisible()
    then
        self:close()
        return
    end
    self:applyContentStyle()
    local now = PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
    self:checkRadio(now)
    local current = state()
    if (tonumber(current.colonyJournalRevision) or 0) ~= self.lastRevision then
        self:refreshRows()
    end
    self:requestJournal(now)
    PsychopatzWindow.prerender(self)
    if WidgetWindow then WidgetWindow.Sync(self) end
end

function ISPNCColonyJournalWindow:render()
    PsychopatzWindow.render(self)
    local header = self.headerRect
    if not header then return end
    UI.DrawSurface(self, header.x, header.y, header.width, header.height,
        true, self.contentOpacity)
    local signalTexture = self.radioImageAnimation
        and self.radioImageAnimation:GetTexture(self.radioActive)
    local titleX = header.x + 10
    local titleWidth = header.width - 20
    if signalTexture then
        local imageSize = math.min(Layout.Pixels(30, self.uiScale),
            math.max(1, header.height - Layout.Pixels(10, self.uiScale)))
        local imageX = header.x + header.width - imageSize
            - Layout.Pixels(8, self.uiScale)
        local imageY = header.y + math.floor((header.height - imageSize) / 2)
        self:drawTextureScaled(signalTexture, imageX, imageY,
            imageSize, imageSize, 1, 1, 1, 1)
        titleWidth = math.max(1, imageX - titleX - Layout.Pixels(10,
            self.uiScale))
    end
    UI.DrawSectionTitle(self,
        tr("UI_PNC_ColonyJournal_Title", "COLONY JOURNAL"),
        titleX, header.y + 7, titleWidth)
    local countText = string.format("%d %s  /  %s",
        self.rowCount or 0,
        tr("UI_PNC_ColonyJournal_Entries", "ENTRIES"),
        tr("UI_PNC_ColonyJournal_AutoSync", "AUTO-SYNC"))
    self:drawText(countText, header.x + 10, header.y + 32,
        Theme.colors.textMuted.r, Theme.colors.textMuted.g,
        Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    if (self.rowCount or 0) == 0 then
        local list = self.list
        self:drawTextCentre(
            tr("UI_PNC_ColonyJournal_NoEntries", "No colony events received yet"),
            list:getX() + list:getWidth() / 2,
            list:getY() + list:getHeight() / 2 - 8,
            Theme.colors.textMuted.r, Theme.colors.textMuted.g,
            Theme.colors.textMuted.b, Theme.colors.textMuted.a, UIFont.Small)
    end

end

function ISPNCColonyJournalWindow:close()
    self:saveGeometry(true)
    self:setVisible(false)
    self:removeFromUIManager()
    if JournalUI.instance == self then JournalUI.instance = nil end
end

function ISPNCColonyJournalWindow:new(x, y, width, height, options)
    local object = PsychopatzWindow:new(x, y, width, height, options)
    setmetatable(object, self)
    self.__index = self
    return object
end

function JournalUI.CanOpen()
    -- The event viewer is useful even without a radio. Radio possession and
    -- signal availability only control whether new entries can be synced.
    return true
end

function JournalUI.HasRadio()
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    return RadioDeviceState.HasPlayerDevice(player)
end

function JournalUI.Open(owner)
    if not JournalUI.CanOpen() then return nil, "radio_unavailable" end
    local window = JournalUI.instance
    if not window then
        window = UI.NewWindow(ISPNCColonyJournalWindow, {
            title = tr("UI_PNC_ColonyJournal_Title", "COLONY JOURNAL"),
            resizable = true,
            persistenceKey = "PNC.ColonyJournal",
            responsiveSpec = {
                width = 640, height = 540,
                minWidth = 460, minHeight = 360,
                maxWidth = 980, maxHeight = 900,
            },
        })
        window:initialise()
        window:instantiate()
        JournalUI.instance = window
    end
    window.owner = owner or window.owner
    window:addToUIManager()
    window:setVisible(true)
    Options.ApplyOpacity(window, Options.GetOpacity())
    window:bringToTop()
    window.radioActive = RadioDeviceState.FindActivePlayerDevice(
        getSpecificPlayer and getSpecificPlayer(0) or nil) ~= nil
    window:refreshRows()
    window:requestJournal(PNC.Core.Now())
    return window
end

function JournalUI.Close()
    if JournalUI.instance then JournalUI.instance:close() end
end

function JournalUI.Toggle(owner)
    if JournalUI.instance and JournalUI.instance:getIsVisible() then
        JournalUI.instance:close()
        return false
    end
    return JournalUI.Open(owner) ~= nil
end

return JournalUI
