-- Project Hoomans adapter for the portable Core actor conversation service.
--
-- The adapter is deliberately a runtime projection.  Hoomans remains the
-- owner of its registry, identity disclosure, Knowledge authority, effects,
-- and presentation.  Core owns the conversation service and the router that
-- this module attaches to the existing Hoomans session.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Adapter = PNC.Semantics.ActorConversationService or {}
PNC.Semantics.ActorConversationService = Adapter

local loaded, CoreService = pcall(require,
    "PsychopatzCore/Conversation/PsychopatzActorConversationService")
if not loaded or type(CoreService) ~= "table"
    or type(CoreService.New) ~= "function"
then
    CoreService = nil
end

local function cleanID(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function sourceFor(view, npcID, context)
    local registry = PNC.Registry
    if registry and type(registry.Get) == "function" then
        local ok, record = pcall(registry.Get, npcID)
        if ok and type(record) == "table" then return record end
    end
    local entry = context and context.entry or nil
    if type(entry) == "table" then
        return entry.record or entry.snapshot or entry
    end
    return {}
end

local function actorFor(view)
    local spec = view and view.spec or {}
    local context = spec.context or {}
    local session = view and view.session or {}
    local npcID = cleanID(spec.npcID or context.npcID or session.npcID)
    if not npcID then return nil, "actor_id_required" end

    local source = sourceFor(view, npcID, context)
    local identity = source.identity
        or context.identity
        or {
            seed = source.identitySeed or context.identitySeed,
        }
    local social = source.social or {}
    return {
        actorId = npcID,
        id = npcID,
        identity = identity,
        persona = source.persona or context.persona,
        social = {
            personality = source.personality or social.personality
                or context.personality,
            relationships = source.relationships or social.relationships
                or context.relationships,
        },
        -- This is only a non-authoritative projection.  Core's GetKnowledge
        -- still requires server authority and Hoomans supplies its reader in
        -- the authority-owned integration boundary.
        knowledge = source.knowledge or context.knowledge,
    }, npcID
end

local function authority(context)
    if type(context) == "table" and context.authority ~= nil then
        return tostring(context.authority)
    end
    if type(isServer) == "function" and isServer() == true then
        return "server"
    end
    return "client"
end

function Adapter.IsAvailable()
    return CoreService ~= nil
end

function Adapter.Attach(view, router, options)
    options = type(options) == "table" and options or {}
    if not CoreService then return nil, "core_service_unavailable" end
    if type(view) ~= "table" or type(router) ~= "table" then
        return nil, "conversation_router_unavailable"
    end
    local session = view.session
    if type(session) ~= "table" then return nil, "conversation_unavailable" end

    local actor, npcID = actorFor(view)
    if not actor then return nil, npcID end

    local current = session.semanticActorConversationService
    if type(current) == "table"
        and tostring(current.actor and current.actor.actorId or "")
            == tostring(actor.actorId)
    then
        -- Refresh only the projection. The service's state/router and actor
        -- ID remain stable for the lifetime of this conversation session.
        current.actor.identity = actor.identity
        current.actor.persona = actor.persona
        current.actor.social = actor.social
        current.actor.knowledge = actor.knowledge
        current.router = router
        current.conversationID = session.conversationID
        return current
    end

    local context = type(options.context) == "table" and options.context
        or {}
    local service, reason = CoreService.New({
        actor = actor,
        router = router,
        state = router.state,
        policy = options.policy,
        parser = options.parser,
        candidateParser = options.candidateParser,
        candidateSelector = options.candidateSelector,
        contextResolver = options.contextResolver,
        context = context,
        authority = authority(context),
        conversationID = session.conversationID,
    })
    if not service then return nil, reason or "core_service_create_failed" end
    session.semanticActorConversationService = service
    return service
end

function Adapter.For(view)
    local session = view and view.session
    return session and session.semanticActorConversationService or nil
end

return Adapter
