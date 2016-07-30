-- UNIT_POWER_FREQUENT, SPELL_UPDATE_COOLDOWN, SPELL_UPDATE_CHARGES, PLAYER_TARGET_CHANGED, UNIT_SPELLCAST_SUCCEEDED

function ()
    if not WA_Redfellas_Rot_VDH_Enabled or UnitOnTaxi("player") or not UnitCanAttack("player", "target") then
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

    local soul_framents = aura_env.soul_fragments()
    local pain = UnitPower("player")
    local health_percentage = aura_env.health_percentage()
    local missing_health_percentage = 100 - health_percentage
    local soul_cleave_heal = aura_env.soul_cleave_heal()
    local in_combat = aura_env.in_combat

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

    -- for easy if / else APL'ing
    local danger_treshold = aura_env.danger_treshold
    local critical_treshold = aura_env.critical_treshold
    local ready = aura_env.ready
    local rec = aura_env.rec

    -- Set pain cap for when to Soul Cleave even if it overheals
    local pain_cap = 70

    ---------------
    -- APL START --
    ---------------

    print("currently fighting against X targets:", targets)
    
    if not in_combat and ready( 'sigil_of_flame' ) then rec( 'sigil_of_flame' ) end
    if not in_combat and ready( 'infernal_strike' ) then rec( 'infernal_strike' ) end

    if WA_Redfellas_Rot_VDH_Def_CDs then
        -- Soul Carver if: health is below 70% and 0 fragments
        if ready( 'soul_carver' ) and health_percentage <= 70 and soul_fragments == 0 then rec( 'soul_carver' ) end

        -- Fiery Brand if: health is below 65%
        if ready( 'fiery_brand' ) and health_percentage <= 65 then rec( 'fiery_brand' ) end

        if health_percentage <= danger_treshold then
            -- Soul Cleave if: every time we can
            if ready( 'soul_cleave' ) then rec( 'soul_cleave' ) end
            -- Meta if: health drops below 25%
            if ready( 'metamorphosis' ) and health_percentage <= critical_treshold then rec( 'metamorphosis' ) end
            -- Darkness if: health still below 25%
            if ready( 'darkness' ) and health_percentage <= critical_treshold then rec( 'darkness' ) end
        end

        -- Demon Spikes charge if: health is below 90% and capped or nearly capped on DS charges
        if ready( 'demon_spikes' ) and chargeCt('demon_spikes') >= 1.70 and health_percentage <= 90 then rec( 'demon_spikes' ) end
    end

    -- Soul Cleave if: ready and over pain cap (default: 70)  -- OR --  Soul Cleave will not overheal
    if ready( 'soul_cleave' ) and (pain >= pain_cap or soul_cleave_heal < missing_health_percentage) then rec( 'soul_cleave' ) end

    -- Immolation Aura on CD
    if ready( 'immolation_aura' ) then rec( 'immolation_aura' ) end

    if ready( 'sigil_of_flame' ) and targets >= 2 then rec( 'sigil_of_flame' ) end

    -- Felblade on CD unless it would cap RP
    if talented.felblade and ready( 'felblade' ) and pain <= 75 then rec( 'felblade' ) end

    -- infernal_strike if about to cap charges
    if ready( 'infernal_strike' ) and chargeCt('infernal_strike') >= 1.75 then rec( 'infernal_strike' ) end

    -- infernal_strike if about to cap charges
    if ready( 'shear' ) then rec( 'shear' ) end

    ---------------
    -- APL END --
    ---------------



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
