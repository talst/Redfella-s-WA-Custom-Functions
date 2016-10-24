function()
    if UnitAffectingCombat("player") and aura_env.recommended then
        local rec = aura_env.recommended
        local default = ""
        if (aura_env.targetCount > 1) then default = string.format("%.0f", aura_env.targetCount) end

        local maelstrom = UnitPower("player", SPELL_POWER_MAELSTROM)
        local boulderfist_charges = GetSpellCharges(201897) or 0
        local _, _, _, strombringer_stacks = UnitBuff("player","Stormbringer")
        local strombringer_charges = strombringer_stacks or 0

        -- Charged abilities
        if rec == 201897
        then return boulderfist_charges .. "/2\n\n" .. default .. "\n\n" .. maelstrom .. "M" end

        if rec == 17364
        then return strombringer_charges .. "/2\n\n".. default .. "\n\n" .. maelstrom .. "M" end

        return "      \n\n" .. default .. "\n\n" .. maelstrom .. "M"
    else
        return "ooc\n\n\n\n"
    end
end
