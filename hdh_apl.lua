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

    local fury = UnitPower("player", SPELL_POWER_FURY)
    local fury_max = UnitPowerMax("player", SPELL_POWER_FURY)
    local fury_deficit = fury_max - fury
    local health_percentage = aura_env.health_percentage()
    local missing_health_percentage = 100 - health_percentage
    local in_combat = aura_env.in_combat
    local fury_starved = false
    if fury < 5 then fury_starved = true end

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
    aura_env.timeToReady = 10

    local danger_treshold = aura_env.danger_treshold
    local critical_treshold = aura_env.critical_treshold
    local ready = aura_env.ready
    local rec = aura_env.rec
    local artifact_weapon = IsEquippedItem(127829)
    local demon_form = false
    if buffRemains.metamorphosis > 0 then demon_form = true end
    local fel_barrage_stacks = select(1, GetSpellCharges(211053)) or 0
    local throw_glaive_stacks = select(1, GetSpellCharges(185123)) or 0
    local momentum_duration = select(7,UnitBuff("player",GetSpellInfo(208628))) or 0
    aura_env.momentum_duration = momentum_duration - GetTime()
    local momentum_buff = false
    if talented.momentum and aura_env.momentum_duration > 0 then momentum_buff = true end
    local range = IsSpellInRange( abilityNames[162243] )
    local anguish_of_the_deceiver = aura_env.get_trait_rank(201473) > 0

    ---------------
    -- APL START --
    ---------------

    if not in_combat then
        if ready( 'fel_rush') then rec ('fel_rush')
        elseif ready( 'throw_glaive') then rec ('throw_glaive' )
        else rec ('demons_bite' ) end
    else
        -- Defensive cooldowns are toggled on
        if WA_Redfellas_Rot_HDH_Def_CDs then
            -- Blur if: health is below 40%
            if ready( 'blur' )
                and health_percentage <= 40
            then rec( 'blur' )

            -- Darkness if: health is below 30% and not affected by blur
            elseif ready( 'darkness' )
                and cooldowns.blur > 0
                and buffRemains.blur == 0
                and health_percentage <= 30
            then rec( 'darkness' ) end
        end

        if ready('vengeful_retreat')
          and (talented.prepared or (talented.momentum and buffRemains.momentum <= 0))
        then rec('vengeful_retreat')

        elseif ready('fel_rush')
          and talented.momentum
          and buffRemains.momentum <= 0
          and cooldowns.vengeful_retreat > buffRemains.momentum
        then rec('fel_rush')

        elseif ready('fury_of_the_illidari') then rec('fury_of_the_illidari')
        elseif aura_env.targetCount >= 3 then
          if ready('death_sweep') and buffRemains.metamorphosis > 0 then rec('death_sweep')
          elseif ready('fel_barrage') and talented.fel_barrage and fel_barrage_stacks == 5 then rec('fel_barrage')
          elseif ready('eye_beam') then rec('eye_beam')
          elseif ready('fel_rush') then rec('fel_rush')
          elseif ready('blade_dance') and cooldowns.eye_beam > 0 then rec('blade_dance')
          elseif ready('throw_glaive') then rec('throw_glaive')
          elseif ready('annihilation') and buffRemains.metamorphosis > 0 and talented.chaos_cleave then rec('annihilation')
          elseif ready('chaos_strike') and talented.chaos_cleave then rec('chaos_strike')
          elseif ready('chaos_nova') and (cooldowns.eye_beam > 0 or talented.unleashed_power) then rec('chaos_nova')
          elseif ready('annihilation') and buffRemains.metamorphosis > 0 and fury_deficit <= 30 then rec('annihilation')
          elseif ready('chaos_strike') and fury_deficit <= 30 then rec('chaos_strike')
          else rec('demons_bite')
          end
        elseif ready('fel_eruption') and talented.fel_eruption then rec('fel_eruption')
        elseif ready('death_sweep') and buffRemains.metamorphosis > 0 and talented.first_blood then rec('death_sweep')
        elseif ready('annihilation') and buffRemains.metamorphosis > 0 and (not talented.momentum or (talented.momentum and buffRemains.momentum > 0) or fury_deficit <= 30) then rec('annihilation')
        elseif ready('fel_barrage') and talented.fel_barrage and fel_barrage_stacks == 5 and (not talented.momentum or (talented.momentum and buffRemains.momentum > 0)) then rec('fel_barrage')
        elseif ready('throw_glaive') and talented.bloodlet then rec('throw_glaive')
        elseif ready('eye_beam') and anguish_of_the_deceiver and not buffRemains.metamorphosis > 0 and (not talented.momentum or (talented.momentum and buffRemains.momentum > 0)) then rec('eye_beam')
        elseif ready('blade_dance') and talented.first_blood then rec('blade_dance')
        elseif ready('chaos_strike') and (not talented.momentum or (talented.momentum and buffRemains.momentum > 0) or fury_deficit <= 30) then rec('chaos_strike')
        elseif ready('fel_rush') and not talented.momentum then rec('fel_rush')
        elseif ready('felblade') and talented.felblade then rec('felblade')
        else rec('demons_bite')
        end
    end

    ---------------
    -- APL END --
    ---------------

    if aura_env.timeToReady < 5 then
        if aura_env.showCooldownRing then
            local startSpell, durationSpell = GetSpellCooldown( aura_env.recommended )
            local spellCharges = select(1, GetSpellCharges(aura_env.recommended )) or 0
            local startGCD, durationGCD = GetSpellCooldown( 61304 )

            local start = 0
            local duration = 0

            if (startGCD + durationGCD) >= (startSpell + durationSpell) or spellCharges > 0 then
              start = startGCD
              duration = durationGCD
            else
              start = startSpell
               duration = durationSpell
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
