if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.PopulationDirector = PNC.PopulationDirector or {}
PNC.PopulationDirector.Internal =
    PNC.PopulationDirector.Internal or {}

local Director = PNC.PopulationDirector
local Internal = Director.Internal
local context = Internal.context

local function reconcile(kind, now, budget, forceDry)
    if Director.Paused or PNC.WorldDirector and PNC.WorldDirector.Paused then return 0 end
    local ctx = context(now)
    if not ctx.resolved.enabled then
        return 0
    end
    local dry
    if forceDry ~= nil then
        dry = forceDry == true
    else
        dry = now < Director.StartupGraceUntil
        if not dry and Director.DryRunPending[kind] then
            dry = true
            Director.DryRunPending[kind] = false
        end
    end
    return PNC.PopulationReconciler.Run(kind, now, budget, ctx, dry)
end

Internal.reconcile = reconcile
