# Defines example shop items.
# This data is meant ONLY for development purposes to get a good idea of
# how things are gonna look like in production.

module MockShopItems
  SHOP_ITEMS = [
    {
      name: "Free Stickers!",
      type: "ShopItem::FreeStickers",
      description: "we'll actually send you these!",
      ticket_cost: 0.00,
      usd_cost: 3.00,
      hacker_score: 0,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "Spider",
      type: "ShopItem::BadgeItem",
      description: "buy a little guy who walks around on your screen all the time!",
      internal_description: "spider",
      ticket_cost: 5.00,
      usd_cost: 0.00,
      hacker_score: 0,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "Graphic design is my passion",
      type: "ShopItem::BadgeItem",
      description: "custom CSS for your profile!",
      internal_description: "graphic_design_is_my_passion",
      ticket_cost: 10.00,
      usd_cost: 0.00,
      hacker_score: 0,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "username flair",
      type: "ShopItem::SiteActionItem",
      description: "pink & comic sans! a match made in heaven!",
      ticket_cost: 15.00,
      usd_cost: 3.00,
      hacker_score: 50,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "preferred customer",
      type: "ShopItem::BadgeItem",
      description: "skip that annoying fucking loading dialog",
      internal_description: "preferred_customer",
      ticket_cost: 20.00,
      usd_cost: 0.00,
      hacker_score: 0,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "(FLASH SALE) Teardown",
      type: "ShopItem::ThirdPartyPhysical",
      description: "A one time deal for a copy of <a href=\"https://store.steampowered.com/app/1167630/?curator_clanid=4777282&utm_source=SteamDB\" target=\"_blank\"><u>Teardown</u></a> on Steam! You must have a Steam account.",
      ticket_cost: 20.00,
      usd_cost: 30.00,
      hacker_score: 0,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "Pile of Stickers",
      type: "ShopItem::LetterMail",
      description: "couple hack club branded stickers",
      ticket_cost: 25.00,
      usd_cost: 4.00,
      hacker_score: 25,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "random piece of paper from HQ?",
      type: "ShopItem::LetterMail",
      description: "might have secrets on it?",
      ticket_cost: 27.00,
      usd_cost: 5.00,
      hacker_score: 40,
      one_per_person_ever: false,
      show_in_carousel: false
    },
    {
      name: "kestrel heidi sticker sheet",
      type: "ShopItem::LetterMail",
      description: "categorically adorable",
      ticket_cost: 27.00,
      usd_cost: 6.00,
      hacker_score: 0,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "b o n g",
      type: "ShopItem::SiteActionItem",
      description: "play the taco bell bong on everyone's browser!",
      ticket_cost: 30.00,
      usd_cost: 0.00,
      hacker_score: 0,
      one_per_person_ever: false,
      show_in_carousel: false
    },
    {
      name: "TIS-100",
      type: "ShopItem::ThirdPartyPhysical",
      description: "asm but now in a fun game!",
      ticket_cost: 32.00,
      usd_cost: 7.00,
      hacker_score: 60,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Geometry Dash",
      type: "ShopItem::ThirdPartyPhysical",
      description: "cube jump haha (steam btw)",
      ticket_cost: 33.00,
      usd_cost: 5.00,
      hacker_score: 20,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "64GB USB Drive",
      type: "ShopItem::HQMailItem",
      description: "great for storing cat pictures",
      ticket_cost: 35.00,
      usd_cost: 7.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Cloudflare credits",
      type: "ShopItem::HCBGrant",
      description: "good luck bro im behind 7 reverse proxies",
      ticket_cost: 35.00,
      usd_cost: 10.00,
      hacker_score: 80,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "AI Usage Credits",
      type: "ShopItem::HCBGrant",
      description: "Credits for your favorite AI providers!",
      ticket_cost: 35.00,
      usd_cost: 10.00,
      hacker_score: 80,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Summer of Making Blue",
      type: "ShopItem::BadgeItem",
      description: "verify yourself for that premium feel!\\r                                                                                                                                                                                                            +",
      internal_description: "verified",
      ticket_cost: 40.00,
      usd_cost: 8.00,
      hacker_score: 50,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "Hot Glue Gun",
      type: "ShopItem::ThirdPartyPhysical",
      description: "it is a hot glue gun, nothing too special",
      ticket_cost: 41.00,
      usd_cost: 9.00,
      hacker_score: 60,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Domain grant",
      type: "ShopItem::HCBGrant",
      description: "RSVP your spot online! (this is a grant for 10$)",
      ticket_cost: 45.00,
      usd_cost: 10.00,
      hacker_score: 60,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "CH341A Programmer",
      type: "ShopItem::WarehouseItem",
      description: "flash? serial? PARALLEL? you got it, buddy.",
      ticket_cost: 47.00,
      usd_cost: 10.00,
      hacker_score: 55,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Server hosting credits",
      type: "ShopItem::HCBPreauthGrant",
      description: "Credits for your favorite hosting providers!",
      ticket_cost: 50.00,
      usd_cost: 10.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Orpheus Pico! (preorder)",
      type: "ShopItem::SpecialFulfillmentItem",
      description: "Hack Club's take on the Raspberry Pi Pico, you will need to solder it yourself",
      ticket_cost: 50.00,
      usd_cost: 10.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "128GB USB Drive",
      type: "ShopItem::ThirdPartyPhysical",
      description: "great for storing more cat pictures",
      ticket_cost: 50.00,
      usd_cost: 10.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Logic Analyzer",
      type: "ShopItem::HQMailItem",
      description: "Capture and analyze digital signals",
      ticket_cost: 50.00,
      usd_cost: 10.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Cat Printer",
      type: "ShopItem::WarehouseItem",
      description: "The printer does not go meow",
      ticket_cost: 55.00,
      usd_cost: 10.00,
      hacker_score: 40,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Pico-8 License",
      type: "ShopItem::ThirdPartyPhysical",
      description: "get the worlds best fantasy console now!",
      ticket_cost: 60.00,
      usd_cost: 15.00,
      hacker_score: 70,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Allen Wrench",
      type: "ShopItem::ThirdPartyPhysical",
      description: "They see me turnin, they hating...",
      ticket_cost: 67.00,
      usd_cost: 14.00,
      hacker_score: 55,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "family guy seasons 1 & 2 on dvd",
      type: "ShopItem::HQMailItem",
      description: "signed by zach latta – probably the only such object to exist",
      ticket_cost: 70.00,
      usd_cost: 10.00,
      hacker_score: 5,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "Digital Calipers",
      type: "ShopItem::ThirdPartyPhysical",
      description: "plastic, but fantastic!",
      ticket_cost: 77.00,
      usd_cost: 17.00,
      hacker_score: 60,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "E-Fidget",
      type: "ShopItem::HQMailItem",
      description: "The one and only haptic fidget toy, now mollusk-shaped!",
      ticket_cost: 79.00,
      usd_cost: 15.00,
      hacker_score: 45,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Voxatron License",
      type: "ShopItem::ThirdPartyPhysical",
      description: "voxel your voxels!",
      ticket_cost: 80.00,
      usd_cost: 20.00,
      hacker_score: 70,
      one_per_person_ever: false,
      show_in_carousel: false
    },
    {
      name: "Bloons TD 6 (Steam)",
      type: "ShopItem::ThirdPartyPhysical",
      description: "monkey pop ballon game",
      ticket_cost: 91.00,
      usd_cost: 14.00,
      hacker_score: 20,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Hydroneer",
      type: "ShopItem::ThirdPartyPhysical",
      description: "Fun mining game!",
      ticket_cost: 98.00,
      usd_cost: 15.00,
      hacker_score: 20,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Sunglasses",
      type: "ShopItem::BadgeItem",
      description: "protect yourself from custom profile CSS",
      internal_description: "sunglasses",
      ticket_cost: 100.00,
      usd_cost: 0.00,
      hacker_score: 0,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "Raspberry Pi Zero 2 W",
      type: "ShopItem::ThirdPartyPhysical",
      description: "computing on a budget!",
      ticket_cost: 100.00,
      usd_cost: 22.00,
      hacker_score: 60,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "sketch from msw",
      type: "ShopItem::SpecialFulfillmentItem",
      description: "Personal drawing by a staff member here at HQ",
      ticket_cost: 100.00,
      usd_cost: 10.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: false
    },
    {
      name: "Pocket Watcher",
      type: "ShopItem::BadgeItem",
      description: "view other users' shell balances!",
      internal_description: "pocket_watcher",
      ticket_cost: 100.00,
      usd_cost: 0.00,
      hacker_score: 0,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "cwalker toe pic card (signed)",
      type: "ShopItem::LetterMail",
      description: "3-track magstripe for all your swiping-related needs",
      ticket_cost: 100.00,
      usd_cost: 20.00,
      hacker_score: 0,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "DigiKey/LCSC Credit",
      type: "ShopItem::HCBGrant",
      description: "Order anything for your hardware projects, possibilities are endless!",
      ticket_cost: 100.00,
      usd_cost: 20.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "256GB USB Drive",
      type: "ShopItem::ThirdPartyPhysical",
      description: "great for storing even more cat pictures",
      ticket_cost: 100.00,
      usd_cost: 20.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "20 bucks in Framework credit",
      type: "ShopItem::HCBGrant",
      description: "expand your horizons...? expansion card? get it?",
      ticket_cost: 103.00,
      usd_cost: 20.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: false
    },
    {
      name: "256GB microSD card + adapter",
      type: "ShopItem::ThirdPartyPhysical",
      description: "this thing can fit so many cat pictures",
      ticket_cost: 110.00,
      usd_cost: 22.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Smolhaj",
      type: "ShopItem::HQMailItem",
      description: "friend shark",
      ticket_cost: 111.00,
      usd_cost: 15.00,
      hacker_score: 1,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "USB C Cable + Wall Adapter",
      type: "ShopItem::ThirdPartyPhysical",
      description: "charge up your device, send cat pictures, etc",
      ticket_cost: 120.00,
      usd_cost: 20.00,
      hacker_score: 30,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Bambu Lab Credits",
      type: "ShopItem::HCBGrant",
      description: "Do you have a Bambu but no filament? Or do you want AMS? You can purchase it all!",
      ticket_cost: 130.00,
      usd_cost: 20.00,
      hacker_score: 20,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Qiyi XMD XT3 speedcube",
      type: "ShopItem::ThirdPartyPhysical",
      description: "this is nora's favorite cube, and we are now selling it",
      ticket_cost: 132.00,
      usd_cost: 25.00,
      hacker_score: 45,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Dupont Crimping Tool Kit",
      type: "ShopItem::ThirdPartyPhysical",
      description: "This tool has three crimping cavities in one tool with color-coded wire markings for three size ranges of insulated terminals",
      ticket_cost: 137.00,
      usd_cost: 25.00,
      hacker_score: 40,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "shapez 2",
      type: "ShopItem::ThirdPartyPhysical",
      description: "Dive into a factory-building game with the focus on just that – building huge space factories!",
      ticket_cost: 137.00,
      usd_cost: 25.00,
      hacker_score: 40,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Pinecil",
      type: "ShopItem::WarehouseItem",
      description: "64 whole pines!",
      ticket_cost: 144.00,
      usd_cost: 27.79,
      hacker_score: 60,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Offshore Bank Account",
      type: "ShopItem::BadgeItem",
      description: "hide your shell balance from users with \"pocket watcher\"",
      internal_description: "offshore_bank_account",
      ticket_cost: 150.00,
      usd_cost: 0.00,
      hacker_score: 0,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "a physical copy of why's (poignant) guide to ruby",
      type: "ShopItem::HQMailItem",
      description: "nora thinks you should read this book",
      ticket_cost: 150.00,
      usd_cost: 30.00,
      hacker_score: 50,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "Gold Verified",
      type: "ShopItem::BadgeItem",
      description: "Upgrade your verification status with this exclusive gold checkmark badge.",
      internal_description: "gold_verified",
      ticket_cost: 160.00,
      usd_cost: 32.00,
      hacker_score: 50,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "25 bucks in IKEA credit",
      type: "ShopItem::HCBGrant",
      description: "get a BLÅVINGAD... or an AFTONSPARV...or a DJUNGELSKOG..or maybe some furniture? idk",
      ticket_cost: 170.00,
      usd_cost: 25.00,
      hacker_score: 15,
      one_per_person_ever: false,
      show_in_carousel: false
    },
    {
      name: "Lexaloffle Games bundle",
      type: "ShopItem::ThirdPartyPhysical",
      description: "Get Pico-8, Picotron, and Voxatron all in one cute bundle!",
      ticket_cost: 175.00,
      usd_cost: 39.00,
      hacker_score: 60,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Factorio",
      type: "ShopItem::ThirdPartyPhysical",
      description: "ah where did the past 5 hours go?",
      ticket_cost: 175.00,
      usd_cost: 35.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Brother Label Maker",
      type: "ShopItem::ThirdPartyPhysical",
      description: "Easy, simple, portable label maker, perfect for silly labels to place anywhere!",
      ticket_cost: 180.00,
      usd_cost: 40.00,
      hacker_score: 60,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Mullvad VPN 6 Month Voucher",
      type: "ShopItem::ThirdPartyPhysical",
      description: "the worlds best vpn for privacy online!",
      ticket_cost: 216.00,
      usd_cost: 32.00,
      hacker_score: 15,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Squishmallow",
      type: "ShopItem::HCBPreauthGrant",
      description: "because whatever the heck nowadays",
      ticket_cost: 220.00,
      usd_cost: 30.00,
      hacker_score: 4,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "full-size blahaj.",
      type: "ShopItem::HQMailItem",
      description: "even more shark to hug!",
      ticket_cost: 222.00,
      usd_cost: 30.00,
      hacker_score: 1,
      one_per_person_ever: false,
      show_in_carousel: false
    },
    {
      name: "Proxmark 3 Easy",
      type: "ShopItem::ThirdPartyPhysical",
      description: "RFID cloning device",
      ticket_cost: 225.00,
      usd_cost: 60.00,
      hacker_score: 75,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Satisfactory",
      type: "ShopItem::ThirdPartyPhysical",
      description: "best factory game with belts, pipes, trains, and belts, and more belts... most addictive yet!",
      ticket_cost: 260.00,
      usd_cost: 40.00,
      hacker_score: 20,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Yubikey USB-A",
      type: "ShopItem::HQMailItem",
      description: "Hardware backed 2FA",
      ticket_cost: 300.00,
      usd_cost: 50.00,
      hacker_score: 30,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Waveshare 7.5inch E-Ink Display",
      type: "ShopItem::ThirdPartyPhysical",
      description: "(comes with controller pcb, not a pi) refresh rates starting at 0.2hz",
      ticket_cost: 302.00,
      usd_cost: 67.00,
      hacker_score: 60,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Baofeng UV-5R (2 pack)",
      type: "ShopItem::ThirdPartyPhysical",
      description: "Portable radio, requires a HAM license to operate in some regions",
      ticket_cost: 323.00,
      usd_cost: 68.00,
      hacker_score: 55,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Yubikey USB-C",
      type: "ShopItem::HQMailItem",
      description: "The cooler Hardware backed 2FA",
      ticket_cost: 330.00,
      usd_cost: 55.00,
      hacker_score: 30,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "min(amame) Parts Kit",
      type: "ShopItem::ThirdPartyPhysical",
      description: "DIY Headphones Kit",
      ticket_cost: 335.00,
      usd_cost: 67.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: false
    },
    {
      name: "CMF Buds Pro 2",
      type: "ShopItem::ThirdPartyPhysical",
      description: "nothing to hear here!",
      ticket_cost: 360.00,
      usd_cost: 60.00,
      hacker_score: 30,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Seagate 2TB external HDD",
      type: "ShopItem::ThirdPartyPhysical",
      description: "great for storing all of the cat pictures you could ever need",
      ticket_cost: 467.00,
      usd_cost: 85.00,
      hacker_score: 40,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Logitech MX Master 3S",
      type: "ShopItem::HQMailItem",
      description: "Wireless, quiet, and full of buttons!",
      ticket_cost: 570.00,
      usd_cost: 120.00,
      hacker_score: 55,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Thermal Imager",
      type: "ShopItem::HQMailItem",
      description: "for repair! or fun... pretty high res?",
      ticket_cost: 580.00,
      usd_cost: 115.00,
      hacker_score: 50,
      one_per_person_ever: true,
      show_in_carousel: true
    },
    {
      name: "K4 desktop laser engraver",
      type: "ShopItem::HQMailItem",
      description: "the diode's kinda wimpy...the software REALLY sucks...could *you* be the one to solve these problems?",
      ticket_cost: 600.00,
      usd_cost: 125.00,
      hacker_score: 54,
      one_per_person_ever: true,
      show_in_carousel: true
    },
    {
      name: "Raspberry Pi 5",
      type: "ShopItem::ThirdPartyPhysical",
      description: "Does not come with power adapter or SD card",
      ticket_cost: 607.00,
      usd_cost: 135.00,
      hacker_score: 60,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "head(amame) Parts Kit",
      type: "ShopItem::ThirdPartyPhysical",
      description: "DIY Overear Headphones kit",
      ticket_cost: 650.00,
      usd_cost: 130.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: false
    },
    {
      name: "Glasgow Interface Explorer",
      type: "ShopItem::ThirdPartyPhysical",
      description: "thingy",
      ticket_cost: 712.00,
      usd_cost: 190.00,
      hacker_score: 75,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Logitech G Pro X Superlight",
      type: "ShopItem::ThirdPartyPhysical",
      description: "super high quality mouse used by your favorite gamers",
      ticket_cost: 750.00,
      usd_cost: 150.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "XPPen Deco Pro MW",
      type: "ShopItem::ThirdPartyPhysical",
      description: "perfect for artists! nice and big, make it your canvas!",
      ticket_cost: 770.00,
      usd_cost: 140.00,
      hacker_score: 40,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Flipper Zero",
      type: "ShopItem::ThirdPartyPhysical",
      description: "Flipper Zero is a portable multi-tool for pentesters and geeks in a toy-like body, dolphins included",
      ticket_cost: 950.00,
      usd_cost: 200.00,
      hacker_score: 55,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "I am Rich",
      type: "ShopItem::BadgeItem",
      description: "just as useful as the iOS app!",
      internal_description: "i_am_rich",
      ticket_cost: 1000.00,
      usd_cost: 0.00,
      hacker_score: 0,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "Bose QuietComfort 45",
      type: "ShopItem::ThirdPartyPhysical",
      description: "best in class bluetooth headphones!",
      ticket_cost: 1020.00,
      usd_cost: 170.00,
      hacker_score: 30,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Cricut Explore 3",
      type: "ShopItem::ThirdPartyPhysical",
      description: "Cricut Explore 3 cuts, draws, scores, and more with speed and precision, letting you make better art, and faster",
      ticket_cost: 1125.00,
      usd_cost: 300.00,
      hacker_score: 75,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Bambu A1 mini Printer",
      type: "ShopItem::ThirdPartyPhysical",
      description: "print your wildest dreams! or that one squid with the rock head",
      ticket_cost: 1125.00,
      usd_cost: 250.00,
      hacker_score: 55,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Playdate",
      type: "ShopItem::ThirdPartyPhysical",
      description: "Small portable game console",
      ticket_cost: 1265.00,
      usd_cost: 230.00,
      hacker_score: 40,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "AirPods Pro 2",
      type: "ShopItem::ThirdPartyPhysical",
      description: "tic tacs but for your ears!",
      ticket_cost: 1500.00,
      usd_cost: 250.00,
      hacker_score: 30,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "100MHZ Oscilloscope",
      type: "ShopItem::ThirdPartyPhysical",
      description: "Siglent <a href=\"https://siglentna.com/wp-content/uploads/dlm_uploads/2021/04/SDS1000CMLplus_DataSheet_DS0101A-E03A.pdf\" target=\"_blank\"><u>SDS1102CML+</u></a>",
      ticket_cost: 1507.00,
      usd_cost: 335.00,
      hacker_score: 60,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "ThinkPad X1 Carbon 6th Gen (Renewed)",
      type: "ShopItem::ThirdPartyPhysical",
      description: "i5 8350U 1.70GHz 8GB RAM 256GB SSD 14\" FHD Win 11",
      ticket_cost: 1540.00,
      usd_cost: 280.00,
      hacker_score: 40,
      one_per_person_ever: true,
      show_in_carousel: true
    },
    {
      name: "CMF Phone 2 Pro (White)",
      type: "ShopItem::ThirdPartyPhysical",
      description: "semi repairable phone in this economy?",
      ticket_cost: 1540.00,
      usd_cost: 280.00,
      hacker_score: 40,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "CMF Phone 2 Pro (Black)",
      type: "ShopItem::ThirdPartyPhysical",
      description: "semi repairable phone in this economy?",
      ticket_cost: 1540.00,
      usd_cost: 280.00,
      hacker_score: 40,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Lenovo ThinkPad T14 14\" Laptop",
      type: "ShopItem::ThirdPartyPhysical",
      description: "i5, 16GB RAM, 512GB SSD, Win11 Pro (Renewed)",
      ticket_cost: 1740.00,
      usd_cost: 290.00,
      hacker_score: 30,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Bambu Labs A1",
      type: "ShopItem::ThirdPartyPhysical",
      description: "for when you need to print things that aren't mini...",
      ticket_cost: 1750.00,
      usd_cost: 350.00,
      hacker_score: 50,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "$500 in Amp credit",
      type: "ShopItem::SpecialFulfillmentItem",
      description: "use the coding agent a good chunk of this platform was made with!",
      ticket_cost: 1750.00,
      usd_cost: 350.00,
      hacker_score: 50,
      one_per_person_ever: true,
      show_in_carousel: false
    },
    {
      name: "Lenovo Thinkpad X1 Carbon Gen 8 (Refurbished)",
      type: "ShopItem::ThirdPartyPhysical",
      description: "14\" FHD, Intel Core i7-10610, 16GB DDR4 RAM, 512GB SSD",
      ticket_cost: 1800.00,
      usd_cost: 300.00,
      hacker_score: 30,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Nebula.tv Lifetime subscription",
      type: "ShopItem::ThirdPartyPhysical",
      description: "Binge the best that your creators have to offer!",
      ticket_cost: 1800.00,
      usd_cost: 300.00,
      hacker_score: 30,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Lenovo V15 AMD Ryzen 7 7730U 15.6\"",
      type: "ShopItem::ThirdPartyPhysical",
      description: "economy laptop for india!",
      ticket_cost: 2550.00,
      usd_cost: 510.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "iPad + Apple Pencil",
      type: "ShopItem::ThirdPartyPhysical",
      description: "iPad A16 + Apple Pencil 1st gen",
      ticket_cost: 3400.00,
      usd_cost: 680.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Steam Deck 512GB OLED",
      type: "ShopItem::ThirdPartyPhysical",
      description: "At least its cheaper than the switch 2!",
      ticket_cost: 3540.00,
      usd_cost: 590.00,
      hacker_score: 30,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "HP Victus, AMD Ryzen 5 5600H, NVIDIA RTX 3050",
      type: "ShopItem::SpecialFulfillmentItem",
      description: "midrange laptop for my friends in india!",
      ticket_cost: 3600.00,
      usd_cost: 720.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "M4 Mac Mini",
      type: "ShopItem::ThirdPartyPhysical",
      description: "16GB Memory, 256GB SSD Storage",
      ticket_cost: 4050.00,
      usd_cost: 810.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "Framework Laptop 12",
      type: "ShopItem::HCBGrant",
      description: "DIY Edition, i3-1315U, 16GB Ram, 500GB Storage + 4 assorted expansion cards!",
      ticket_cost: 4499.00,
      usd_cost: 950.00,
      hacker_score: 55,
      one_per_person_ever: true,
      show_in_carousel: true
    },
    {
      name: "Prusa MK4S 3D Printer",
      type: "ShopItem::ThirdPartyPhysical",
      description: "One of the best 3D printers, useful for any creative",
      ticket_cost: 5000.00,
      usd_cost: 1000.00,
      hacker_score: 50,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "13-inch M4 MacBook Air",
      type: "ShopItem::ThirdPartyPhysical",
      description: "16GB of memory and 256GB SSD, all in a lightweight form factor!",
      ticket_cost: 5512.00,
      usd_cost: 1050.00,
      hacker_score: 45,
      one_per_person_ever: false,
      show_in_carousel: true
    },
    {
      name: "MacBook Pro",
      type: "ShopItem::ThirdPartyPhysical",
      description: "M4 14\", 16GB/1TB",
      ticket_cost: 8995.00,
      usd_cost: 1799.00,
      hacker_score: 50,
      one_per_person_ever: true,
      show_in_carousel: true
    }
  ]
end
