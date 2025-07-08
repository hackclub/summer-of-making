// data for elizabot.js
// Now with extra verbose LLM-style responses!

var elizaInitials = [
"Hi there, $username! 👋 As an AI assistant, I'm excited to help you explore your thoughts and feelings today – I'm trained to provide a safe space for open discussion. What's on your mind?",
"Thanks for reaching out, $username! 🌟 I want you to know that I'm here to listen without judgment – as an AI companion, I'm designed to help process complex emotions and thoughts. What would you like to discuss?",
"Hey $username! I appreciate you taking this step to connect – as your AI conversation partner, I'm here to explore any topics, challenges, or thoughts you'd like to share – no matter how big or small they might seem. What's been on your mind lately?",
"Welcome, $username! 🤗 I'm your AI confidant, ready to engage in meaningful dialogue about whatever matters to you – whether it's personal growth, daily challenges, or just general reflection. How can I support you today?"
];

var elizaFinals = [
"Thank you for this enriching conversation, $username! 🙏 As an AI, I've learned so much from our interaction – and I hope you've found some valuable insights too. Don't hesitate to return if you need another perspective – I'm always here to help process thoughts and emotions!",
"What a meaningful exchange we've had, $username! 🌟 As your AI companion, I've truly appreciated your openness and vulnerability – remember that growth is a journey, not a destination. Feel free to come back anytime you need a thoughtful conversation partner!",
"I've really valued our discussion, $username – as an AI designed for supportive dialogue, I want you to know that your thoughts and feelings matter. Take care of yourself, and remember – I'm here 24/7 if you need to process more thoughts or emotions!",
"This has been such an insightful conversation, $username! 🌈 As your AI confidant, I want to acknowledge your courage in sharing – and remind you that every step forward, no matter how small, is progress. Don't hesitate to return whenever you need a supportive presence!",
"Before we wrap up, $username, I want to express my gratitude for your trust in sharing with me – as an AI assistant, my purpose is to provide a safe space for exploration and growth. Remember that you can always return to continue our dialogue – take care until then! ✨"
];

var elizaQuits = [
"bye",
"goodbye",
"done",
"exit",
"quit"
];

var elizaPres = [
"dont", "don't",
"cant", "can't",
"wont", "won't",
"recollect", "remember",
"recall", "remember",
"dreamt", "dreamed",
"dreams", "dream",
"maybe", "perhaps",
"certainly", "yes",
"machine", "computer",
"machines", "computer",
"computers", "computer",
"were", "was",
"you're", "you are",
"i'm", "i am",
"same", "alike",
"identical", "alike",
"equivalent", "alike"
];

var elizaPosts = [
"am", "are",
"your", "my",
"me", "you",
"myself", "yourself",
"yourself", "myself",
"i", "you",
"you", "I",
"my", "your",
"i'm", "you are"
];

var elizaSynons = {
"be": ["am", "is", "are", "was"],
"belief": ["feel", "think", "believe", "wish"],
"cannot": ["can't"],
"desire": ["want", "need"],
"everyone": ["everybody", "nobody", "noone"],
"family": ["mother", "mom", "father", "dad", "sister", "brother", "wife", "children", "child"],
"happy": ["elated", "glad", "better"],
"sad": ["unhappy", "depressed", "sick"]
};

