-- UNIT_POWER_FREQUENT, SPELL_UPDATE_COOLDOWN, SPELL_UPDATE_CHARGES, PLAYER_TARGET_CHANGED, UNIT_SPELLCAST_SUCCEEDED
function ()
    if UnitCanAttack("player", "target") == false then return false end
    if not WA_Redfellas_Rot_BRM_Enabled or UnitOnTaxi("player") then
        return false
    end

    local now = GetTime()

    if now < aura_env.lastUpdate + aura_env.updateInterval then
        return true
    end

    aura_env.lastUpdate = now

    local targets = aura_env.targets
    local talentList = aura_env.talents
    local talented = aura_env.talented
    local abilities = aura_env.abilities
    local abilityNames = aura_env.abilityNames
    local cooldowns = aura_env.cooldowns
    local charges = aura_env.charges
    local chargeTime = aura_env.chargeTime
    local chargedAbilities = aura_env.chargedAbilities
    local chargesMax = aura_env.chargesMax
    local buffList = aura_env.buffs
    local buffNames = aura_env.buffNames
    local buffRemains = aura_env.buffRemains
    local debuffList = aura_env.debuffs
    local debuffNames = aura_env.debuffNames
    local debuffRemains = aura_env.debuffRemains
    local chargeCt = aura_env.chargeCt
    local cdLeft = aura_env.cdLeft

    local health_percentage = math.ceil( (UnitHealth("player") / UnitHealthMax("player") * 100) )
    local missing_health_percentage = 100 - health_percentage
    local stagger_percentage = math.ceil( ((UnitStagger("player") or 0) / UnitHealthMax("player") * 100) )
    local energy = UnitPower("player")
    local purify_treshold = aura_env.purify_treshold
    local class_trinket = IsEquippedItem(124517)
    local goto_orbs = GetSpellCount(115072) or 0

    for k,v in pairs( targets ) do
        if now - v > aura_env.targetWipeInterval then
            targets[k] = nil
            aura_env.targetCount = max(0, aura_env.targetCount - 1)
        end
    end

    local gcdStart, gcdDuration = GetSpellCooldown(61304)
    local gcd = gcdStart + gcdDuration

    -- if GCD is active, we'll just advance to the end of the GCD.
    now = max( now, gcd )

    -- if the GCD isn't active, calculate what the GCD should be.
    if gcdDuration == 0 then
        gcdDuration = max( 1, 1.5 / ( 1 + ( GetHaste() / 100 ) ) )
    end

    -- Get active talents.
    for k,v in pairs( talentList ) do
        talented[ k ] = select(4, GetTalentInfo( unpack( v ) ) )
    end

    -- Grab ability CDs.
    for k,v in pairs( abilities ) do
        local start, duration = GetSpellCooldown(v)
        cooldowns[ k ] = select(2, IsUsableSpell(v)) and 999 or max( 0, start + duration - now )
    end

    -- Check # of charges.
    for k,v in pairs( chargedAbilities ) do
        local c, maxCharges, start, duration = GetSpellCharges(v)
        charges[ k ] = min( maxCharges, c + ( max(0, 1 - ( start + duration - now) / duration ) ) )
        chargeTime[ k ] = duration
        chargesMax[ k ] = maxCharges
    end


    -- Check if buffs are up.
    for k,v in pairs( buffList ) do
        local _, _, _, _, _, _, expires = UnitBuff("player", buffNames[ v ] )

        buffRemains[ k ] = 0

        if expires then
            if expires == 0 then
                buffRemains[ k ] = 10 -- No real duration, i.e. Fury of Air.
            else
                buffRemains[ k ] = expires - now
            end
        end

    end

    -- Check if debuffs are up.
    for k,v in pairs( debuffList ) do
        local _, _, _, _, _, _, expires = UnitDebuff("target", debuffNames[ v ] )

        debuffRemains[ k ] = expires and expires - now or 0
    end

    aura_env.lastRec = aura_env.recommended
    aura_env.recommended = 0
    aura_env.timeToReady = 10

    local rec = aura_env.rec
    local ready = aura_env.ready

    local wait_for_priority_abilities = false
    if cooldowns.keg_smash < 0.75 or cooldowns.blackout_strike < 0.75 then
        wait_for_priority_abilities = true
    end

    -- Get remaining time on Keg Smash (ignoring energy cost)
    local start, duration = GetSpellCooldown(121253)
    local timeleft = max(0, start + duration - now)

    -- Calculate where energy regen will get us to once keg smash comes off cooldown
    local energy_regen = select(2, GetPowerRegen())
    aura_env.tp_threshold = (energy + (timeleft * energy_regen)) - 25
    tp_threshold = aura_env.tp_threshold


    -- Talent not in use: Blackout Combo
    if talented.blackout_combo == false then
        -- Keg Smash if it's ready
        if ready( 'keg_smash' ) then rec( 'keg_smash' ) end
        -- Tiger palm if about to cap energy
        if ready( 'tiger_palm' ) and energy >= 90 then rec( 'tiger_palm' ) end
        -- Blackout Strike if it's ready
        if ready( 'blackout_strike' ) then rec( 'blackout_strike' ) end
        -- Breath of Fire if it's ready
        if ready( 'breath_of_fire' ) then rec( 'breath_of_fire' ) end
        -- RJW if it's talented and ready
        if talented.rushing_jade_wind and ready( 'rushing_jade_wind' ) then rec( 'rushing_jade_wind') end
        -- Chi Burst if it's talented and ready
        if talented.chi_burst and ready( 'chi_burst' ) then rec( 'chi_burst' ) end
        -- Chi Wave if it's talented and ready
        if talented.chi_wave and ready( 'chi_wave' ) then rec( 'chi_wave' ) end
        -- Tiger Palm if more than 58 Energy
        if ready( 'tiger_palm' ) and tp_threshold >= 40 then rec( 'tiger_palm' ) end
    end

    -- Talent in use: Blackout Combo
    if talented.blackout_combo == true then
        -- Generate as many brews as possible when actively tanking or using class trinket
        if stagger_percentage >= 5 then
            -- Blackout strike if it's ready
            if ready( 'blackout_strike' ) then rec( 'blackout_strike' ) end

            -- If we have the Blackout Combo buff
            if buffRemains.blackout_combo > 0 then
                -- Always combo it with KS for Brew Generation
                if ready( 'keg_smash' ) and buffRemains.blackout_combo > 0 then rec( 'keg_smash' ) end
                -- BoF to reduce it's CD (Not optimal in Prepatch, but with the Artifact trait in Legion it will be)
                if ready( 'breath_of_fire' ) and buffRemains.blackout_combo > 0 then rec( 'breath_of_fire' ) end
                -- Combo with TP for -1s on brews and 200% dmg on TP
                if ready( 'tiger_palm' ) and buffRemains.blackout_combo > 0 and tp_threshold >= 40 then rec( 'tiger_palm' ) end
            end
            -- Weave in one non-blacked out ability between BoS > BoS buffed ability
            if buffRemains.blackout_combo == 0 then
                -- Tiger palm if about to cap energy
                if ready( 'tiger_palm' ) and energy >= 90 then rec( 'tiger_palm' ) end
                -- RJW if it's talented and ready
                if talented.rushing_jade_wind and ready( 'rushing_jade_wind' ) then rec( 'rushing_jade_wind') end
                -- Chi Burst if it's talented and ready
                if talented.chi_burst and ready( 'chi_burst' ) then rec( 'chi_burst' ) end
                -- Chi Wave if it's talented and ready
                if talented.chi_wave and ready( 'chi_wave' ) then rec( 'chi_wave' ) end
                -- TP
                if ready( 'tiger_palm' ) and tp_threshold >= 40 then rec( 'tiger_palm' ) end
            end
        end

        -- Not tanking, prioritize DPS
        if stagger_percentage < 5 then
            -- Ks #1 prio if not using Class Trinket
            if not class_trinket and ready( 'keg_smash' ) then rec( 'keg_smash' ) end
            -- Blackout strike if it's ready
            if ready( 'blackout_strike' ) then rec( 'blackout_strike' ) end

            -- If we have the Blackout Combo buff
            if buffRemains.blackout_combo > 0 then
              -- Always combo it with KS for Brew Generation, since with Class Trinket more brews equals more damage
              if class_trinket and ready( 'keg_smash' ) and buffRemains.blackout_combo > 0 then rec( 'keg_smash' ) end
              -- Combo with TP for -1s on brews and 200% dmg on TP, and hope for Face Palm procs
              if ready( 'tiger_palm' ) and not wait_for_priority_abilities and buffRemains.blackout_combo > 0 and tp_threshold >= 40 then rec( 'tiger_palm' ) end
            end
            -- Weave in one non-blacked out ability between BoS > BoS buffed ability
            if buffRemains.blackout_combo == 0 then
                -- Tiger palm if about to cap energy
                if ready( 'tiger_palm' ) and energy >= 90 then rec( 'tiger_palm' ) end
                -- Breath of Fire if it's ready
                if ready( 'breath_of_fire' ) then rec( 'breath_of_fire' ) end
                -- RJW if it's talented and ready
                if talented.rushing_jade_wind and ready( 'rushing_jade_wind' ) then rec( 'rushing_jade_wind') end
                -- Chi Burst if it's talented and ready
                if talented.chi_burst and ready( 'chi_burst' ) then rec( 'chi_burst' ) end
                -- Chi Wave if it's talented and ready
                if talented.chi_wave and ready( 'chi_wave' ) then rec( 'chi_wave' ) end
                -- TP
                if ready( 'tiger_palm' ) and tp_threshold >= 40 then rec( 'tiger_palm' ) end
            end
        end
    end


    if aura_env.timeToReady < 5 then
        if aura_env.showCooldownRing then
            local start, duration = GetSpellCooldown( aura_env.recommended )

            if not start or start == 0 then
                start, duration = GetSpellCooldown( 61304 )
            end

            WeakAuras.regions[aura_env.id].region.cooldown:SetReverse(aura_env.invertCooldownRing)
            WeakAuras.regions[aura_env.id].region.cooldown:SetCooldown(start, duration)
        end

        if aura_env.showRangeHighlight then
            local range = aura_env.recommended == 0 and 0 or  IsSpellInRange( abilityNames[ aura_env.recommended ] )

            if range == 0 then WeakAuras.regions[aura_env.id].region:Color(1, 0, 0, 1)
            else WeakAuras.regions[aura_env.id].region:Color(1, 1, 1, 1)
            end
        end
    else
        WeakAuras.regions[aura_env.id].region.cooldown:SetCooldown(0,0)
        WeakAuras.regions[aura_env.id].region:Color(1,1,1,1)
    end


    return true
end
