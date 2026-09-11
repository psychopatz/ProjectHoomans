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

local function voiced(_, text)
    return { text = text, speakerRole = "primary" }
end

local function reply(context, text)
    if context.hasSecondSpeaker ~= true then return nil end
    return { text = text, speakerRole = "secondary" }
end

local function introduction(context)
    if not context.identityIntroduced then return nil end
    return voiced(context, "My name is {npcFullName}. I speak for {factionName}.")
end

local function addressPlayer(context)
    if context.playerNameKnown == true then
        return voiced(context,
            "{playerFirstName}, if that is you listening, please answer.")
    end
    return voiced(context, "If that is you listening, please answer.")
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
        voiced(context, "Mayday, mayday. Is anyone still listening?"),
        reply(context, "Tell them about the wounded. The fever is getting worse."),
        voiced(context, "We're moving near {location}. We need medicine and food."),
        introduction(context),
        addressPlayer(context),
        "<fzzt>"
    ) end,
    function(context) return lines(
        "<bzzt>",
        voiced(context, "This is a civilian group. Families, not soldiers."),
        reply(context, "Battery is nearly gone. Keep the call short."),
        voiced(context, "We are close to {location}. We need somewhere safe."),
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
        voiced(context, "Any survivors out there, we have food and a safe roof."),
        reply(context, "Tell them to come alone. Crowds draw the dead."),
        voiced(context, "Come to {location}. We will be waiting."),
        introduction(context),
        "<wzzt>"
    ) end,
    function(context) return lines(
        voiced(context, "Attention travelers. Free supplies near {location}."),
        reply(context, "Yeah, free. Just signal twice when you're close."),
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
        voiced(context, "Caravan calling on the open band."),
        reply(context, "We still have batteries, tools, and two crates of cans."),
        voiced(context, "We are passing {location}. Keep weapons lowered and we can trade."),
        introduction(context)
    ) end,
    function(context) return lines(
        voiced(context, "Traveling merchants near {location}."),
        reply(context, "Ask for medicine, fuel, and clean water."),
        voiced(context, "No trouble wanted. Fair trades only."),
        introduction(context),
        "<fzzt>"
    ) end,
})

pack("settlement", 50, function(context)
    return context.kind == Types.KIND_SETTLEMENT
end, {
    function(context) return lines(
        "<wzzt>",
        voiced(context, "This is an enclave broadcasting on an open band."),
        reply(context, "North watch is clear. Keep the gate shut anyway."),
        voiced(context, "Our perimeter is near {location}. Approach slowly, weapons down."),
        introduction(context),
        voiced(context, "Identify yourself before coming close.")
    ) end,
    function(context) return lines(
        voiced(context, "Mayday relay to anyone passing through {location}."),
        reply(context, "The generator is holding. We can keep transmitting."),
        voiced(context, "People are alive here. Announce yourself on approach."),
        introduction(context),
        "<bzzt>"
    ) end,
})

pack("mobile", 0, function(context)
    return context.kind == Types.KIND_MOBILE_GROUP
end, {
    function(context) return lines(
        "<fzzt>",
        voiced(context, "Unknown group calling from around {location}."),
        reply(context, "We need to move before dark."),
        voiced(context, "We will not stay long. Respond if you hear this."),
        introduction(context)
    ) end,
})

pack("ambient_open_band", 20, function(context)
    return context.eventType == "ambient"
        and context.ambientVariant == "open_band"
end, {
    function(context) return lines(
        "<fzzt>",
        voiced(context, "...copy that... no, start again."),
        voiced(context, "If anyone is awake, keep the channel clear."),
        "<wzzt>"
    ) end,
    function(context) return lines(
        "<bzzt>",
        voiced(context, "Static on the line. Thought I heard somebody."),
        voiced(context, "Never mind. Just the wind and a bad connection."),
        "<fzzt>"
    ) end,
    function(context) return lines(
        voiced(context, "Check, check... still transmitting."),
        voiced(context, "No response. Leave it open for another minute."),
        "<wzzt>"
    ) end,
    function(context) return lines(
        "<wzzt>",
        voiced(context, "The last one was garbled. Send it slow."),
        voiced(context, "I said slow. Forget it, just listen for the tone."),
        "<bzzt>"
    ) end,
}, "ambient")

pack("ambient_cross_talk", 20, function(context)
    return context.eventType == "ambient"
        and context.ambientVariant == "cross_talk"
end, {
    function(context) return lines(
        "<fzzt>",
        voiced(context, "Did you mark the channel?"),
        reply(context, "Which channel? No, say that again."),
        voiced(context, "Never mind. I can barely hear you."),
        "<wzzt>"
    ) end,
    function(context) return lines(
        voiced(context, "Tell the west side to hold."),
        reply(context, "The west side of what?"),
        voiced(context, "Exactly. That is why I said hold."),
        "<bzzt>"
    ) end,
    function(context) return lines(
        "<wzzt>",
        voiced(context, "You are breaking up around the—"),
        reply(context, "Around the what?"),
        voiced(context, "The thing. The big thing. Just stay put."),
        "<fzzt>"
    ) end,
    function(context) return lines(
        voiced(context, "Read that back to me."),
        reply(context, "I did. You were not listening."),
        voiced(context, "I am listening. The radio is not."),
        "<bzzt>"
    ) end,
}, "ambient")

return PNC.WorldDiscovery
