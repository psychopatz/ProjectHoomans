if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local loaded, reason = pcall(require,
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_DownedDistress_Inputs_Shared")
if not loaded then error(reason) end
