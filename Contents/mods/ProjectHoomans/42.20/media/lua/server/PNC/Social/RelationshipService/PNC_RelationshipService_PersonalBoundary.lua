if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Relationships = PNC.Relationships or {}
PNC.Relationships.Internal = PNC.Relationships.Internal or {}

local Relationships = PNC.Relationships

-- Canonical directed personal-relationship boundary. Direct methods above are
-- retained for compatibility with existing callers and extension code.
Relationships.Personal = Relationships.Personal or {}
Relationships.Personal.Queries = Relationships.Personal.Queries or {}
Relationships.Personal.Commands = Relationships.Personal.Commands or {}

local PersonalQueries = Relationships.Personal.Queries
PersonalQueries.Get = Relationships.Get
PersonalQueries.GetApproval = Relationships.GetApproval
PersonalQueries.GetRespect = Relationships.GetRespect
PersonalQueries.GetFamiliarity = Relationships.GetFamiliarity
PersonalQueries.GetState = Relationships.GetState

local PersonalCommands = Relationships.Personal.Commands
PersonalCommands.GetOrCreate = Relationships.GetOrCreate
PersonalCommands.SetInitialBaseline = Relationships.SetInitialBaseline
PersonalCommands.SetDebugBaseline = Relationships.SetDebugBaseline
PersonalCommands.AddMemory = Relationships.AddMemory
PersonalCommands.ApplyEventMutation = Relationships.ApplyEventMutation
PersonalCommands.ApplyConversationEffect = Relationships.ApplyConversationEffect
PersonalCommands.RecordInteraction = Relationships.RecordInteraction
PersonalCommands.RemoveMemory = Relationships.RemoveMemory
PersonalCommands.Recalculate = Relationships.Recalculate
PersonalCommands.PruneMemories = Relationships.PruneMemories
