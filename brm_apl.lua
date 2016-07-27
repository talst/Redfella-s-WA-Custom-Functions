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

    local health_percentage = ("%.0f"):format( ( UnitHealth("player") / UnitHealthMax("player") ) * 100 )
    local missing_health_percentage = 100 - health_percentage
    local stagger_percentage = math.ceil( (UnitStagger("player") / UnitHealthMax("player") * 100) )
    local energy = UnitPower("player")

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

    -- Grab ability CDs. OLD, using Roll confuses this
    --    for k,v in pairs( abilities ) do
    --        local start, duration = GetSpellCooldown(v)
    --        cooldowns[ k ] = IsUsableSpell(v) and max( 0, start + duration - now ) or 999
    --    end

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

    if WA_Redfellas_Rot_BRM_CDs then
        -- purify excessive stagger dot
        if ready ('purifying_brew' ) and stagger_percentage >= aura_env.purify_treshold then rec( 'purifying_brew' ) end

        -- tanking, use isbs and save 2 charges for purify + am combo
        if ready( 'ironskin_brew' ) and stagger_percentage >= 5 and chargeCt( 'ironskin_brew' ) > 2 then rec( 'ironskin_brew' ) end

        -- use brews for damage if using class trinket and not tanking
        if ready( 'ironskin_brew' ) and stagger_percentage < 5 and IsEquippedItem(124517) and chargeCt( 'ironskin_brew' ) > 2.5 then rec( 'ironskin_brew' ) end
    end

    -- if not using blackout combo
    if talented.blackout_combo == false then

        if ready( 'keg_smash' ) then rec( 'keg_smash' ) end

        if ready( 'tiger_palm' ) and energy >= 90 then rec( 'tiger_palm' ) end

        if ready( 'blackout_strike' ) then rec( 'blackout_strike' ) end

        if ready( 'breath_of_fire' ) then rec( 'breath_of_fire' ) end

        if ready( 'chi_burst' ) then rec( 'chi_burst' ) end

        if ready( 'tiger_palm' ) and energy >= 58  then rec( 'tiger_palm' ) end

    end

    -- if using blackout combo
    if talented.blackout_combo == true then
        -- try to generate as many brews as possible when staggering damage or using class trinket (dps buff)
        if stagger_percentage > 5 or IsEquippedItem(124517) then
            if ready( 'keg_smash' ) and energy == 100 then rec( 'keg_smash' ) end

            if ready( 'tiger_palm' ) and energy > 90 and energy < 100 then rec( 'tiger_palm' ) end

            if ready( 'blackout_strike' ) and ( cooldowns.keg_smash > 3 or ready( 'keg_smash') ) then rec( 'blackout_strike' ) end

            if ready( 'keg_smash' ) and buffRemains.blackout_combo > 0 then rec( 'keg_smash' ) end

            if ready( 'breath_of_fire' ) and buffRemains.blackout_combo > 0 then rec( 'breath_of_fire' ) end

            if ready( 'chi_burst' ) and aura_env.targetCount > 1 then rec( 'chi_burst' ) end

            if ready( 'tiger_palm' ) and buffRemains.blackout_combo > 0 and energy > 60 then rec( 'tiger_palm' ) end

            if ready( 'tiger_palm' ) and energy > 65 then rec( 'tiger_palm' ) end

            if ready( 'chi_burst' ) then rec( 'chi_burst' ) end
            -- just dps when low stagger or no class trinket
        else
            if ready( 'keg_smash' ) then rec( 'keg_smash' ) end

            if ready( 'tiger_palm' ) and  energy > 90 then rec( 'tiger_palm' ) end

            if ready( 'blackout_strike' ) then rec( 'blackout_strike' ) end

            if ready( 'breath_of_fire' ) then rec( 'breath_of_fire' ) end

            -- difference to normal prio since bos tp can hurt a lot with somne luck
            if ready( 'tiger_palm' ) and buffRemains.blackout_combo > 0 and energy > 50 then rec( 'tiger_palm' ) end

            if ready( 'chi_burst' ) then rec( 'chi_burst' ) end

            if ready( 'tiger_palm' ) and energy > 58 then rec( 'tiger_palm' ) end
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
