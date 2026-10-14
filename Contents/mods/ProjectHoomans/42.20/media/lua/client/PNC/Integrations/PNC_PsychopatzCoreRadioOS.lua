-- Project Hoomans adapter for the Core Radio OS Contacts provider.
-- Discovery remains the authority for names, phases and call requests;
-- this module only translates the bounded client snapshot into Core rows.

PNC = PNC or {}

local loaded, OS = pcall(require,
    "PsychopatzCore/UI/Radio/OS/PsychopatzRadioOS")
if not loaded or type(OS) ~= "table"
    or type(OS.RegisterContactProvider) ~= "function"
then
    return nil
end

local ClientState = PNC.Network and PNC.Network.ClientState or {}
local Presentation = PNC.WorldDiscoveryPresentation
local PROVIDER_ID = "projecthoomans:contacts"
local ACTION_ID = "projecthoomans:call_contact"
local MAX_CONTACTS = 64
local MAX_PAGE_SIZE = 12
local snapshotRequestStarted = false

local function T(key, fallback)
    local translation = PNC.Translation
    if translation and type(translation.GetKey) == "function" then
        return translation.GetKey(key, fallback)
    end
    return fallback or key or ""
end

local function currentSnapshot()
    local snapshot = ClientState.worldDiscovery
    return type(snapshot) == "table" and snapshot or nil
end

local function rowsFromSnapshot(snapshot)
    local rows = {}
    local entities = snapshot and snapshot.entities or {}
    if type(entities) ~= "table" then return rows end
    for _, entity in ipairs(entities) do
        if #rows >= MAX_CONTACTS then break end
        local kind = tostring(entity.kind or "")
        local entityID = tostring(entity.entityID or "")
        if kind ~= "" and entityID ~= "" then
            local title = tostring(entity.name or entityID)
            if Presentation and Presentation.SignalName then
                title = Presentation.SignalName(entity)
            end
            local status = tostring(entity.phaseName or entity.phase or "unknown")
            if Presentation and Presentation.Phase then
                status = Presentation.Phase(entity.phaseName or entity.phase)
            end
            rows[#rows + 1] = {
                id = kind .. ":" .. entityID,
                title = title,
                status = status,
                actions = {
                    {
                        id = ACTION_ID,
                        label = T("UI_PNC_DiscoveryCall",
                            "Call / triangulate"),
                    },
                },
                capabilities = {
                    kind = kind,
                    entityID = entityID,
                    approximate = entity.approximate == true,
                },
            }
        end
    end
    return rows
end

local function requestInitialSnapshot()
    if snapshotRequestStarted or currentSnapshot() then return end
    if PNC.Client and PNC.Client.RequestWorldDiscovery then
        snapshotRequestStarted = true
        PNC.Client.RequestWorldDiscovery("snapshot")
    end
end

local function listContacts(_, page)
    local snapshot = currentSnapshot()
    if not snapshot then requestInitialSnapshot() end
    local rows = rowsFromSnapshot(snapshot)
    page = type(page) == "table" and page or {}
    local offset = math.max(0, math.floor(tonumber(page.offset) or 0))
    local limit = math.max(1, math.min(MAX_PAGE_SIZE,
        math.floor(tonumber(page.limit) or MAX_PAGE_SIZE)))
    local contacts = {}
    for index = offset + 1, math.min(#rows, offset + limit) do
        contacts[#contacts + 1] = rows[index]
    end
    return {
        contacts = contacts,
        total = #rows,
        revision = snapshot and snapshot.revision or 0,
    }
end

local function splitContactID(contactID)
    local value = tostring(contactID or "")
    local kind, entityID = string.match(value, "^([^:]+):(.+)$")
    if not kind or not entityID then return nil, nil end
    return kind, entityID
end

local function invokeContact(_, contactID, actionID)
    if tostring(actionID or "") ~= ACTION_ID then
        return false, "action_unsupported"
    end
    local kind, entityID = splitContactID(contactID)
    if not kind or not entityID then return false, "invalid_contact" end
    if not PNC.Client or not PNC.Client.RequestWorldDiscovery then
        return false, "discovery_service_unavailable"
    end
    local sent, payload = PNC.Client.RequestWorldDiscovery("call_contact", {
        kind = kind,
        entityID = entityID,
    })
    if sent == false then return false, payload or "request_failed" end
    return true, payload
end

local definition = {
    id = PROVIDER_ID,
    ownerModID = "ProjectHoomans",
    order = 20,
    isAvailable = function()
        return PNC.Client and PNC.Client.RequestWorldDiscovery ~= nil
    end,
    list = listContacts,
    invoke = invokeContact,
    onRefresh = function()
        snapshotRequestStarted = false
    end,
}

if OS.UnregisterContactProvider then OS.UnregisterContactProvider(PROVIDER_ID) end
OS.RegisterContactProvider(definition)

return definition
