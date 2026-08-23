-- Single-player and exceptional fallback embodied movement.

PNC = PNC or {}
PNC.FakeLocomotion = PNC.FakeLocomotion or {}
PNC.FakeLocomotion.Internal = PNC.FakeLocomotion.Internal or {}

require "PNC/Core/Pathing/PNC_FakeLocomotion/PNC_FakeLocomotion_Profiles"
require "PNC/Core/Pathing/PNC_FakeLocomotion/PNC_FakeLocomotion_Steering"
require "PNC/Core/Pathing/PNC_FakeLocomotion/PNC_FakeLocomotion_Body"
require "PNC/Core/Pathing/PNC_FakeLocomotion/PNC_FakeLocomotion_Candidate"
require "PNC/Core/Pathing/PNC_FakeLocomotion/PNC_FakeLocomotion_Step"

return PNC.FakeLocomotion
