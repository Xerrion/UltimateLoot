ProfileDefaults = {
    enabled = false,
    loot_quality_threshold = "legendary",
    pass_on_all = false,             -- Override all rules and pass on everything
    debug_mode = false,
    debug_to_chat = true,            -- Also print debug output to chat by default
    show_notifications = true,
    max_history = 1000,

    -- Item Rules settings
    item_rules_enabled = false,
    item_rules = {
        whitelist = {},             -- Items to always pass on (override threshold)
        blacklist = {},             -- Items to never pass on (override threshold)
        always_need = {},           -- Items to always roll Need on
        always_greed = {},          -- Items to always roll Greed on
        always_greed_disenchant = {} -- Items to always roll Greed/Disenchant on
    },

    -- Minimap icon settings
    minimap = {
        hide = false,
        minimapPos = 220,
        lock = false
    }
}
