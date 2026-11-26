-- Client-side scene-builder model for Puppet Opera.
--
-- This model owns only declarative draft data and UI selection state.  It
-- never moves an actor or starts an animation; playback remains in the
-- existing Puppet Opera transport and the proven Core/Hoomans adapters.

require "PNC/Debug/PNC_PlayerAnimationDebugCatalog"
require "PNC/Debug/PNC_AnimationDebugCatalog"

PNC = PNC or {}
PNC.ChoreographyDebugModel = PNC.ChoreographyDebugModel or {}

local Model = PNC.ChoreographyDebugModel
local Opera = PNC.Choreography
local Client = Opera and Opera.Client
local Blueprints = Opera and Opera.Blueprints
local Anchors = Opera and Opera.Anchors
local Capabilities = Opera and Opera.AnimationCapabilities
    or require "PNC/Core/Choreography/PNC_Choreography_AnimationCapabilities"
local PlayerCatalog = PNC.PlayerAnimationDebugCatalog or {}
local NPCCatalog = PNC.AnimationDebugCatalog or {}

Model.Internal = Model.Internal or {}
local Internal = Model.Internal
Internal.Opera = Opera
Internal.Client = Client
Internal.Blueprints = Blueprints
Internal.Anchors = Anchors
Internal.Capabilities = Capabilities
Internal.PlayerCatalog = PlayerCatalog
Internal.NPCCatalog = NPCCatalog

require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_State"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Refresh"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Drafts"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_LiveActors"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Runtime"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Beats"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Timeline"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Layout"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Catalogs"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Targets"
require "PNC/UI/Choreography/PNC_ChoreographyDebugModel_Animation"

return Model
