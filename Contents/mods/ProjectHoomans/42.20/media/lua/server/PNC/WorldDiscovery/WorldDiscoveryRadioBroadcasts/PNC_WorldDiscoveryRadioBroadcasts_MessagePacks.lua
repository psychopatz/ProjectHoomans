if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Types = PNC.WorldDiscoveryTypes
local Channel = PNC.RadioDiscoveryChannel
local Radio = PsychopatzCore.CustomRadio

local function pack(id, priority, matches, messages, eventType)
    Radio.RegisterMessagePack("projecthoomans." .. id, {
        channel = Channel.ID,
        eventType = eventType or "discovery",
        priority = priority,
        matches = matches,
        messages = messages,
    })
end

local function voiced(_, key, fallback)
    return {
        textKey = key,
        textFallback = fallback,
        textSource = "ProjectHoomans",
        speakerRole = "primary",
    }
end

local function reply(context, key, fallback)
    if context.hasSecondSpeaker ~= true then return nil end
    return {
        textKey = key,
        textFallback = fallback,
        textSource = "ProjectHoomans",
        speakerRole = "secondary",
    }
end

local function introduction(context)
    if not context.identityIntroduced then return nil end
    return voiced(context, "UI_PNC_Discovery_Radio_Introduction",
        "My name is {npcFullName}. I speak for {factionName}.")
end

local function addressPlayer(context)
    if context.playerNameKnown == true then
        return voiced(context, "UI_PNC_Discovery_Radio_AddressNamed",
            "{playerFirstName}, if that is you listening, please answer.")
    end
    return voiced(context, "UI_PNC_Discovery_Radio_AddressUnknown",
        "If that is you listening, please answer.")
end

