local E = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB
local L = E.Libs.AceLocale:NewLocale(E._name, "deDE")

-- Addon related strings
L["ADDON_LOADED"] = "%s wurde geladen."
L["CURRENT_LOCALE"] = "The current locale is: %s"
L["MY_ID"] = "My player ID is: %s"

-- Settings related strings
L["DEBUG_MODE"] = "Debug mode: %s"

-- Frame related strings
L["FRAME_TITLE"] = "%s Frame"
L["FRAME_STATUS"] = "%s example frame created."

-- Event related strings
L["PLAYER_HEALTH_CHANGED"] = "Player health changed."

-- Buttons
L["CLEAR"] = "Leeren"
L["REMOVE"] = "Entfernen"

-- Settings options
L["PASS_ON_ALL"] = "Auf alle Gegenstände verzichten"
L["PASS_ON_ALL_DESC"] = "Alle Regeln und Qualitätsschwellen überschreiben - automatisch auf jeden Gegenstand verzichten"
L["PASS_ON_ALL_WARNING"] =
"|cffff8000Warnung:|r Modus 'Auf alles verzichten' ist |cffff0000AKTIV|r - alle Regeln und Schwellen werden ignoriert"



-- Items tab
L["NO_ITEMS_PASSED"] = "Es wurden noch keine Gegenstände behandelt."
L["ITEMS_PASSED_MOST_OFTEN"] = "Am häufigsten behandelte Gegenstände"
L["PASSED_X_TIMES"] = "%d mal behandelt"
L["LAST_SEEN"] = "Zuletzt: %s"
L["ROLL_TYPE_BREAKDOWN"] = "Aufschlüsselung nach Würfeltyp"
L["PASS_ROLLS"] = "Weitergeben"
L["NEED_ROLLS"] = "Bedarf"
L["GREED_ROLLS"] = "Gier/Entzaubern"
L["DECISION"] = "Entscheidung"
