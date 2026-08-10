--[[
    PNC Attack Execution
    Loads the committed-attack lifecycle in dependency order.
]]

PNC = PNC or {}
PNC.Combat = PNC.Combat or {}
PNC.Combat.Internal = PNC.Combat.Internal or {}

local Combat = PNC.Combat
local Internal = Combat.Internal

Internal.AttackExecution = Internal.AttackExecution or {}

require "PNC/Core/Combat/AttackExecution/PNC_AttackExecution_Targeting"
require "PNC/Core/Combat/AttackExecution/PNC_AttackExecution_Lifecycle"
require "PNC/Core/Combat/AttackExecution/PNC_AttackExecution_Damage"
require "PNC/Core/Combat/AttackExecution/PNC_AttackExecution_HitResolution"
require "PNC/Core/Combat/AttackExecution/PNC_AttackExecution_Pump"

return Combat
