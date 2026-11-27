-- Scavenge policy request transport and client category helpers.
PNC = PNC or {}
PNC.Client = PNC.Client or {}

local Client = PNC.Client
local Const = PNC.Const
local Core = PNC.Core

local function ensureLocalPolicy()
    local state = PNC.Network and PNC.Network.ClientState
    if not state then
        local cats = PNC.WorldItemCategories
        return {
            enabled = true,
            categories = cats and cats.Defaults and cats.Defaults(false) or {},
            preferences = { containers = true, floorItems = true, corpses = true, allowStealing = false },
        }
    end
    if not state.scavengePolicy then
        local cats = PNC.WorldItemCategories
        state.scavengePolicy = {
            enabled = true,
            categories = cats and cats.Defaults and cats.Defaults(false) or {},
            preferences = { containers = true, floorItems = true, corpses = true, allowStealing = false },
        }
    end
    return state.scavengePolicy
end

function Client.SendScavengeRequest(action, payload)
    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    if not player then return false, "player_unavailable" end
    local args = Core.DeepCopy(payload or {})
    args.action = tostring(action or "")
    if Core.IsClientOnly and Core.IsClientOnly() then
        if not sendClientCommand then return false, "network_unavailable" end
        sendClientCommand(player, Const.MODULE, Const.CMD_SCAVENGE_REQUEST, args)
        return true, "request_sent"
    end
    local runtime = PNC.ScavengeRuntime
    if not runtime or type(runtime.HandleRequest) ~= "function" then
        return false, "scavenge_runtime_unavailable"
    end
    local ok, reason, snapshot = runtime.HandleRequest(player, args)
    if ok and snapshot and Client.Internal and Client.Internal.ApplyScavengeSnapshot then
        Client.Internal.ApplyScavengeSnapshot(snapshot)
    end
    return ok == true, reason, snapshot
end

function Client.GetScavengePolicy()
    local policy = ensureLocalPolicy()
    local state = PNC.Network and PNC.Network.ClientState
    if state and state.scavengePolicySynced ~= true and state.scavengePolicyRequested ~= true then
        state.scavengePolicyRequested = true
        pcall(Client.SendScavengeRequest, "request_policy", {})
    end
    return policy
end

function Client.SetScavengeEnabled(enabled)
    local policy = ensureLocalPolicy()
    policy.enabled = enabled == true
    return Client.SendScavengeRequest("set_enabled", { enabled = enabled == true })
end

function Client.SetNpcOpportunisticLoot(npcId, enabled)
    if npcId == nil or tostring(npcId) == "" then
        return false, "npc_id_required"
    end
    return Client.SendScavengeRequest("set_npc_loot_enabled", {
        npcId = tostring(npcId),
        enabled = enabled == true,
    })
end

function Client.SetScavengeCategory(categoryId, enabled)
    local policy = ensureLocalPolicy()
    local cats = PNC.WorldItemCategories
    local resolved = cats and cats.ResolveID and cats.ResolveID(categoryId)
        or string.lower(tostring(categoryId or ""))
    if resolved ~= "" then
        policy.categories = policy.categories or {}
        policy.categories[resolved] = enabled == true
    end
    return Client.SendScavengeRequest("set_category", {
        categoryId = resolved,
        enabled = enabled == true,
    })
end

function Client.SetScavengeCategories(categories)
    local policy = ensureLocalPolicy()
    local cats = PNC.WorldItemCategories
    policy.categories = cats and cats.NormalizeCategories
        and cats.NormalizeCategories(categories) or (type(categories) == "table" and categories or {})
    return Client.SendScavengeRequest("set_categories", { categories = policy.categories })
end

function Client.SetScavengePreferences(preferences)
    local policy = ensureLocalPolicy()
    if type(preferences) == "table" then
        policy.preferences = {
            containers = preferences.containers ~= false,
            floorItems = preferences.floorItems ~= false,
            corpses = preferences.corpses ~= false,
        }
    end
    return Client.SendScavengeRequest("set_preferences", { sourcePolicy = policy.preferences })
end

return PNC.Client
