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
string.format("%sWarnung:%s Modus 'Auf alles verzichten' ist %sAKTIV%s - alle Regeln und Schwellen werden ignoriert", 
    ORANGE_FONT_COLOR_CODE, FONT_COLOR_CODE_CLOSE, RED_FONT_COLOR_CODE, FONT_COLOR_CODE_CLOSE)

-- Item Rules UI strings
L["ITEM_RULES_DESC"] = "Automatische Regeln für die Behandlung bestimmter Gegenstände konfigurieren, wenn Beutewürfe erscheinen"
L["RULES_SUMMARY"] = "Regelzusammenfassung"
L["TOTAL_RULES"] = "Gesamtzahl der Regeln"
L["MANAGE_RULES"] = "Regeln verwalten"
L["ITEM_RULES_MANAGER"] = "Gegenstandsregeln-Manager"
L["CLEAR_RULES_OF_TYPE"] = "Alle Regeln dieses Typs löschen"
L["NO_RULES_OF_TYPE"] = "Keine Regeln dieses Typs konfiguriert"

-- Manager window strings
L["RULES_OVERVIEW"] = "Regelübersicht"
L["STATUS"] = "Status"
L["ENABLED"] = "Aktiviert"
L["DISABLED"] = "Deaktiviert"
L["IMPORT_EXPORT"] = "Import/Export"
L["EDIT"] = "Bearbeiten"
L["SELECT_ALL"] = "Alle auswählen"
L["CLEAR_ALL"] = "Alle löschen"
L["CONFIGURED_RULES"] = "Konfigurierte Regeln"
L["RULE"] = "Regel"
L["RULES"] = "Regeln"
L["NO_RULES_OF_TYPE_DETAILED"] = "Keine %s-Regeln konfiguriert.\n\nKlicken Sie unten auf 'Regel hinzufügen' oder verwenden Sie den Hauptbereich, um Ihre erste Regel zu erstellen."
L["YES"] = "Ja"
L["NO"] = "Nein"

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
L["SHOWING_ITEMS_SUMMARY"] = "Zeige %d Gegenstände (%s) | Weitergeben: %d | Bedarf: %d | Gier/Entzaubern: %d"

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
L["FILTER_GREED_ONLY"] = "Nur Gier/Entzaubern"
L["CLEAR_HISTORY_CONFIRM"] = "Sind Sie sicher, dass Sie die Würfelhistorie löschen möchten?\n\nDies kann nicht rückgängig gemacht werden."
L["UNKNOWN"] = "Unbekannt"
L["DATE_FORMAT"] = "(JJJJ-MM-TT)"

-- Statistics breakdown
L["NO_ROLL_DATA"] = "Keine Würfeldaten verfügbar"
L["ROLL_BREAKDOWN_FORMAT"] = "|cffff0000Weitergeben:|r %d (%.1f%%)\n|cff0080ffBedarf:|r %d (%.1f%%)\n|cffffaa00Gier/Entzaubern:|r %d (%.1f%%)"
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

-- Graph tab
L["HOURLY_ACTIVITY"] = "Stündliche Aktivität (Letzte 24 Stunden)"
L["HOURLY_ACTIVITY_GRAPH"] = "Aktivitätsdiagramm"
L["TOTAL_ROLLS_24H"] = "Gesamte Würfe in den letzten 24 Stunden: %d"
L["GRAPH_SUMMARY_FORMAT"] = "Gesamte Würfe: %d | Durchschnitt pro Stunde: %.1f | Spitze: %d Würfe vor %dh"
