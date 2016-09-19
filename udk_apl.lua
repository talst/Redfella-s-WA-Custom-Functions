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
    local target_missing_health_percentage = 100 - health_percentage

    -- suggest cds if the target isn't a trash mob
    local recommend_cooldowns = false
    if WA_Redfellas_Rot_UDK_Off_CDs
        and target_health_max > 150000000
    then recommend_cooldowns = true end

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
    local runes = aura_env.runes_available()
    local ready = aura_env.ready
    local rec = aura_env.rec
    local runes = aura_env.runes_available()
    local artifact_weapon = IsEquippedItem(128403)

    local runic_power = UnitPower("player")
    local runic_power_max = UnitPowerMax("player")
    local runic_power_deficit = runic_power_max - runic_power
    local runic_power_cap = 20 -- @TODO


    local festering_wounds = select(4,UnitDebuff("target",GetSpellInfo(194310))) or 0

    local prepare_for_SR_and_Apo = false

    -- SR + Apocalypse are up or will be up soon, get to 8 wounds
    if festering_wounds < 8
        and cooldowns.soul_reaper < 10
        and cooldowns.apocalypse < 10
    then prepare_for_SR_and_Apo = true end

    -- SR is up or will be up soon, get to 3 wounds
    if festering_wounds < 3
        and cooldowns.soul_reaper < 5
    then prepare_for_SR_and_Apo = true end

    ---------------
    -- APL START --
    ---------------

    -- Keep VirulentPlague up
    if ready( 'outbreak' )
        and debuffRemains.virulent_plague == 0
    then rec( 'outbreak' ) end

    -- DT on CD
    if ready( 'dark_transformation' )
    then rec( 'dark_transformation' ) end

    -- Gargoyle on CD
    if ready( 'summon_gargoyle' )
    then rec( 'summon_gargoyle' ) end

    -- SR if Apocalypse is ready and got 8 wounds
    if ready( 'soul_reaper' )
        and festering_wounds >= 8
        and cooldowns.apocalypse == 0
    then rec( 'soul_reaper' ) end

    -- SR if Apocalypse CD > 45s and got 3 runes and 3 wounds
    if ready( 'soul_reaper' )
        and festering_wounds >= 3
        and cooldowns.apocalypse >= 45
        and runes_available >= 3
    then rec( 'soul_reaper' ) end

    -- Apocalypse when target is affected by SR
    if ready( 'apocalypse' )
        and festering_wounds >= 8
        and debuffRemains.soul_reaper > 0
    then rec( 'apocalypse' ) end

    -- Scourge Strike to pop 3 wounds when SR is active and Apocalypse is on cooldown
    if ready( 'scourge_strike' )
        and cooldowns.apocalypse > 0
        and debuffRemains.soul_reaper > 0
    then rec( 'scourge_strike' ) end

    -- Epidemic when fighting multiple targets if talent taken
    if ready( 'epidemic' )
        and talented.epidemic
        and aura_env.targetCount >= 3
    then rec( 'epidemic') end

    -- Death and Decay on CD when fighting multiple targets
    if ready('death_and_decay' )
        and aura_env.targetCount >= 2
    then rec( 'death_and_decay' ) end

    -- Scourge Strike when fighting multiple targets after Epidemic & DnD are already used
    if ready( 'scourge_strike' )
        and not prepare_for_SR_and_Apo
        and cooldowns.apocalypse > 5
        and cooldowns.epidemic > 0
        and cooldowns.death_and_decay > 0
        and aura_env.targetCount >= 3
    then rec( 'scourge_strike') end

    -- Death Coil when RP cap is near or we want to reduce DT cooldown
    if ready( 'death_coil' )
        and runic_power_deficit <= 20
        or (cooldowns.dark_transformation > 5 and cooldowns.dark_transformation < 30)
    then rec( 'death_coil' ) end

    -- Build wounds in anticipation of Apocalypse
    if ready( 'festering_strike' )
        and prepare_for_SR_and_Apo
    then rec( 'festering_strike' ) end

    -- Regular wound rotation
    if ready( 'festering_strike' )
        and not prepare_for_SR_and_Apo
        and festering_wounds < 3
    then rec( 'festering_strike' ) end

    if ready( 'scourge_strike' )
        and not prepare_for_SR_and_Apo
        and festering_wounds >= 3
    then rec( 'scourge_strike' ) end

    -- Death Coil if no runes
    if ready( 'death_coil' )
        and runes_available == 0
    then rec( 'death_coil' ) end

    -- Nothing to recommend, display AA icon instead of green box
    if ready( 'auto_attack' )
    then rec( 'auto_attack' ) end

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
