-- Reusable colonist selector shared by every colony-facing UI.
--
-- The selector owns roster projection and stable selection restoration. Tabs
-- consume the selected snapshot through the controller; they never need to
-- know how the roster list is built or how native list selection works.

local Components = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Components"
local Presentation = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Presentation"
local Shared = require "PNC/UI/Communities/ColonyManagement/PNC_ColonyManagement_Shared"

local Selector = {}

PNC = PNC or {}
PNC.ColonistUI = PNC.ColonistUI or {}
PNC.ColonistUI.Selector = Selector

local function selectedIndex(rows, selectedID)
    if selectedID == nil then return nil end
    for index, row in ipairs(rows or {}) do
        if tostring(row.id or "") == tostring(selectedID) then
            return index
        end
    end
    return nil
end

function Selector.Create(window, onSelected)
    local pane, list = Components.CreateRosterPane(window)
    list.onMouseDown = function(self, x, y)
        if ISScrollingListBox and ISScrollingListBox.onMouseDown then
            ISScrollingListBox.onMouseDown(self, x, y)
        end
        if type(onSelected) == "function" then onSelected(self) end
    end
    return pane, list
end

function Selector.GetSelected(list)
    return Shared.ListValue(list)
end

function Selector.BuildRows(snapshot)
    return Presentation.BuildRoster(snapshot)
end

function Selector.SetRows(list, snapshot, selectedID)
    local rows = Selector.BuildRows(snapshot)
    Components.SetRows(list, rows)
    if #rows == 0 then
        list.selected = 0
        return rows, nil
    end
    list.selected = selectedIndex(rows, selectedID) or 1
    return rows, Selector.GetSelected(list)
end

function Selector.SetHeader(pane, title, count)
    if pane and pane.setHeader then pane:setHeader(title, count) end
end

return Selector
