-- UNIT_POWER_FREQUENT, SPELL_UPDATE_COOLDOWN, SPELL_UPDATE_CHARGES, PLAYER_TARGET_CHANGED, UNIT_SPELLCAST_SUCCEEDED

function ()
    if UnitCanAttack("player", "target") == false then return false end
    if not WA_RedsBDKRota_Enabled or UnitOnTaxi("player") then
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

    local runic_power = UnitPower("player")
    local health_percentage = ("%.0f"):format( ( UnitHealth("player") / UnitHealthMax("player") ) * 100 )
    local missing_health_percentage = 100 - health_percentage

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
    gcdDuration = 1

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

    aura_env.bb_charges = charges.blood_boil

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


    -- for easy if / else APL'ing
    local ds_usable = false
    local two_ds_usable = false
    local spend_runes = false
    local danger_treshold = aura_env.danger_treshold
    local ready = aura_env.ready
    local rec = aura_env.rec

    -- grab amount of runes up
    local runes = aura_env.runes_available()

    -- grab amount of HP DS will heal based on damage taken in the past 5s modified by vers, VE, Guardian Spirit, Divine Hymn
    local ds_heal = aura_env.death_strike_heal()

    -- grab bs stacks
    local bone_shield_stacks = aura_env.get_unit_aura_value(195181, 'count') or 0

    -- handle ds available
    if (buffRemains.ossuary > 0 and runic_power >= 40) or runic_power >= 45 then ds_usable = true end
    if (buffRemains.ossuary > 0 and runic_power >= 80) or runic_power >= 90 then two_ds_usable = true end

    --print("two ds debug", runic_power, two_ds_usable)
    -- spend runes before we get to 4 runes so as to always, ALWAYS have 3 runes charging
    local time_to_3_runes = aura_env.time_to_x_runes(3)
    if time_to_3_runes <= 3 then spend_runes = true end

    local rp_cap_warning = 75
    if talented.ossuary then rp_cap_warning = 85 end
    aura_env.bone_shield_danger = 0

    ---------------
    -- APL START --
    ---------------

    -- refresh marrowrend if about to fall off
    if buffRemains.bone_shield > 0 and buffRemains.bone_shield < 6 then
        aura_env.bone_shield_danger = buffRemains.bone_shield
        if ready( 'marrowrend' ) and runes >= 2 then rec( 'marrowrend') end
    end

    -- below danger treshold
    if WA_RedsBDKRota_CDs and missing_health_percentage >= danger_treshold then
        -- really low hp, skip banking and just VE
        if ready( 'vampiric_blood' ) and missing_health_percentage >= 80 then rec( 'vampiric_blood' ) end

        -- heal with DS if VE is on cooldown, otherwise we bank for 2 DS for VE > DS > DS combo
        if ready( 'death_strike' ) and missing_health_percentage >= danger_treshold and cooldowns.vampiric_blood > 0 then rec( 'death_strike' ) end

        -- VE if we have enough RP for two DS
        if ready( 'vampiric_blåood' ) and two_ds_usable then rec( 'vampiric_blood' ) end

        -- heal with DS if VE active
        if ready( 'death_strike' ) and ds_usable and buffRemains.vampiric_blood > 0 then rec( 'death_strike' ) end
    else
        -- dont manage cds, just suggest healign if it wont overheal
        if ready( 'death_strike' ) and missing_health_percentage >= danger_treshold then rec( 'death_strike' ) end
    end

    -- above danger treshold, heal with DS if the heal won't overheal
    if ready( 'death_strike' ) and missing_health_percentage < danger_treshold and missing_health_percentage >= ds_heal then rec( 'death_strike' ) end

    -- activate DRW if under 50% HP, RP starved and no VE
    if WA_RedsBDKRota_CDs and ready( 'dancing_rune_weapon' ) and not ds_usable and cooldowns.vampiric_blood > 0 and missing_health_percentage >= 50 then rec( 'dancing_rune_weapon' ) end

    -- tag the enemy with bp
    if ready( 'blood_boil' ) and charges.blood_boil >= 0 and debuffRemains.blood_plague == 0 then rec( 'blood_boil' ) end

    -- DRW for bone shield stacks, usually this happens on pull after first BB
    if WA_RedsBDKRota_CDs and ready( 'dancing_rune_weapon' ) and bone_shield_stacks <= 6 and runes >= 4 then rec( 'dancing_rune_weapon' ) end

    -- dnd on cd when using RD or if crimson scourge procs, or if more than 1 target
    if ready( 'death_and_decay' ) and (talented.rapid_decomposition or buffRemains.crimson_scourge >= 0 or targets > 1) then rec( 'death_and_decay' ) end

    -- marrowrend if missing bone shield
    -- marrowrend if DRW active and missing lots of bone shield stacks to build up fast
    if ready( 'marrowrend' ) and (bone_shield_stacks == 0 and runes >= 2) or (buffRemains.dancing_rune_weapon > 0 and bone_shield_stacks <= 4) then rec( 'marrowrend') end

    -- spend bb if 1.5 charges aka around 3 seconds to cap cahrges
    if ready( 'blood_boil' ) and chargeCt( 'blood_boil' ) >= 1.6 then rec( 'blood_boil' ) end

    -- death strike for dps if too much rp
    if ready( 'death_strike' ) and runic_power >= rp_cap_warning then rec( 'death_strike' ) end

    -- we want to give higher prio to HS during dnd buff for increased RP gains if we talented RD
    if talented.rapid_decomposition and buffRemains.death_and_decay > 0 then
        -- marrowrend if at six or less bone shield stacks
        if ready( 'marrowrend' ) and bone_shield_stacks <= 4 and spend_runes then rec( 'marrowrend') end

        -- heart strike if good on bone shield
        if ready( 'heart_strike' ) and bone_shield_stacks > 4 and spend_runes then rec( 'heart_strike') end

    else
        -- marrowrend if at six or less bone shield stacks
        if ready( 'marrowrend' ) and bone_shield_stacks <= 6 and spend_runes then rec( 'marrowrend') end

        -- heart strike if good on bone shield
        if ready( 'heart_strike' ) and bone_shield_stacks >= 7 and spend_runes then rec( 'heart_strike') end
    end

    -- if blood tap talent taken, recommend it when time to 3 runes available is higher than 5 seconds
    if talented.blood_tap and ready ('blood_tap') and aura_env.time_to_x_runes(3) > 5 then rec( 'blood_tap' ) end

    -- blood boil your last charge if nothing else to do
    if ready( 'blood_boil' ) then rec( 'blood_boil' ) end

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
