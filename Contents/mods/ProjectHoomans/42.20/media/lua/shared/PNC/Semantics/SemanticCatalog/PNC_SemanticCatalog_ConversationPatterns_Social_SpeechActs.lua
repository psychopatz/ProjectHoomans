-- Social acknowledgement and speech-act pattern registration.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Catalog = PNC.Semantics.Catalog
local Internal = Catalog and Catalog.Internal
if type(Internal) ~= "table" then
    error("semantic catalog social module requires Catalog.Internal")
end

local registerPattern = Internal.RegisterPattern
if type(registerPattern) ~= "function" then
    error("semantic catalog social module requires RegisterPattern")
end

function Internal.RegisterSocialSpeechActs()
    registerPattern(
        "pnc.social.thank",
        { "@THANK" },
        { intent = "THANK", speechAct = "THANK" },
        0.96,
        70
    )

    registerPattern(
        "pnc.social.apologize",
        { "@APOLOGIZE" },
        { intent = "APOLOGIZE", speechAct = "APOLOGIZE" },
        0.96,
        70
    )

    registerPattern(
        "pnc.social.accept",
        { "@ACCEPT" },
        { intent = "ACCEPT", speechAct = "ACCEPT" },
        0.94,
        70
    )

    registerPattern(
        "pnc.social.refuse",
        { "@REFUSE" },
        { intent = "REFUSE", speechAct = "REFUSE" },
        0.94,
        70
    )

    registerPattern(
        "pnc.social.agree",
        { "@AGREE" },
        { intent = "AGREE", speechAct = "AGREE" },
        0.94,
        71
    )

    registerPattern(
        "pnc.social.acknowledge",
        { "@ACKNOWLEDGE" },
        { intent = "ACKNOWLEDGE", speechAct = "ACKNOWLEDGE" },
        0.96,
        72
    )

    registerPattern(
        "pnc.social.disagree",
        { "@DISAGREE" },
        { intent = "DISAGREE", speechAct = "DISAGREE" },
        0.94,
        71
    )

    registerPattern(
        "pnc.social.greet",
        { "@GREET" },
        { intent = "GREET", speechAct = "GREET" },
        0.97,
        75
    )
end

return Internal
