-- Projection exports for the semantic conversation façade.

local Projection = {}
local Block = require "worker/Conversation_BlockProjection"
local Graph = require "worker/Conversation_GraphProjection"
local View = require "worker/Conversation_View"
local Snapshot = require "worker/Conversation_Snapshot"

Projection.blockProjection = Block.project
Projection.graphProjection = Graph.project
Projection.buildView = View.build
Projection.relationshipSnapshot = Snapshot.relationship
Projection.contextSnapshot = Snapshot.context

return Projection
