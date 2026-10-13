local Components = require "PNC/UI/Shared/PNC_ColonyUIComponents"

local Headers = {}
local HEADER_HEIGHT = 32
local SETTINGS_NAMESPACE = "ProjectHoomansBaseBuildingUI"
local SETTINGS_FILE = "ProjectHoomans_BaseBuildingUI.txt"
local NAME_PARTS = {
    categories = "Category",
    recipes = "Recipe",
    queue = "Queue",
    materials = "Material",
}

local DEFINITIONS = {
    categories = {
        columns = {},
        minimums = {},
        title = "CATEGORIES",
        cells = {},
    },
    recipes = {
        columns = {
            { key = "category", x = 0.56 },
            { key = "stock", x = 0.76 },
            { key = "action", x = 0.91 },
        },
        minimums = { 170, 90, 80, 95 },
        title = "BUILDABLE RECIPES",
        cells = { category = "CATEGORY", stock = "STOCK", action = "ACTION" },
    },
    queue = {
        columns = {
            { key = "worker", x = 0.38 },
            { key = "progress", x = 0.67 },
            { key = "action", x = 0.89 },
        },
        minimums = { 150, 110, 90, 90 },
        title = "BUILD QUEUE",
        cells = { worker = "WORKER", progress = "PROGRESS", action = "ACTION" },
    },
    materials = {
        columns = {
            { key = "required", x = 0.62 },
            { key = "available", x = 0.82 },
        },
        minimums = { 170, 100, 90 },
        title = "REQUIRED ITEMS",
        cells = { required = "REQUIRED", available = "STOCK" },
    },
}

local function stateFor(key, definition)
    return Components.CreateCatalogColumnState({
        namespace = SETTINGS_NAMESPACE,
        fileName = SETTINGS_FILE,
        key = key .. "Columns",
        columns = definition.columns,
    })
end

local function listName(key)
    return "build" .. NAME_PARTS[key] .. "List"
end

local function columnName(key)
    return "build" .. NAME_PARTS[key] .. "Columns"
end

local function headerName(key)
    return "build" .. NAME_PARTS[key] .. "Header"
end

local function saveCallback(state)
    return function() state:save() end
end

function Headers.InitializeState(window)
    if window.buildCatalogColumnStates then return end
    window.buildCatalogColumnStates = {}
    for key, definition in pairs(DEFINITIONS) do
        local state = stateFor(key, definition)
        window.buildCatalogColumnStates[key] = state
        window[columnName(key)] = state.columns
    end
end

function Headers.Create(window)
    if window.buildCategoryHeader then return end
    Headers.InitializeState(window)
    for key, definition in pairs(DEFINITIONS) do
        local list = window[listName(key)]
        local state = window.buildCatalogColumnStates[key]
        local header = Components.CreateCatalogHeader(window, state.columns, {
            lists = { list },
            minWidths = definition.minimums,
            onColumnResizeEnd = saveCallback(state),
        })
        header:setContent(definition.title, definition.cells, state.columns)
        window[headerName(key)] = header
    end
end

function Headers.LayoutList(LayoutApi, window, key, x, y, width, height)
    local list = window[listName(key)]
    local header = window[headerName(key)]
    if not list or not header then
        if list then LayoutApi.SetBounds(list, x, y, width, height) end
        return
    end
    local headerHeight = HEADER_HEIGHT
    LayoutApi.SetBounds(header, x, y, width, headerHeight)
    LayoutApi.SetBounds(list, x, y + headerHeight, width,
        math.max(1, height - headerHeight))
    header:layoutSplitters()
end

function Headers.Apply(window, active)
    for key, _ in pairs(DEFINITIONS) do
        local header = window[headerName(key)]
        if header then header:setVisible(active == true) end
    end
end

return Headers
