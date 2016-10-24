-- UNIT_POWER_FREQUENT, SPELL_UPDATE_COOLDOWN, SPELL_UPDATE_CHARGES, PLAYER_TARGET_CHANGED, UNIT_SPELLCAST_SUCCEEDED
function ()
    if not WA_Redfellas_Rot_HDH_Enabled or UnitOnTaxi("player") or not UnitCanAttack("player", "target") then
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

    local maelstrom = UnitPower("player", SPELL_POWER_MAELSTROM)
    local maelstrom_max = UnitPowerMax("player", SPELL_POWER_MAELSTROM)
    local maelstrom_deficit = maelstrom_max - maelstrom
    local health_percentage = aura_env.health_percentage()
    local missing_health_percentage = 100 - health_percentage
    local in_combat = aura_env.in_combat
    local maelstrom_starved = false
    if maelstrom < 5 then maelstrom_starved = true end

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
        local _, _, _, _, _, _, expires = UnitDebuff("target", debuffNames[ v ], nil, 'PLAYER' )
        debuffRemains[ k ] = expires and expires - now or 0
    end

    aura_env.lastRec = aura_env.recommended
    aura_env.recommended = 0
    aura_env.timeToReady = gcdDuration

    local danger_treshold = aura_env.danger_treshold
    local critical_treshold = aura_env.critical_treshold
    local ready = aura_env.ready
    local rec = aura_env.rec
    local range = IsSpellInRange( abilityNames[17364] )

    local boulderfist_stacks = select(1, GetSpellCharges(201897)) or 0
    local is_akainus_absolute_justice = IsEquippedItem(137084)
    local frostbrand_full_duration = 16
    local flametongue_full_duration = 16
    local is_gathering_storms = aura_env.get_trait_rank(198299) > 0

    ---------------
    -- APL START --
    ---------------

    if not in_combat then
      if ready( 'feral_lunge') and talented.feral_lunge then rec ('feral_lunge')
        elseif ready( 'spirit_walk') then rec ('spirit_walk')
        elseif ready( 'wind_rush_totem') and talented.wind_rush_totem then rec ('wind_rush_totem')
      end
    else
      if ready('boulderfist')
        and talented.boulderfist
        and (buffRemains.boulderfist <= gcdDuration or boulderfist_stacks == 2)
      then rec('boulderfist')

      elseif ready('rockbiter')
       and talented.landslide
       and buffRemains.landslide <= gcdDuration
      then rec('rockbiter')

        elseif ready('frostbrand')
          and talented.hailstorm
          and buffRemains.frostbrand < gcdDuration
        then rec('frostbrand')

        elseif ready('flametongue')
          and buffRemains.flametongue < gcdDuration
        then rec('flametongue')

        elseif ready('fury_of_air')
         and talented.fury_of_air
         and aura_env.targetCount >= 5
        then rec('fury_of_air')

        elseif ready('windsong')
          and talented.windsong
        then rec('windsong')

        elseif ready('earthen_spike')
          and talented.earthen_spike
        then rec('earthen_spike')

        elseif ready('doom_winds') then rec('doom_winds')

        elseif ready('ascendance')
          and talented.ascendance
          and buffRemains.doom_winds > gcdDuration
        then rec('ascendance')

        elseif ready('sundering')
         and talented.sundering
         and aura_env.targetCount >= 3
        then rec('sundering')

        elseif ready('crash_lightning')
         and aura_env.targetCount >= 3
        then rec('crash_lightning')

        elseif ready('lava_lash')
         and talented.hot_hand
         and buffRemains.hot_hand > gcdDuration
         and is_akainus_absolute_justice
         and buffRemains.frostbrand > gcdDuration
         and buffRemains.flametongue > gcdDuration
        then rec('lava_lash')

        elseif ready('stormstrike') then rec('stormstrike')

        elseif ready('frostbrand')
          and talented.hailstorm
          and buffRemains.frostbrand <= 0.3 * frostbrand_full_duration
        then rec('frostbrand')

        elseif ready('flametongue')
          and buffRemains.flametongue <= 0.3 * flametongue_full_duration
        then rec('flametongue')

        elseif ready('lightning_bolt')
         and talented.overcharge
         and maelstrom >= 45
        then rec('lightning_bolt')

        elseif ready('crash_lightning')
          and (talented.crashing_storm
            or targetCount >= 2
            or (is_gathering_storms and buffRemains.gathering_storms == 0))
        then rec('crash_lightning')

        elseif ready('sundering')
          and talented.sundering
          and targetCount >= 2
        then rec('sundering')

        elseif ready('frostbrand')
         and is_akainus_absolute_justice
         and buffRemains.frostbrand == 0
        then rec('frostbrand')

        elseif ready('lava_lash')
          and talented.hot_handd
        then rec('lava_lash')

        elseif ready('crash_lightning')
          and talented.cras
        then rec('crash_lightning')

        elseif ready('lava_lash')
         and maelstrom >= 90
        then rec('lava_lash')

        elseif ready('boulderfist')
          and talented.boulderfist
        then rec('boulderfist')

        elseif ready('rockbiter')
          and not talented.boulderfist
        then rec('rockbiter')

        elseif ready('lightning_bolt') then rec('lightning_bolt')
        end
      end

    -- print("REC:", aura_env.recommended)
    -- print("TEST:", talented.chaos_blades)

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
