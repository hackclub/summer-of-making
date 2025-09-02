// Factory that returns the dialogue array for the new tutorial.
// Accepts displayName so the calling controller can inject runtime values.
function getNewTutorialDialogue(scene = "intro", params = {}) {
    if (scene === "intro") {
        return getNewTutorialIntroDialogue(params);
    } else if (scene === "ship") {
        return getNewTutorialShipDialogue(params);
    } else if (scene === "to_vote") {
        return getNewTutorialToVoteDialogue(params);
    } else if (scene === "vote") {
        return getNewTutorialVoteDialogue(params);
    }
}

function getNewTutorialCheckpointStep(scene = "intro", checkpoint) {
  const dialogue = getNewTutorialDialogue(scene);
  const i = dialogue.findIndex(step => step.checkpoint === checkpoint);
  return i === -1 ? 0 : i;
}

function getNewTutorialIntroDialogue(params = {}) {
  const name = params.displayName ?? "Hey";

  return [
    // intro
    { text: `Psst! Hey there! <span class="new-tutorial-shake">${name}!</span>` },
    { text: `Welcome to the... <span class="new-tutorial-shake">SUMMER OF MAKING!!!</span>` },
    { text: `Oh... I don't believe I've introduced myself.<br>I'm Explorpheus!` },
    { text: `I'm here to guide you through everything you need to know to start shipping and earning <span class="new-tutorial-bling">prizes</span>` },

    // campfire
    {
      text: `You're currently at the Campfire! This is where the latest news is shared!`,
      focus: 'new-tutorial-campfire-title', x: 0, y: 10, width: 50, height: -50, radius: 20
    },
    {
      text: `You should check back here every once in a while! There's always so much happening on the island!`,
      focus: 'new-tutorial-campfire-title', x: 0, y: 10, width: 50, height: -50, radius: 20
    },

    // currency
    { text: `Shells are our currency here. You can get so much cool stuff with them, but to get 'em, you gotta...` },
    { text: `<span class="new-tutorial-shake">Build cool projects and ship them!</span>` },
    { text: `Awesome! Let's dive a bit deeper!` },
    {
      text: `Check out this video!`,
      video: '/onboarding.mp4', skip: 10
    },

    // step-by-step - skipped if watched video
    { text: `I'll walk you through what this is about!` },
    { text: `1. Come up with a cool project idea. Make it something you've always wanted to build.` },
    { text: `2. Start building! Track how much time you spent with Hackatime.` },
    { text: `3. As you build, post <span class="new-tutorial-shake">devlogs</span>! They're mini updates on your progress.` },
    { text: `4. Once it's ready, <span class="new-tutorial-shake">ship it</span> to the world! It doesn't have to be perfect. A MVP is okay!` },
    { text: `5. Our shipwrights will make sure your project is working. They'll give you feedback!` },
    { text: `6. Your project will then be voted on by the community. You'll vote on others' projects as well.` },
    { text: `7. You'll earn shells depending on the number of votes and how long you've worked on your project.` },
    { text: `8. You can spend these shells in our shop for awesome prizes!` },
    { text: `Alright, that was quite the ramble...` },

    // hackatime
    { text: `Don't worry if this is confusing, I'll walk you through each step` },
    { 
      text: `We use Hackatime to track your time spent. You'll need to get that set up.`,
      condition: 'hackatime',
      alt: {
        text: `We use Hackatime to track your time spent. You're all set up on Hackatime!`,
      },
      checkpoint: 'hackatime',
      skip: 1
    },
    {
      // skipped if hackatime is set up
      text: `Head to the Hackatime website. Follow the instructions there. I'll be waiting for you!`,
      focus: 'new-tutorial-hackatime', focusOther: ['new-tutorial-hackatime-container'], 
      x: 0, y: 0, width: 30, height: 30, radius: 10, preventAdvance: true
    },
    {
      text: "Let's head over to the shop to purchase your first item!",
      checkpoint: 'hackatime-installed',
      focus: `new-tutorial-shop`,
      x: 0, y: 0, width: 30, height: 30, radius: 10, preventAdvance: true 
    }
  ];
}

