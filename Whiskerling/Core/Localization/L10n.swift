import Foundation

/// Every piece of text the player sees. English is the development language; Danish lives in
/// `Localizable.xcstrings`. Keep keys stable: the catalog is matched on them.
enum L10n {
    // MARK: Actions and HUD
    static var feed: String { String(localized: "action.feed", defaultValue: "Feed") }
    static var play: String { String(localized: "action.play", defaultValue: "Play") }
    static var wash: String { String(localized: "action.wash", defaultValue: "Wash") }
    static var sleep: String { String(localized: "action.sleep", defaultValue: "Sleep") }
    static var lightsOn: String { String(localized: "action.lightsOn", defaultValue: "Lights on") }
    static var dressUp: String { String(localized: "action.dressUp", defaultValue: "Dress up") }
    static var done: String { String(localized: "action.done", defaultValue: "Done") }
    static var close: String { String(localized: "action.close", defaultValue: "Close") }

    static var meterFood: String { String(localized: "meter.food", defaultValue: "Full") }
    static var meterFun: String { String(localized: "meter.fun", defaultValue: "Happy") }
    static var meterEnergy: String { String(localized: "meter.energy", defaultValue: "Energy") }
    static var meterClean: String { String(localized: "meter.clean", defaultValue: "Clean") }
    static var soundOn: String { String(localized: "hud.soundOn", defaultValue: "Sound on") }
    static var soundOff: String { String(localized: "hud.soundOff", defaultValue: "Sound off") }
    static func hearts(_ n: Int) -> String { String(localized: "hud.hearts", defaultValue: "\(n) hearts") }
    static func stageDay(_ stage: String, _ day: Int) -> String {
        String(localized: "hud.stageDay", defaultValue: "\(stage) · day \(day)")
    }

    static func stageName(_ index: Int) -> String {
        switch index {
        case 0: return String(localized: "stage.kitten", defaultValue: "Kitten")
        case 1: return String(localized: "stage.young", defaultValue: "Young cat")
        default: return String(localized: "stage.adult", defaultValue: "Grown-up cat")
        }
    }

    static func coatName(_ id: String) -> String {
        switch id {
        case "orange": return String(localized: "coat.orange", defaultValue: "Ginger")
        case "gray": return String(localized: "coat.gray", defaultValue: "Grey")
        case "black": return String(localized: "coat.black", defaultValue: "Black")
        case "white": return String(localized: "coat.white", defaultValue: "White")
        case "tabby": return String(localized: "coat.tabby", defaultValue: "Tabby")
        case "tuxedo": return String(localized: "coat.tuxedo", defaultValue: "Tuxedo")
        case "siamese": return String(localized: "coat.siamese", defaultValue: "Siamese")
        case "gingerwhite": return String(localized: "coat.gingerwhite", defaultValue: "Ginger and white")
        default: return String(localized: "coat.calico", defaultValue: "Calico")
        }
    }

    static func decorName(_ id: String) -> String {
        switch id {
        case "plant": return String(localized: "decor.plant", defaultValue: "Plant")
        case "rug": return String(localized: "decor.rug", defaultValue: "Pink rug")
        case "cattree": return String(localized: "decor.cattree", defaultValue: "Cat tree")
        case "wallpaper": return String(localized: "decor.wallpaper", defaultValue: "Heart wallpaper")
        case "portrait": return String(localized: "decor.portrait", defaultValue: "Cat picture")
        default: return String(localized: "decor.lights", defaultValue: "Fairy lights")
        }
    }

    static func itemName(_ id: String) -> String {
        switch id {
        case "bow": return String(localized: "item.bow", defaultValue: "Bow")
        case "bell": return String(localized: "item.bell", defaultValue: "Bell")
        case "flowers": return String(localized: "item.flowers", defaultValue: "Flowers")
        case "glasses": return String(localized: "item.glasses", defaultValue: "Sunglasses")
        case "hat": return String(localized: "item.hat", defaultValue: "Top hat")
        case "scarf": return String(localized: "item.scarf", defaultValue: "Scarf")
        default: return String(localized: "item.crown", defaultValue: "Crown")
        }
    }

