-- Generated; do not edit by hand.
return {
    {
        ["domain"] = "world_event_beats",
        ["domainPath"] = "world_event_beats",
        ["exchangeFamily"] = {
            ["familyID"] = "world.beats.events",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Shit, an alarm! {addressee.name}, every deadhead in blocks is gonna hear that!",
                                ["id"] = "house_alarm_open",
                                ["templateID"] = "convo.world.beats.events.say.1.house_alarm_open",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "I hear it, {addressee.name}. Weapons up and keep moving away from that noise.",
                                ["id"] = "house_alarm_reply",
                                ["templateID"] = "convo.world.beats.events.say.1.house_alarm_reply",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Did everything just go dark? Looks like the power grid finally died today, {addressee.name}.",
                                ["id"] = "power_shutoff_open",
                                ["templateID"] = "convo.world.beats.events.say.1.power_shutoff_open",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Yeah, {addressee.name}, no more free electricity. Watch the spoilage and stock fuel.",
                                ["id"] = "power_shutoff_reply",
                                ["templateID"] = "convo.world.beats.events.say.1.power_shutoff_reply",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Pipes just ran dry today, {addressee.name}. Water system finally quit on us.",
                                ["id"] = "water_shutoff_open",
                                ["templateID"] = "convo.world.beats.events.say.1.water_shutoff_open",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Got it, {addressee.name}. Rain collectors and pots are top priority now.",
                                ["id"] = "water_shutoff_reply",
                                ["templateID"] = "convo.world.beats.events.say.1.water_shutoff_reply",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "world.beats",
            ["textRoles"] = {
                {
                    ["fallback"] = "Shit, an alarm! {addressee.name}, every deadhead in blocks is gonna hear that!",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.events.say.1.house_alarm_open",
                    ["variantID"] = "house_alarm_open",
                },
                {
                    ["fallback"] = "I hear it, {addressee.name}. Weapons up and keep moving away from that noise.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.events.say.1.house_alarm_reply",
                    ["variantID"] = "house_alarm_reply",
                },
                {
                    ["fallback"] = "Did everything just go dark? Looks like the power grid finally died today, {addressee.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.events.say.1.power_shutoff_open",
                    ["variantID"] = "power_shutoff_open",
                },
                {
                    ["fallback"] = "Yeah, {addressee.name}, no more free electricity. Watch the spoilage and stock fuel.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.events.say.1.power_shutoff_reply",
                    ["variantID"] = "power_shutoff_reply",
                },
                {
                    ["fallback"] = "Pipes just ran dry today, {addressee.name}. Water system finally quit on us.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.events.say.1.water_shutoff_open",
                    ["variantID"] = "water_shutoff_open",
                },
                {
                    ["fallback"] = "Got it, {addressee.name}. Rain collectors and pots are top priority now.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.events.say.1.water_shutoff_reply",
                    ["variantID"] = "water_shutoff_reply",
                },
            },
        },
        ["id"] = "world.beats.events",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "events",
            ["sourceId"] = "world.beats.events",
            ["sourcePath"] = "dialogue/world_event_beats/world_beats_events.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WorldEventBeats",
        ["namespace"] = "world.beats",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Shit, an alarm! {addressee.name}, every deadhead in blocks is gonna hear that!",
                                ["id"] = "house_alarm_open",
                            },
                            {
                                ["fallback"] = "I hear it, {addressee.name}. Weapons up and keep moving away from that noise.",
                                ["id"] = "house_alarm_reply",
                            },
                            {
                                ["fallback"] = "Did everything just go dark? Looks like the power grid finally died today, {addressee.name}.",
                                ["id"] = "power_shutoff_open",
                            },
                            {
                                ["fallback"] = "Yeah, {addressee.name}, no more free electricity. Watch the spoilage and stock fuel.",
                                ["id"] = "power_shutoff_reply",
                            },
                            {
                                ["fallback"] = "Pipes just ran dry today, {addressee.name}. Water system finally quit on us.",
                                ["id"] = "water_shutoff_open",
                            },
                            {
                                ["fallback"] = "Got it, {addressee.name}. Rain collectors and pots are top priority now.",
                                ["id"] = "water_shutoff_reply",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "world.beats.events",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Shit, an alarm! {addressee.name}, every deadhead in blocks is gonna hear that!",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.world.beats.events.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
        },
        ["slots"] = {
        },
        ["sourceShard"] = "dialogue/world_event_beats/world_beats_events.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Shit, an alarm! {addressee.name}, every deadhead in blocks is gonna hear that!",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.events.say.1.house_alarm_open",
                ["variantID"] = "house_alarm_open",
            },
            {
                ["fallback"] = "I hear it, {addressee.name}. Weapons up and keep moving away from that noise.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.events.say.1.house_alarm_reply",
                ["variantID"] = "house_alarm_reply",
            },
            {
                ["fallback"] = "Did everything just go dark? Looks like the power grid finally died today, {addressee.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.events.say.1.power_shutoff_open",
                ["variantID"] = "power_shutoff_open",
            },
            {
                ["fallback"] = "Yeah, {addressee.name}, no more free electricity. Watch the spoilage and stock fuel.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.events.say.1.power_shutoff_reply",
                ["variantID"] = "power_shutoff_reply",
            },
            {
                ["fallback"] = "Pipes just ran dry today, {addressee.name}. Water system finally quit on us.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.events.say.1.water_shutoff_open",
                ["variantID"] = "water_shutoff_open",
            },
            {
                ["fallback"] = "Got it, {addressee.name}. Rain collectors and pots are top priority now.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.events.say.1.water_shutoff_reply",
                ["variantID"] = "water_shutoff_reply",
            },
        },
        ["when"] = nil,
    },
    {
        ["domain"] = "world_event_beats",
        ["domainPath"] = "world_event_beats",
        ["exchangeFamily"] = {
            ["familyID"] = "world.beats.television",
            ["initiatingSay"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Seeing an old TV still sitting there hits strange, {addressee.name}. Miss lazy nights on the couch.",
                                ["id"] = "tv_reminisce_open",
                                ["templateID"] = "convo.world.beats.television.say.1.tv_reminisce_open",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Yeah, {addressee.name}, feels like a lifetime ago when that was our biggest worry.",
                                ["id"] = "tv_reminisce_reply",
                                ["templateID"] = "convo.world.beats.television.say.1.tv_reminisce_reply",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Dead screen and dark tubes, {addressee.name}. Without the grid, that TV's just furniture.",
                                ["id"] = "tv_power_out_open",
                                ["templateID"] = "convo.world.beats.television.say.1.tv_power_out_open",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Feels eerie seeing every screen dead like that, {addressee.name}.",
                                ["id"] = "tv_power_out_reply",
                                ["templateID"] = "convo.world.beats.television.say.1.tv_power_out_reply",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Shh, {addressee.name}, keep watching {slot.show.name}! You can actually learn solid survival tricks from this.",
                                ["id"] = "tv_watching_life_and_living_open",
                                ["templateID"] = "convo.world.beats.television.say.1.tv_watching_life_and_living_open",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Taking mental notes already, {addressee.name}. Keep the volume reasonable so we don't draw company.",
                                ["id"] = "tv_watching_life_and_living_reply",
                                ["templateID"] = "convo.world.beats.television.say.1.tv_watching_life_and_living_reply",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Still weird hearing voices on {slot.show.name}, {addressee.name}. Almost feels normal for a minute.",
                                ["id"] = "tv_watching_show_open",
                                ["templateID"] = "convo.world.beats.television.say.1.tv_watching_show_open",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                            {
                                ["fallback"] = "Feels oddly grounding listening to {slot.show.name} with you, {addressee.name}.",
                                ["id"] = "tv_watching_show_reply",
                                ["templateID"] = "convo.world.beats.television.say.1.tv_watching_show_reply",
                                ["textRole"] = "spoken_action",
                                ["variantCount"] = 3,
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["namespace"] = "world.beats",
            ["slots"] = {
                ["show"] = {
                    ["multiple"] = false,
                    ["public"] = true,
                    ["required"] = false,
                    ["type"] = "topic",
                },
            },
            ["textRoles"] = {
                {
                    ["fallback"] = "Seeing an old TV still sitting there hits strange, {addressee.name}. Miss lazy nights on the couch.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.television.say.1.tv_reminisce_open",
                    ["variantID"] = "tv_reminisce_open",
                },
                {
                    ["fallback"] = "Yeah, {addressee.name}, feels like a lifetime ago when that was our biggest worry.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.television.say.1.tv_reminisce_reply",
                    ["variantID"] = "tv_reminisce_reply",
                },
                {
                    ["fallback"] = "Dead screen and dark tubes, {addressee.name}. Without the grid, that TV's just furniture.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.television.say.1.tv_power_out_open",
                    ["variantID"] = "tv_power_out_open",
                },
                {
                    ["fallback"] = "Feels eerie seeing every screen dead like that, {addressee.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.television.say.1.tv_power_out_reply",
                    ["variantID"] = "tv_power_out_reply",
                },
                {
                    ["fallback"] = "Shh, {addressee.name}, keep watching {slot.show.name}! You can actually learn solid survival tricks from this.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.television.say.1.tv_watching_life_and_living_open",
                    ["variantID"] = "tv_watching_life_and_living_open",
                },
                {
                    ["fallback"] = "Taking mental notes already, {addressee.name}. Keep the volume reasonable so we don't draw company.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.television.say.1.tv_watching_life_and_living_reply",
                    ["variantID"] = "tv_watching_life_and_living_reply",
                },
                {
                    ["fallback"] = "Still weird hearing voices on {slot.show.name}, {addressee.name}. Almost feels normal for a minute.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.television.say.1.tv_watching_show_open",
                    ["variantID"] = "tv_watching_show_open",
                },
                {
                    ["fallback"] = "Feels oddly grounding listening to {slot.show.name} with you, {addressee.name}.",
                    ["realizationKey"] = "1",
                    ["role"] = "spoken_action",
                    ["templateID"] = "convo.world.beats.television.say.1.tv_watching_show_reply",
                    ["variantID"] = "tv_watching_show_reply",
                },
            },
        },
        ["id"] = "world.beats.television",
        ["kind"] = "dialogue",
        ["lineage"] = {
            ["authoringSchema"] = "psychopatz.convo-engine.v1",
            ["canonicalSchema"] = "psychopatz.convo-engine.v1",
            ["localId"] = "television",
            ["sourceId"] = "world.beats.television",
            ["sourcePath"] = "dialogue/world_event_beats/world_beats_television.json",
            ["sourceSchema"] = "psychopatz.convo-engine.v1",
        },
        ["module"] = "PNC/ConvoEngine/Dialogue/WorldEventBeats",
        ["namespace"] = "world.beats",
        ["owner"] = "ProjectHoomans",
        ["participants"] = {
            ["addressee"] = {
                "participant",
            },
            ["speaker"] = {
                "participant",
            },
        },
        ["payload"] = {
            ["domains"] = {
                {
                    ["domain"] = "social",
                    ["owner"] = "ProjectHoomans",
                },
            },
            ["metadata"] = {
                ["category"] = "projecthoomans:event_reactions",
                ["contentOwner"] = "projecthoomans.dialogue_content.events",
                ["responseAct"] = "REACT",
            },
            ["say"] = {
                ["keyOrder"] = {
                    "1",
                },
                ["mode"] = "single",
                ["realizations"] = {
                    ["1"] = {
                        ["key"] = "1",
                        ["shorthand"] = true,
                        ["variants"] = {
                            {
                                ["fallback"] = "Seeing an old TV still sitting there hits strange, {addressee.name}. Miss lazy nights on the couch.",
                                ["id"] = "tv_reminisce_open",
                            },
                            {
                                ["fallback"] = "Yeah, {addressee.name}, feels like a lifetime ago when that was our biggest worry.",
                                ["id"] = "tv_reminisce_reply",
                            },
                            {
                                ["fallback"] = "Dead screen and dark tubes, {addressee.name}. Without the grid, that TV's just furniture.",
                                ["id"] = "tv_power_out_open",
                            },
                            {
                                ["fallback"] = "Feels eerie seeing every screen dead like that, {addressee.name}.",
                                ["id"] = "tv_power_out_reply",
                            },
                            {
                                ["fallback"] = "Shh, {addressee.name}, keep watching {slot.show.name}! You can actually learn solid survival tricks from this.",
                                ["id"] = "tv_watching_life_and_living_open",
                            },
                            {
                                ["fallback"] = "Taking mental notes already, {addressee.name}. Keep the volume reasonable so we don't draw company.",
                                ["id"] = "tv_watching_life_and_living_reply",
                            },
                            {
                                ["fallback"] = "Still weird hearing voices on {slot.show.name}, {addressee.name}. Almost feels normal for a minute.",
                                ["id"] = "tv_watching_show_open",
                            },
                            {
                                ["fallback"] = "Feels oddly grounding listening to {slot.show.name} with you, {addressee.name}.",
                                ["id"] = "tv_watching_show_reply",
                            },
                        },
                    },
                },
                ["textRole"] = "spoken_action",
            },
            ["topics"] = {
                {
                    ["domain"] = "social",
                    ["id"] = "social_interaction",
                },
            },
        },
        ["references"] = {
        },
        ["responsePlan"] = {
            ["dialogueAct"] = "REACT",
            ["kind"] = "dialogue_act_plan",
            ["responsePlanID"] = "world.beats.television",
            ["schemaVersion"] = 1,
            ["turns"] = {
                {
                    ["continuation"] = "end",
                    ["id"] = "say_1",
                    ["offers"] = {
                    },
                    ["segments"] = {
                        {
                            ["args"] = {
                            },
                            ["fallback"] = "Seeing an old TV still sitting there hits strange, {addressee.name}. Miss lazy nights on the couch.",
                            ["kind"] = "translation",
                            ["templateID"] = "convo.world.beats.television.say_1",
                        },
                    },
                },
            },
        },
        ["roles"] = {
            ["addressee"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "addressee",
            },
            ["speaker"] = {
                ["cardinality"] = "ONE",
                ["kinds"] = {
                    "actor",
                },
                ["role"] = "speaker",
            },
        },
        ["slots"] = {
            ["show"] = {
                ["multiple"] = false,
                ["public"] = true,
                ["required"] = false,
                ["type"] = "topic",
            },
        },
        ["sourceShard"] = "dialogue/world_event_beats/world_beats_television.json",
        ["target"] = {
            ["multiple"] = false,
            ["required"] = false,
            ["type"] = "entity.any",
        },
        ["textRoles"] = {
            {
                ["fallback"] = "Seeing an old TV still sitting there hits strange, {addressee.name}. Miss lazy nights on the couch.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.television.say.1.tv_reminisce_open",
                ["variantID"] = "tv_reminisce_open",
            },
            {
                ["fallback"] = "Yeah, {addressee.name}, feels like a lifetime ago when that was our biggest worry.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.television.say.1.tv_reminisce_reply",
                ["variantID"] = "tv_reminisce_reply",
            },
            {
                ["fallback"] = "Dead screen and dark tubes, {addressee.name}. Without the grid, that TV's just furniture.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.television.say.1.tv_power_out_open",
                ["variantID"] = "tv_power_out_open",
            },
            {
                ["fallback"] = "Feels eerie seeing every screen dead like that, {addressee.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.television.say.1.tv_power_out_reply",
                ["variantID"] = "tv_power_out_reply",
            },
            {
                ["fallback"] = "Shh, {addressee.name}, keep watching {slot.show.name}! You can actually learn solid survival tricks from this.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.television.say.1.tv_watching_life_and_living_open",
                ["variantID"] = "tv_watching_life_and_living_open",
            },
            {
                ["fallback"] = "Taking mental notes already, {addressee.name}. Keep the volume reasonable so we don't draw company.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.television.say.1.tv_watching_life_and_living_reply",
                ["variantID"] = "tv_watching_life_and_living_reply",
            },
            {
                ["fallback"] = "Still weird hearing voices on {slot.show.name}, {addressee.name}. Almost feels normal for a minute.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.television.say.1.tv_watching_show_open",
                ["variantID"] = "tv_watching_show_open",
            },
            {
                ["fallback"] = "Feels oddly grounding listening to {slot.show.name} with you, {addressee.name}.",
                ["realizationKey"] = "1",
                ["role"] = "spoken_action",
                ["templateID"] = "convo.world.beats.television.say.1.tv_watching_show_reply",
                ["variantID"] = "tv_watching_show_reply",
            },
        },
        ["when"] = nil,
    },
}
