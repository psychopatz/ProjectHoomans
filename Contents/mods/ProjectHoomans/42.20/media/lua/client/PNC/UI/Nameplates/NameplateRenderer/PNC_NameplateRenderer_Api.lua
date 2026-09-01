local Renderer = PNC.NameplateRenderer
local Internal = Renderer.Internal
local Diagnostics = PNC.PerformanceScalingDiagnostics
local Presentation = PNC.NameplatePresentation
local Scopes = PNC.NameplateScopes
local scopeVisible = Internal.ScopeVisible
local drawPathGoal = Internal.DrawPathGoal
local drawCombatDebug = Renderer.RenderCombatDebug
local drawSeatingDebug = Renderer.RenderSeatingDebug
local drawCampResourceDebug = Renderer.RenderCampResourceDebug
local drawCampResourceHover = Renderer.DrawCampResourceHover
local drawDebugOnly = Internal.DrawDebugOnly
local drawLive = Internal.DrawLive

function Renderer.Render(manager, settings)
    if Diagnostics then
        Diagnostics.Increment("UI.NameplateRenderCalls")
    end
    if not settings.enabled or not manager.player then
        manager:clearStencilRect()
        return
    end

    local metrics = Presentation.ScaleFor(manager.playerIndex)
    local currentTime = getTimeInMillis()
    local campHover = settings.showCampDebug
        and { distance = nil, resource = nil } or nil
    local drawnCamps = {}
    if Diagnostics then
        local entryCount = 0
        for _, _ in pairs(manager.entries) do entryCount = entryCount + 1 end
        Diagnostics.Increment("UI.NameplateEntriesRendered", entryCount)
    end
    if settings.showPathDebug then
        for _, entry in pairs(manager.entries) do
            if not entry.debugOnly
                and scopeVisible(entry, Scopes.DEBUG, true)
            then
                drawPathGoal(manager, entry)
            end
        end
    end
    if settings.showCombatDebug then
        for _, entry in pairs(manager.entries) do
            if not entry.debugOnly
                and scopeVisible(entry, Scopes.DEBUG, true)
            then
                drawCombatDebug(manager, entry)
            end
        end
    end
    if settings.showAIDebug or settings.showCampDebug then
        for _, entry in pairs(manager.entries) do
            if not entry.debugOnly
                and scopeVisible(entry, Scopes.DEBUG, true)
            then
                drawSeatingDebug(manager, entry)
                if campHover then
                    drawCampResourceDebug(
                        manager, entry, campHover, drawnCamps)
                end
            end
        end
    end
    if campHover and campHover.resource then
        drawCampResourceHover(manager, campHover.resource)
    end
    for _, entry in pairs(manager.entries) do
        if entry.debugOnly then
            drawDebugOnly(manager, entry, metrics)
        else
            drawLive(manager, entry, metrics, currentTime, settings)
        end
    end
    manager:clearStencilRect()
end

return Renderer