    // MARK: Food
    static func foodTitle(_ name: String) -> String { String(localized: "food.title", defaultValue: "What should \(name) have?") }
    static func foodName(_ food: Food) -> String {
        switch food {
        case .kibble: return String(localized: "food.kibble", defaultValue: "Kibble")
        case .fish: return String(localized: "food.fish", defaultValue: "Fish")
        case .shrimp: return String(localized: "food.shrimp", defaultValue: "Shrimp")
        case .cookie: return String(localized: "food.cookie", defaultValue: "Fish cookies")
        }
    }
    static func foodNote(_ food: Food) -> String {
        switch food {
        case .kibble: return String(localized: "food.kibble.note", defaultValue: "A little filling")
        case .fish: return String(localized: "food.fish.note", defaultValue: "Very filling")
        case .shrimp: return String(localized: "food.shrimp.note", defaultValue: "A treat, makes them happy")
        case .cookie: return cookieNote(0)
        }
    }
    static func cookieNote(_ n: Int) -> String {
        String(localized: "food.cookie.note", defaultValue: "Baked in the kitchen, \(n) in the jar")
    }

    // MARK: Garden and games
    static var garden: String { String(localized: "action.garden", defaultValue: "Garden") }
    // the rooms and the kitchen (#38)
    static var goTo: String { String(localized: "action.goTo", defaultValue: "Go to") }
    static func roomsTitle(_ name: String) -> String { String(localized: "rooms.title", defaultValue: "Where shall \(name) go?") }
    static var livingRoom: String { String(localized: "rooms.living", defaultValue: "The living room") }
    static var livingRoomNote: String { String(localized: "rooms.living.note", defaultValue: "Bowl, basket and litter box") }
    static var kitchen: String { String(localized: "rooms.kitchen", defaultValue: "The kitchen") }
    static var kitchenNote: String { String(localized: "rooms.kitchen.note", defaultValue: "Bake fish cookies") }
    static var gardenRoom: String { String(localized: "rooms.garden", defaultValue: "The garden") }
    static var gardenNote: String { String(localized: "rooms.garden.note", defaultValue: "The pond and the apple tree") }
    static var youAreHere: String { String(localized: "rooms.here", defaultValue: "You're here") }
    static var kitchenHello: String { String(localized: "say.kitchen", defaultValue: "Shall we bake? Tap the bowl! 🍪") }
    static var fridgeLine: String { String(localized: "say.fridge", defaultValue: "Anything for me in there? 🐟") }
    static var stoleCookie: String { String(localized: "say.stoleCookie", defaultValue: "Mmm, a cookie! 🍪") }
    static var jarFull: String { String(localized: "say.jarFull", defaultValue: "The jar is full of cookies! 🍪") }
    static var bakeStart: String { String(localized: "say.bakeStart", defaultValue: "Let's bake! 🍪") }
    static var bakeBye: String { String(localized: "say.bakeBye", defaultValue: "Fish cookies! Yum 😺") }
    static var bakeHintIngredients: String { String(localized: "hint.bake.ingredients", defaultValue: "Tap the fish and the flour!") }
    static var bakeHintStir: String { String(localized: "hint.bake.stir", defaultValue: "Stir round and round in the bowl!") }
    static var bakeHintCut: String { String(localized: "hint.bake.cut", defaultValue: "Tap the dough to cut out fish!") }
    static var bakeHintOven: String { String(localized: "hint.bake.oven", defaultValue: "Tap the tray to put it in the oven!") }
    static var bakeHintBaking: String { String(localized: "hint.bake.baking", defaultValue: "Baking… it smells good!") }
    static var bakeHintDone: String { String(localized: "hint.bake.done", defaultValue: "Ready! Into the jar they go.") }
    static func cookiesInJar(_ n: Int) -> String {
        String(localized: "toast.cookies", defaultValue: "\(n) fish cookies in the jar! 🍪")
    }
    static var indoors: String { String(localized: "action.indoors", defaultValue: "Indoors") }
    static func gamesTitle(_ name: String) -> String { String(localized: "games.title", defaultValue: "What shall \(name) play?") }
    static var featherGame: String { String(localized: "games.feather", defaultValue: "The feather") }
    static var featherGameNote: String { String(localized: "games.feather.note", defaultValue: "Drag it around") }
    static var fishGame: String { String(localized: "games.fish", defaultValue: "Catch the fish") }
    static var fishGameNote: String { String(localized: "games.fish.note", defaultValue: "At the garden pond") }
    static var fishHint: String { String(localized: "hint.fish", defaultValue: "Tap the fish when they jump!") }
    static var hideGame: String { String(localized: "games.hide", defaultValue: "Hide and seek") }
    static var hideGameNote: String { String(localized: "games.hide.note", defaultValue: "Find the cat") }
    static func hideHint(_ name: String) -> String {
        String(localized: "hint.hide", defaultValue: "Find \(name)! Look for a tail or two ears.")
    }
    static func hideResult(_ name: String, _ n: Int) -> String {
        String(localized: "toast.hideResult", defaultValue: "You found \(name) \(n) times! 🙈")
    }
    static func fishResult(_ name: String, _ n: Int) -> String {
        String(localized: "toast.fishResult", defaultValue: "\(name) caught \(n) fish! 🐟")
    }

