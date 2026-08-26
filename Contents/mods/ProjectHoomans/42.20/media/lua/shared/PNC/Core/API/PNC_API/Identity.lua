-- Versioned, read-only identity API for UI, integrations, and future LLM
-- adapters. It exposes factionID-based facts without returning live records.

PNC = PNC or {}
PNC.API = PNC.API or {}
PNC.API.Identity = PNC.API.Identity or {}

local API = PNC.API.Identity
local Verifier = PNC.Identity and PNC.Identity.Verifier
local Registry = PNC.Registry

function API.GetVersion()
    return Verifier and Verifier.API_VERSION or 1
end

function API.GetCapabilities()
    return {
        apiVersion = API.GetVersion(),
        schemaVersion = Verifier and Verifier.SCHEMA_VERSION or 1,
        factionAuthority = "factionID",
        multiPlayerFaction = true,
        characterScopedOwnership = true,
        viewerFactionResolution = true,
        ownershipResolution = true,
        publicView = true,
        payloadVerification = true,
    }
end

local function sourceFor(npcID)
    local id = tostring(npcID or "")
    local record = Registry and Registry.Get and Registry.Get(id) or nil
    if record then return record end
    local state = PNC.Network and PNC.Network.ClientState or nil
    return state and state.snapshots and state.snapshots[id] or nil
end

function API.Get(npcID, options)
    local source = sourceFor(npcID)
    if not source or not Verifier then return nil, "npc_not_found" end
    return Verifier.BuildView(source, options)
end

function API.GetForSource(source, options)
    if not Verifier or type(source) ~= "table" then
        return nil, "invalid_source"
    end
    return Verifier.BuildView(source, options)
end

function API.Verify(npcID, options)
    local source = sourceFor(npcID)
    if not source or not Verifier then
        return nil, "npc_not_found"
    end
    return Verifier.Verify(source, options)
end

function API.VerifyPayload(payload, options)
    if not Verifier then return nil, "verifier_unavailable" end
    return Verifier.VerifyPayload(payload, options)
end

function API.GetPlayerFactionID(player)
    if not Verifier then return nil, "verifier_unavailable" end
    return Verifier.GetPlayerFactionID(player)
end

function API.ResolveOwnership(npcID, player)
    local source = sourceFor(npcID)
    if not source or not Verifier then
        return false, "npc_not_found"
    end
    return Verifier.ResolveOwnership(source, player)
end

function API.IsOwnedByPlayer(npcID, player)
    local owned = API.ResolveOwnership(npcID, player)
    return owned == true
end

return API
