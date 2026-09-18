-- Client-side scene-builder model for Puppet Opera.
--
-- This model owns only declarative draft data and UI selection state.  It
-- never moves an actor or starts an animation; playback remains in the
-- existing Puppet Opera transport and the proven Core/Hoomans adapters.

require "PNC/Debug/PNC_PlayerAnimationDebugCatalog"
require "PNC/Debug/PNC_AnimationDebugCatalog"

PNC = PNC or {}
PNC.PuppetOperaDebugModel = PNC.PuppetOperaDebugModel or {}

local Model = PNC.PuppetOperaDebugModel
local Opera = PNC.PuppetOpera
local Client = Opera and Opera.Client
local Blueprints = Opera and Opera.Blueprints
local Anchors = Opera and Opera.Anchors
local Capabilities = Opera and Opera.AnimationCapabilities
    or require "PNC/Core/PuppetOpera/PNC_PuppetOpera_AnimationCapabilities"
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

require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_State"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Refresh"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Drafts"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_LiveActors"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Runtime"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Beats"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Layout"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Catalogs"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Targets"
require "PNC/UI/PuppetOpera/PNC_PuppetOperaDebugModel_Animation"

return Model