    // MARK: Wardrobe
    static var wardrobeTitle: String { String(localized: "wardrobe.title", defaultValue: "Dress up your cat") }
    static func wardrobeInfo(_ hearts: Int, _ name: String) -> String {
        String(localized: "wardrobe.info", defaultValue: "You have \(hearts) ❤️. Take good care of \(name) to earn more.")
    }
    static var wardrobeCoats: String { String(localized: "wardrobe.coats", defaultValue: "Coat") }
    static var wardrobeItems: String { String(localized: "wardrobe.items", defaultValue: "Accessories") }
    static var wear: String { String(localized: "wardrobe.wear", defaultValue: "Put on") }
    static var takeOff: String { String(localized: "wardrobe.takeOff", defaultValue: "Take off") }
    static var wearing: String { String(localized: "wardrobe.wearing", defaultValue: "Wearing") }
    static var wardrobeRoom: String { String(localized: "wardrobe.room", defaultValue: "The room") }
    static var putUp: String { String(localized: "wardrobe.putUp", defaultValue: "Add") }
    static var takeDown: String { String(localized: "wardrobe.takeDown", defaultValue: "Take away") }
    static func needHearts(_ n: Int) -> String { String(localized: "wardrobe.needHearts", defaultValue: "You need \(n) ❤️ for that one") }
    static var pro: String { String(localized: "badge.pro", defaultValue: "Pro") }
    static var askGrownUp: String { String(localized: "badge.askGrownUp", defaultValue: "Ask a grown-up") }

    // MARK: Start
    static var chooseKitten: String { String(localized: "start.choose", defaultValue: "Choose your kitten") }
    static var nameQuestion: String { String(localized: "start.nameQuestion", defaultValue: "What will you call it?") }
    static var namePlaceholder: String { String(localized: "start.namePlaceholder", defaultValue: "Kitty") }
    static var bringHome: String { String(localized: "start.bringHome", defaultValue: "Bring the kitten home 🏠") }

    // MARK: Grown-ups
    static var forGrownUps: String { String(localized: "gate.title", defaultValue: "For grown-ups") }
    static func gateQuestion(_ a: Int, _ b: Int) -> String { String(localized: "gate.question", defaultValue: "What is \(a) × \(b)?") }
    static var gateWrong: String { String(localized: "gate.wrong", defaultValue: "Wrong answer. Try again.") }
    static var ok: String { String(localized: "gate.ok", defaultValue: "OK") }
    static var cancel: String { String(localized: "gate.cancel", defaultValue: "Cancel") }

    static var menuTitle: String { String(localized: "menu.title", defaultValue: "Settings for grown-ups") }
    static func menuInfo(_ name: String, _ day: Int, _ hearts: Int) -> String {
        String(localized: "menu.info", defaultValue: "\(name) is on day \(day) and has \(hearts) ❤️.")
    }
    static var sendFeedback: String { String(localized: "menu.feedback", defaultValue: "Send feedback") }
    static var rateApp: String { String(localized: "menu.rate", defaultValue: "Rate Whiskerling") }
    static var privacyPolicy: String { String(localized: "menu.privacy", defaultValue: "Privacy policy") }
    static var feedbackNote: String {
        String(localized: "menu.feedbackNote",
               defaultValue: "Feedback opens an email to support@iamjarl.com with the app and iPadOS version filled in. Nothing is sent until you send it.")
    }
    static var menuSoundOn: String { String(localized: "menu.soundOn", defaultValue: "Sound: on") }
    static var menuSoundOff: String { String(localized: "menu.soundOff", defaultValue: "Sound: off") }
    static var startOver: String { String(localized: "menu.startOver", defaultValue: "Start over with a new cat") }
    static func twoNames(_ first: String, _ second: String) -> String { String(localized: "menu.twoNames", defaultValue: "\(first) and \(second)") }
    static func startOverConfirm(_ name: String) -> String {
        String(localized: "menu.startOverConfirm", defaultValue: "Are you sure? Tap again to say goodbye to \(name).")
    }

