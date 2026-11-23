#!/usr/bin/env python3
"""Builds Whiskerling/Resources/Localizable.xcstrings from L10n.swift and the Danish table below,
and checks that every key has a Danish text with the same placeholders.

    /usr/bin/python3 tools/l10n.py          # write the catalog
    /usr/bin/python3 tools/l10n.py --check  # only check, exit 1 on problems
"""
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SWIFT = os.path.join(ROOT, "Whiskerling/Core/Localization/L10n.swift")
CATALOG = os.path.join(ROOT, "Whiskerling/Resources/Localizable.xcstrings")
INT_ARGS = {"n", "day", "days", "hearts", "a", "b"}

DA = {
    "action.feed": "Mad",
    "action.play": "Leg",
    "action.wash": "Vask",
    "action.sleep": "Sov",
    "action.lightsOn": "Tænd lys",
    "action.dressUp": "Pynt",
    "action.done": "Færdig",
    "action.close": "Luk",
    "meter.food": "Mæt",
    "meter.fun": "Glad",
    "meter.energy": "Energi",
    "meter.clean": "Ren",
    "hud.soundOn": "Lyd til",
    "hud.soundOff": "Lyd fra",
    "hud.hearts": "%lld hjerter",
    "hud.stageDay": "%@ · dag %lld",
    "stage.kitten": "Killing",
    "stage.young": "Ung kat",
    "stage.adult": "Voksen kat",
    "coat.orange": "Rød",
    "coat.gray": "Grå",
    "coat.black": "Sort",
    "coat.white": "Hvid",
    "coat.tabby": "Stribet",
    "coat.tuxedo": "Sort-hvid",
    "coat.siamese": "Siameser",
    "coat.gingerwhite": "Rød-hvid",
    "coat.calico": "Trefarvet",
    "item.bow": "Sløjfe",
    "item.bell": "Klokke",
    "item.flowers": "Blomster",
    "item.glasses": "Solbriller",
    "item.hat": "Høj hat",
    "item.scarf": "Halstørklæde",
    "item.crown": "Krone",
    "food.title": "Hvad skal %@ have?",
    "food.kibble": "Tørfoder",
    "food.fish": "Fisk",
    "food.shrimp": "Rejer",
    "food.kibble.note": "Mætter lidt",
    "food.fish.note": "Mætter godt",
    "food.shrimp.note": "Godbid, gør glad",
    "wardrobe.title": "Pynt din kat",
    "wardrobe.info": "Du har %lld ❤️. Pas godt på %@, så får du flere.",
    "wardrobe.coats": "Pels",
    "wardrobe.items": "Pynt",
    "wardrobe.wear": "Tag på",
    "wardrobe.takeOff": "Tag af",
    "wardrobe.wearing": "Valgt",
    "wardrobe.needHearts": "Du skal have %lld ❤️ for at få den",
    "badge.pro": "Pro",
    "badge.askGrownUp": "Spørg en voksen",
    "start.choose": "Vælg din killing",
    "start.nameQuestion": "Hvad skal den hedde?",
    "start.namePlaceholder": "Mis",
    "start.bringHome": "Hent killingen hjem 🏠",
    "gate.title": "Til de voksne",
    "gate.question": "Hvad er %lld × %lld?",
    "gate.wrong": "Forkert svar. Prøv igen.",
    "gate.ok": "OK",
    "gate.cancel": "Annuller",
    "menu.title": "Indstillinger for voksne",
    "menu.info": "%@ er på dag %lld og har %lld ❤️.",
    "menu.soundOn": "Lyd: til",
    "menu.soundOff": "Lyd: fra",
    "menu.startOver": "Start forfra med en ny kat",
    "menu.startOverConfirm": "Er du sikker? Tryk igen for at sige farvel til %@.",
    "pro.title": "Whiskerling Pro",
    "pro.subtitle": "Lås alt op, én gang for alle.",
    "pro.coats.title": "Alle ni pelsfarver",
    "pro.coats.body": "Rød, rød-hvid, grå, sort, sort-hvid, hvid, stribet, trefarvet og siameser.",
    "pro.items.title": "Alt pynt",
    "pro.items.body": "Blomster, solbriller, høj hat, halstørklæde og krone. De låses stadig op med hjerter.",
    "pro.private.title": "Stadig privat",
    "pro.private.body": "Ét køb. Intet abonnement, ingen reklamer, ingen konti. Alt bliver på denne iPad.",
    "pro.unlockPrice": "Lås Pro op · %@",
    "pro.unlock": "Lås Pro op",
    "pro.restore": "Gendan køb",
    "pro.notNow": "Ikke nu",
    "pro.unlocked": "Pro er låst op. Tak!",
    "pro.offline": "Kunne ikke nå App Store. Tjek forbindelsen og prøv igen.",
    "pro.tryAgain": "Prøv igen",
    "pro.pending": "Købet venter på godkendelse.",
    "pro.unverified": "Købet kunne ikke bekræftes.",
    "pro.failed": "Købet gik ikke igennem.",
    "pro.alertTitle": "Køb",
    "toast.daily": "Dagens gave: +3 ❤️",
    "toast.itemUnlocked": "Nyt pynt låst op: %@!",
    "toast.grewYoung": "%@ er blevet til en ung kat! 🎉",
    "toast.grewAdult": "%@ er blevet til en voksen kat! 🎉",
    "toast.petTip": "Tip: Stryg over %@ for at kæle 🐾",
    "toast.asleep": "%@ sover. Tænd lyset først ☀️",
    "hint.play": "Træk fjeren rundt. Kan %@ fange den?",
    "hint.wash": "Skrub %@ med svampen!",
    "hint.washLitter": "Skrub %@ med svampen, og tryk på kattebakken!",
    "say.hello": "Hej! Jeg hedder %@! 🐾",
    "say.hungry": "Jeg er sulten! 🐟",
    "say.tired": "Jeg er så træt… 💤",
    "say.dirty": "Jeg trænger til en vask! 🛁",
    "say.bored": "Vil du lege med mig? 🧶",
    "say.litterSmells": "Kattebakken lugter! 💩",
    "say.bedtime": "Det er sengetid… 🌙",
    "say.happy1": "Miav! ❤️",
    "say.happy2": "Purrr…",
    "say.happy3": "Jeg elsker dig! ❤️",
    "say.happy4": "Hvad skal vi lave nu?",
    "say.happy5": "Jeg er så glad i dag! 😸",
    "say.happy6": "Miav miav!",
    "say.tap1": "Miav! ❤️",
    "say.tap2": "Miav!",
    "say.tap3": "Purr… 😺",
    "say.tap4": "Hej med dig!",
    "say.zzz": "Zzz…",
    "say.full": "Jeg er helt mæt! 😸",
    "say.noMoreTreats": "Ikke flere godbidder lige nu 😸",
    "say.ate1": "Nam nam! Tak! 😸",
    "say.ate2": "Mmm, det smagte godt!",
    "say.ate3": "Tak for mad! ❤️",
    "say.nom1": "nam",
    "say.nom2": "nam!",
    "say.nom3": "mmm",
    "say.poop1": "Puh! 💩",
    "say.poop2": "Hihi… 💩",
    "say.poop3": "Så er det gjort! 💩",
    "say.wakeRested": "Godmorgen! Jeg er udhvilet ☀️",
    "say.wake1": "Miav? Er det morgen?",
    "say.wake2": "Gaab… hej! 😺",
    "say.tooTired": "Jeg er for træt til at lege… 💤",
    "say.caught1": "Fanget! 🎉",
    "say.caught2": "Jeg fangede den!",
    "say.caught3": "Hihi! 😸",
    "say.caught4": "Mere, mere!",
    "say.miss1": "Næsten!",
    "say.miss2": "Hov!",
    "say.miss3": "Den slap væk!",
    "say.tiredAfterPlay": "Puh… nu er jeg træt 💤",
    "say.alreadyClean": "Jeg er allerede helt ren! ✨",
    "say.squeakyClean": "Skinnende ren! ✨",
    "say.litterCleaned": "Tak! Nu er kattebakken ren 😸",
    "say.litterAlreadyClean": "Kattebakken er ren ✨",
    "say.notTired": "Jeg er ikke så træt… men okay 😴",
    "say.goodNight": "Godnat! 💤",
    "say.grew": "Se, jeg er blevet større! 🎉",
    "say.missedYou": "Der er du! Jeg har savnet dig ❤️",
    "say.back1": "Hej igen! 🐾",
    "say.back2": "Miav! Der er du!",
    "say.dressed1": "Er jeg ikke fin? 😸",
    "say.dressed2": "Den er flot!",
    "say.dressed3": "Tak! ❤️",
    "menu.feedback": "Giv feedback",
    "menu.rate": "Bedøm Whiskerling",
    "menu.privacy": "Privatlivspolitik",
    "menu.feedbackNote": "Feedback åbner en mail til support@iamjarl.com med app- og iPadOS-version udfyldt. Intet bliver sendt, før du selv sender den.",
    "action.garden": "Haven",
    "action.indoors": "Stuen",
    "games.title": "Hvad skal %@ lege?",
    "games.feather": "Fjeren",
    "games.feather.note": "Træk den rundt",
    "games.fish": "Fang fisken",
    "games.fish.note": "Ved dammen i haven",
    "games.hide": "Gemmeleg",
    "games.hide.note": "Find katten",
    "hint.hide": "Find %@! Kig efter en hale eller to ører.",
    "toast.hideResult": "Du fandt %@ %lld gange! 🙈",
    "say.hideStart": "Gemmeleg! Luk øjnene… 🙈",
    "say.hideBye": "Det var sjovt! Igen snart? 😺",
    "say.found1": "Du fandt mig! 😸",
    "say.found2": "Borte, tittut!",
    "say.found3": "Hvordan vidste du det?",
    "say.found4": "Igen, igen!",
    "hint.fish": "Tryk på fiskene, når de hopper!",
    "toast.fishResult": "%@ fangede %lld fisk! 🐟",
    "pro.garden.title": "Haven og to lege",
    "pro.garden.body": "Et ekstra rum med dam, træ og sommerfugle, og legene Fang fisken og Gemmeleg.",
    "pro.future.title": "Mere på vej",
    "pro.future.body": "Det, der kommer til Pro senere, som nye katte og lege, er med.",
    "say.garden1": "Frisk luft! 🌳",
    "say.garden2": "Se, sommerfugle! 🦋",
    "say.garden3": "Se, fisk i dammen! 🐟",
    "say.gardenNight": "Se stjernerne! ✨",
    "say.home": "Hjemme igen! 🏠",
    "say.fishStart": "Fisk! Dem fanger vi! 🐟",
    "say.fishBye": "Farvel, fisk! Svøm hjem 🐟",
    "say.fishPerfect": "Alle sammen! 🎉",
    "toast.birthday": "Tillykke med fødselsdagen, %@! 🎂",
    "say.birthdayOne": "Jeg er 1 år! 🎂",
    "say.birthdayYears": "Jeg er %lld år! 🎂",
    "say.party": "Er det en fest for mig? 🎉",
    "say.stretch": "Aaah, det var godt 😺",
    "say.toy": "Den er til dig! 🧶",
    "say.napWake": "Mrr? Jeg tog en lur 😺",
}