local function lines(...)
    local output = {}
    for index = 1, select("#", ...) do
        local value = select(index, ...)
        if value then output[#output + 1] = value end
    end
    return { lines = output }
end

pack("refugee", 100, function(context)
    return context.groupType == "REFUGEE"
        or context.archetypeID == "refugee"
end, {
    function(context) return lines(
        "<wzzt>",
        voiced(context, "UI_PNC_Discovery_Radio_RefugeeMayday",
            "Mayday, mayday. Is anyone still listening?"),
        reply(context, "UI_PNC_Discovery_Radio_RefugeeWounded",
            "Tell them about the wounded. The fever is getting worse."),
        voiced(context, "UI_PNC_Discovery_Radio_RefugeeMovingNear",
            "We're moving near {location}. We need medicine and food."),
        introduction(context),
        addressPlayer(context),
        "<fzzt>"
    ) end,
    function(context) return lines(
        "<bzzt>",
        voiced(context, "UI_PNC_Discovery_Radio_RefugeeCivilian",
            "This is a civilian group. Families, not soldiers."),
        reply(context, "UI_PNC_Discovery_Radio_RefugeeBattery",
            "Battery is nearly gone. Keep the call short."),
        voiced(context, "UI_PNC_Discovery_Radio_RefugeeClose",
            "We are close to {location}. We need somewhere safe."),
        introduction(context),
        "<fzzt>"
    ) end,
})

pack("looter", 100, function(context)
    return context.groupType == "LOOTER"
        or context.archetypeID == "looter"
end, {
    function(context) return lines(
        "<bzzt>",
        voiced(context, "UI_PNC_Discovery_Radio_LooterSurvivors",
            "Any survivors out there, we have food and a safe roof."),
        reply(context, "UI_PNC_Discovery_Radio_LooterComeAlone",
            "Tell them to come alone. Crowds draw the dead."),
        voiced(context, "UI_PNC_Discovery_Radio_LooterComeTo",
            "Come to {location}. We will be waiting."),
        introduction(context),
        "<wzzt>"
    ) end,
    function(context) return lines(
        voiced(context, "UI_PNC_Discovery_Radio_LooterAttention",
            "Attention travelers. Free supplies near {location}."),
        reply(context, "UI_PNC_Discovery_Radio_LooterSignalTwice",
            "Yeah, free. Just signal twice when you're close."),
        introduction(context),
        "<fzzt>"
    ) end,
})

pack("trader", 100, function(context)
    return context.groupType == "TRADER"
        or context.archetypeID == "trader"
end, {
    function(context) return lines(
        "<bzzt>",
        voiced(context, "UI_PNC_Discovery_Radio_TraderCaravan",
            "Caravan calling on the open band."),
        reply(context, "UI_PNC_Discovery_Radio_TraderSupplies",
            "We still have batteries, tools, and two crates of cans."),
        voiced(context, "UI_PNC_Discovery_Radio_TraderPassing",
            "We are passing {location}. Keep weapons lowered and we can trade."),
        introduction(context)
    ) end,
    function(context) return lines(
        voiced(context, "UI_PNC_Discovery_Radio_TraderMerchants",
            "Traveling merchants near {location}."),
        reply(context, "UI_PNC_Discovery_Radio_TraderAskSupplies",
            "Ask for medicine, fuel, and clean water."),
        voiced(context, "UI_PNC_Discovery_Radio_TraderNoTrouble",
            "No trouble wanted. Fair trades only."),
        introduction(context),
        "<fzzt>"
    ) end,
})

pack("settlement", 50, function(context)
    return context.kind == Types.KIND_SETTLEMENT
end, {
    function(context) return lines(
        "<wzzt>",
        voiced(context, "UI_PNC_Discovery_Radio_SettlementEnclave",
            "This is an enclave broadcasting on an open band."),
        reply(context, "UI_PNC_Discovery_Radio_SettlementNorthWatch",
            "North watch is clear. Keep the gate shut anyway."),
        voiced(context, "UI_PNC_Discovery_Radio_SettlementPerimeter",
            "Our perimeter is near {location}. Approach slowly, weapons down."),
        introduction(context),
        voiced(context, "UI_PNC_Discovery_Radio_SettlementIdentify",
            "Identify yourself before coming close.")
    ) end,
    function(context) return lines(
        voiced(context, "UI_PNC_Discovery_Radio_SettlementMaydayRelay",
            "Mayday relay to anyone passing through {location}."),
        reply(context, "UI_PNC_Discovery_Radio_SettlementGenerator",
            "The generator is holding. We can keep transmitting."),
        voiced(context, "UI_PNC_Discovery_Radio_SettlementPeopleAlive",
            "People are alive here. Announce yourself on approach."),
        introduction(context),
        "<bzzt>"
    ) end,
})

pack("mobile", 0, function(context)
    return context.kind == Types.KIND_MOBILE_GROUP
end, {
    function(context) return lines(
        "<fzzt>",
        voiced(context, "UI_PNC_Discovery_Radio_MobileUnknownGroup",
            "Unknown group calling from around {location}."),
        reply(context, "UI_PNC_Discovery_Radio_MobileMove",
            "We need to move before dark."),
        voiced(context, "UI_PNC_Discovery_Radio_MobileNotStay",
            "We will not stay long. Respond if you hear this."),
        introduction(context)
    ) end,
})

pack("ambient_open_band", 20, function(context)
    return context.eventType == "ambient"
        and context.ambientVariant == "open_band"
end, {
    function(context) return lines(
        "<fzzt>",
        voiced(context, "UI_PNC_Discovery_Radio_AmbientCopy",
            "...copy that... no, start again."),
        voiced(context, "UI_PNC_Discovery_Radio_AmbientClearChannel",
            "If anyone is awake, keep the channel clear."),
        "<wzzt>"
    ) end,
    function(context) return lines(
        "<bzzt>",
        voiced(context, "UI_PNC_Discovery_Radio_AmbientStatic",
            "Static on the line. Thought I heard somebody."),
        voiced(context, "UI_PNC_Discovery_Radio_AmbientWind",
            "Never mind. Just the wind and a bad connection."),
        "<fzzt>"
    ) end,
    function(context) return lines(
        voiced(context, "UI_PNC_Discovery_Radio_AmbientCheck",
            "Check, check... still transmitting."),
        voiced(context, "UI_PNC_Discovery_Radio_AmbientNoResponse",
            "No response. Leave it open for another minute."),
        "<wzzt>"
    ) end,
    function(context) return lines(
        "<wzzt>",
        voiced(context, "UI_PNC_Discovery_Radio_AmbientGarbled",
            "The last one was garbled. Send it slow."),
        voiced(context, "UI_PNC_Discovery_Radio_AmbientSendSlow",
            "I said slow. Forget it, just listen for the tone."),
        "<bzzt>"
    ) end,
}, "ambient")

pack("ambient_cross_talk", 20, function(context)
    return context.eventType == "ambient"
        and context.ambientVariant == "cross_talk"
end, {
    function(context) return lines(
        "<fzzt>",
        voiced(context, "UI_PNC_Discovery_Radio_AmbientMarkChannel",
            "Did you mark the channel?"),
        reply(context, "UI_PNC_Discovery_Radio_AmbientWhichChannel",
            "Which channel? No, say that again."),
        voiced(context, "UI_PNC_Discovery_Radio_AmbientBarelyHear",
            "Never mind. I can barely hear you."),
        "<wzzt>"
    ) end,
    function(context) return lines(
        voiced(context, "UI_PNC_Discovery_Radio_AmbientWestHold",
            "Tell the west side to hold."),
        reply(context, "UI_PNC_Discovery_Radio_AmbientWestWhat",
            "The west side of what?"),
        voiced(context, "UI_PNC_Discovery_Radio_AmbientExactly",
            "Exactly. That is why I said hold."),
        "<bzzt>"
    ) end,
    function(context) return lines(
        "<wzzt>",
        voiced(context, "UI_PNC_Discovery_Radio_AmbientBreaking",
            "You are breaking up around the—"),
        reply(context, "UI_PNC_Discovery_Radio_AmbientAroundWhat",
            "Around the what?"),
        voiced(context, "UI_PNC_Discovery_Radio_AmbientThing",
            "The thing. The big thing. Just stay put."),
        "<fzzt>"
    ) end,
    function(context) return lines(
        voiced(context, "UI_PNC_Discovery_Radio_AmbientReadBack",
            "Read that back to me."),
        reply(context, "UI_PNC_Discovery_Radio_AmbientNotListening",
            "I did. You were not listening."),
        voiced(context, "UI_PNC_Discovery_Radio_AmbientRadioNot",
            "I am listening. The radio is not."),
        "<bzzt>"
    ) end,
}, "ambient")

return PNC.WorldDiscovery
