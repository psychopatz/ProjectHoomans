-- Project Hoomans adapter for the provider-neutral Core actor-map hover.
-- Core owns the hover lifecycle and card; Hoomans contributes only its
-- learned-identity cache, request transport, and legacy portrait projection.

require "PNC/Knowledge/PNC_NPCIdentityPresentation"

local SurvivorWorldClient = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldClient"
local Hover = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldMapHover"

PNC = PNC or {}
local Identity = PNC.NPCIdentityPresentation

local function actorIDFor(entryOrID)
    local value = type(entryOrID) == "table"
        and (entryOrID.actorID or entryOrID.id or entryOrID.npcId)
        or entryOrID
    return tostring(value or "")
end

local function portraitSpec(entry)
    local portrait = entry and entry.portrait or nil
    if type(portrait) ~= "table" then return nil end
    if type(portrait.face) == "table" then
        return SurvivorWorldClient.GetPortraitSpec(entry)
    end
    return {
        id = actorIDFor(entry),
        identitySeed = portrait.identitySeed or 1,
        isFemale = portrait.isFemale == true,
        preferDescriptor = true,
        faceOnly = true,
        includeCurrentClothing = true,
        clothingMode = "current",
        appearance = portrait.appearance or {},
        equipment = portrait.equipment or { worn = {} },
    }
end

local function knowledge(entryOrID)
    local actorID = actorIDFor(entryOrID)
    local state = PNC.Network and PNC.Network.ClientState or nil
    local presentation = state and state.npcPresentations
        and state.npcPresentations[actorID] or nil
    local knownName = Identity
        and type(Identity.GetKnownName) == "function"
        and Identity.GetKnownName(actorID) or nil
    local faction = Identity
        and type(Identity.GetFaction) == "function"
        and Identity.GetFaction(actorID) or nil
    local factionName = Identity
        and type(Identity.GetFactionName) == "function"
        and Identity.GetFactionName(actorID) or nil
    local nameKnown = knownName ~= nil and knownName ~= ""
    return {
        -- The learned identity API is the authority. A stale presentation
        -- row can remain `unknown` while the name fact has already arrived.
        -- Do not make Core wait for another unrelated presentation refresh.
        state = nameKnown and "known"
            or presentation and presentation.state or "unknown",
        pending = not nameKnown and presentation
            and presentation.knowledgePending == true or false,
        nameKnown = nameKnown,
        knownName = knownName,
        factionKnown = faction ~= nil,
        factionID = faction and (faction.factionID or faction.id) or nil,
        factionName = factionName,
        revision = presentation
            and tonumber(presentation.knowledgeRevision) or 0,
    }
end

local function requestKnowledge(actorID)
    local client = PNC.Client
    if not client or type(client.RequestNPCKnowledge) ~= "function" then
        return false, "pnc_knowledge_unavailable"
    end
    return client.RequestNPCKnowledge(actorID)
end

local function context(entry)
    local presentation = PNC.FactionPresentation
        and type(PNC.FactionPresentation.Resolve) == "function"
        and PNC.FactionPresentation.Resolve(entry) or nil
    local faction = presentation or entry and entry.organizationalFaction
        or nil
    local knownName = Identity
        and type(Identity.GetKnownName) == "function"
        and Identity.GetKnownName(actorIDFor(entry)) or nil
    return {
        name = knownName or entry and (entry.name or entry.displayName),
        factionID = presentation and presentation.factionID
            or faction and (faction.factionID or faction.id),
        factionName = presentation and presentation.factionName
            or faction and (faction.name or faction.factionName),
        factionRole = presentation and presentation.factionRole
            or faction and (faction.role or faction.rank),
        factionPresentation = faction,
        presence = entry and entry.presenceState,
        provider = entry and entry.provider,
        providerState = entry and entry.providerState,
    }
end

local Adapter = {
    getPortraitSpec = portraitSpec,
    getContext = context,
    get = knowledge,
    request = requestKnowledge,
}

if SurvivorWorldClient
    and type(SurvivorWorldClient.RegisterActorKnowledgeProvider)
        == "function"
then
    SurvivorWorldClient.RegisterActorKnowledgeProvider(
        "ProjectHoomans", Adapter)
    -- DTHoomans projects the same Hoomans knowledge under its provider ID.
    SurvivorWorldClient.RegisterActorKnowledgeProvider(
        "DTHoomans", Adapter)
end

if Hover and type(Hover.RegisterProvider) == "function" then
    Hover.RegisterProvider("ProjectHoomans", Adapter)
end

return Adapter
