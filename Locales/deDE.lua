local E = unpack(select(2, ...)) --Import: Engine, Locales, ProfileDB
local L = E.Libs.AceLocale:NewLocale(E._name, "deDE")
if not L then return end

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
L["ITEMS_HANDLED_MOST_OFTEN"] = "Am häufigsten behandelte Gegenstände"
L["PASSED_X_TIMES"] = "%d mal behandelt"
L["LAST_SEEN"] = "Zuletzt: %s"
L["ROLL_TYPE_BREAKDOWN"] = "Aufschlüsselung nach Würfeltyp"
L["PASS_ROLLS"] = "Weitergeben"
L["NEED_ROLLS"] = "Bedarf"
L["GREED_ROLLS"] = "Gier/Entzaubern"
L["DECISION"] = "Entscheidung"

-- Table column headers
L["ITEM_COLUMN"] = "Gegenstand"
L["QUALITY_COLUMN"] = "Qualität"
L["DATE_COLUMN"] = "Datum"

-- Summary text
L["ALL_TYPES"] = "Alle Typen"
L["FILTER_SUMMARY"] = "Nur %s"
L["SHOWING_ITEMS_SUMMARY"] = "Zeige %d Gegenstände (%s) | Weitergeben: %d | Bedarf: %d | Gier: %d"

-- History UI elements
L["SHOW_LABEL"] = "Zeigen:"
L["FILTER_LABEL"] = "Filter:"
L["LIMIT_25"] = "25"
L["LIMIT_50"] = "50"
L["LIMIT_100"] = "100"
L["LIMIT_200"] = "200"
L["LIMIT_ALL"] = "Alle"
L["FILTER_ALL"] = "Alle"
L["FILTER_PASS_ONLY"] = "Nur Weitergeben"
L["FILTER_NEED_ONLY"] = "Nur Bedarf"
L["FILTER_GREED_ONLY"] = "Nur Gier"
L["CLEAR_HISTORY_CONFIRM"] = "Sind Sie sicher, dass Sie die Würfelhistorie löschen möchten?\n\nDies kann nicht rückgängig gemacht werden."
L["UNKNOWN"] = "Unbekannt"
L["DATE_FORMAT"] = "(JJJJ-MM-TT)"

-- Statistics breakdown
L["NO_ROLL_DATA"] = "Keine Würfeldaten verfügbar"
L["ROLL_BREAKDOWN_FORMAT"] = "|cffff0000Weitergeben:|r %d (%.1f%%)\n|cff0080ffBedarf:|r %d (%.1f%%)\n|cffffaa00Gier:|r %d (%.1f%%)"
L["QUALITY_STATS_FORMAT"] = "%s: %d (%.1f%%) - %s"
L["QUALITY_NO_DATA_FORMAT"] = "%s: 0"
L["ROLL_STATS_FORMAT"] = "W:%d B:%d G:%d"
L["TOTAL_WITH_ROLLS_FORMAT"] = "Gesamt: %d (%s)"

-- Note related
L["NO_NOTE"] = "Keine Notiz"
L["ADD_NOTE"] = "Notiz hinzufügen..."
L["NOTE_PREFIX"] = "Notiz: "
L["EDIT_NOTE_FOR"] = "Bearbeite Notiz für "
L["UNKNOWN_ITEM"] = "Gegenstand"
