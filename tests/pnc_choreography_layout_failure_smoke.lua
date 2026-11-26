local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
})

PNC = {
    Core = {
        Now = function() return 1000 end,
    },
    Choreography = {
        Client = {
            GetNearbyNPCs = function() return {} end,
            GetSnapshot = function() return nil end,
            GetTrace = function() return {} end,
            GetStatus = function() return "idle", nil end,
        },
    },
}

T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Choreography/PNC_Choreography_Blueprints.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Choreography/PNC_Choreography_Anchors.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Choreography/PNC_Choreography_Trace.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Choreography/PNC_Choreography.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/UI/Choreography/PNC_ChoreographyDebugModel.lua"
)

local Model = PNC.ChoreographyDebugModel
local draft = Model.GetDraft()
local definition = draft and draft.actors and draft.actors.actor_2
local anchor = definition and draft.anchorFrame
    and draft.anchorFrame.anchors[definition.anchor] or nil
T.truthy(anchor, "failure test could not resolve the NPC anchor")

local freeLiveNPC = {
    id = "npc-bind-failure",
    name = "NPC Bind Failure",
    distSq = 1,
    zombie = {},
    record = {},
}
PNC.Choreography.Client.GetNearbyNPCs = function()
    return { freeLiveNPC }
end

local targetRight
for candidate = -8, 8 do
    if not Model.GetActorAtOffset(candidate, anchor.forward) then
        targetRight = candidate
        break
    end
end
T.truthy(targetRight ~= nil,
    "failure test could not find a free anchor coordinate")

local oldRight = anchor.right
local oldForward = anchor.forward
local oldZ = anchor.z
local beforeSerial = Model.GetChangeSerial()
local originalBind = Model.BindLiveActor
Model.BindLiveActor = function()
    return false, "simulated_bind_failure"
end
local accepted, reason = Model.AddLiveActorToScene(
    freeLiveNPC.id,
    targetRight,
    anchor.forward,
    anchor.z,
    "actor_2"
)
Model.BindLiveActor = originalBind

T.falsy(accepted, "a rejected bind was reported as accepted")
T.equal(reason, "simulated_bind_failure",
    "the bind failure reason was not preserved")
T.equal(anchor.right, oldRight,
    "a failed bind left the actor anchor partially moved")
T.equal(anchor.forward, oldForward,
    "a failed bind changed the actor forward offset")
T.equal(anchor.z, oldZ,
    "a failed bind changed the actor height offset")
T.falsy(Model.GetActorBinding("actor_2"),
    "a failed bind left a scene binding behind")
T.equal(Model.GetChangeSerial(), beforeSerial,
    "a failed bind changed the draft serial")

return T.finish("pnc_choreography_layout_failure_smoke")
