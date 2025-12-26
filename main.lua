---@param self Mod
---@return { scale: number, background_colour: [number, number, number, number], text_colour: [number, number, number, number], shadow: true }
function SMODS.current_mod.description_loc_vars(self)
    return { scale = 1.2, background_colour = G.C.CLEAR, text_colour = G.C.UI.TEXT_LIGHT, shadow = true }
end

SMODS.Atlas {
    key = "modicon",
    path = "icon.png",
    px = 34,
    py = 34,
}
SMODS.Atlas {
    key = "decks",
    path = "decks.png",
    px = 71,
    py = 95,
}

---get the key of the blind corresponding to this boss deck
---@param deck SMODS.Back
---@return string
local function get_blind_key(deck)
    return SMODS.Blind.class_prefix .. "_" .. deck.original_key
end
---template implementation of `locked_loc_vars`
---@param self SMODS.Back
---@param info_queue table[]
---@return { vars: [string, integer] }
local function locked_loc_vars(self, info_queue)
    return { vars = { localize { type = "name_text", set = "Blind", key = get_blind_key(self) }, 7 } }
end
---template implementation of `check_for_unlock`
---@param self SMODS.Back
---@param args table
---@return boolean
local function check_for_unlock(self, args)
    return args.type == "round_win" and G.GAME.round_resets.ante >= 7 and
        G.GAME.blind.config.blind.key == get_blind_key(self)
end
---template implementation of `apply` that bans the deck's corresponding blind
---@param self SMODS.Back
---@param deck Back
local function apply(self, deck)
    G.GAME.banned_keys[get_blind_key(self)] = true
end

SMODS.Back {
    key = "arm",
    atlas = "decks",
    pos = { x = 3, y = 1 },
    unlocked = false,
    locked_loc_vars = locked_loc_vars,
    check_for_unlock = check_for_unlock,
    apply = apply,
    calculate = function(self, back, context)
        if context.before and G.GAME.hands[context.scoring_name].level > 1 then
            SMODS.upgrade_poker_hands { hands = context.scoring_name, level_up = -1 }
            ---@type PokerHands
            local hand = G.handlist[1]
            ---@type integer
            local count = -1
            for _, key in ipairs(G.handlist) do
                if G.GAME.hands[key].played > count then
                    hand = key
                    count = G.GAME.hands[key].played
                end
            end
            SMODS.upgrade_poker_hands { hands = hand, level_up = 1 }
        end
    end,
}

SMODS.Back {
    key = "serpent",
    atlas = "decks",
    pos = { x = 1, y = 2 },
    unlocked = false,
    locked_loc_vars = locked_loc_vars,
    check_for_unlock = check_for_unlock,
    apply = apply,
}

SMODS.Back {
    key = "needle",
    atlas = "decks",
    pos = { x = 0, y = 3 },
    unlocked = false,
    config = { ante_scaling = 0.5, extra_discard_bonus = 2 },
    loc_vars = function(self, info_queue)
        return { vars = { self.config.ante_scaling, self.config.extra_discard_bonus } }
    end,
    locked_loc_vars = locked_loc_vars,
    check_for_unlock = check_for_unlock,
    apply = apply,
    calculate = function(self, back, context)
        if context.setting_blind then
            ease_hands_played(1 - G.GAME.current_round.hands_left)
        end
    end,
}
