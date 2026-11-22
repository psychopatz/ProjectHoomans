local Effects = PNC and PNC.ClientFirearmEffects
if not Effects then return end

function Effects.Reset()
    Effects.ActiveLights = {}
    Effects.ActiveTracers = {}
    Effects.ActiveMuzzleFlashes = {}
    Effects.SeenShots = {}
    Effects.SeenShotCount = 0
    Effects.LastSeenShotsPruneAt = 0
    Effects.DrawAuditState = {}
    Effects.DebugSimulation = nil
    Effects.LightWindowAt = 0
    Effects.LightsInWindow = 0
end