    // MARK: Pro
    static var proTitle: String { String(localized: "pro.title", defaultValue: "Whiskerling Pro") }
    static var proSubtitle: String { String(localized: "pro.subtitle", defaultValue: "Unlock everything, once and for all.") }
    static var proCoatsTitle: String { String(localized: "pro.coats.title", defaultValue: "All nine coats") }
    static var proCoatsBody: String { String(localized: "pro.coats.body", defaultValue: "Ginger, ginger and white, grey, black, tuxedo, white, tabby, calico and Siamese.") }
    static var proItemsTitle: String { String(localized: "pro.items.title", defaultValue: "All the accessories and the room") }
    static var proItemsBody: String {
        String(localized: "pro.items.body", defaultValue: "Flowers, sunglasses, top hat, scarf and crown, and for the room a cat tree, heart wallpaper, a picture of the cat and fairy lights. They still unlock with hearts.")
    }
    static var proGardenTitle: String { String(localized: "pro.garden.title", defaultValue: "The garden, the kitchen and two games") }
    static var proGardenBody: String {
        String(localized: "pro.garden.body", defaultValue: "A garden with a pond, a tree and butterflies, a kitchen to bake fish cookies in, and the games Catch the fish and Hide and seek.")
    }
    static var proSecondCatTitle: String { String(localized: "pro.secondCat.title", defaultValue: "A second cat") }
    static var proSecondCatBody: String {
        String(localized: "pro.secondCat.body", defaultValue: "Once the first cat is grown up, a kitten can come to live with it.")
    }
    static var adoptButton: String { String(localized: "adopt.button", defaultValue: "A kitten to live with your cat") }
    static func adoptTitle(_ name: String) -> String {
        String(localized: "adopt.title", defaultValue: "Choose a kitten to live with \(name)")
    }
    static var adoptCancel: String { String(localized: "adopt.cancel", defaultValue: "Not now") }
    static func showCat(_ name: String) -> String { String(localized: "adopt.show", defaultValue: "Show \(name)") }
    static func newFriend(_ name: String) -> String { String(localized: "say.newFriend", defaultValue: "Hi, \(name)! Welcome home 😺") }
    static func adopted(_ name: String, _ friend: String) -> String {
        String(localized: "toast.adopted", defaultValue: "\(name) has come to live with \(friend)! 🏠")
    }
    static var proFutureTitle: String { String(localized: "pro.future.title", defaultValue: "More to come") }
    static var proFutureBody: String {
        String(localized: "pro.future.body", defaultValue: "Future additions to Pro, like new cats and games, are included.")
    }
    static var proPrivateTitle: String { String(localized: "pro.private.title", defaultValue: "Still private") }
    static var proPrivateBody: String {
        String(localized: "pro.private.body", defaultValue: "One payment. No subscription, no ads, no accounts. Everything stays on this iPad.")
    }
    static func unlockPro(_ price: String) -> String { String(localized: "pro.unlockPrice", defaultValue: "Unlock Pro · \(price)") }
    static var unlockProPlain: String { String(localized: "pro.unlock", defaultValue: "Unlock Pro") }
    static var restore: String { String(localized: "pro.restore", defaultValue: "Restore purchase") }
    static var notNow: String { String(localized: "pro.notNow", defaultValue: "Not now") }
    static var proUnlocked: String { String(localized: "pro.unlocked", defaultValue: "Pro is unlocked. Thank you!") }
    static var storeOffline: String {
        String(localized: "pro.offline", defaultValue: "Couldn't reach the App Store. Check the connection and try again.")
    }
    static var tryAgain: String { String(localized: "pro.tryAgain", defaultValue: "Try again") }
    static var purchasePending: String { String(localized: "pro.pending", defaultValue: "The purchase is waiting for approval.") }
    static var purchaseUnverified: String { String(localized: "pro.unverified", defaultValue: "The purchase couldn't be verified.") }
    static var purchaseFailed: String { String(localized: "pro.failed", defaultValue: "The purchase didn't go through.") }
    static var purchaseTitle: String { String(localized: "pro.alertTitle", defaultValue: "Purchase") }

