-- Speech-act vocabulary shared by every semantic pattern family.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog concept module requires Catalog.Internal")
end

local registerSpeechAct = Internal.RegisterSpeechAct
local registerConcept = Internal.RegisterConcept
if type(registerConcept) ~= "function"
    or type(registerSpeechAct) ~= "function"
then
    error("semantic catalog concept module requires registration adapters")
end

function Internal.RegisterSpeechActs()
    registerSpeechAct("REQUEST")
    registerSpeechAct("OFFER")
    registerSpeechAct("ACCEPT")
    registerSpeechAct("REFUSE")
    registerSpeechAct("QUESTION")
    registerSpeechAct("ANSWER")
    registerSpeechAct("INFORM")
    registerSpeechAct("WARN")
    registerSpeechAct("GREET")
    registerSpeechAct("FAREWELL")
    registerSpeechAct("AGREE")
    registerSpeechAct("DISAGREE")
    registerSpeechAct("ACKNOWLEDGE")
    registerSpeechAct("APOLOGIZE")
    registerSpeechAct("THANK")
    registerSpeechAct("COMPLAIN")
    registerSpeechAct("THREATEN")
    registerSpeechAct("PROMISE")
    registerSpeechAct("ASK_FOR_CLARIFICATION")
    registerSpeechAct("CLARIFY")
    registerSpeechAct("GOSSIP")
end

return Internal
