function()
    if UnitAffectingCombat("player") and aura_env.recommended then
        local rec = aura_env.recommended
        local default = aura_env.targetCount > 1 and aura_env.targetCount or nil
        local soul_fragments = aura_env.soul_fragments()
        local pain = UnitPower("player")
        local infernal_strike_charges = GetSpellCharges(189110)
        local demon_spikes_charges = GetSpellCharges(203720)
        local health_percentage = math.ceil( (UnitHealth("player") / UnitHealthMax("player") * 100) )

        -- Defensives
        if rec == 207407
            or (rec == 204021 and health_percentage <90)
            or rec == 187827
            or rec == 196718
        then return health_percentage .. "%%" end

        -- Soul Cleave
        if rec == 228477 then
            if health_percentage < 90
            then return health_percentage .. "%%\n\n" .. pain .. "P"
            else return pain .. "P"  end
        end
        -- Pain generators / Pure spenders
        if rec == 203782
            or rec == 209795
            or rec == 213241
        then return pain .. "P" end

        -- Charged abilities
        if rec == 189110
        then return infernal_strike_charges .. "/2" end

        if rec == 203720
        then return demon_spikes_charges .. "/2" end

        -- Default if no matches
        return default
    else
        return "ooc"
    end
end
