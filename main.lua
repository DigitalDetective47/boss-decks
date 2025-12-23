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
