function()
    if UnitAffectingCombat("player") and aura_env.recommended then
        local stagger_percentage = math.ceil( ((UnitStagger("player") or 0) / UnitHealthMax("player") * 100) )
        local default = ""
        if (aura_env.targetCount > 1) then default = string.format("%.0f", aura_env.targetCount) end


        if aura_env.targetCount > 1
            and stagger_percentage > 0
        then
            return default .. "\n\n\n\n" .. stagger_percentage .. "%%"
        elseif aura_env.targetCount > 1 then
            return default .. "\n\n\n\n"
        elseif stagger_percentage > 1  then
            return stagger_percentage .. "%%\n\n\n\n"
        else
            return ""
        end
    else
        return "ooc\n\n\n\n"
    end
end
