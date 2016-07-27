function()
    if UnitAffectingCombat("player") then

        local recommended = GetSpellInfo(aura_env.recommended) or nil
        local bone_shield_stacks = aura_env.get_unit_aura_value(195181, 'count') or 0
        local bbcharges = GetSpellCharges(50842)
        local targets = aura_env.targetCount > 1 and aura_env.targetCount or nil
        local runic_power = ("%.0f"):format(UnitPower("player"))
        local health_percentage = ("%.0f"):format( ( UnitHealth("player") / UnitHealthMax("player") ) * 100 )
        local runes_available = aura_env.runes_available()
        local default = targets

        if aura_env.bone_shield_danger > 0 then
            return string.format("%.1f", aura_env.bone_shield_danger) .. "s\n\n" .. bone_shield_stacks .. "/10"
        end

        if recommended == 'Marrowrend' then return bone_shield_stacks .. "/10" end
        if recommended == 'Vampiric Blood' then return health_percentage .. "%%" end
        if recommended == 'Death Strike' then return health_percentage .. "%%\n\n" .. runic_power .. "RP"  end
        if recommended == 'Heart Strike' then return runes_available .. "R" end
        if recommended == 'Blood Boil' then return bbcharges .. "/2" end
        --
        return default
    else
        return "ooc"
    end
end
