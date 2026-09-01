-- Data-only reply variants for tool-only NPC turns.

PNC = PNC or {}
PNC.Conversation = PNC.Conversation or {}

PNC.Conversation.ToolReplyCatalog = {
    social_react = {
        accepted = {
            compliment = {
                "That is kind of you to say.",
                "I appreciate the compliment.",
                "You noticed. Thank you.",
            },
            romantic_interest = {
                "Careful. You are making me smile.",
                "You always know how to get my attention.",
                "That is a dangerous thing to say to me.",
            },
            sexual_advance = {
                "You are bold. I cannot say I dislike that.",
                "That is a very direct proposition.",
                "You are moving fast, but I heard you.",
            },
            hostile_abuse = {
                "Watch your mouth.",
                "Try that again and see what happens.",
                "I have heard worse, but do not make a habit of it.",
            },
            admire = {
                "I appreciate that more than you know.",
                "That is kind of you to say.",
                "You see more in me than most people do.",
            },
            praise = {
                "I appreciate that.",
                "Good. I was hoping you noticed.",
                "That is nice to hear from you.",
            },
            comfort = {
                "Thanks. I needed that.",
                "I appreciate you being here.",
                "That helps more than I expected.",
            },
            apologize = {
                "All right. Let us move on.",
                "I accept the apology.",
                "Fine. We can put it behind us.",
            },
            flirt = {
                "Careful. You are making me smile.",
                "You always know how to get my attention.",
                "That is a dangerous thing to say to me.",
            },
            insult = {
                "Watch your mouth.",
                "Try that again and see what happens.",
                "I have heard worse, but do not make a habit of it.",
            },
            generic = {
                "I hear you.",
                "I will keep that in mind.",
            },
        },
        queued = {
            compliment = {
                "I heard the compliment.",
                "That is kind of you to say.",
            },
            romantic_interest = {
                "I heard you. You are bold, I will give you that.",
                "You certainly know how to get my attention.",
            },
            sexual_advance = {
                "I heard you. Give me a second.",
                "That is a bold thing to say.",
            },
            hostile_abuse = {
                "I heard you. Watch yourself.",
                "Noted. Choose your next words carefully.",
            },
            admire = {
                "I hear you.",
                "That got through.",
            },
            praise = {
                "I hear you.",
                "I will remember that.",
            },
            comfort = {
                "I hear you.",
                "Thanks for saying that.",
            },
            apologize = {
                "I hear you.",
                "We will talk about it.",
            },
            flirt = {
                "I heard you.",
                "You are bold, I will give you that.",
            },
            insult = {
                "I heard you.",
                "Noted.",
            },
            generic = {
                "I hear you.",
                "Give me a moment.",
            },
        },
        rejected = {
            positive_cooldown_active = {
                "You have had your turn with the compliments today.",
                "Save the sweet talk for tomorrow.",
            },
            relationship_gate = {
                "We are not there yet.",
                "That is a little too familiar for us.",
            },
            personality_gate = {
                "That kind of attention is not welcome from me.",
                "You are reading me wrong.",
            },
            orientation_gate = {
                "That is not the kind of interest I have in you.",
                "Do not mistake my kindness for an invitation.",
            },
            rejected_by_game = {
                "Not now.",
                "That did not land well.",
            },
            sexual_advance = {
                "That is not happening.",
                "Do not talk to me like that.",
                "You are moving far too fast.",
            },
            hostile_abuse = {
                "Back off.",
                "You do not get to speak to me that way.",
            },
            generic = {
                "That did not land well.",
                "I am not taking that from you right now.",
            },
        },
    },
    ask_name = {
        named = {
            "I am %s.",
            "The name is %s.",
            "You can call me %s.",
        },
        unnamed = {
            "You want to know my name? Give me a second.",
            "My name is a longer story than you might expect.",
        },
        rejected = {
            "I am not ready to share that yet.",
            "Ask me again when we know each other better.",
        },
    },
    orders = {
        accepted = {
            follow = {
                "All right. I am with you.",
                "Lead the way.",
                "I will stay close.",
            },
            stay = {
                "All right. I will hold here.",
                "I will stay put.",
            },
            camp = {
                "All right. We will make camp here.",
                "I will settle in here for now.",
                "Understood. I will stay here and take care of my needs.",
            },
            generic = {
                "All right.",
                "Understood.",
                "I will handle it.",
            },
        },
        rejected = {
            "I cannot do that right now.",
            "That order is not going to work.",
        },
    },
}

return PNC.Conversation.ToolReplyCatalog
