function ()
    rec = false

    aura_env.abilities = {
        ironskin_brew = 115308,
        purifying_brew = 119582,
        black_ox_brew = 115399,
        expel_harm = 115072
    }

    function rec2(spell)
        aura_env.recommended_purifier = aura_env.abilities[ spell ]
        return true
    end

    local health_percentage = math.ceil( (UnitHealth("player") / UnitHealthMax("player") * 100) )
    local missing_health_percentage = 100 - health_percentage
    local stagger_percentage = math.ceil( ((UnitStagger("player") or 0) / UnitHealthMax("player") * 100) )
    local purify_treshold = 60
    local energy = UnitPower("player")
    local class_trinket = IsEquippedItem(124517)
    local bob_start, bob_duration, bob_enabled = GetSpellCooldown(115399)
    local bob_ready = bob_start + bob_duration - GetTime()
    if bob_ready <= 0 then bob_ready = true else bob_ready = false end
    local brew_charges, maxCharges, start, duration = GetSpellCharges(115308)
    local brew_cooldown = start + duration - GetTime()
    local goto_orbs = GetSpellCount(115072) or 0
    local ironskin_buff = select(7,UnitBuff("player",GetSpellInfo(215479))) or 0
    ironskin_buff = (ironskin_buff or 0 ) - GetTime()

    -- Cooldown usage toggled on
    if WA_Redfellas_Rot_BRM_CDs then
        -- Use black_ox_brew
        if bob_ready == true and brew_charges == 0 and brew_cooldown > 5 then rec = rec2( 'black_ox_brew' )
        -- Heal with EH if under 50
        elseif health_percentage < 50 and energy >= 15 and goto_orbs >= 1 then rec = rec2( 'expel_harm' )
        -- Purify if stagger exceeds purify_treshold (default: 60%)
        elseif stagger_percentage >= purify_treshold and brew_charges >= 1 then rec = rec2( 'purifying_brew' )
        -- Ironskin Brew if: Actively tanking and more than 2 ISB charges
        elseif stagger_percentage >= 5 and brew_charges >= 2 then rec = rec2( 'ironskin_brew' )
        -- Ironskin Brew if: Class trinket equipped while not tanking and more than 2.5 ISB charges
        elseif stagger_percentage < 5 and class_trinket and brew_charges >= 2 then rec = rec2( 'ironskin_brew' )
        end
    end

    return rec
end