    // MARK: Toasts
    static var dailyGift: String { String(localized: "toast.daily", defaultValue: "Today's gift: +3 ❤️") }
    static func decorUnlocked(_ label: String) -> String { String(localized: "toast.decorUnlocked", defaultValue: "New for the room: \(label)!") }
    static func itemUnlocked(_ label: String) -> String { String(localized: "toast.itemUnlocked", defaultValue: "New accessory unlocked: \(label)!") }
    static func grewYoung(_ name: String) -> String { String(localized: "toast.grewYoung", defaultValue: "\(name) is a young cat now! 🎉") }
    static func grewAdult(_ name: String) -> String { String(localized: "toast.grewAdult", defaultValue: "\(name) is a grown-up cat now! 🎉") }
    static func petTip(_ name: String) -> String { String(localized: "toast.petTip", defaultValue: "Tip: Stroke \(name) to give a cuddle 🐾") }
    static func asleep(_ name: String) -> String { String(localized: "toast.asleep", defaultValue: "\(name) is asleep. Turn on the light first ☀️") }

    // MARK: Mode hints
    static func playHint(_ name: String) -> String { String(localized: "hint.play", defaultValue: "Drag the feather around. Can \(name) catch it?") }
    static func washHint(_ name: String) -> String { String(localized: "hint.wash", defaultValue: "Scrub \(name) with the sponge!") }
    static func washLitterHint(_ name: String) -> String {
        String(localized: "hint.washLitter", defaultValue: "Scrub \(name) with the sponge, and tap the litter box!")
    }

