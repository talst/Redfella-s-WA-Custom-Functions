function()
    if aura_env.state then
        local charges, maxCharges, start, duration, charges, rounded
        local itemtype = 0
        local charges = 0
        local maxCharges = 0
        local retstring = ""

        -- Cooldown Progress (Spell)
        if not aura_env.state.trigger.itemName and aura_env.state.trigger.spellName then
            charges, maxCharges, start, duration = GetSpellCharges(aura_env.state.trigger.spellName)

            if charges == nil then
                charges = 0
                maxCharges = 0
                start, duration = GetSpellCooldown(aura_env.state.trigger.spellName)
            end
        end


        -- Cooldown Progress (Item)
        if aura_env.state.trigger.itemName and aura_env.state.trigger.spellName then
            start, duration = GetItemCooldown(aura_env.state.trigger.itemName)
            itemtype = select(8,GetItemInfo(109223))
        end


        if start and duration then
            local cooldown = start + duration - GetTime()

            -- hack for items that stack to 20 and have 60 fixed CD during combat
            if itemtype == 20 and cooldown == 60 then
              return "USED"
            end

            if cooldown > 0 then
                if cooldown < 60 then
                    retstring = string.format("%.0f", cooldown)
                    if maxCharges > 0 then retstring = charges .. "/" .. retstring end
                elseif cooldown >= 60 and cooldown < 999 then
                    rounded = math.floor(cooldown / 60 + 0.5)
                    retstring = string.format("%.0f", rounded) .. "m"
                    if maxCharges > 0 then retstring = charges .. "/" .. retstring end
                elseif cooldown > 999 then
                    retstring = charges
                end

                return retstring
            end
        end
    end
end
