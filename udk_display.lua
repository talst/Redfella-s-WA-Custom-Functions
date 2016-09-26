function()
    if UnitAffectingCombat("player") and aura_env.recommended then
        local rec = aura_env.recommended

        local default = " "
        if (aura_env.targetCount > 1) then default = string.format("%.0f", aura_env.targetCount) end

        local fester_player = select(8,UnitDebuff("target",GetSpellInfo(194310)));
        local festering_wounds = select(4,UnitDebuff("target",GetSpellInfo(194310), nil, 'PLAYER')) or 0

        local runic_power = UnitPower("player")
        local health_percentage = math.ceil( (UnitHealth("player") / UnitHealthMax("player") * 100) )
        local runes_available = aura_env.runes_available()

        if aura_env.bank == true
        then return runes_available .. "R\n\n\n\n" .. "bank" end

        if aura_env.prepare == true
        then return festering_wounds .. "W\n\n\n" .. "bank" end

        -- Death Coil
        if rec == 47541 then return runic_power .. "RP\n\n\n\n" end

        -- Apocalypse
        if rec == 220143 then return festering_wounds .. "W\n\n\n\n" end

        -- Rune/Wound spenders & builders
        if rec == 85948
            or rec == 55090
            or rec == 130736
        then
            return runes_available .. "R\n\n\n" .. festering_wounds .. "W"
        end

        return festering_wounds .. "W\n\n\n" .. default
    end
end
