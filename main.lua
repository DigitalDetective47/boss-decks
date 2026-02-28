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
        if context.before and StrangeLib.safe_compare(G.GAME.hands[context.scoring_name].level, ">", 1) then
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
    key = "water",
    atlas = "decks",
    pos = { x = 0, y = 2 },
    unlocked = false,
    config = { extra = 1 },
    loc_vars = function(self, info_queue)
        return { vars = { G.GAME.b_bdeck_water or 0, self.config.extra } }
    end,
    locked_loc_vars = locked_loc_vars,
    check_for_unlock = check_for_unlock,
    apply = function(self, back)
        apply(self, back)
        G.E_MANAGER:add_event(Event { func = function()
            G.GAME.round_resets.discards = 0
            G.GAME.current_round.discards_left = 0
            G.GAME.b_bdeck_water = 0
            return true
        end })
    end,
    calculate = function(self, back, context)
        if context.final_scoring_step then
            return { mult = G.GAME.b_bdeck_water }
        elseif context.hand_total and StrangeLib.safe_compare(context.hand_total, ">=", math.floor((G.GAME.blind.chips - G.GAME.chips) / (G.GAME.current_round.hands_left + 1))) then
            SMODS.scale_card(G.deck.cards[1],
                { ref_table = G.GAME, ref_value = self.key, scalar_table = self.config, scalar_value = "extra" })
        end
    end
}
local ease_discards_ref = ease_discard
function ease_discard(...)
    if G.GAME.selected_back.name ~= "b_bdeck_water" then
        return ease_discards_ref(...)
    end
    G.GAME.round_resets.discards = 0
    G.GAME.current_round.discards_left = 0
    attention_text {
        text = localize("k_nope_ex"),
        scale = 1,
        hold = 0.7,
        cover = G.HUD:get_UIE_by_ID("discard_UI_count").parent,
        cover_colour = G.C.GREY,
        align = "cm",
    }
    play_sound("timpani", 0.8)
    play_sound("generic1")
end

SMODS.Back {
    key = "window",
    atlas = "decks",
    pos = { x = 4, y = 0 },
    unlocked = false,
    config = { extra = 1 },
    loc_vars = function(self, info_queue)
        return { vars = { self.config.extra } }
    end,
    locked_loc_vars = locked_loc_vars,
    check_for_unlock = check_for_unlock,
    apply = apply,
    calculate = function(self, back, context)
        if context.debuff_card and context.debuff_card:is_suit("Diamonds", true) then
            return { debuff = true }
        elseif context.change_suit and context.old_suit == "Diamonds" and context.new_suit ~= "Diamonds" then
            return { dollars = self.config.extra }
        elseif context.remove_playing_cards then
            ---@type integer
            local diamonds = 0
            for _, other in ipairs(context.removed) do
                if other.base.suit == "Diamonds" then
                    diamonds = diamonds + 1
                end
            end
            return { dollars = diamonds * self.config.extra }
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
    apply = function(self, back)
        apply(self, back)
        G.E_MANAGER:add_event(Event { func = function()
            G.GAME.round_resets.hands = 1
            G.GAME.current_round.hands_left = 1
            return true
        end })
    end
}
local ease_hands_ref = ease_hands_played
function ease_hands_played(...)
    if G.b_bdeck_needle_immune or G.GAME.selected_back.name ~= "b_bdeck_needle" then
        return ease_hands_ref(...)
    end
    G.GAME.round_resets.hands = 1
    G.GAME.current_round.hands_left = 1
    attention_text {
        text = localize("k_nope_ex"),
        scale = 1,
        hold = 0.7,
        cover = G.HUD:get_UIE_by_ID("hand_UI_count").parent,
        cover_colour = G.C.GREY,
        align = "cm",
    }
    play_sound("timpani", 0.8)
    play_sound("generic1")
end

SMODS.Back {
    key = "tooth",
    atlas = "decks",
    pos = { x = 2, y = 3 },
    unlocked = false,
    locked_loc_vars = locked_loc_vars,
    check_for_unlock = check_for_unlock,
    apply = apply,
    calculate = function(self, back, context)
        if context.press_play then
            G.E_MANAGER:add_event(Event {
                delay = 0.2,
                func = function()
                    for _, card in ipairs(G.play.cards) do
                        G.E_MANAGER:add_event(Event { func = function()
                            card:juice_up()
                            return true
                        end })
                        ease_dollars(-1)
                        delay(0.23)
                    end
                    return true
                end
            })
        elseif context.end_of_round and not (context.repetition or context.individual) then
            return {
                dollars = -2 * (G.GAME.dollars + (G.GAME.dollar_buffer or 0)),
                dollar_message = { message = localize("k_negated_ex"), colour = G.C.MONEY }
            }
        end
    end,
}
