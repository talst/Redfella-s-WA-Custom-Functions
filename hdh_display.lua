function()
    if UnitAffectingCombat("player") and aura_env.recommended then
        local rec = aura_env.recommended
        local default = ""
        if (aura_env.targetCount > 1) then default = string.format("%.0f", aura_env.targetCount) end

        local fury = UnitPower("player")
        local fel_rush_charges = GetSpellCharges(195072) or 0
        local blade_dance_charges = GetSpellCharges(188499) or 0
        local throw_glaive_stacks = GetSpellCharges(185123) or 0
        local fel_barrage_stacks = select(1, GetSpellCharges(211053)) or 0
        -- Charged abilities
        if rec == 195072
        then return fel_rush_charges .. "/2\n\n\n" .. fury .. "F" end

        if rec == 188499
        then return blade_dance_charges .. "/2\n\n\n" .. fury .. "F" end

        if rec == 211053 then return fel_barrage_stacks .. "/5\n\n\n\n" end

        if rec == 203555
            or rec == 198793
            or rec == 162794
            or rec == 191427
            or rec == 206491
            or rec == 201427
        then return fury .. "F\n\n\n\n" end
        return "\n\n\n" .. default
    else
        return "ooc\n\n\n\n"
    end
end
