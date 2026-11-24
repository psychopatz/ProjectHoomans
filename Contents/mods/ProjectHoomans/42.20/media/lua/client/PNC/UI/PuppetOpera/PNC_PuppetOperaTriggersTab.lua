-- Triggers & Export tab for the Puppet Opera Studio GUI.
--
-- Lets creators wire gameplay trigger events (e.g. teammate_incapacitated,
-- social_kiss, camp_dance, escort_handhold, conversation_beat) onto any
-- blueprint, toggle beat mode / phase-lock / collision settings, and publish
-- or export standalone Lua (+ optional AnimSet XML) files in one click.

if not ISPanel then require "ISUI/ISPanel" end
if not ISComboBox then require "ISUI/ISComboBox" end
if not ISScrollingListBox then require "ISUI/ISScrollingListBox" end
if not (PsychopatzCore and PsychopatzCore.UI) then
    require "PsychopatzCore/UI/PsychopatzUI"
end

PNC = PNC or {}

local UI = PsychopatzCore.UI
local Layout = UI.Layout
local TriggerRegistry = PNC.PuppetOpera and PNC.PuppetOpera.TriggerRegistry
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_TriggerRegistry"
local Exporter = PNC.PuppetOpera and PNC.PuppetOpera.Exporter
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_Exporter"

ISPNCPuppetOperaTriggersTab = ISPanel:derive("ISPNCPuppetOperaTriggersTab")

local function tr(key, fallback)
    local translation = PNC.Translation
    local value = translation and translation.GetKey
        and translation.GetKey(key, fallback) or fallback
    if not value or value == "" or value == key then return fallback end
    return value
end

local function drawRow(list, y, row, alternate)
    if type(row) ~= "table" then return y + list.itemheight end
    local item = type(row.item) == "table" and row.item or {}
    if alternate then
        list:drawRect(0, y, list:getWidth(), list.itemheight,
            0.12, 0.16, 0.18, 0.20)
    end
    local labelW = math.max(120, math.floor(list:getWidth() * 0.34))
    list:drawText(
        Layout.Ellipsize(tostring(item.label or ""), UIFont.Small, labelW - 12),
        8, y + 4, 0.70, 0.80, 0.88, 1, UIFont.Small
    )
    list:drawText(
        Layout.Ellipsize(tostring(item.value or "-"), UIFont.Small,
            math.max(40, list:getWidth() - labelW - 22)),
        labelW, y + 4,
        item.warn and 1.00 or 0.92,
        item.warn and 0.65 or 0.96,
        item.warn and 0.40 or 1.00,
        1, UIFont.Small
    )
    return y + list.itemheight
end

function ISPNCPuppetOperaTriggersTab:setContext(window)
    self.window = window
    self.model = window and window.model or nil
end