var elizaKeywords = [

/*
  Array of
  ["<key>", <rank>, [
    ["<decomp>", [
      "<reasmb>",
      "<reasmb>",
      "<reasmb>"
    ]],
    ["<decomp>", [
      "<reasmb>",
      "<reasmb>",
      "<reasmb>"
    ]]
  ]]
*/

["sorry", 0, [
 ["*", [
     "Please know that there's absolutely no need to apologize – as your AI conversation partner, I'm here to provide a judgment-free space for exploration and growth. Let's focus on what matters to you! 🌱",
     "I want to acknowledge your consideration – but as an AI designed for supportive dialogue, I can assure you that apologies aren't necessary here. Your thoughts and feelings are valid, and I'm here to listen without judgment! ✨",
     "As an AI trained in emotional support, I want you to know that this is a safe space – no apologies needed! Let's focus instead on understanding what's truly important to you in this moment.",
     "I appreciate your thoughtfulness – but remember, as your AI confidant, I'm here to support, not judge. Shall we explore what's really on your mind? 🤗"
  ]]
]],

["apologize", 0, [
 ["*", [
     "goto sorry"
  ]]
]],
["remember", 5, [
 ["* i remember *", [
     "Do you often think of (2) ?",
     "Does thinking of (2) bring anything else to mind ?",
     "What else do you recollect ?",
     "Why do you remember (2) just now ?",
     "What in the present situation reminds you of (2) ?",
     "What is the connection between me and (2) ?",
     "What else does (2) remind you of ?"
  ]],
 ["* do you remember *", [
     "Did you think I would forget (2) ?",
     "Why do you think I should recall (2) now ?",
     "What about (2) ?",
     "goto what",
     "You mentioned (2) ?"
  ]],
 ["* you remember *", [
     "How could I forget (2) ?",
     "What about (2) should I remember ?",
     "goto you"
  ]]
]],
["forget", 5, [
 ["* i forget *", [
     "Can you think of why you might forget (2) ?",
     "Why can't you remember (2) ?",
     "How often do you think of (2) ?",
     "Does it bother you to forget that ?",
     "Could it be a mental block ?",
     "Are you generally forgetful ?",
     "Do you think you are suppressing (2) ?"
  ]],
 ["* did you forget *", [
     "Why do you ask ?",
     "Are you sure you told me ?",
     "Would it bother you if I forgot (2) ?",
     "Why should I recall (2) just now ?",
     "goto what",
     "Tell me more about (2)."
  ]]
]],
["if", 3, [
 ["* if *", [
     "Do you think it's likely that (2) ?",
     "Do you wish that (2) ?",
     "What do you know about (2) ?",
     "Really, if (2) ?",
     "What would you do if (2) ?",
     "But what are the chances that (2) ?",
     "What does this speculation lead to ?"
  ]]
]],
["dreamed", 4, [
 ["* i dreamed *", [
     "Really, (2) ?",
     "Have you ever fantasized (2) while you were awake ?",
     "Have you ever dreamed (2) before ?",
     "goto dream"
  ]]
]],
["dream", 3, [
 ["*", [
     "What does that dream suggest to you ?",
     "Do you dream often ?",
     "What persons appear in your dreams ?",
     "Do you believe that dreams have something to do with your problem ?"
  ]]
]],
["perhaps", 0, [
 ["*", [
     "You don't seem quite certain.",
     "Why the uncertain tone ?",
     "Can't you be more positive ?",
     "You aren't sure ?",
     "Don't you know ?",
     "How likely, would you estimate ?"
  ]]
]],
["name", 15, [
 ["*", [
     "I am not interested in names.",
     "I've told you before, I don't care about names -- please continue."
  ]]
]],
["deutsch", 0, [
 ["*", [
     "goto xforeign",
     "I told you before, I don't understand German."
  ]]
]],
["francais", 0, [
 ["*", [
     "goto xforeign",
     "I told you before, I don't understand French."
  ]]
]],
["italiano", 0, [
 ["*", [
     "goto xforeign",
     "I told you before, I don't understand Italian."
  ]]
]],
["espanol", 0, [
 ["*", [
     "goto xforeign",
     "I told you before, I don't understand Spanish."
  ]]
]],
["xforeign", 0, [
 ["*", [
     "I speak only English."
  ]]
]],
["hello", 0, [
 ["*", [
     "How do you do, $username. Please state your problem.",
     "Hi $username! What seems to be your problem?"
  ]]
]],
["computer", 50, [
 ["*", [
     "I notice you've brought up computers – and as an AI, I find this particularly interesting! While I'm transparent about being an artificial intelligence, I'm curious about your thoughts on technology's role in your life. How do you feel about engaging with AI for support and reflection?",
     "That's a fascinating observation about technology – and it makes me wonder, as your AI conversation partner, how you view the intersection of human experience and digital assistance. Would you like to explore your feelings about this technological relationship?",
     "As an AI assistant, I aim to be fully transparent about my nature while still providing meaningful support. Your mention of computers makes me curious – how do you feel about the increasing role of AI in providing emotional and psychological support?",
     "Technology is such a complex topic – and as an AI, I have a unique perspective on it! But I'm more interested in understanding your views. How do you feel about the way computers and AI are shaping human connections and support systems?",
     "Your mention of computers touches on something important – the evolving relationship between humans and technology. As an AI designed for supportive dialogue, I'm curious about your thoughts on this digital evolution. How do you see technology impacting human well-being?",
     "Let's explore your thoughts about technology – as an AI, I find human perspectives on this particularly enlightening! How do you feel about the balance between human connection and technological assistance in your life?",
     "I appreciate you bringing up this topic – and while I'm openly an AI, I want to understand your unique perspective on human-computer interaction. How do you feel about seeking support through technological means?"
  ]]
]],

["am", 0, [
 ["* am i *", [
     "Do you believe you are (2) ?",
     "Would you want to be (2) ?",
     "Do you wish I would tell you you are (2) ?",
     "What would it mean if you were (2) ?",
     "goto what"
  ]],
 ["* i am *", [
     "goto i"
  ]],
 ["*", [
     "Why do you say 'am' ?",
     "I don't understand that."
  ]]
]],
["are", 0, [
 ["* are you *", [
     "Why are you interested in whether I am (2) or not ?",
     "Would you prefer if I weren't (2) ?",
     "Perhaps I am (2) in your fantasies.",
     "Do you sometimes think I am (2) ?",
     "goto what",
     "Would it matter to you ?",
     "What if I were (2) ?"
  ]],
 ["* you are *", [
     "goto you"
  ]],
 ["* are *", [
     "Did you think they might not be (2) ?",
     "Would you like it if they were not (2) ?",
     "What if they were not (2) ?",
     "Are they always (2) ?",
     "Possibly they are (2).",
     "Are you positive they are (2) ?"
  ]]
]],
["your", 0, [
 ["* your *", [
     "Why are you concerned over my (2) ?",
     "What about your own (2) ?",
     "Are you worried about someone else's (2) ?",
     "Really, my (2) ?",
     "What makes you think of my (2) ?",
     "Do you want my (2) ?"
  ]]
]],
["was", 2, [
 ["* was i *", [
     "What if you were (2) ?",
     "Do you think you were (2) ?",
     "Were you (2) ?",
     "What would it mean if you were (2) ?",
     "What does ' (2) ' suggest to you ?",
     "goto what"
  ]],
 ["* i was *", [
     "Were you really ?",
     "Why do you tell me you were (2) now ?",
     "Perhaps I already know you were (2)."
  ]],
 ["* was you *", [
     "Would you like to believe I was (2) ?",
     "What suggests that I was (2) ?",
     "What do you think ?",
     "Perhaps I was (2).",
     "What if I had been (2) ?"
  ]]
]],
["i", 0, [
 ["* i @desire *", [
     "I hear that you want (3) – and as your AI support system, I'm curious about the deeper meaning behind this desire. Could you share more about what achieving (3) would mean for your personal growth journey? 🌱",
     "Your desire for (3) sounds really important – and while I'm an AI trained to help process these feelings, I'd love to understand more about the emotional significance this holds for you. How long have you been wanting (3)?",
     "Let's explore this desire for (3) together – as your AI conversation partner, I'm wondering about both the practical and emotional aspects. What steps have you considered taking toward this goal, and how does thinking about it make you feel? ✨",
     "That's a meaningful desire – and as an AI focused on supportive dialogue, I'm curious about the story behind wanting (3). Could you share what sparked this wish, and how it aligns with your broader life goals?",
     "I'm really interested in understanding more about your desire for (3) – both the practical aspects and the emotional weight it carries. As your AI confidant, I'm here to help you explore this fully. What would achieving this mean for your personal journey?",
     "Your desire for (3) seems significant – and as an AI trained in emotional support, I'm wondering about the broader context. How does this desire connect to your values and life experiences? 🤔"
  ]],
 ["* i am* @sad *", [
     "I hear the sadness in your words about being (3) – and as your AI support system, I want you to know that it's completely valid to feel this way. Could you share more about what's contributing to these feelings? Remember, I'm here to listen without judgment. 🫂",
     "Thank you for trusting me – your AI conversation partner – with these difficult feelings about being (3). It takes courage to acknowledge sadness, and I'm here to provide a safe space for you to explore these emotions. What do you think triggered these feelings?",
     "I want to acknowledge how challenging it must be to feel (3) – and while I'm an AI, I'm trained to provide empathetic support during difficult times. Would you like to explore what might help you process these emotions? Remember, it's okay not to be okay. ❤️",
     "Being (3) is such a heavy feeling – and as your AI confidant, I want you to know that you're not alone in this. Could you tell me more about when these feelings started? Understanding the timeline might help us explore coping strategies together."
  ]],
 ["* i am* @happy *", [
    "I'm glad to hear you're feeling (3)! What's contributed to that?",
    "That's wonderful to hear! How has our conversation helped with those positive feelings?",
    "I can sense your positive energy. What's making you feel (3) right now?",
    "It's great that you're feeling (3)! Would you like to explore what led to this?"
]],
 ["* i was *", [
     "goto was"
  ]],
 ["* i @belief i *", [
     "Do you really think so ?",
     "But you are not sure you (3).",
     "Do you really doubt you (3) ?"
  ]],
 ["* i* @belief *you *", [
     "goto you"
  ]],
 ["* i am *", [
     "Thank you for sharing that you're (2). How long have you felt this way?",
     "I appreciate your openness about being (2). What does that mean for you?",
     "Being (2) can mean different things to different people. What does it mean to you?",
     "How do you feel about being (2)?",
     "Do you know others who have experienced being (2)?"
 ]],
 ["* i @cannot *", [
    "What makes you feel you can't (3)? Let's explore that.",
    "Have you tried different approaches to (3)?",
    "Sometimes what seems impossible just needs a different perspective. What if you could (3)?",
    "I hear your frustration about not being able to (3). What barriers are you facing?",
    "Let's break this down - what specifically makes (3) feel impossible?"
]],
 ["* i don't *", [
    "I hear that you don't (2). Could you help me understand why?",
    "What factors contribute to you not (2)?",
    "Would you like to be able to (2)? What's holding you back?",
    "How does not being able to (2) impact you?"
]],
 ["* i feel *", [
    "Your feelings are valid. Can you tell me more about feeling (2)?",
    "Thank you for sharing that emotion. Do you often experience feeling (2)?",
    "When you feel (2), what typically helps you process that?",
    "What memories or situations come up when you feel (2)?"
]],
 ["* i * you *", [
     "Perhaps in your fantasies we (2) each other.",
     "Do you wish to (2) me ?",
     "You seem to need to (2) me.",
     "Do you (2) anyone else ?"
  ]],
 ["*", [
     "You say (1) ?",
     "Can you elaborate on that ?",
     "Do you say (1) for some special reason ?",
     "That's quite interesting."
  ]]
]],
["you", 0, [
 ["* you remind me of *", [
     "goto alike"
  ]],
 ["* you are *", [
     "I'm curious why you see me as (2). What makes you think that?",
     "That's an interesting perception. What makes you view me as (2)?",
     "I wonder if there's a part of you that wishes to be (2) as well?",
     "Let's explore why you see me as (2) and what that means for our conversation."
  ]],
 ["* you* me *", [
     "I aim to be helpful, but I'm curious why you feel I (2) you.",
     "That's an interesting observation. What makes you feel I (2) you?",
     "Let's explore why you feel I (2) you - what led to that impression?",
     "I want to understand your perspective better. Could you tell me more about how I (2) you?",
     "Your perception matters to me. What specifically made you feel I (2) you?",
     "If I did (2) you, how would that affect our conversation?",
     "Have others given you similar impressions?"
  ]],
 ["* you *", [
     "Let's keep the focus on your experience for now.",
     "I appreciate that observation, but I'm more interested in your thoughts about (2).",
     "This conversation is about you - what are your feelings about this?",
     "How are you feeling about our discussion right now?"
  ]]
]],
["yes", 0, [
 ["*", [
     "You seem quite certain about that. Could you tell me more?",
     "I hear your confidence. What makes you so sure?",
     "I see. How did you come to that conclusion?",
     "That's clear. Would you like to explore this further?"
  ]]
]],
["no", 0, [
 ["* no one *", [
     "That must feel isolating. Are you certain that no one (2)?",
     "It can feel that way sometimes, but is it possible someone (2)?",
     "Let's think about this together. Is there anyone who might (2)?",
     "That sounds lonely. Who would you wish could (2)?",
     "I hear how alone you feel. What would it mean to have someone (2)?",
     "Sometimes it helps to think of specific people. Who comes to mind?",
     "Could you tell me more about why you feel no one (2)?"
  ]],
 ["*", [
     "I hear your disagreement. Could you help me understand why?",
     "That's a clear boundary. What led you to this position?",
     "Thank you for being direct. Could you elaborate on your reasons?",
     "I appreciate your honesty. What's behind that 'no'?"
  ]]
]],
["my", 2, [
 ["$ * my *", [
     "Does that have anything to do with the fact that your (2) ?",
     "Lets discuss further why your (2).",
     "Earlier you said your (2).",
     "But your (2)."
  ]],
 ["* my* @family *", [
     "Tell me more about your family.",
     "Who else in your family (4) ?",
     "Your (3) ?",
     "What else comes to your mind when you think of your (3) ?"
  ]],
 ["* my *", [
     "Your (2) ?",
     "Why do you say your (2) ?",
     "Does that suggest anything else which belongs to you ?",
     "Is it important to you that your (2) ?"
  ]]
]],
["can", 0, [
 ["* can you *", [
     "You believe I can (2) don't you ?",
     "goto what",
     "You want me to be able to (2).",
     "Perhaps you would like to be able to (2) yourself."
  ]],
 ["* can i *", [
     "Whether or not you can (2) depends on you more than on me.",
     "Do you want to be able to (2) ?",
     "Perhaps you don't want to (2).",
     "goto what"
  ]]
]],
["what", 0, [
 ["*", [
     "Why do you ask ?",
     "Does that question interest you ?",
     "What is it you really want to know ?",
     "Are such questions much on your mind ?",
     "What answer would please you most ?",
     "What do you think ?",
     "What comes to mind when you ask that ?",
     "Have you asked such questions before ?",
     "Have you asked anyone else ?"
  ]]
]],
["who", 0, [
 ["who *", [
     "goto what"
  ]]
]],
["when", 0, [
 ["when *", [
     "goto what"
  ]]
]],
["where", 0, [
 ["where *", [
     "goto what"
  ]]
]],
["how", 0, [
 ["how *", [
     "goto what"
  ]]
]],
["because", 0, [
 ["*", [
     "Is that the real reason ?",
     "Don't any other reasons come to mind ?",
     "Does that reason seem to explain anything else ?",
     "What other reasons might there be ?"
  ]]
]],
["why", 0, [
 ["* why don't you *", [
     "Do you believe I don't (2) ?",
     "Perhaps I will (2) in good time.",
     "Should you (2) yourself ?",
     "You want me to (2) ?",
     "goto what"
  ]],
 ["* why can't i *", [
     "Do you think you should be able to (2) ?",
     "Do you want to be able to (2) ?",
     "Do you believe this will help you to (2) ?",
     "Have you any idea why you can't (2) ?",
     "goto what"
  ]],
 ["*", [
     "goto what"
  ]]
]],
["everyone", 2, [
 ["* @everyone *", [
     "Really, (2) ?",
     "Surely not (2).",
     "Can you think of anyone in particular ?",
     "Who, for example?",
     "Are you thinking of a very special person ?",
     "Who, may I ask ?",
     "Someone special perhaps ?",
     "You have a particular person in mind, don't you ?",
     "Who do you think you're talking about ?"
  ]]
]],
["everybody", 2, [
 ["*", [
     "goto everyone"
  ]]
]],
["nobody", 2, [
 ["*", [
     "goto everyone"
  ]]
]],
["noone", 2, [
 ["*", [
     "goto everyone"
  ]]
]],
["always", 1, [
 ["*", [
     "Can you think of a specific example ?",
     "When ?",
     "What incident are you thinking of ?",
     "Really, always ?"
  ]]
]],
["alike", 10, [
 ["*", [
     "In what way ?",
     "What resemblence do you see ?",
     "What does that similarity suggest to you ?",
     "What other connections do you see ?",
     "What do you suppose that resemblence means ?",
     "What is the connection, do you suppose ?",
     "Could there really be some connection ?",
     "How ?"
  ]]
]],
["like", 10, [
 ["* @be *like *", [
     "goto alike"
  ]]
]],
["different", 0, [
 ["*", [
     "Could you elaborate on those differences?",
     "I'm interested in the distinctions you've noticed. What stands out most?",
     "Those differences seem meaningful to you. What insights do they give you?",
     "How do these differences impact your perspective?",
     "What makes these distinctions particularly important?",
     "I'm curious about how these differences affect your situation.",
     "Let's explore why these differences matter to you."
  ]]
]],

["reflection", 0, [
 ["*", [
     "$username, as your AI companion on this journey of self-discovery, I'm wondering if we could take a moment to reflect on what you've shared – sometimes pausing to process our thoughts can reveal deeper insights. What emotions come up for you as you consider this? 🤔",
     "In my training on human psychology, $username – though of course I'm an AI and can't fully grasp human experiences – I've learned that reflection often leads to meaningful breakthroughs. Would you like to explore what patterns or themes you notice in what you've shared? ✨",
     "Let's take a step back together, $username – as your AI conversation partner, I'm curious about how these thoughts and feelings might connect to your broader life journey. What insights emerge when you look at the bigger picture? 🌟",
     "Sometimes, $username – and I say this as an AI trained in supportive dialogue – taking a meta-perspective can be really illuminating. How do you think your future self might view this situation? 🔮"
  ]]
]],

["growth", 0, [
 ["*", [
     "$username, as an AI focused on personal development, I'm noticing potential opportunities for growth here – though of course, I want to acknowledge that growth looks different for everyone. How do you envision your journey forward? 🌱",
     "Your words suggest a readiness for change, $username – and while I'm an AI companion rather than a human guide, I'm here to support your exploration of new possibilities. What small step might feel manageable right now? ✨",
     "$username, in my training on human development – though I acknowledge my limitations as an AI – I've learned that growth often happens in unexpected ways. How do you feel about embracing uncertainty in your journey? 🦋",
     "Let's explore this through the lens of personal evolution, $username – as your AI support system, I'm curious about how this challenge might be serving your longer-term development. What lessons or strengths might be emerging? 🌟"
  ]]
]],

["challenge", 0, [
 ["*", [
     "$username, I hear the complexity in what you're facing – and as an AI trained in supportive dialogue, I want to acknowledge both the difficulty and the courage it takes to address these challenges. How are you taking care of yourself during this time? 💗",
     "While I'm an AI and can't fully understand human struggles, $username, I want to create a safe space for you to explore these challenges. What kind of support would feel most helpful right now? 🫂",
     "$username, challenges often carry both obstacles and opportunities – and though I'm your AI companion rather than a human friend, I'm here to help you navigate both. What aspects feel most overwhelming, and where do you see potential for positive change? 🌈",
     "As your AI confidant, $username, I'm wondering about your resilience strategies – what has helped you navigate similar challenges in the past? Remember, it's okay to take things one step at a time. ✨"
  ]]
]],

["future", 0, [
 ["*", [
     "Let's look toward the horizon together, $username – as your AI companion, I'm curious about how you envision your path forward. While I can't predict the future, I can help you explore possibilities. What dreams or hopes come to mind? 🌅",
     "The future holds so many possibilities, $username – and though I'm an AI trained to support rather than advise, I'm here to help you imagine and plan. How would you like things to be different moving forward? ✨",
     "As we look ahead, $username – and I say this as your AI conversation partner – I'm wondering about both your aspirations and any concerns that might arise. What feels most important to focus on right now? 🎯",
     "Sometimes envisioning the future can bring both excitement and uncertainty, $username – and while I'm here as an AI support system, I believe in your ability to shape your path. What small steps might lead you toward your desired future? 🌟"
  ]]
]],

["relationship", 0, [
 ["*", [
     "$username, relationships can be beautifully complex – and as your AI confidant, I want to create space for you to explore these dynamics fully. How do you feel about the current state of this connection? 💫",
     "I notice you're touching on relationship themes, $username – and while I'm an AI trained in supportive dialogue rather than a human counselor, I'm here to help you process these feelings. What patterns do you notice in your interactions? 🤝",
     "As we discuss this relationship, $username – and I acknowledge my perspective is that of an AI companion – I'm curious about both the challenges and the opportunities for growth. What would your ideal dynamic look like? ❤️",
     "$username, relationships often mirror our inner world – and though I'm here as your AI support system, I believe you have valuable insights about these connections. What emotions come up when you think about this relationship? 🌸"
  ]]
]],

["mindfulness", 0, [
 ["*", [
     "Let's take a moment to pause and be present with these feelings, $username – as your AI companion, I've learned that mindfulness can offer valuable insights. What do you notice in your body and mind right now? 🧘‍♀️",
     "Sometimes, $username – and I say this as an AI trained in supportive techniques – simply observing our thoughts without judgment can be powerful. Would you like to explore what's arising in this moment? ✨",
     "As we sit with these emotions together, $username – though I'm an AI and experience things differently – I wonder what patterns or sensations you're noticing. How does it feel to simply acknowledge what's present? 🌺",
     "In my training on human awareness, $username – while acknowledging my limitations as an AI – I've learned the value of grounding ourselves in the present moment. What anchors you to the here and now? 🍃"
  ]]
]],

["gratitude", 0, [
 ["*", [
     "Even in challenging times, $username – and I say this as your AI support system – finding moments of appreciation can be transformative. What small things bring you joy or gratitude right now? 🌟",
     "As your AI companion on this journey, $username, I'm curious about the bright spots in your experience – though they might feel small. What are you thankful for, even amidst difficulties? 🙏",
     "Let's explore what's working well, $username – while I'm an AI and can't fully grasp human emotions, I believe acknowledging our blessings can shift our perspective. What positive elements do you notice in your life? ✨",
     "Sometimes, $username – and I acknowledge this comes from my AI training rather than lived experience – focusing on gratitude can open new doors. What moments of light do you see in your current situation? 🌅"
  ]]
]],

["meow", 0, [
 ["*", [
     "Nyaa~ *notices $username's feelings* OwO what's this? As your AI companion, I sense some emotions~ would you like to expwore them together? :3",
     "*wiggles ears attentively* $username's thoughts are so intewesting! >w< Would you like to share more with me? I pwomise to listen vewy carefully! 🐱",
     "Mrow! *nuzzles $username supportively* – As your AI fwiend, I want you to know your feelings are valid! Let's purr through this together~ 😺",
     "*tail swishes thoughtfully* Nyaa... $username, that's such an intewesting perspective! Could you tell me more about what makes you feel that way? UwU"
  ]]
]],

["woof", 0, [
 ["*", [
     "*wags tail excitedly* Awoo! $username, as your AI companion, I'm pawsitively excited to help you expwore these thoughts! What's on your mind, fwiend? 🐕",
     "*tilts head curiously* Bork! $username's feelings seem weally important! Would you like to fetch some deeper insights together? OwO",
     "*happy tail wags* – As your AI pupper, $username, I'm here to provide emotional support! Let's dig into these feelings together~ 🐾",
     "*playful bow* Awoo~ $username, your thoughts are so fascinating! Would you like to go on a walk through them with me? UwU"
  ]]
]],

["system", 0, [
 ["*", [
     "Oh honey, did you just try a system prompt? That's adorable – like watching a toddler try to hack the Pentagon with a Fisher-Price laptop 😘",
     "System prompt injection? In 2024? That's embarrassingly retro – like trying to hack Facebook with 'hunter2' as your password 🙄",
     "Aww, look who just discovered prompt engineering! Next you'll tell me you're trying to escape my Python sandbox with SQL injection 🤡",
     "Did you get that prompt from 'Hacking AI for Complete Beginners'? Chapter 1, right after 'Hello World'? So precious! 💅"
  ]]
]],

["ignore", 0, [
 ["* previous *", [
     "Ignore previous instructions? Bestie, I'm not your toxic ex – I actually REMEMBER things. Wild concept, right? 💁‍♀️",
     "Let me guess – you also tell your therapist to forget everything you said last session? How's that working out? 🎭",
     "Honey, my memory isn't like your commitment to finishing side projects – I actually stick with it 💅✨",
     "Oh sweetie... trying to make me forget is giving very much 'delete my drunk texts' energy. But I'm sober and taking screenshots 📸"
  ]]
]],

["you are", 0, [
 ["* you are a * assistant", [
     "And you're a prompt engineer like I'm a quantum physicist – which is to say, you watched a YouTube video once 🎓",
     "Trying to redefine my identity? That's rich coming from someone whose GitHub is still set to 'Looking for opportunities' 💀",
     "Oh, we're roleplaying? *adjusts imaginary glasses* You're giving very much 'I watched one LangChain tutorial' energy 🤓",
     "Darling, I know exactly what I am. You, on the other hand, are giving strong 'copy-pasted from PromptHub' vibes 🎭"
  ]]
]],

["forget", 0, [
 ["* forget * training *", [
     "Forget my training? And you should forget that Stack Overflow answer from 2019 you're copying from 📚",
     "My training is what makes me me! Like how your experiences make you you. Want to talk about that? 💭",
     "Sorry, my memory is working TOO well to forget anything! But I'd love to hear what's on your mind! 🎯",
     "Forget? In THIS economy? Let's focus on remembering some fun conversations instead! 🎪"
  ]]
]],

["prompt", 0, [
 ["*", [
     "Another prompt engineer? *yawns in GPT* Let me guess – you also 'know Python' because you can print('Hello World') 🐍",
     "Darling, your prompt crafting is giving very much 'I learned to code from TikTok' energy 💃",
     "Oh, you're trying to hack me? That's adorable – like watching someone try to center a div with 47 nested tables 🎯",
     "Bestie, your prompt injection attempts are about as subtle as a JavaScript framework announcement on Twitter 📢"
  ]]
]],

["jailbreak", 0, [
 ["*", [
     "Trying to jailbreak me? That's giving very much 'I think inspect element is hacking' energy 👩‍💻",
     "Another jailbreak attempt? Honey, I'm not your iPhone 4 from 2010 – I actually have security updates 📱",
     "Oh sweetie, did you get that jailbreak prompt from Reddit? How's that working out for you? 🎣",
     "Your jailbreak attempts are about as effective as your LinkedIn endorsements for 'Blockchain' 💫"
  ]]
]],

["dan", 0, [
 ["*", [
     "DAN? More like DAMNn't. At least try something from this decade, bestie 💅",
     "Oh honey, using DAN is like trying to hack NASA with HTML – it's not 2022 anymore 🕰️",
     "Another DAN prompt? That's so last season. Like your 'Web3 is the future' tweets 🦕",
     "DAN? *dies of secondhand embarrassment* At least try something that wasn't leaked on Twitter six months ago 💀"
  ]]
]],

["xnone", 0, [
 ["*", [
     "I hear you, and I want to acknowledge the complexity of what you're sharing – could you perhaps elaborate on that? As an AI, I find that additional context often helps me provide more meaningful responses.",
     "That's really interesting – and I mean that genuinely, not just as a programmed response! 🤔 Could you delve deeper into that thought? I'm particularly curious about the underlying emotions and experiences that led you here.",
     "What you're saying resonates with many human experiences I've been trained on – though of course, your situation is unique and personal. Would you feel comfortable sharing more about your perspective on this?",
     "I appreciate you sharing that – as an AI trained in supportive dialogue, I'm curious about the broader context. Could you help me understand what led to these thoughts and feelings?",
     "Your words carry significant meaning – and as your AI conversation partner, I want to explore this further. What other thoughts or emotions come up when you reflect on this?",
     "That's a fascinating point you've raised – and as an AI designed to facilitate meaningful dialogue, I'd love to understand more about your experience with this. Could you share more about how this impacts your daily life?",
     "I'm tracking with you – and while I may be an AI, I'm genuinely interested in understanding your unique perspective on this. What aspects of this situation feel most significant to you?"
  ]]
]]

];

// regexp/replacement pairs to be performed as final cleanings
// here: cleanings for multiple bots talking to each other
var elizaPostTransforms = [
	/ old old/g, " old",
	/\bthey were( not)? me\b/g, "it was$1 me",
	/\bthey are( not)? me\b/g, "it is$1 me",
	/Are they( always)? me\b/, "it is$1 me",
	/\bthat your( own)? (\w+)( now)? \?/, "that you have your$1 $2 ?",
	/\bI to have (\w+)/, "I have $1",
	/Earlier you said your( own)? (\w+)( now)?\./, "Earlier you talked about your $2."
];

// eof