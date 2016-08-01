aura_env.updateInterval = 0.03
aura_env.lastUpdate = GetTime()
aura_env.targetWipeInterval = 5

-- danger measures (hp %): build up to 2x DS and do VE > DS > DS or DRW if VE down and no RP
aura_env.danger_treshold = 55
aura_env.critical_treshold = 25

aura_env.enabledToggle = "ALT-SHIFT-T"
aura_env.offCooldownsToggle = "ALT-SHIFT-R"
aura_env.defCooldownsToggle = "ALT-SHIFT-E"

WA_Redfellas_Rot_BDK_Enabled = WeakAurasSaved.displays[aura_env.id].hekiliEnabled == nil and true or WeakAurasSaved.displays[aura_env.id].hekiliEnabled
WA_Redfellas_Rot_BDK_Off_CDs = WeakAurasSaved.displays[aura_env.id].hekiliCooldownsOff == nil and false or WeakAurasSaved.displays[aura_env.id].hekiliCooldownsOff
WA_Redfellas_Rot_BDK_Def_CDs = WeakAurasSaved.displays[aura_env.id].hekiliCooldownsDef == nil and false or WeakAurasSaved.displays[aura_env.id].hekiliCooldownsDef

aura_env.bindsInitialized = false

aura_env.keyhandler = aura_env.keyhandler or CreateFrame("Button", aura_env.id.."_Keyhandler", UIParent)
aura_env.keyhandler.parent = aura_env
aura_env.keyhandler:RegisterForClicks("AnyDown")
aura_env.keyhandler:SetScript("OnClick", function (self, button, down)
        if button == "defCooldowns" then
            WA_Redfellas_Rot_BDK_Def_CDs = not WA_Redfellas_Rot_BDK_Def_CDs
            print("|cFF00FFFFRedfella's Rotation Helper Defensive Cooldowns: " .. ( WA_Redfellas_Rot_BDK_Def_CDs and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        elseif button == "Enabled" then
            WA_Redfellas_Rot_BDK_Enabled = not WA_Redfellas_Rot_BDK_Enabled
            print("|cFF00FFFFRedfella's Rotation Helper: " .. ( WA_Redfellas_Rot_BDK_Enabled and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        elseif button == "offCooldowns" then
            WA_Redfellas_Rot_BDK_Off_CDs = not WA_Redfellas_Rot_BDK_Off_CDs
            print("|cFF00FFFFRedfella's Rotation Offensive Helper: " .. ( WA_Redfellas_Rot_BDK_Off_CDs and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        end

        WeakAurasSaved.displays[self.parent.id].hekiliEnabled = WA_Redfellas_Rot_BDK_Enabled
        WeakAurasSaved.displays[self.parent.id].hekiliCooldownsOff = WA_Redfellas_Rot_BDK_Off_CDs
        WeakAurasSaved.displays[self.parent.id].hekiliCooldownsDef = WA_Redfellas_Rot_BDK_Def_CDs
end)

function aura_env.setupBinds()

    if InCombatLockdown() then return end

    ClearOverrideBindings( aura_env.keyhandler )
    SetOverrideBindingClick( aura_env.keyhandler, true, aura_env.enabledToggle, aura_env.id.."_Keyhandler", "Enabled" )
    SetOverrideBindingClick( aura_env.keyhandler, true, aura_env.offCooldownsToggle, aura_env.id.."_Keyhandler", "offCooldowns" )
    SetOverrideBindingClick( aura_env.keyhandler, true, aura_env.defCooldownsToggle, aura_env.id.."_Keyhandler", "defCooldowns" )

    print("|cFF00FFFFRedfella's Rotation Helper|r:  Keybinds are now active.")
    print("Enable/Disable - |cFFFFD100" .. aura_env.enabledToggle .. "|r.")
    print("Toggle Defensive Cooldowns - |cFFFFD100" .. aura_env.defCooldownsToggle .. "|r.")
    print("Toggle Offensive Cooldowns - |cFFFFD100" .. aura_env.offCooldownsToggle .. "|r.")
    print("You can *carefully* change these keybinds in the " .. aura_env.id .. " WeakAura on the Actions Tab, On Init, Expand Text Editor and see lines 11 to 13." )

    aura_env.bindsInitialized = true

end

aura_env.setupBinds()

aura_env.showCooldownRing = true
aura_env.invertCooldownRing = false
aura_env.showRangeHighlight = true



aura_env.recommended = 204945
aura_env.timeToReady = 0
aura_env.timeOffset = 0

aura_env.targets = {}
aura_env.targetCount = 0

aura_env.talents = {
    bloodworms = { 1, 1, 1 },
    hearbreaker = { 1, 2, 1 },
    bloddrinker = { 1, 3, 1 },

    rapid_decomposition = { 2, 1, 1 },
    soulgorge = { 2, 2, 1 },
    spectral_deflection = { 2, 3, 1 },

    ossuary = { 3, 1, 1 },
    blood_tap = { 3, 2, 1 },
    antimagic_barrier = { 3, 3, 1 },

    mark_of_blood = { 4, 1, 1 },
    red_thirst = { 4, 2, 1 },
    tombstone = { 4, 3, 1 },

    tightening_grasp = {5, 1, 1 },
    tremble_before_me = { 5, 2, 1 },
    march_of_the_damned = { 5, 3, 1 },

    will_of_the_necropolis = { 6, 1, 1 },
    rune_tap = { 6, 2, 1 },
    foul_bulwark = {6, 3, 1 },

    bonestorm = { 7, 1, 1 },
    blood_mirror = { 7, 2, 1 },
    purgatory = { 7, 3, 1 }
}

aura_env.talented = {}

aura_env.abilities = {
    death_strike = 49998,
    death_and_decay = 43265,
    marrowrend = 195182,
    blood_boil = 50842,
    heart_strike = 206930,
    dancing_rune_weapon = 49028,
    vampiric_blood = 55233,
    blood_tap = 221699,
    bonestorm = 194844,
    consumption = 205223
}

aura_env.chargedAbilities = {
    blood_boil = 50842
}

aura_env.abilityNames = {}

for k,v in pairs( aura_env.abilities ) do
    aura_env.abilityNames[ v ] = GetSpellInfo( v )
end

aura_env.cooldowns = {
    dancing_rune_weapon = 49028,
    vampiric_blood = 55233,
    blood_boil = 50842,
    death_and_decay = 43265,
    poo_tap = 221699
}

aura_env.charges = {}
aura_env.chargeTime = {}
aura_env.chargesMax = {}

aura_env.buffs = {
    bone_shield = 195181,
    crimson_scourge = 81136,
    ossuary = 219788,
    death_and_decay = 188290,
    dancing_rune_weapon = 81256,
    vampiric_blood = 55233
}

aura_env.buffNames = {}

for k,v in pairs( aura_env.buffs ) do
    aura_env.buffNames[ v ] = GetSpellInfo( v )
end

aura_env.buffRemains = {}

aura_env.debuffs = {
    blood_plague = 55078
}

aura_env.debuffNames = {}

for k,v in pairs( aura_env.debuffs ) do
    aura_env.debuffNames[ v ] = GetSpellInfo( v )
end

aura_env.debuffRemains = {}

function aura_env.rec( spell )
    aura_env.recommended = aura_env.abilities[ spell ]
    aura_env.timeToReady = aura_env.cooldowns[ spell ]
end

function aura_env.ready( spell )
    local result = aura_env.cooldowns[ spell ] < aura_env.timeToReady
    return result
end

function aura_env.runes_available()
    local readycount = 0
    local x = 0

    while (x < 6) do
        x = x + 1
        local temp = GetRuneCooldown(x)
        if temp == 0 then readycount = readycount + 1 end
    end

    return readycount
end

function aura_env.time_to_x_runes(runes_required)
    if not runes_required then return 0 end
    -- #1 figure how many runes we have ready for use
    local runes_ready = aura_env.runes_available()

    -- #2 figure how many runes we still need, since we might have some runes up already (checked in #1)
    local runes_required = runes_required - runes_ready

    if runes_required <= 0 then
      return 0
    else
      -- #3 start figuring out the time in seconds before we reach runes_required
      local runestable = {}
      local current_rune_index = 0
      local current_rune_cd = 0
      local start = 0
      local duration = 0

      -- store every runes recharge time to a table
      while current_rune_index < 6 do
          current_rune_index = current_rune_index + 1
          start, duration, runeReady = GetRuneCooldown(current_rune_index)
          current_rune_cd = start + duration - GetTime()
          -- if rune is charging, store the precies value
          if current_rune_cd > 0 then
            runestable[current_rune_index] = current_rune_cd
          -- if rune isn't charging, store a dummy value that doesn't get stop us from using min() to grab smallest cd
          else
            runestable[current_rune_index] = 999
          end
      end

      -- make a copy of runestable for manipulating
      local t = runestable
      local x = 0

      -- loop as many times as we need runes
      while x < runes_required do
          x = x + 1
          local key, min = 1, t[1]
          for k, v in ipairs(t) do
              if t[k] < min then
                  key, min = k, v
              end
          end

          -- if we're going for a next lap, store a dummy value that doesn't get stop us from using min() to grab smallest cd
          if x < runes_required then t[key] = 999 end
          runestable = t
      end

      -- grab the smallest cd from our table, which after all of this fuckery should tell us how long until we have required amount of runes
      local next_ready_time = math.min(unpack(runestable))

      -- get rid of our dummy value if we already had more runes than asked of this function
      if next_ready_time == 999 then next_ready_time = 0 end
      return next_ready_time
    end
end

-- Alarog's DS predictor hookup, un-localized
function aura_env.death_strike_heal()
    local dmg = 0
    local healMult = 1
    local heal, health, healScaled, healPercent
    local deathStrikeWindow = 5
    local latencyEstimate = 0.2

    deathStrikeDamageHistory = deathStrikeDamageHistory or {}
    deathStrikeDamageTimeHistory = deathStrikeDamageTimeHistory or {}

    if deathStrikeDamageTimeHistory[1] ~= nil then
        if time() > (deathStrikeDamageTimeHistory[1] + deathStrikeWindow - latencyEstimate) then
            table.remove(deathStrikeDamageHistory,1)
            table.remove(deathStrikeDamageTimeHistory,1)
        end
    end

    for i,v in ipairs(deathStrikeDamageHistory) do
        dmg = dmg + tonumber(v)
    end

    heal = dmg * 0.2
    health = UnitHealthMax("player")

    if (heal / health) < 0.07 then
        heal = health * 0.07
    end

    -- Scale healing based on versatility
    healMult = 1 + GetCombatRatingBonus(29)/100

    -- Scale heal estimate when Vampiric Blood is active
    if UnitAura("player", 55233) then
        -- TODO
        --   This will need to scale with the number of
        --   ranks in the Vampiric Fangs artifact trait, but do
        --   not know how to do that yet (not in beta)
        healMult = healMult * 1.3
    end

    -- Scale heal with priest guardian spirit
    if UnitAura("player", 47788) then
        healMult = healMult * 1.4
    end

    -- Scale heal with priest divine hymn
    if UnitAura("player", 64844) then
        healMult = healMult * 1.1
    end

    -- TODO
    --   This will also need to scale with any external CDs
    --   that will increase healing taken.  I haven't done
    --   an audit of them though, but maybe other DKs can
    --   contribute

    heal = heal * healMult

    if (heal / health) < 0.1 then
        heal = health * 0.1
    end

    healScaled = math.floor( (heal+500) / 1000 )
    healPercent = math.floor( heal / health * 100 )


    return healPercent
    --return healScaled -- debug
end


function aura_env.get_unit_aura_value(aura, valueType, unit, sourceUnit)
    if not aura then return end valueType, unit = valueType or 'name', unit or 'player' if not UnitExists(unit) then return end local v, value = {}
    local GetAuraValues = function(unit, aura, filter)
        local v, filter = {}, filter or 'HELPFUL'
        v.name, v.rank, v.icon, v.count, v.auraType, v.duration, v.expirationTime, v.unitCaster, v.isStealable, v.shouldConsolidate, v.spellId, v.canApplyAura, v.isBossDebuff, v.value1, v.value2, v.value3 = UnitAura(unit, aura, type(aura)=='number' and filter or nil, filter)
        return v
    end
    local GetAuraValue = function(v, t, s) if v[t] then if s then if v.unitCaster and UnitExists(s) and v.unitCaster == s then return v[t] end else return v[t] end end end
    local ScanAuras = function(aura, valueType, unit, sourceUnit)
        local output = nil
        if type(aura) == 'string' then
            v = GetAuraValues(unit, aura)
            output = GetAuraValue(v,valueType,sourceUnit)
            if output then return output end
            v = GetAuraValues(unit, aura, 'HARMFUL')
            output = GetAuraValue(v,valueType,sourceUnit)
            if output then return output end
        elseif type(aura) == 'number' then
            for i=1,40 do
                v = GetAuraValues(unit, i)
                output = GetAuraValue(v,valueType,sourceUnit)
                if v.spellId and v.spellId == aura then if output then return output end end
                v = GetAuraValues(unit, i, 'HARMFUL')
                output = GetAuraValue(v,valueType,sourceUnit)
                if v.spellId and v.spellId == aura then if output then return output end end
            end
        end
    end
    if type(aura) == 'table' then
        local output = nil
        for iAura,vAura in pairs(aura) do
            output = ScanAuras(vAura, valueType, unit, sourceUnit)
            if output then return output end
        end
    else
        return ScanAuras(aura, valueType, unit, sourceUnit)
    end
end

function aura_env.chargeCt( spell )
    local rounded = tonumber( format( "%.1f", aura_env.timeOffset ) ) - 0.1
    return min( aura_env.chargesMax[ spell ], aura_env.charges[ spell ] + rounded / aura_env.chargeTime[ spell ] )
end


function aura_env.cdLeft( spell )
    return max( 0, aura_env.cooldowns[ spell ] - aura_env.timeOffset )
end