function ISPNCPuppetOperaTriggersTab:createChildren()
    ISPanel.createChildren(self)
    self.backgroundColor = { r = 0.05, g = 0.07, b = 0.09, a = 0.92 }
    self.borderColor = { r = 0.24, g = 0.32, b = 0.40, a = 0.65 }

    self.eventCombo = ISComboBox:new(0, 0, 1, 1, self, nil)
    self.eventCombo:initialise()
    self.eventCombo:instantiate()
    for _, eventName in ipairs(TriggerRegistry.KnownEvents()) do
        self.eventCombo:addOption(eventName)
    end
    self:addChild(self.eventCombo)

    self.buttons = {}
    for _, def in ipairs({
        { "add_trigger", "UI_PNC_PuppetOpera_AddTrigger", "ADD TRIGGER", "selected" },
        { "clear_triggers", "UI_PNC_PuppetOpera_ClearTriggers", "CLEAR TRIGGERS", "danger" },
        { "cycle_mode", "UI_PNC_PuppetOpera_CycleBeatMode", "BEAT MODE: TIMED", "quiet" },
        { "cycle_sync", "UI_PNC_PuppetOpera_CyclePhaseLock", "SYNC: NONE", "quiet" },
        { "export_lua", "UI_PNC_PuppetOpera_ExportLua", "EXPORT LUA + XML", "selected" },
    }) do
        local btn = UI.CreateButton(self, {
            id = def[1],
            title = tr(def[2], def[3]),
            variant = def[4],
            target = self,
            onclick = UI.ButtonCallback(function(clicked)
                return self:onAction(clicked)
            end),
        })
        self.buttons[#self.buttons + 1] = btn
    end

    self.summaryList = ISScrollingListBox:new(0, 0, 1, 1)
    self.summaryList:initialise()
    self.summaryList:instantiate()
    self.summaryList.itemheight = 24
    self.summaryList.doDrawItem = drawRow
    self.summaryList.backgroundColor = { r = 0.07, g = 0.10, b = 0.12, a = 0.92 }
    self.summaryList.borderColor = { r = 0.24, g = 0.32, b = 0.40, a = 0.65 }
    self:addChild(self.summaryList)
end

function ISPNCPuppetOperaTriggersTab:onAction(button)
    local id = button and button.internal or ""
    local model = self.model
    if not model or not model.GetDraft then return end
    local draft = model.GetDraft()
    if type(draft) ~= "table" then return end

    if id == "add_trigger" then
        local idx = tonumber(self.eventCombo.selected) or 1
        local eventName = self.eventCombo.options
            and self.eventCombo.options[idx] or "manual"
        draft.triggers = type(draft.triggers) == "table" and draft.triggers or {}
        draft.triggers[#draft.triggers + 1] = {
            event = tostring(eventName),
            priority = 50,
            cooldownSec = 30,
            filters = { sameFaction = true },
        }
        if model.MarkDirty then model.MarkDirty() end
        if self.window and self.window.setEditorStatus then
            self.window:setEditorStatus("trigger_added:" .. tostring(eventName), false)
        end
    elseif id == "clear_triggers" then
        draft.triggers = {}
        if model.MarkDirty then model.MarkDirty() end
        if self.window and self.window.setEditorStatus then
            self.window:setEditorStatus("triggers_cleared", false)
        end
    elseif id == "cycle_mode" then
        local beat = model.GetSelectedBeat and model.GetSelectedBeat() or nil
        if beat then
            local modes = { "timed", "sustained", "locomotive" }
            local cur = tostring(beat.mode or "timed")
            local nextMode = modes[1]
            for i, m in ipairs(modes) do
                if m == cur then
                    nextMode = modes[(i % #modes) + 1]
                    break
                end
            end
            beat.mode = nextMode
            beat.tetherActive = (nextMode == "locomotive") or beat.tetherActive == true
            if model.MarkDirty then model.MarkDirty() end
        end
    elseif id == "cycle_sync" then
        local beat = model.GetSelectedBeat and model.GetSelectedBeat() or nil
        if beat then
            local locks = { "none", "leader_track", "server_clock" }
            local cur = tostring(beat.phaseLock or "none")
            local nextLock = locks[1]
            for i, m in ipairs(locks) do
                if m == cur then
                    nextLock = locks[(i % #locks) + 1]
                    break
                end
            end
            beat.phaseLock = nextLock
            if model.MarkDirty then model.MarkDirty() end
        end
    elseif id == "export_lua" then
        local ok, result = Exporter.Export(draft, {
            publish = true,
            includeXml = true,
        })
        if self.window and self.window.setEditorStatus then
            if ok then
                self.window:setEditorStatus(
                    "exported:" .. tostring(result.luaPath),
                    false
                )
            else
                self.window:setEditorStatus("export_failed:" .. tostring(result), true)
            end
        end
    end
    if self.window and self.window.refreshViews then
        self.window:refreshViews()
    else
        self:refresh()
    end
end

function ISPNCPuppetOperaTriggersTab:onResponsiveLayout()
    local w = math.max(1, self:getWidth())
    local h = math.max(1, self:getHeight())
    local pad = 10
    local gap = 8
    local rowH = 28
    local innerW = math.max(1, w - pad * 2)
    Layout.SetBounds(self.eventCombo, pad, pad, math.min(260, innerW), rowH)

    local btnY = pad + rowH + gap
    local btnCount = math.max(1, #self.buttons)
    local btnW = math.max(1, math.floor((innerW - gap * (btnCount - 1)) / btnCount))
    for i, btn in ipairs(self.buttons) do
        Layout.SetBounds(btn, pad + (i - 1) * (btnW + gap), btnY, btnW, rowH)
    end

    local listY = btnY + rowH + gap
    Layout.SetBounds(self.summaryList, pad, listY, innerW, math.max(1, h - listY - pad))
end

function ISPNCPuppetOperaTriggersTab:refresh()
    if not self.summaryList then return end
    self.summaryList:clear()
    local model = self.model
    local draft = model and model.GetDraft and model.GetDraft() or nil
    if type(draft) ~= "table" then
        self.summaryList:addItem("none", { label = "Scene", value = "No draft loaded", warn = true })
        return
    end
    local beat = model.GetSelectedBeat and model.GetSelectedBeat() or nil
    local beatMode = beat and tostring(beat.mode or "timed") or "timed"
    local phaseLock = beat and tostring(beat.phaseLock or "none") or "none"
    for _, btn in ipairs(self.buttons or {}) do
        if btn.internal == "cycle_mode" and btn.setTitle then
            btn:setTitle("BEAT MODE: " .. string.upper(beatMode))
        elseif btn.internal == "cycle_sync" and btn.setTitle then
            btn:setTitle("SYNC: " .. string.upper(phaseLock))
        end
    end

    local function add(label, value, warn)
        self.summaryList:addItem(label, { label = label, value = value, warn = warn == true })
    end
    add("Scene ID", tostring(draft.id or "-"))
    add("Selected Beat", beat and tostring(beat.id or "-") or "-")
    add("Beat Mode", beatMode)
    add("Phase Lock", phaseLock)
    add("Export Path", Exporter.EXPORT_ROOT .. tostring(draft.id or "scene") .. ".lua")
    local triggers = type(draft.triggers) == "table" and draft.triggers or {}
    if #triggers == 0 then
        add("Triggers", "None (manual / API only)")
    else
        for i, trig in ipairs(triggers) do
            add("Trigger #" .. tostring(i),
                tostring(trig.event) .. "  (prio=" .. tostring(trig.priority or 50)
                    .. ", cd=" .. tostring(trig.cooldownSec or 0) .. "s)")
        end
    end
end

function ISPNCPuppetOperaTriggersTab:new(x, y, width, height)
    local o = ISPanel:new(x, y, width, height)
    setmetatable(o, self)
    self.__index = self
    return o
end

return ISPNCPuppetOperaTriggersTab
