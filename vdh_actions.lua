aura_env.updateInterval = 0.03
aura_env.lastUpdate = GetTime()
aura_env.targetWipeInterval = 5

aura_env.danger_treshold = 55
aura_env.critical_treshold = 30

if aura_env.in_combat == nil then aura_env.in_combat = false end

aura_env.enabledToggle = "ALT-SHIFT-T"
aura_env.offCooldownsToggle = "ALT-SHIFT-R"
aura_env.defCooldownsToggle = "ALT-SHIFT-E"

WA_Redfellas_Rot_VDH_Enabled = WeakAurasSaved.displays[aura_env.id].hekiliEnabled == nil and true or WeakAurasSaved.displays[aura_env.id].hekiliEnabled
WA_Redfellas_Rot_VDH_Off_CDs = WeakAurasSaved.displays[aura_env.id].hekiliCooldownsOff == nil and false or WeakAurasSaved.displays[aura_env.id].hekiliCooldownsOff
WA_Redfellas_Rot_VDH_Def_CDs = WeakAurasSaved.displays[aura_env.id].hekiliCooldownsDef == nil and false or WeakAurasSaved.displays[aura_env.id].hekiliCooldownsDef

aura_env.bindsInitialized = false

aura_env.keyhandler = aura_env.keyhandler or CreateFrame("Button", aura_env.id.."_Keyhandler", UIParent)
aura_env.keyhandler.parent = aura_env
aura_env.keyhandler:RegisterForClicks("AnyDown")
aura_env.keyhandler:SetScript("OnClick", function (self, button, down)
        if button == "defCooldowns" then
            WA_Redfellas_Rot_VDH_Def_CDs = not WA_Redfellas_Rot_VDH_Def_CDs
            print("|cFF00FFFFRedfella's Rotation Helper Defensive Cooldowns: " .. ( WA_Redfellas_Rot_VDH_Def_CDs and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        elseif button == "Enabled" then
            WA_Redfellas_Rot_VDH_Enabled = not WA_Redfellas_Rot_VDH_Enabled
            print("|cFF00FFFFRedfella's Rotation Helper: " .. ( WA_Redfellas_Rot_VDH_Enabled and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        elseif button == "offCooldowns" then
            WA_Redfellas_Rot_VDH_Off_CDs = not WA_Redfellas_Rot_VDH_Off_CDs
            print("|cFF00FFFFRedfella's Rotation Offensive Helper: " .. ( WA_Redfellas_Rot_VDH_Off_CDs and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        end

        WeakAurasSaved.displays[self.parent.id].hekiliEnabled = WA_Redfellas_Rot_VDH_Enabled
        WeakAurasSaved.displays[self.parent.id].hekiliCooldownsOff = WA_Redfellas_Rot_VDH_Off_CDs
        WeakAurasSaved.displays[self.parent.id].hekiliCooldownsDef = WA_Redfellas_Rot_VDH_Def_CDs
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

aura_env.recommended = 208175
aura_env.timeToReady = 0
aura_env.timeOffset = 0

aura_env.targets = {}
aura_env.targetCount = 0

aura_env.talents = {
    abyssal_strike = { 1, 1, 1 },
    agonizing_flames = { 1, 2, 1 },
    razor_spikes = { 1, 3, 1 },

    feast_of_souls = { 2, 1, 1 },
    fallout = { 2, 2, 1 },
    burning_alive = { 2, 3, 1 },

    felblade = { 3, 1, 1 },
    flame_crash = { 3, 2, 1 },
    fel_eruption = { 3, 3, 1 },

    feed_the_demon = { 4, 1, 1 },
    fracture = { 4, 2, 1 },
    soul_rending = { 4, 3, 1 },

    concentrated_sigils = { 5, 1, 1 },
    sigil_of_chains = { 5, 2, 1 },
    quickened_sigils = { 5, 3, 1 },

    fel_devastation = {6, 1, 1 },
    blade_turning = { 6, 2, 1 },
    spirit_bomb = { 6, 3, 1 },

    last_resort = { 7, 1, 1 },
    nether_bond = { 7, 2, 1 },
    soul_barrier = {7, 3, 1 }
}

aura_env.talented = {}

aura_env.abilities = {
    shear = 203782,
    soul_cleave = 228477,
    immolation_aura = 178740,
    sigil_of_flame = 204596,
    infernal_strike = 189110,
    demon_spikes = 203720,
    metamorphosis = 187827,
    fiery_brand = 204021,
    fel_devastation = 212084,
    soul_barrier = 227225,
    spirit_bomb = 218679,
    fel_eruption = 211881,
    felblade = 213241,
    fracture = 209795,
    throw_glaive = 204157,
    soul_carver = 207407
}

aura_env.chargedAbilities = {
    infernal_strike = 189110,
    demon_spikes = 203720
}

aura_env.abilityNames = {}

for k,v in pairs( aura_env.abilities ) do
    aura_env.abilityNames[ v ] = GetSpellInfo( v )
end

aura_env.cooldowns = {
    metamorphosis = 187827,
    soul_carver = 207407,
}

aura_env.charges = {}
aura_env.chargeTime = {}
aura_env.chargesMax = {}

aura_env.buffs = {
    demon_spikes = 203819,
    metamorphosis = 187827,
    immolation_aura = 178740,
    soul_fragments = 203981,
    soul_barrier = 227225
}

aura_env.buffNames = {}

for k,v in pairs( aura_env.buffs ) do
    aura_env.buffNames[ v ] = GetSpellInfo( v )
end

aura_env.buffRemains = {}

aura_env.debuffs = {
    frailty = 224509
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

function aura_env.soul_fragments()
    local soul_fragments = GetSpellCount(228477) or 0
    return soul_fragments
end

function aura_env.health_percentage()
    return math.ceil( (UnitHealth("player") / UnitHealthMax("player") * 100) )
end



function aura_env.get_power_info(power_id,artifact_id)
   if not power_id then return false end
   local power_info

   if not artifact_id then
      if HasArtifactEquipped() then
         local item_id = GetInventoryItemID("player", 16)
         if artifact[item_id][power_id] then
            power_info = artifact[item_id][power_id]
         end
      end
   elseif artifact[artifact_id] then
      if artifact[artifact_id][power_id] then
         power_info = artifact[artifact_id][power_id]
      end
   end

   return power_info or false
end


function aura_env.get_artifact_trait_rank(trait_id)
    local info = aura_env.get_power_info(trait_id)
    if info then
        return select(3, info)
    else
        return 0
    end
end

function aura_env.get_artifact_multiplier()
    local devour_souls_rank = aura_env.get_artifact_trait_rank(1233)
    local tormented_souls_rank = aura_env.get_artifact_trait_rank(1328)
    -- Devour souls multiplier is 3% * rank
    local multiplier = 1 + devour_souls_rank * 0.03
    -- Tormented Souls multiplier is 10% * rank
    multiplier = multiplier * (1 + tormented_souls_rank * 0.1)
    return multiplier
end

function aura_env.get_external_multiplier()
    local multiplier = 1
    -- Scale heal with priest guardian spirit
    if UnitAura("player", 47788) then multiplier = multiplier * 1.4 end
    -- Scale heal with priest divine hymn
    if UnitAura("player", 64844) then multiplier = multiplier * 1.1 end

    return multiplier
end

-- by MightBeGiant originally
function aura_env.soul_cleave_heal()
    local max_health = UnitHealthMax("player")
    local pain = UnitPower("player")
    if pain < 30 then return 0 end

    -- Stat multipliers
    local ap_base, ap_pos, ap_neg = UnitAttackPower("player")
    local AP = ap_base + ap_pos + ap_neg

    local versatility = GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE) + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
    local vers_multi = 1 + (versatility / 100)

    -- Artifact trait multipliers
    local artifact_multi = aura_env.get_artifact_multiplier()

    -- External buff multipliers
    local external_multi = aura_env.get_external_multiplier()

    -- Soul Fragments healing
    local fragments = select(4, UnitBuff("player", GetSpellInfo(203981))) or 0

    local single_frag_heal = (2.5 * AP) * vers_multi
    local total_frag_heal = single_frag_heal * fragments

    -- Soul Cleave healing

    local base_heal = 2 * AP * 5.5

    local cleave_heal = base_heal * vers_multi * (min(60, pain) / 60) * artifact_multi * external_multi

    -- Total healing
    local total_heal = (total_frag_heal + cleave_heal)
    local heal_percent = math.floor( total_heal / max_health * 100 )

    return heal_percent
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
