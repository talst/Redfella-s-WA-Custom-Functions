-- COMBAT_LOG_EVENT_UNFILTERED,PLAYER_REGEN_ENABLED,PLAYER_REGEN_DISABLED
function ( event, _, subtype, _, sourceGUID, sourceName, _, _, destGUID, destName, destFlags, _, spellID, spellName, _, amount, interrupt, a, b, c, d, offhand, multistrike )

    if event == 'PLAYER_REGEN_ENABLED' then
        -- Setup keybinds if not yet setup
        if not aura_env.bindsInitialized then aura_env.setupBinds() end
        aura_env.in_combat = false
        return false
    end

    if event == 'PLAYER_REGEN_DISABLED' then
        aura_env.in_combat = true
        return false
    end

    local me = UnitGUID("player")

    if aura_env.targets[destGUID] and ( subtype == 'UNIT_DIED' or subtype == 'UNIT_DESTROYED' ) then
        aura_env.targets[destGUID] = nil
        aura_env.targetCount = max( 0, aura_env.targetCount - 1 )
        return
    end

    local hostile = nil

    if destFlags then
      hostile = ( bit.band( destFlags, COMBATLOG_OBJECT_REACTION_FRIENDLY ) == 0 )
    end
    local time = GetTime()

    -- If being melee'd, count as a target.
    if destGUID == me and sourceGUID ~= me and ( subtype == "SWING_DAMAGE" or subtype == "SWING_MISSED" ) then
        if not aura_env.targets[sourceGUID] then
            aura_env.targetCount = aura_env.targetCount + 1
        end
        aura_env.targets[sourceGUID] = time
        return
    end

    -- Otherwise, just watch what I do.
    if sourceGUID ~= me then
        return
    end

    if hostile and sourceGUID ~= destGUID then
        if subtype == 'SPELL_AURA_APPLIED'  or subtype == 'SPELL_AURA_REFRESH' or subtype == 'SPELL_AURA_APPLIED_DOSE' or
        subtype == 'SPELL_PERIODIC_DAMAGE' or subtype == 'SPELL_PERIODIC_MISSED' or subtype == 'SPELL_DAMAGE' or subtype == 'SPELL_MISSED' or subtype == 'SWING_DAMAGE' or subtype == 'SWING_MISSED' then
            if not aura_env.targets[ destGUID ] then
                aura_env.targetCount = aura_env.targetCount + 1
            end
            aura_env.targets[ destGUID ] = time

        end

    end

    return

end
