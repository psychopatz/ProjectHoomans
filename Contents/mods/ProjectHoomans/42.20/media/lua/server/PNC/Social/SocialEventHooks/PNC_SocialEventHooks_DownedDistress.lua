-- Downed-distress hook composition root.
-- Shared listener state loads before resolver inputs and bounded delivery hooks.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.SocialEventHooks = PNC.SocialEventHooks or {}
PNC.SocialEventHooksInternal = PNC.SocialEventHooksInternal or {}

local function loadProvider(moduleName)
    local loaded, reason = pcall(require, moduleName)
    if not loaded then error(reason) end
end

loadProvider(
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DownedDistress_Core_Shared"
)
loadProvider(
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DownedDistress_Inputs_Shared"
)
loadProvider(
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DownedDistress_Public_Shared"
)

return PNC.SocialEventHooks