function getNewTutorialShipDialogue(params = {}) {
  return [
    { text: "I see you're trying to ship your project!" },
    { text: "But first, what even is a ship???" },
    { 
      text: "Check out this video!",
      video: "/ship.mp4", skip: 14
    },

    // skipped if watched video
    { text: "That's okay, I'll explain it to you here." },
    { text: `A <strong>project</strong> is something you build.` },
    { text: `A <strong>shipped project</strong> is something you build and present to the world.` },
    { text: `A <strong>ship</strong> is a <strong>milestone</strong> where a project becomes real to somebody else.` },
    { text: `Shipped projects must be presentable and functional for the world to see.` },
    { text: `Websites must be deployed, games need to need to be easily playable, CLIs need to be published as packages...`},
    { text: `You get the idea!` },
    { text: `Presentation matters! Your README must explain your project and its features.` },
    { text: `If something is mentioned in the README, it must actually exist.`},
    { text: `Also, make sure you credit work from others, this includes AI.`},
    { text: `The Hack Club community votes for ships based off of their creativity, technicality, and presentation.`},
    { text: `But before your ships can be voted on, the Shipwrights will certify that it's ready!` },
    { text: `They'll help you to make sure your project can do well in voting!` },

    // cta
    { 
      text: `Once you feel that you're ready, click the ship button to ship it!`,
      checkpoint: 'ship'
    }
  ]
}

function getNewTutorialToVoteDialogue(params = {}) {
  return [
    { text: `<span class="new-tutorial-shake">Congrats on shipping your project!!</span>` },
    { text: "The Shipwrights are on their way to inspect your ship." },
    {
      text: "They're pretty fast, but be patient! It might take a little while."
    },

    // cta to vote
    { text: "Now it's time to vote!" },
    { text: "For every ship, you need to vote at least 20 times." },
    { 
      text: "Let's head over to the voting page",
      focus: `new-tutorial-vote`,
      x: 0, y: 0, width: 30, height: 30, radius: 10, preventAdvance: true,
      pointerNone: true
    }
  ]
}

function getNewTutorialVoteDialogue(params = {}) {
  return [
    { text: "Welcome to voting!!" },
    { text: "Each vote is a matchup between two projects." },
    { 
      text: "Try the demo for each...",
      focus: `new-tutorial-vote-demo`,
      x: 0, y: 0, width: 30, height: 30, radius: 10, z: false
    },
    { 
      text: "And read the devlogs!",
      focus: `new-tutorial-vote-devlogs`,
      x: 0, y: 0, width: 30, height: 30, radius: 10, z: false
    },
    {
      text: "Pick a winner based on creativity, technicality, and storytelling."
    },
    {
      text: "Then, make a decision and write a few sentences about your choice.",
      action: "voteScrollEnd",
      focus: `new-tutorial-vote-decision`,
      x: 0, y: 0, width: 50, height: 50, radius: 10, z: false
    },
    {
      text: "Every vote matters, so be sure to vote thoughtfully!",
      focus: `new-tutorial-vote-decision`,
      x: 0, y: 0, width: 50, height: 50, radius: 10, z: false
    },
    { 
      text: "Low quality or randomly voting will be met with consequences.",
      focus: `new-tutorial-vote-decision`,
      x: 0, y: 0, width: 50, height: 50, radius: 10, z: false
    },
    {
      text: "If a project's demo doesn't work, or feels low effort. Use the report feature.",
      action: "voteScrollStart",
      focus: `new-tutorial-vote-report`,
      x: 0, y: 0, width: 30, height: 30, radius: 10, z: false
    },
    {
      text: "Our shipwrights will take a closer look.",
      focus: `new-tutorial-vote-report`,
      x: 0, y: 0, width: 30, height: 30, radius: 10, z: false
    },
    {
      text: "Please keep in mind that projects are never perfect.",
      focus: `new-tutorial-vote-report`,
      x: 0, y: 0, width: 30, height: 30, radius: 10, z: false
    },
    {
      text: "Projects can be simple, but they must demonstrate effort and creativity.",
      focus: `new-tutorial-vote-report`,
      x: 0, y: 0, width: 30, height: 30, radius: 10, z: false
    },
    {
      text: "Examples of low-effort are: copying a tutorial, AI generating the entire project...",
      focus: `new-tutorial-vote-report`,
      x: 0, y: 0, width: 30, height: 30, radius: 10, z: false
    },
    {
      text: "Or basic apps like todo lists without meaningful improvements.",
      focus: `new-tutorial-vote-report`,
      x: 0, y: 0, width: 30, height: 30, radius: 10, z: false
    },
    {
      text: "While you vote, other people will cast votes on your project too.",
    },
    {
      text: "Once you and your project are done with voting, you'll get your shells!"
    },
    {
      text: "The more votes for your project, the more shells you'll earn!"
    },
    {
      text: "That's enough yap for now. Get voting!"
    }
  ]
}