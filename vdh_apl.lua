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

    local soul_fragments = aura_env.soul_fragments()
    local pain = UnitPower("player")
    local pain_max = UnitPowerMax("player")
    local pain_deficit = pain_max - pain
    local pain_deficit_limit = 25
    local health_percentage = math.ceil( (UnitHealth("player") / UnitHealthMax("player") * 100) )
    local missing_health_percentage = 100 - health_percentage
    local soul_cleave_heal = aura_env.soul_cleave_heal()
    local in_combat = aura_env.in_combat
    local fiery_demise_rank = aura_env.get_trait_rank(212817);

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
    local artifact_weapon = IsEquippedItem(128832)

    local use_sigil_of_flame = false
    if (talented.flame_crash and debuffRemains.sigil_of_flame <= 1) or not talented.flame_crash then use_sigil_of_flame = true end

    local wait_for_priority_abilities = false
    if cooldowns.immolation_aura < 0.5 and pain_deficit >= 15 then wait_for_priority_abilities = true end
    if talented.felblade and cooldowns.felblade < 0.5 and pain_deficit >= pain_deficit_limit then wait_for_priority_abilities = true end
    if talented.fel_eruption and cooldowns.fel_eruption < 0.5 then wait_for_priority_abilities = true end
    if use_sigil_of_flame and aura_env.targetCount >= 2 and cooldowns.sigil_of_flame < 0.5 then wait_for_priority_abilities = true end
    if health_percentage <= danger_treshold and cooldowns.fel_devastation < 0.5 and pain >= 30 then wait_for_priority_abilities = true end

    ---------------
    -- APL START --
    ---------------

    if not in_combat then
        -- Sigil of Flame
        if ready( 'sigil_of_flame' )
        then rec( 'sigil_of_flame' ) end

        -- Infernal Strike
        if ready( 'infernal_strike' )
            and chargeCt('infernal_strike') >= 1
        then rec( 'infernal_strike' ) end

        -- Throw Glaive
        if ready( 'throw_glaive' )
        then rec( 'throw_glaive' ) end

        -- Just so we don't ever get a green icon
        if ready( 'shear' )
        then rec( 'shear' ) end
    else
        -- Defensive cooldowns are toggled on
        if WA_Redfellas_Rot_VDH_Def_CDs then
            -- Soul Carver
            if ready( 'soul_carver' )
                and artifact_weapon
                and health_percentage <= 75
                and soul_fragments == 0
            then rec( 'soul_carver' ) end

            -- Demon Spikes
            if ready( 'demon_spikes' )
                and chargeCt('demon_spikes') >= 1.75
                and buffRemains.demon_spikes == 0
                and pain >= 20
                and health_percentage <= 85
            then rec( 'demon_spikes' ) end

            -- Fiery Brand
            if ready( 'fiery_brand' )
                and buffRemains.demon_spikes == 0
                and buffRemains.metamorphosis == 0
                and buffRemains.soul_barrier == 0
                and chargeCt('demon_spikes') < 0.8
            then rec( 'fiery_brand' ) end

            -- Meta if: health drops below critical treshold (30%)
            if ready( 'metamorphosis' )
                and health_percentage <= critical_treshold
            then rec( 'metamorphosis' ) end

            -- Below danger treshold (55%) hp
            if health_percentage <= danger_treshold then
                -- Fel Devastation
                if ready( 'fel_devastation' )
                    and talented.fel_devastation
                    and pain >= 30
                then rec( 'fel_devastation' ) end

                -- Soul Barrier
                if ready( 'soul_barrier' )
                    and talented.soul_barrier
                then rec( 'soul_barrier' ) end

                -- Soul Cleave
                if ready( 'soul_cleave' )
                    and pain >= 60
                then rec( 'soul_cleave' ) end

                -- Fiery Brand
                if ready( 'fiery_brand' )
                    and buffRemains.demon_spikes == 0
                    and buffRemains.metamorphosis == 0
                    and buffRemains.soul_barrier == 0
                then rec( 'fiery_brand' ) end

                -- Generate Pain for healing instead of bothering with pure DPS abilities when in danger
                if ready( 'immolation_aura' )
                    and pain_deficit >= 15
                then rec( 'immolation_aura' ) end

                if ready( 'felblade' )
                    and talented.felblade
                    and pain_deficit >= pain_deficit_limit
                then rec( 'felblade' ) end

                if ready( 'shear' )
                then rec( 'shear' ) end
            end
        end

        -- Soul Cleave for healing
        if ready( 'soul_cleave' )
            and pain >= 60
            and soul_cleave_heal <= missing_health_percentage
        then rec( 'soul_cleave' ) end

        -- Immolation Aura
        if ready( 'immolation_aura' )
            and pain_deficit >= 15
        then rec( 'immolation_aura' ) end

        -- Sigil of Flame
        if ready( 'sigil_of_flame' )
            and aura_env.targetCount >= 2
            and debuffRemains.sigil_of_flame <= 1
        then rec( 'sigil_of_flame' ) end

        -- Spirit Bomb
        if ready( 'spirit_bomb' )
            and talented.spirit_bomb
            and debuffRemains.frailty == 0
            and soul_fragments >= 1
        then rec( 'spirit_bomb' ) end

        -- Felblade
        if ready( 'felblade' )
            and talented.felblade
            and pain_deficit >= pain_deficit_limit
        then rec( 'felblade' ) end

        -- Having these enabled is NOT optimal for proper defensive play
        -- Enable them only at your own peril (questing, overgearing content etc.)
        if WA_Redfellas_Rot_VDH_Off_CDs then
            -- Fiery Brand
            --
            -- Note: When using also Fel Devastation and Fiery Demise, recommend
            -- only if we can combo FB+FD
            --
            -- Without Fiery Demise or Fel Devastation, just use on CD
            if ready( 'fiery_brand' )
                and (
                    ( fiery_demise_rank >= 1 and talented.fel_devastation and cooldowns.fel_devastation == 0 and pain >= 30 )
                    or ( not talented.fel_devastation or fiery_demise_rank == 0 )
                )
            then rec( 'fiery_brand' ) end

            -- Fel Devastation
            --
            -- Note: Should be used on single target in combination with Fiery
            -- Brand if you have any ranks in Fiery Demise artifact trait
            --
            -- Without Fiery Demise, just use on CD
            if ready( 'fel_devastation' )
                and talented.fel_devastation
                and pain >= 30
                and (
                    (fiery_demise_rank >= 1 and aura_env.targetCount == 1 and debuffRemains.fiery_brand >= 2)
                    or (fiery_demise_rank == 0 or aura_env.targetCount >= 2)
                )
            then rec( 'fel_devastation' ) end

            -- Spirit Bomb
            if ready( 'spirit_bomb' )
                and talented.spirit_bomb
                and aura_env.targetCount >= 2
                and soul_fragments >= 1
            then rec( 'spirit_bomb' ) end

            -- Soul Carver
            if ready( 'soul_carver' )
            then rec( 'soul_carver' ) end
        end

        -- Fracture
        if ready( 'fracture' )
            and aura_env.targetCount == 1
            and talented.fracture
            and pain_deficit < pain_deficit_limit
        then rec( 'fracture' ) end
        -- Soul Cleave for DPS

        if ready( 'soul_cleave' )
            and ( not talented.fracture or aura_env.targetCount >= 2 )
            and pain_deficit < pain_deficit_limit
        then rec( 'soul_cleave' ) end

        -- Fel Eruption
        if ready( 'fel_eruption' )
            and talented.fel_eruption
        then rec( 'fel_eruption' ) end

        -- Infernal Strike
        --
        -- Note: Don't cap charges or use when available during cleave without
        -- overlapping SoF dot when using Flame Crash
        if ready( 'infernal_strike' )
            and use_sigil_of_flame
            and ( chargeCt('infernal_strike') >= 1.85 or aura_env.targetCount >= 2 )
        then rec( 'infernal_strike' ) end

        -- Shear
        if ready( 'shear' ) and
            not wait_for_priority_abilities
        then rec( 'shear' ) end
    end

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
