function()
    if UnitAffectingCombat("player") and aura_env.recommended then
        local default = aura_env.targetCount > 1 and aura_env.targetCount or nil
        local soul_fragments = aura_env.soul_fragments()
        local pain = UnitPower("player")
        local infernal_strike_charges = GetSpellCharges(189110)
        local demon_spikes_charges = GetSpellCharges(203720)
        local health_percentage = math.ceil( (UnitHealth("player") / UnitHealthMax("player") * 100) )

        -- Defensives
        if aura_env.recommended == 207407 or aura_env.recommended == 204021 or aura_env.recommended == 187827 or aura_env.recommended == 196718 then return health_percentage .. "%%" end
        -- Soul Cleave
        if aura_env.recommended == 228477 then
            if health_percentage < 95 then return health_percentage .. "%%\n\n" .. pain .. "P"
            else return pain .. "P"  end
        end
        -- Pain generators
        if aura_env.recommended == 203782 or aura_env.recommended == 213241 then return pain .. "P" end
        -- Charged abilities
        if aura_env.recommended == 189110 then return infernal_strike_charges .. "/2" end
        if aura_env.recommended == 203720 then return demon_spikes_charges .. "/2" end
        return default
    else
        return "ooc"
    end
end
