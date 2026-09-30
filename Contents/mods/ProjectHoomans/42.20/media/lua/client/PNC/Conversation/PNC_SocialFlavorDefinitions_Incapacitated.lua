--[[
    Authored incapacitated-state flavor -- load-order barrel.

    The matrix is split into a shared helper header plus one file per flavor
    id so each stays small enough to read and review as a unit.  Order matters:
    Shared defines `cell`/`line`, then the call and update registrations run.
]]

require "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Shared"
require "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Call"
require "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Update"
require "PNC/Conversation/PNC_SocialFlavorDefinitions_Incapacitated_Repeat"

return PNC.SocialFlavorDefinitions.Incapacitated
