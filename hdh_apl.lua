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
        if ready( 'fel_rush')
        then rec ('fel_rush' ) end
        if ready( 'throw_glaive')
        then rec ('throw_glaive' ) end
        if ready( 'demons_bite')
        then rec ('demons_bite' ) end
    else

        -- Defensive cooldowns are toggled on
        if WA_Redfellas_Rot_HDH_Def_CDs then
            -- Blur if: health is below 40%
            if ready( 'blur' )
                and health_percentage <= 40
            then rec( 'blur' ) end

            -- Darkness if: health is below 30% and not affected by blur
            if ready( 'darkness' )
                and cooldowns.blur > 0
                and buffRemains.blur == 0
                and health_percentage <= 30
            then rec( 'darkness' ) end
        end

        -- AOE Rotation
        if aura_env.targetCount >= 3 then
          -- 1
          if ready('fel_rush')
            and chargeCt('fel_rush') >= 1.5
            and (
              not momentum_buff
              or (aura_env.targetCount > 3)
            )
          then rec('fel_rush') end

          -- 2
          if ready('vengeful_retreat')
            and not momentum_buff
          then rec('vengeful_retreat') end

          -- Build Fury for Meta
          if WA_Redfellas_Rot_HDH_Off_CDs then
              -- Pool fury for meta if not using demon blades and missing more than 25 fury
              if ready('demons_bite')
                  and not talented.demon_blades
                  and fury_deficit >= 20
                  and (cooldowns.metamorphosis == 0 or cooldowns.metamorphosis <= 5)
              then rec( 'demons_bite' ) end

              -- Nemesis before Meta if talented
              if ready( 'nemesis' )
                  and talented.nemesis
                  and cooldowns.metamorphosis == 0
                  and fury_deficit <= 20
              then rec( 'nemesis' ) end

              -- Meta available and near fury cap
              if ready( 'metamorphosis' )
                  and fury_deficit <= 20
              then rec('metamorphosis') end
          end

          -- 4
          if ready('fury_of_the_illidari')
            and (momentum_buff or not talented.momentum)
          then rec('fury_of_the_illidari') end

          -- 5
          if ready('fel_barrage')
            and talented.fel_barrage
            and fel_barrage_stacks >= 4
            and (momentum_buff or not talented.momentum)
          then rec('fel_barrage') end

          -- 6
          if ready( 'eye_beam' )
              and (momentum_buff or not talented.momentum)
          then rec( 'eye_beam' ) end

          -- Cast Vengeful Retreat with Prepared taken as long as you are 20
          -- or lower Fury from your cap.
          if ready('vengeful_retreat')
            and talented.prepared
            and not talented.momentum
            and fury_deficit >= 25
          then rec('vengeful_retreat') end

          -- Cast Fel Rush with Fel Mastery taken as long as you are 30 Fury or
          -- lower from your cap, or about to hit 2 charges.
          if ready('fel_rush')
            and chargeCt('fel_rush') >= 1.5
            and talented.fel_mastery
            and not talented.momentum
            and fury_deficit >= 30
          then rec('fel_rush') end

          -- 7
          if ready('death_sweep') and demon_form then rec('death_sweep')
          else if ready('blade_dance') then rec('blade_dance') end
          end

          -- 8
          if ready('throw_glaive')
            and talented.bloodlet
            and (momentum_buff or not talented.momentum)
            and debuffRemains.bloodlet < 1
          then rec('throw_glaive') end

          -- 9
          if ready('chaos_strike')
            and talented.chaos_cleave
            and aura_env.targetCount <= 3
          then rec('chaos_strike') end

          -- 10
          if ready('throw_glaive') then rec('throw_glaive') end

          -- 11
          if ready('chaos_strike')
            and (fury_deficit <= 30 or (fury_deficit <= 40 and talented.demon_blades))
          then rec('chaos_strike') end

        -- Single Target Rotation
        else
          -- Cast Vengeful Retreat to trigger Momentum.
          if ready('vengeful_retreat')
            and not momentum_buf
          then rec('vengeful_retreat') end

          -- Cast Fel Rush to trigger Momentum.
          if ready('fel_rush')
            and chargeCt('fel_rush') >= 1.5
            and not momentum_buff
          then rec('fel_rush') end

          -- Cast Eye Beam to trigger Demonic.
          if ready('eye_beam')
            and talented.demonic
            and not demon_form
          then rec('eye_beam') end

          -- Chaos Blades during meta or in between
          if ready( 'chaos_blades' )
              and talented.chaos_blades
              and (demon_form or cooldowns.metamorphosis > 120)
          then rec( 'chaos_blades' ) end

          -- Build Fury for Meta
          if WA_Redfellas_Rot_HDH_Off_CDs then
              -- Pool fury for meta if not using demon blades and missing more than 25 fury
              if ready('demons_bite')
                  and not talented.demon_blades
                  and fury_deficit >= 20
                  and (cooldowns.metamorphosis == 0 or cooldowns.metamorphosis <= 5)
              then rec( 'demons_bite' ) end

              -- Nemesis before Meta if talented
              if ready( 'nemesis' )
                  and talented.nemesis
                  and cooldowns.metamorphosis == 0
                  and fury_deficit <= 20
              then rec( 'nemesis' ) end

              -- Meta available and near fury cap
              if ready( 'metamorphosis' )
                  and fury_deficit <= 20
              then rec('metamorphosis') end
          end

          -- Cast Fel Eruption if taken.
          if ready('fel_eruption')
            and talented.fel_eruption
          then rec('fel_eruption') end

          -- Cast Fury of the Illidari, sync with Momentum.
          if ready('fury_of_the_illidari')
            and (momentum_buff or not talented.momentum)
          then rec('fury_of_the_illidari') end

          -- Cast Blade Dance or Death Sweep with First Blood, sync with Momentum.
          if talented.first_blood and (momentum_buff or not talented.momentum) then
            if ready('death_sweep') and demon_form then rec('death_sweep')
            else if ready('blade_dance') then rec('blade_dance') end
            end
          end

          -- Cast Felblade as long as you are 30 Fury or lower from your cap.
          if ready('felblade')
            and talented.felblade
            and fury_deficit >= 30
          then rec('felblade') end

          -- Cast Throw Glaive with Bloodlet, sync with Momentum.
          if ready('throw_glaive')
            and talented.bloodlet
            and (momentum_buff or not talented.momentum)
            and debuffRemains.bloodlet < 1
          then rec('throw_glaive') end

          -- Cast Fel Barrage at 5 charges, sync with Momentum.
          if ready('fel_barrage')
            and talented.fel_barrage
            and fel_barrage_stacks == 5
            and (momentum_buff or not talented.momentum)
          then rec('fel_barrage') end

          -- Cast Vengeful Retreat with Prepared taken as long as you are 20
          -- or lower Fury from your cap.
          if ready('vengeful_retreat')
            and talented.prepared
            and not talented.momentum
            and fury_deficit >= 25
          then rec('vengeful_retreat') end

          -- Cast Fel Rush with Fel Mastery taken as long as you are 30 Fury or
          -- lower from your cap, or about to hit 2 charges.
          if ready('fel_rush')
            and chargeCt('fel_rush') >= 1.5
            and talented.fel_mastery
            and not talented.momentum
            and fury_deficit >= 30
          then rec('fel_rush') end

          -- Cast Annihilation when 30 Fury or less from your cap.
          if ready('annihilation')
            and demon_form
            and (fury_deficit <= 30 or momentum_buff)
          then rec('annihilation') end

          -- Cast Eye Beam if you have the Anguish of the Deceiver trait.
          if  ready('eye_beam')
              and anguish_of_the_deceiver
          then rec('eye_beam') end

          -- Cast Chaos Strike when 30 Fury or less from your cap.
          if ready('chaos_strike')
            and (fury_deficit <= 30 or momentum_buff)
          then rec('chaos_strike') end

          -- Cast Fel Barrage at 4 charges, sync with Momentum.
          if ready('fel_barrage')
            and talented.fel_barrage
            and fel_barrage_stacks == 4
            and (momentum_buff or not talented.momentum)
          then rec('fel_barrage') end
        end

          -- Cast Fel Rush if out of range of targets to re-engage.
          if ready('fel_rush') and range == 0 then rec('fel_rush') end

          -- Cast Throw Glaive if out of range of any targets, or in empty Globals with Demon Blades Icon Demon Blades.
          if ready('throw_glaive') and range == 0 then rec('throw_glaive') end

          -- Cast Demon's Bite to generate Fury.
          if ready('demons_bite') then rec('demons_bite') end

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
