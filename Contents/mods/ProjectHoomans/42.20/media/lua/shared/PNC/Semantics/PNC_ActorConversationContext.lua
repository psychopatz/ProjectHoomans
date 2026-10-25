-- Stable actor conversation context entry point.
-- Keep the public Context object and Build/PublicView APIs unchanged.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Context = PNC.Semantics.ActorConversationContext or {}
PNC.Semantics.ActorConversationContext = Context

local RelationshipConstants = PNC.RelationshipConstants
    or require "PNC/Core/Relationships/PNC_RelationshipConstants"
local RelationshipStates = PNC.RelationshipStates
    or require "PNC/Core/Relationships/PNC_RelationshipStates"
local RelationshipKinds = PNC.RelationshipKinds
    or require "PNC/Core/Relationships/PNC_RelationshipKindRegistry"

Context.VERSION = 1
Context.SCHEMA = "actor.conversation.context.v1"
Context.MAX_TRAITS = 32
Context.MAX_CAPABILITIES = 24

local Core = require
    "PNC/Semantics/PNC_ActorConversationContext_Core"
local Projections = require
    "PNC/Semantics/PNC_ActorConversationContext_Projections"
local installBuild = require
    "PNC/Semantics/PNC_ActorConversationContext_Build"
local installPublicView = require
    "PNC/Semantics/PNC_ActorConversationContext_Public"

Projections = Projections(
    Core,
    Context,
    RelationshipConstants,
    RelationshipStates,
    RelationshipKinds
)
installBuild(Context, Core, Projections)
installPublicView(Context, Core)

return Context
