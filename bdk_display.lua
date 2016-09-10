function()
    if UnitAffectingCombat("player") and aura_env.recommended then
        local default = aura_env.targetCount > 1 and aura_env.targetCount or nil
        local bone_shield_stacks = aura_env.get_unit_aura_value(195181, 'count') or 0
        local bbcharges = GetSpellCharges(50842)
        local runic_power = UnitPower("player")
        local health_percentage = math.ceil( (UnitHealth("player") / UnitHealthMax("player") * 100) )
        local runes_available = aura_env.runes_available()


        if type(aura_env.bone_shield_danger) == 'number' then
            if aura_env.bone_shield_danger > 0 and aura_env.bone_shield_danger < 6 then
                return string.format("%.1f", aura_env.bone_shield_danger) .. "s\n\n\n" .. bone_shield_stacks .. "/10"
            end
        end

        if aura_env.recommended == 195182 then return bone_shield_stacks .. "/10\n\n\n\n" end
        if aura_env.recommended == 55233 then return health_percentage .. "%%\n\n\n\n" end
        if aura_env.recommended == 194844 then return runic_power .. "RP\n\n\n\n" end
        if aura_env.recommended == 49998 then
            if health_percentage < 95 then
                return health_percentage .. "%%\n\n\n" .. runic_power .. "RP"
            else
            return runic_power .. "RP\n\n\n\n"  end
        end
        if aura_env.recommended == 206930 then return runes_available .. "R\n\n\n\n" end
        if aura_env.recommended == 50842 then return bbcharges .. "/2\n\n\n\n" end
        return default
    else
        return "\n\n\n\nOOC"
    end
end