PATTERN = re.compile(r'String\(localized:\s*"([^"]+)",\s*defaultValue:\s*"((?:[^"\\]|\\.)*)"\)')


def english_entries():
    src = open(SWIFT, encoding="utf-8").read()
    out = {}
    for key, value in PATTERN.findall(src):
        def spec(m):
            return "%lld" if m.group(1) in INT_ARGS else "%@"
        out[key] = re.sub(r"\\\(([^)]+)\)", spec, value)
    return out


def placeholders(s):
    return re.findall(r"%(?:\d+\$)?(?:lld|@)", s)


def main():
    en = english_entries()
    problems = []
    for key, value in en.items():
        if key not in DA:
            problems.append(f"missing Danish: {key}")
        elif placeholders(DA[key]) != placeholders(value):
            problems.append(f"placeholders differ: {key}: {value!r} vs {DA[key]!r}")
    for key in DA:
        if key not in en:
            problems.append(f"Danish key not in code: {key}")
    if problems:
        print("\n".join(problems))
        sys.exit(1)
    if "--check" in sys.argv:
        print(f"OK: {len(en)} keys, all with Danish")
        return
    strings = {}
    for key in sorted(en):
        strings[key] = {
            "extractionState": "manual",
            "localizations": {
                "da": {"stringUnit": {"state": "translated", "value": DA[key]}},
                "en": {"stringUnit": {"state": "translated", "value": en[key]}},
            },
        }
    with open(CATALOG, "w", encoding="utf-8") as f:
        json.dump({"sourceLanguage": "en", "strings": strings, "version": "1.0"}, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(f"Wrote {len(strings)} keys to {os.path.relpath(CATALOG, ROOT)}")


if __name__ == "__main__":
    main()
