aura_env.updateInterval = 0.03
aura_env.lastUpdate = GetTime()
aura_env.targetWipeInterval = 5

-- danger measures (hp %): build up to 2x DS and do VE > DS > DS or DRW if VE down and no RP
aura_env.danger_treshold = 50
aura_env.critical_treshold = 20

aura_env.enabledToggle = "ALT-SHIFT-T"
aura_env.offCooldownsToggle = "ALT-SHIFT-R"
aura_env.defCooldownsToggle = "ALT-SHIFT-E"

WA_Redfellas_Rot_UDK_Enabled = WeakAurasSaved.displays[aura_env.id].hekiliEnabled == nil and true or WeakAurasSaved.displays[aura_env.id].hekiliEnabled
WA_Redfellas_Rot_UDK_Off_CDs = WeakAurasSaved.displays[aura_env.id].hekiliCooldownsOff == nil and false or WeakAurasSaved.displays[aura_env.id].hekiliCooldownsOff
WA_Redfellas_Rot_UDK_Def_CDs = WeakAurasSaved.displays[aura_env.id].hekiliCooldownsDef == nil and false or WeakAurasSaved.displays[aura_env.id].hekiliCooldownsDef

aura_env.bindsInitialized = false

aura_env.keyhandler = aura_env.keyhandler or CreateFrame("Button", aura_env.id.."_Keyhandler", UIParent)
aura_env.keyhandler.parent = aura_env
aura_env.keyhandler:RegisterForClicks("AnyDown")
aura_env.keyhandler:SetScript("OnClick", function (self, button, down)
        if button == "defCooldowns" then
            WA_Redfellas_Rot_UDK_Def_CDs = not WA_Redfellas_Rot_UDK_Def_CDs
            print("|cFF00FFFFRedfella's Rotation Helper Defensive Cooldowns: " .. ( WA_Redfellas_Rot_UDK_Def_CDs and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        elseif button == "Enabled" then
            WA_Redfellas_Rot_UDK_Enabled = not WA_Redfellas_Rot_UDK_Enabled
            print("|cFF00FFFFRedfella's Rotation Helper: " .. ( WA_Redfellas_Rot_UDK_Enabled and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        elseif button == "offCooldowns" then
            WA_Redfellas_Rot_UDK_Off_CDs = not WA_Redfellas_Rot_UDK_Off_CDs
            print("|cFF00FFFFRedfella's Rotation Offensive Helper: " .. ( WA_Redfellas_Rot_UDK_Off_CDs and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        end

        WeakAurasSaved.displays[self.parent.id].hekiliEnabled = WA_Redfellas_Rot_UDK_Enabled
        WeakAurasSaved.displays[self.parent.id].hekiliCooldownsOff = WA_Redfellas_Rot_UDK_Off_CDs
        WeakAurasSaved.displays[self.parent.id].hekiliCooldownsDef = WA_Redfellas_Rot_UDK_Def_CDs
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
    all_will_serve = { 1, 1, 1 },
    bursting_sores = { 1, 2, 1 },
    ebon_fever = { 1, 3, 1 },

    epidemic = { 2, 1, 1 },
    pestilent_pustules = { 2, 2, 1 },
    blighted_rune_weapon = { 2, 3, 1 },

    unholy_frenzy = { 3, 1, 1 },
    castigator = { 3, 2, 1 },
    clawing_shadows = { 3, 3, 1 },

    sludge_belcher = { 4, 1, 1 },
    asphyxiate = { 4, 2, 1 },
    debilitating_infestation = { 4, 3, 1 },

    spell_eater = {5, 1, 1 },
    corpse_shield = { 5, 2, 1 },
    lingering_apparition = { 5, 3, 1 },

    shadow_infusion = { 6, 1, 1 },
    necrosis = { 6, 2, 1 },
    infected_claws = {6, 3, 1 },

    dark_arbiter = { 7, 1, 1 },
    defile = { 7, 2, 1 },
    soul_reaper = { 7, 3, 1 }
}

aura_env.talented = {}

aura_env.abilities = {
    auto_attack = 6603,
    festering_strike = 85948,
    scourge_strike = 55090,
    death_coil = 47541,
    soul_reaper = 130736,
    dark_transformation = 63560,
    outbreak = 77575,
    raise_dead = 46584,
    summon_gargoyle = 49206,
    apocalypse = 220143,
    death_and_decay = 43265,
    epidemic = 207317,
    death_strike = 49998
}

aura_env.chargedAbilities = {
}

aura_env.abilityNames = {}

for k,v in pairs( aura_env.abilities ) do
    aura_env.abilityNames[ v ] = GetSpellInfo( v )
end

aura_env.cooldowns = {
}

aura_env.charges = {}
aura_env.chargeTime = {}
aura_env.chargesMax = {}

aura_env.buffs = {
    dark_succor = 178819
}

aura_env.buffNames = {}

for k,v in pairs( aura_env.buffs ) do
    aura_env.buffNames[ v ] = GetSpellInfo( v )
end

aura_env.buffRemains = {}

aura_env.debuffs = {
    soul_reaper = 130736,
    virulent_plague = 191587,
    scourge_of_worlds = 191748
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
