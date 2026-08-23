--[[
    PNC Perception
    Stable entry point for target history, visibility, hostile scanning, and
    high-level target resolution providers.
]]

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

require "PNC/Core/Perception/PNC_Perception/ThreatHistory"
require "PNC/Core/Perception/PNC_Perception/Visibility"
require "PNC/Core/Perception/PNC_Perception/ActorSearch"
require "PNC/Core/Perception/PNC_Perception/ZombieSearch"
require "PNC/Core/Perception/PNC_Perception/ImmediateEnemy"
require "PNC/Core/Perception/PNC_Perception/ImmediateThreat"
require "PNC/Core/Perception/PNC_Perception/ZombieRanking"
require "PNC/Core/Perception/PNC_Perception/OwnerDefense"
require "PNC/Core/Perception/PNC_Perception/Resolvers"
