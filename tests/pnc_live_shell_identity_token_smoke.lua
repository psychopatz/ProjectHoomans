local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "shared" } })

local ROOT = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/"
)

local function makeItem(id)
    local data = {}
    return {
        id = id,
        getFullType = function() return "Base.IDcard" end,
        getModData = function() return data end,
        setName = function(self, name) self.name = name end,
    }
end

local items = {}
local itemList = {
    size = function() return #items end,
    get = function(_, index) return items[index + 1] end,
}
local container = {
    getItems = function() return itemList end,
    AddItem = function(_, item)
        items[#items + 1] = item
        return item
    end,
    Remove = function(_, item)
        for index = #items, 1, -1 do
            if items[index] == item then
                table.remove(items, index)
                return
            end
        end
    end,
}
local body = {
    getInventory = function() return container end,
}

PNC = {
    Core = {
        IsAuthority = function() return true end,
    },
    BodyLifecycle = { Internal = {} },
    Equipment = {
        CreateItem = function()
            return makeItem("created")
        end,
    },
}

T.load(ROOT .. "PNC_BodyLifecycle_LiveShellToken.lua")

local Lifecycle = PNC.BodyLifecycle
local record = {
    id = "npc_token_test",
    name = "Token Test",
}

local token, created, reason =
    Lifecycle.EnsureLiveShellIdentityToken(record, body)
T.truthy(token, "live-shell token was not created")
T.truthy(created, "new live-shell token was not reported as created")
T.equal(reason, "created", "new token reason")
T.equal(#items, 1, "new token count")
T.equal(token:getModData().PNC_LiveShellToken, true,
    "live-shell token marker")
T.equal(token:getModData().PNC_LiveShellTokenVersion, 1,
    "live-shell token version")
T.equal(token:getModData().PNC_LiveShellTokenNPCId, record.id,
    "live-shell token npc id")

local found, foundReason = Lifecycle.GetLiveShellTokenNPCId(body)
T.equal(found, record.id, "exact live-shell token was not readable")
T.equal(foundReason, "live_shell_token", "exact token read reason")

local same, recreated, sameReason =
    Lifecycle.EnsureLiveShellIdentityToken(record, body)
T.equal(same, token, "existing live-shell token was replaced")
T.falsy(recreated, "existing live-shell token reported as created")
T.equal(sameReason, "existing", "existing token reason")
T.equal(#items, 1, "existing token duplicated")

-- Conflicting PNC lifecycle tokens fail closed until canonical repair runs.
local conflict = makeItem("conflict")
local conflictData = conflict:getModData()
conflictData.PNC_LiveShellToken = true
conflictData.PNC_LiveShellTokenVersion = 1
conflictData.PNC_LiveShellTokenNPCId = "npc_other"
items[#items + 1] = conflict

local ambiguous, ambiguousReason =
    Lifecycle.GetLiveShellTokenNPCId(body)
T.equal(ambiguous, nil, "conflicting token identities were guessed")
T.equal(ambiguousReason, "ambiguous_live_shell_tokens",
    "conflicting token reason")

Lifecycle.EnsureLiveShellIdentityToken(record, body)
T.equal(#items, 1, "canonical token repair kept stale token")
T.equal(Lifecycle.GetLiveShellTokenNPCId(body), record.id,
    "canonical token repair lost actor identity")

-- Lifecycle-only identity must not enter logical inventory, and death must
-- strip it before the proper corpse identity card is created.
local captureSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CorePhysicalAdapter.lua"
)
T.contains(captureSource, "PNC_LiveShellToken",
    "live-shell token is not excluded from physical inventory capture")
T.contains(captureSource, "isLifecycleOnlyItem",
    "live-shell token capture filter missing")

local corpseIdentitySource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_CorpseItems_Identity.lua"
)
T.contains(corpseIdentitySource, "PNC_LiveShellToken",
    "death identity cleanup does not own live-shell token")

local materializeSource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_Presence/PNC_Presence_Materialize.lua"
)
T.contains(materializeSource, "EnsureLiveShellIdentityToken",
    "normal/rebound materialization does not stamp live-shell token")

local startupIdentitySource = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Presence/PNC_BodyLifecycle/PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_Identity.lua"
)
T.contains(startupIdentitySource, "GetLiveShellTokenNPCId",
    "startup identity does not consume exact live-shell token")

-- Functional startup proof: stripped zombie ModData/outfit identity can still
-- recover the exact durable NPC id from the engine-saved physical token.
PNC.Const = {
    PRESENCE_LIVE = "live",
    PRESENCE_CORPSE = "corpse",
}
PNC.BodyLifecycle.Internal.registry = function()
    return { LiveByID = {} }
end
T.load(ROOT
    .. "PNC_BodyLifecycle_Startup/PNC_BodyLifecycle_Startup_Identity.lua")
local startupId, startupStrong =
    PNC.BodyLifecycle.Internal.GetLiveShellIdentity(body)
T.equal(startupId, record.id,
    "startup identity did not recover npc id from live-shell token")
T.truthy(startupStrong,
    "live-shell token was not classified as strong startup identity")

return T.finish("pnc_live_shell_identity_token_smoke")
