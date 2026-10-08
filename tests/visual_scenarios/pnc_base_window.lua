-- Invoked only by the disposable pz-headless client scenario bridge.
local Scenario = {}

function Scenario.run()
    if not PNC or not PNC.BaseUI then
        error("Project Hoomans BaseUI has not loaded")
    end
    if type(PNC.BaseUI.Open) ~= "function" then
        error("Project Hoomans BaseUI.Open is unavailable")
    end

    local window = PNC.BaseUI.Open()
    if not window or not window.javaObject then
        error("Project Hoomans BaseUI.Open did not return an instantiated window")
    end
    return window
end

return Scenario
