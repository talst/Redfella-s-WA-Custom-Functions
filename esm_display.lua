function()
    if UnitAffectingCombat("player") and aura_env.recommended then
        local rec = aura_env.recommended
        local default = ""
        if (aura_env.targetCount > 1) then default = string.format("%.0f", aura_env.targetCount) end

        local maelstrom = UnitPower("player")
        local boulderfist_charges = GetSpellCharges(201897) or 0
        local _, _, _, strombringer_count=UnitBuff("player","Stormbringer")
        local strombringer_charges = stormbringer_count or 0
        -- Charged abilities
        if rec == 201897
        then return boulderfist_charges .. "/2\n\n\n" .. maelstrom .. "M" end

        if rec == 17364
        then return strombringer_charges .. "/2\n\n\n" .. maelstrom .. "M" end

        if rec == 196834
            or rec == 60103
        then return maelstrom .. "M\n\n\n\n" end
        return "\n\n\n" .. default
    else
        return "ooc\n\n\n\n"
    end
end