    // MARK: What the cat says
    static func hello(_ name: String) -> String { String(localized: "say.hello", defaultValue: "Hi! My name is \(name)! 🐾") }
    static var hungry: String { String(localized: "say.hungry", defaultValue: "I'm hungry! 🐟") }
    static var tired: String { String(localized: "say.tired", defaultValue: "I'm so tired… 💤") }
    static var dirty: String { String(localized: "say.dirty", defaultValue: "I need a bath! 🛁") }
    static var bored: String { String(localized: "say.bored", defaultValue: "Will you play with me? 🧶") }
    static var litterSmells: String { String(localized: "say.litterSmells", defaultValue: "The litter box smells! 💩") }
    static var bedtime: String { String(localized: "say.bedtime", defaultValue: "It's bedtime… 🌙") }
    static var happyLines: [String] {
        [String(localized: "say.happy1", defaultValue: "Meow! ❤️"),
         String(localized: "say.happy2", defaultValue: "Purrr…"),
         String(localized: "say.happy3", defaultValue: "I love you! ❤️"),
         String(localized: "say.happy4", defaultValue: "What shall we do now?"),
         String(localized: "say.happy5", defaultValue: "I'm so happy today! 😸"),
         String(localized: "say.happy6", defaultValue: "Meow meow!")]
    }
    static var tapLines: [String] {
        [String(localized: "say.tap1", defaultValue: "Meow! ❤️"),
         String(localized: "say.tap2", defaultValue: "Meow!"),
         String(localized: "say.tap3", defaultValue: "Purr… 😺"),
         String(localized: "say.tap4", defaultValue: "Hello there!")]
    }
    static var zzz: String { String(localized: "say.zzz", defaultValue: "Zzz…") }
    static var full: String { String(localized: "say.full", defaultValue: "I'm completely full! 😸") }
    static var noMoreTreats: String { String(localized: "say.noMoreTreats", defaultValue: "No more treats right now 😸") }
    static var ateLines: [String] {
        [String(localized: "say.ate1", defaultValue: "Yum yum! Thank you! 😸"),
         String(localized: "say.ate2", defaultValue: "Mmm, that was tasty!"),
         String(localized: "say.ate3", defaultValue: "Thanks for the food! ❤️")]
    }
    static var nomWords: [String] {
        [String(localized: "say.nom1", defaultValue: "yum"),
         String(localized: "say.nom2", defaultValue: "yum!"),
         String(localized: "say.nom3", defaultValue: "mmm")]
    }
    static var poopLines: [String] {
        [String(localized: "say.poop1", defaultValue: "Phew! 💩"),
         String(localized: "say.poop2", defaultValue: "Hehe… 💩"),
         String(localized: "say.poop3", defaultValue: "All done! 💩")]
    }
    static var wakeRested: String { String(localized: "say.wakeRested", defaultValue: "Good morning! I feel rested ☀️") }
    static var wakeLines: [String] {
        [String(localized: "say.wake1", defaultValue: "Meow? Is it morning?"),
         String(localized: "say.wake2", defaultValue: "Yawn… hi! 😺")]
    }
    static var tooTiredToPlay: String { String(localized: "say.tooTired", defaultValue: "I'm too tired to play… 💤") }
    static var caughtLines: [String] {
        [String(localized: "say.caught1", defaultValue: "Caught it! 🎉"),
         String(localized: "say.caught2", defaultValue: "I got it!"),
         String(localized: "say.caught3", defaultValue: "Hehe! 😸"),
         String(localized: "say.caught4", defaultValue: "More, more!")]
    }
    static var missLines: [String] {
        [String(localized: "say.miss1", defaultValue: "Almost!"),
         String(localized: "say.miss2", defaultValue: "Oops!"),
         String(localized: "say.miss3", defaultValue: "It got away!")]
    }
    static var tiredAfterPlay: String { String(localized: "say.tiredAfterPlay", defaultValue: "Phew… now I'm tired 💤") }
    static var alreadyClean: String { String(localized: "say.alreadyClean", defaultValue: "I'm already squeaky clean! ✨") }
    static var squeakyClean: String { String(localized: "say.squeakyClean", defaultValue: "Squeaky clean! ✨") }
    static var litterCleaned: String { String(localized: "say.litterCleaned", defaultValue: "Thanks! The litter box is clean now 😸") }
    static var litterAlreadyClean: String { String(localized: "say.litterAlreadyClean", defaultValue: "The litter box is clean ✨") }
    static var notTired: String { String(localized: "say.notTired", defaultValue: "I'm not that tired… but okay 😴") }
    static var goodNight: String { String(localized: "say.goodNight", defaultValue: "Good night! 💤") }
    static var grewBigger: String { String(localized: "say.grew", defaultValue: "Look, I've grown bigger! 🎉") }
    static var missedYou: String { String(localized: "say.missedYou", defaultValue: "There you are! I missed you ❤️") }
    static var welcomeBackLines: [String] {
        [String(localized: "say.back1", defaultValue: "Hello again! 🐾"),
         String(localized: "say.back2", defaultValue: "Meow! There you are!")]
    }
    static var gardenLines: [String] {
        [String(localized: "say.garden1", defaultValue: "Fresh air! 🌳"),
         String(localized: "say.garden2", defaultValue: "Look, butterflies! 🦋"),
         String(localized: "say.garden3", defaultValue: "Look, fish in the pond! 🐟")]
    }
    static var gardenNight: String { String(localized: "say.gardenNight", defaultValue: "Look at the stars! ✨") }
    static var homeAgain: String { String(localized: "say.home", defaultValue: "Home again! 🏠") }
    static var fishStart: String { String(localized: "say.fishStart", defaultValue: "Fish! Let's catch them! 🐟") }
    static var hideStart: String { String(localized: "say.hideStart", defaultValue: "Hide and seek! Close your eyes… 🙈") }
    static var hideBye: String { String(localized: "say.hideBye", defaultValue: "That was fun! Again soon? 😺") }
    static var foundLines: [String] {
        [String(localized: "say.found1", defaultValue: "You found me! 😸"),
         String(localized: "say.found2", defaultValue: "Peekaboo!"),
         String(localized: "say.found3", defaultValue: "How did you know?"),
         String(localized: "say.found4", defaultValue: "Again, again!")]
    }
    static var fishBye: String { String(localized: "say.fishBye", defaultValue: "Bye, fish! Swim home 🐟") }
    static var fishPerfect: String { String(localized: "say.fishPerfect", defaultValue: "Every single one! 🎉") }
    // the grown-up cat (#17)
    static func happyBirthday(_ name: String) -> String { String(localized: "toast.birthday", defaultValue: "Happy birthday, \(name)! 🎂") }
    static func birthdayAge(_ n: Int) -> String {
        n == 1 ? String(localized: "say.birthdayOne", defaultValue: "I'm 1 year old! 🎂")
               : String(localized: "say.birthdayYears", defaultValue: "I'm \(n) years old! 🎂")
    }
    static var partyForMe: String { String(localized: "say.party", defaultValue: "A party for me? 🎉") }
    static var stretchLine: String { String(localized: "say.stretch", defaultValue: "Aaah, that's better 😺") }
    static var toyForYou: String { String(localized: "say.toy", defaultValue: "This is for you! 🧶") }
    static var napWake: String { String(localized: "say.napWake", defaultValue: "Mrr? I was having a nap 😺") }
    static var dressedLines: [String] {
        [String(localized: "say.dressed1", defaultValue: "Don't I look nice? 😸"),
         String(localized: "say.dressed2", defaultValue: "I love it!"),
         String(localized: "say.dressed3", defaultValue: "Thank you! ❤️")]
    }
}
