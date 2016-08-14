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
    local artifact_weapon = false -- IsEquippedItem(128832)
    local demon_form = false
    if buffRemains.metamorphosis > 0 then demon_form = true end
    local fel_barrage_stacks = aura_env.get_unit_aura_value(222707, 'count') or 0
    local momentum_duration = select(7,UnitBuff("player",GetSpellInfo(208628))) or 0
    aura_env.momentum_duration = momentum_duration - GetTime()
    local momentum = false
    if aura_env.momentum_duration > 0 then momentum = true end


    ---------------
    -- APL START --
    ---------------
    if not in_combat and ready( 'fel_rush') then rec ('fel_rush' ) end

    -- Defensive cooldowns are toggled on
    if WA_Redfellas_Rot_HDH_Def_CDs then
        -- Blur if: health is below 25%
        if ready( 'blur' ) and health_percentage <= 25 then rec( 'blur' ) end
        -- Darkness if: health is below 25%
        if ready( 'darkness' ) and cooldowns.blur > 0 and buffRemains.blur == 0 and health_percentage <= 25 then rec( 'darkness' ) end
    end

    if talented.momentum and aura_env.momentum_duration <= 0 then
        -- Vengeful retreat /w Momentum
        if fury_deficit >= 20 and ready( 'vengeful_retreat' ) then rec( 'vengeful_retreat' ) end
        -- Fel rush /w Momentum
        if fury_deficit >= 25 and ready( 'fel_rush' ) and chargeCt('fel_rush') >= 1.5 and cooldowns.vengeful_retreat > 4 then rec( 'fel_rush' ) end
        -- Blur Offensively
        if WA_Redfellas_Rot_HDH_Off_CDs and chargeCt('fel_rush') < 1 and ready('blur') and cooldowns.vengeful_retreat > 4 and fury_deficit >= 25 then  rec('blur') end
    end

    if not talented.momentum then
        -- Vengeful retreat
        if fury_deficit >= 20 and ready( 'vengeful_retreat' ) then rec( 'vengeful_retreat' ) end
        -- Fel rush
        if talented.fel_mastery and fury_deficit >= 25 and ready( 'fel_rush' ) and chargeCt('fel_rush') >= 1.5 and cooldowns.vengeful_retreat > 4 then rec( 'fel_rush' ) end
    end

    -- Throw glaives when OOR
    local range = IsSpellInRange( abilityNames[162243] )
    if range == 0 and ready('throw_glaive') then rec( 'throw_glaive' ) end

    -- Fury of the Illidari if Offensive CDs are toggled on
    if WA_Redfellas_Rot_HDH_Off_CDs and artifact_weapon and ready( 'fury_of_the_illidari' ) then rec( 'fury_of_the_illidari' ) end

    -- Eye Beam @ 90+ Fury (with Demonic)
    if fury >= 90 and talented.demonic then rec( 'eye_beam' ) end

    if WA_Redfellas_Rot_HDH_Off_CDs then
        -- If CDs enabled, pool fury for Meta
        if (cooldowns.metamorphosis == 0 or cooldowns.metamorphosis < 5) and fury_deficit > 25 and ready('demons_bite') then rec( 'demons_bite' ) end
        -- Meta up and plenty of fury, activate Meta
        if fury_deficit <= 25 and ready( 'metamorphosis' ) then rec('metamorphosis') end
    end

    -- Death Sweep / Blade Dance if 4+ target (with Momentum)
    if demon_form and talented.momentum and momentum and aura_env.targetCount >= 4 and ready( 'death_sweep' ) then rec( 'death_sweep' ) end
    if not demon_form and talented.momentum and momentum and aura_env.targetCount >= 4 and ready( 'blade_dance' ) then rec( 'blade_dance' ) end

    -- Fel Barrage @ 5 stacks (with Momentum)
    if talented.momentum and momentum and fel_barrage_stacks == 5 and ready('fel_barrage') then rec( 'fel_barrage' ) end

    -- Throw Glaive @ 2 stacks (with Momentum and Bloodlet)
    if talented.momentum and momentum and fel_barrage_stacks == 2 and talented.bloodlet and ready( 'throw_glaive' ) then rec( 'throw_glaive' ) end

    -- Fel Eruption
    if talented.fel_eruption and ready( 'fel_eruption') then rec( 'fel_eruption' ) end

    -- Felblade (if fury deficit >= 30)
    if talented.felblade and fury_deficit >= 30 and ready( 'felblade') then rec( 'felblade' ) end

     -- Annihilation (with Momentum)
    if talented.momentum and momentum and demon_form and ready( 'annihilation' ) then rec( 'annihilation' ) end

    -- Throw Glaive (with Momentum and Bloodlet)
    if talented.momentum and momentum and talented.bloodlet and ready( 'throw_glaive' ) then rec( 'throw_glaive' ) end

    -- Eye Beam (if Anguish in Artifact and Momentum) -- @TODO Anguish detection
    if talented.momentum and momentum and ready( 'eye_beam' ) then rec( 'eye_beam' ) end

    -- Chaos Strike (with Momentum)
    if talented.momentum and momentum and not demon_form and ready( 'chaos_strike' ) then rec( 'chaos_strike' ) end

    -- Fel Barrage @ 4 stacks (with Momentum)
    if talented.momentum and momentum and fel_barrage_stacks == 4 and ready('fel_barrage') then rec( 'fel_barrage' ) end

    -- Eye Beam
    if not talented.momentum and ready( 'eye_beam' ) then rec( 'eye_beam' ) end

    -- Throw Glaive >= 3 target
    if not demon_form and aura_env.targetCount >= 3 and ready( 'throw_glaive') then rec('throw_glaive') end

    -- Chaos Strike
    if ready( 'chaos_strike' ) then rec( 'chaos_strike' ) end

    -- Demon's Bite
    if ready( 'demons_bite' ) then rec( 'demons_bite' ) end

    -- Throw Glaive
    if ready( 'throw_glaive' ) then rec( 'throw_glaive' ) end


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
