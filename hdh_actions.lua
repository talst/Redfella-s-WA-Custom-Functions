aura_env.updateInterval = 0.03
aura_env.lastUpdate = GetTime()
aura_env.targetWipeInterval = 5

aura_env.danger_treshold = 55
aura_env.critical_treshold = 30

if aura_env.in_combat == nil then aura_env.in_combat = false end

aura_env.enabledToggle = "ALT-SHIFT-T"
aura_env.offCooldownsToggle = "ALT-SHIFT-R"
aura_env.defCooldownsToggle = "ALT-SHIFT-E"

WA_Redfellas_Rot_HDH_Enabled = WeakAurasSaved.displays[aura_env.id].hekiliEnabled == nil and true or WeakAurasSaved.displays[aura_env.id].hekiliEnabled
WA_Redfellas_Rot_HDH_Off_CDs = WeakAurasSaved.displays[aura_env.id].hekiliCooldownsOff == nil and false or WeakAurasSaved.displays[aura_env.id].hekiliCooldownsOff
WA_Redfellas_Rot_HDH_Def_CDs = WeakAurasSaved.displays[aura_env.id].hekiliCooldownsDef == nil and false or WeakAurasSaved.displays[aura_env.id].hekiliCooldownsDef

aura_env.bindsInitialized = false

aura_env.keyhandler = aura_env.keyhandler or CreateFrame("Button", aura_env.id.."_Keyhandler", UIParent)
aura_env.keyhandler.parent = aura_env
aura_env.keyhandler:RegisterForClicks("AnyDown")
aura_env.keyhandler:SetScript("OnClick", function (self, button, down)
        if button == "defCooldowns" then
            WA_Redfellas_Rot_HDH_Def_CDs = not WA_Redfellas_Rot_HDH_Def_CDs
            print("|cFF00FFFFRedfella's Rotation Helper Defensive Cooldowns: " .. ( WA_Redfellas_Rot_HDH_Def_CDs and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        elseif button == "Enabled" then
            WA_Redfellas_Rot_HDH_Enabled = not WA_Redfellas_Rot_HDH_Enabled
            print("|cFF00FFFFRedfella's Rotation Helper: " .. ( WA_Redfellas_Rot_HDH_Enabled and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        elseif button == "offCooldowns" then
            WA_Redfellas_Rot_HDH_Off_CDs = not WA_Redfellas_Rot_HDH_Off_CDs
            print("|cFF00FFFFRedfella's Rotation Offensive Helper: " .. ( WA_Redfellas_Rot_HDH_Off_CDs and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        end

        WeakAurasSaved.displays[self.parent.id].hekiliEnabled = WA_Redfellas_Rot_HDH_Enabled
        WeakAurasSaved.displays[self.parent.id].hekiliCooldownsOff = WA_Redfellas_Rot_HDH_Off_CDs
        WeakAurasSaved.displays[self.parent.id].hekiliCooldownsDef = WA_Redfellas_Rot_HDH_Def_CDs
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
    fel_mastery = { 1, 1, 1 },
    chaos_cleave = { 1, 2, 1 },
    blind_fury = { 1, 3, 1 },

    prepared = { 2, 1, 1 },
    demon_blades = { 2, 2, 1 },
    demonic_appetite = { 2, 3, 1 },

    felblade = { 3, 1, 1 },
    first_blood = { 3, 2, 1 },
    bloodlet = { 3, 3, 1 },

    netherwalk = { 4, 1, 1 },
    desperate_insticts = { 4, 2, 1 },
    soul_rending = { 4, 3, 1 },

    momentum = { 5, 1, 1 },
    fel_eruption = { 5, 2, 1 },
    nemesis = { 5, 3, 1 },

    master_of_the_glaive = {6, 1, 1 },
    unleashed_power = { 6, 2, 1 },
    demon_reborn = { 6, 3, 1 },

    chaos_blades = { 7, 1, 1 },
    fel_barrage = { 7, 2, 1 },
    demonic = {7, 3, 1 }
}

aura_env.talented = {}

aura_env.abilities = {
    demons_bite = 162243,
    chaos_strike = 162794,
    annihilation = 201427,
    blade_dance = 188499,
    death_sweep = 210152,
    fury_of_the_illidari = 201467,
    eye_beam = 198013,
    throw_glaive = 185123,
    fel_barrage = 211053,
    fel_rush = 195072,
    vengeful_retreat = 198793,
    blur = 198589,
    metamorphosis = 191427,
    darkness = 196718,
    nemesis = 206491,
    chaos_blades = 211048,
    netherwalk = 196555,
    fel_eruption = 211881,
    felblade = 213241,
    chaos_nova = 179057
}

aura_env.chargedAbilities = {
    fel_rush = 195072
}

aura_env.abilityNames = {}

for k,v in pairs( aura_env.abilities ) do
    aura_env.abilityNames[ v ] = GetSpellInfo( v )
end

aura_env.cooldowns = {
  blade_dance = 188499,
  death_sweep = 210152,
  fury_of_the_illidari = 201467,
  eye_beam = 198013,
  throw_glaive = 185123,
  fel_barrage = 211053,
  fel_rush = 195072,
  vengeful_retreat = 198793,
  blur = 198589,
  metamorphosis = 191427,
  darkness = 196718,
  nemesis = 206491,
  chaos_blades = 211048,
  netherwalk = 196555,
  fel_eruption = 211881,
  felblade = 213241,
  chaos_nova = 179057
}

aura_env.charges = {}
aura_env.chargeTime = {}
aura_env.chargesMax = {}

aura_env.buffs = {
    metamorphosis = 162264,
    fel_barrage = 222707,
    momentum = 208628,
    blur = 212800
}

aura_env.buffNames = {}

for k,v in pairs( aura_env.buffs ) do
    aura_env.buffNames[ v ] = GetSpellInfo( v )
end

aura_env.buffRemains = {}

aura_env.debuffs = {
    frailty = 224509,
    anguish = 202443,
    bloodlet = 207690
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
    local result = aura_env.cooldowns[ spell ] == 0
    return result
end

function aura_env.health_percentage()
    return math.ceil( (UnitHealth("player") / UnitHealthMax("player") * 100) )
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

function aura_env.get_trait_rank(trait_id)
    local rank = 0
    local loaded = IsAddOnLoaded("LibArtifactData-1.0") or LoadAddOn("LibArtifactData-1.0")
    if loaded then
        aura_env.LAD = aura_env.LAD or LibStub("LibArtifactData-1.0")
        if not aura_env.LAD:GetActiveArtifactID() then
            aura_env.LAD:ForceUpdate()
        end
        local _, traits = aura_env.LAD:GetArtifactTraits()
        if traits then
            for _,v in ipairs(traits) do
                if v.spellID == trait_id then
                    rank = v.currentRank
                    break
                end
            end
        end
    end

    return rank
end
