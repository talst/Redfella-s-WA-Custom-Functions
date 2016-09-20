-- UNIT_POWER_FREQUENT, SPELL_UPDATE_COOLDOWN, SPELL_UPDATE_CHARGES, PLAYER_TARGET_CHANGED, UNIT_SPELLCAST_SUCCEEDED
function ()
    if not WA_Redfellas_Rot_UDK_Enabled or UnitOnTaxi("player") or not UnitCanAttack("player", "target") then
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

    local target_health = UnitHealth("target");
    local target_health_percentage = math.ceil( (UnitHealth("target") / UnitHealthMax("target") * 100) )
    local target_health_max = UnitHealthMax("target");
    local target_missing_health_percentage = 100 - target_health_percentage

    local dead_soon = false
    local recommend_cooldowns = false

    if WA_Redfellas_Rot_UDK_Off_CDs
        and target_health > 50000000
        or target_health_max > 500000000
    then recommend_cooldowns = true end

    if target_health < 10000000 and target_health_max > 10000000
    then dead_soon = true end

    if target_health < 2500000
    then dead_soon = true end

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

    local danger_treshold = aura_env.danger_treshold
    local critical_treshold = aura_env.critical_treshold
    local ready = aura_env.ready
    local rec = aura_env.rec
    local runes_available = aura_env.runes_available()
    local artifact_weapon = IsEquippedItem(128403)
    local runic_power = UnitPower("player")
    local runic_power_max = UnitPowerMax("player")
    local runic_power_deficit = runic_power_max - runic_power
    local runic_power_cap = 20 -- @TODO
    local festering_wounds = select(4,UnitDebuff("target",GetSpellInfo(194310))) or 0
    local soul_reaper_stacks = aura_env.get_unit_aura_value(215711, 'count') or 0

    aura_env.bank = false
    aura_env.prepare = false

    local wound_treshold = 3
    local pop_wounds = true
    local rune_treshold = 0

    -- Bank 8 wounds for SR + Apocalypse
    if recommend_cooldowns
        and cooldowns.soul_reaper < 10
        and cooldowns.apocalypse < 10
    then
        aura_env.prepare = true
        wound_treshold = 8
        pop_wounds = false
        rune_treshold = 1 -- for SR
    end

    -- Bank 4 runes and 3 wounds for SR w/o Apocalypse
    if recommend_cooldowns
        and cooldowns.soul_reaper < 8
        and cooldowns.apocalypse > 40
    then
        aura_env.prepare = true
        wound_treshold = 3
        pop_wounds = false
        rune_treshold = 3 -- for SR + 3x SS, basicly 4, but 3 GCDs is enough to regen 1 rune
    end

    ---------------
    -- APL START --
    ---------------
    if not aura_env.in_combat then
        -- DT on CD
        if ready( 'dark_transformation' )
            and recommend_cooldowns
        then rec( 'dark_transformation' ) end

        -- Gargoyle on CD
        if ready( 'summon_gargoyle' )
            and recommend_cooldowns
        then rec( 'summon_gargoyle' ) end

        -- Keep VirulentPlague up
        if ready( 'outbreak' )
            and debuffRemains.virulent_plague < 0.5
        then rec( 'outbreak' ) end
    else

        -- Death Strike when near death
        if ready( 'death_strike' )
            and aura_env.critical_treshold > health_percentage
        then rec( 'death_strike' ) end

        -- Keep VirulentPlague up, Pandemic it before SR w/o Apocalypse
        if ready( 'outbreak' )
            and (cooldowns.soul_reaper < 5 and debuffRemains.virulent_plague < 5)
            or debuffRemains.virulent_plague < 3.15
        then rec( 'outbreak' ) end

        -- DT on CD
        if ready( 'dark_transformation' )
            and recommend_cooldowns
        then rec( 'dark_transformation' ) end

        -- Gargoyle on CD
        if ready( 'summon_gargoyle' )
            and recommend_cooldowns
        then rec( 'summon_gargoyle' ) end

        -- SR if Apocalypse is ready and got 8 wounds
        if ready( 'soul_reaper' )
            and recommend_cooldowns
            and festering_wounds >= 7
            and cooldowns.apocalypse == 0
        then rec( 'soul_reaper' ) end

        -- SR if Apocalypse CD > 45s and got 3 runes and 3 wounds
        if ready( 'soul_reaper' )
            and recommend_cooldowns
            and festering_wounds >= 3
            and cooldowns.apocalypse >= 40
            and runes_available >= 3
        then rec( 'soul_reaper' ) end


        -- Apocalypse when target is affected by SR
        if ready( 'apocalypse' )
            and recommend_cooldowns
            and festering_wounds >= 7
            and debuffRemains.soul_reaper > 0
        then rec( 'apocalypse' ) end


        -- Scourge Strike to get 3xSR haste buff if debuffed by SR
        if ready( 'scourge_strike' )
            and festering_wounds > 0
            and debuffRemains.soul_reaper > 0
            and soul_reaper_stacks < 3
        then rec( 'scourge_strike' ) end


        -- Epidemic when fighting multiple targets if talent taken
        if ready( 'epidemic' )
            and talented.epidemic
            and aura_env.targetCount >= 3
        then rec( 'epidemic') end


        -- Death and Decay on CD when fighting multiple targets
        if ready('death_and_decay' )
            and spend_runes
            and runes_available >= rune_treshold
            and aura_env.targetCount >= 2
        then rec( 'death_and_decay' ) end


        -- Scourge Strike when fighting multiple targets after Epidemic & DnD are already used
        if ready( 'scourge_strike' )
            and spend_runes
            and pop_wounds
            and runes_available >= rune_treshold
            and cooldowns.epidemic > 0
            and cooldowns.death_and_decay > 0
            and aura_env.targetCount >= 3
        then rec( 'scourge_strike') end

        -- Death Strike to fill a global when it's free and we need healing
        if ready( 'death_strike' )
            and health_percentage < 80
            and buffRemains.dark_succor > 0
        then rec( 'death_strike' ) end

        -- Death Coil when RP cap is near or we want to reduce DT cooldown
        if ready( 'death_coil' )
            and (runic_power_deficit <= 20 and cooldowns.dark_transformation < 32 and cooldowns.dark_transformation > 42)
            or (cooldowns.dark_transformation > 5 and cooldowns.dark_transformation < 32)
        then rec( 'death_coil' ) end

        -- Build required amount of wounds
        if ready( 'festering_strike' )
            and festering_wounds < wound_treshold
            and runes_available >= rune_treshold
        then rec( 'festering_strike' ) end

        -- Pop wounds unless special situation applies
        if ready( 'scourge_strike' )
            and pop_wounds
            and runes_available >= rune_treshold
            and (festering_wounds >= wound_treshold or dead_soon)
        then rec( 'scourge_strike' ) end

        -- Death Strike to fill a global when it's free
        if ready( 'death_strike' )
            and buffRemains.dark_succor > 0
        then rec( 'death_strike' ) end

        -- Death Coil if no runes
        if ready( 'death_coil' )
        then rec( 'death_coil' ) end

        -- Nothing to recommend, display AA icon instead of green box
        if ready( 'auto_attack' )
        then
             rec( 'auto_attack' )
             return false
         end
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
