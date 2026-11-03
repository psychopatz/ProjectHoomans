if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then
    return
end

require "PNC/Director/SurvivorWorldExtensions/PNC_SurvivorWorldExtensions_Core"
require "PNC/Director/SurvivorWorldExtensions/PNC_SurvivorWorldExtensions_Factions"
require "PNC/Director/SurvivorWorldExtensions/PNC_SurvivorWorldExtensions_Communities"
require "PNC/Director/SurvivorWorldExtensions/PNC_SurvivorWorldExtensions_Abstract"
return require
    "PNC/Director/SurvivorWorldExtensions/PNC_SurvivorWorldExtensions_Cutover"
