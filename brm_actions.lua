aura_env.updateInterval = 0.03
aura_env.lastUpdate = GetTime()
aura_env.targetWipeInterval = 5

aura_env.purify_treshold = 60

aura_env.showCooldownRing = true
aura_env.invertCooldownRing = false
aura_env.showRangeHighlight = true

aura_env.enabledToggle = "ALT-SHIFT-T"
aura_env.cooldownsToggle = "ALT-SHIFT-R"

WA_Redfellas_Rot_BRM_Enabled = WeakAurasSaved.displays[aura_env.id].hekiliEnabled == nil and true or WeakAurasSaved.displays[aura_env.id].hekiliEnabled
WA_Redfellas_Rot_BRM_CDs = WeakAurasSaved.displays[aura_env.id].hekiliCooldowns == nil and false or WeakAurasSaved.displays[aura_env.id].hekiliCooldowns

aura_env.bindsInitialized = false

aura_env.keyhandler = aura_env.keyhandler or CreateFrame("Button", aura_env.id.."_Keyhandler", UIParent)
aura_env.keyhandler.parent = aura_env
aura_env.keyhandler:RegisterForClicks("AnyDown")
aura_env.keyhandler:SetScript("OnClick", function (self, button, down)
        if button == "Cooldowns" then
            WA_Redfellas_Rot_BRM_CDs = not WA_Redfellas_Rot_BRM_CDs
            print("|cFF00FFFFRedfella's Rotation Helper Cooldowns: " .. ( WA_Redfellas_Rot_BRM_CDs and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        elseif button == "Enabled" then
            WA_Redfellas_Rot_BRM_Enabled = not WA_Redfellas_Rot_BRM_Enabled
            print("|cFF00FFFFRedfella's Rotation Helper: " .. ( WA_Redfellas_Rot_BRM_Enabled and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r" ) )
        end

        WeakAurasSaved.displays[self.parent.id].hekiliEnabled = WA_Redfellas_Rot_BRM_Enabled
        WeakAurasSaved.displays[self.parent.id].hekiliCooldowns = WA_Redfellas_Rot_BRM_CDs
end)

function aura_env.setupBinds()

    if InCombatLockdown() then return end

    ClearOverrideBindings( aura_env.keyhandler )
    SetOverrideBindingClick( aura_env.keyhandler, true, aura_env.enabledToggle, aura_env.id.."_Keyhandler", "Enabled" )
    SetOverrideBindingClick( aura_env.keyhandler, true, aura_env.cooldownsToggle, aura_env.id.."_Keyhandler", "Cooldowns" )

    print("|cFF00FFFFRedfella's Rotation Helper|r:  Keybinds are now active.")
    print("Enable/Disable - |cFFFFD100" .. aura_env.enabledToggle .. "|r.")
    print("Toggle Cooldowns - |cFFFFD100" .. aura_env.cooldownsToggle .. "|r.")
    print("You can *carefully* change these keybinds in the " .. aura_env.id .. " WeakAura on the Actions Tab, On Init, Expand Text Editor and see lines 9 and 10." )

    aura_env.bindsInitialized = true

end

aura_env.setupBinds()
aura_env.recommended = 204945
aura_env.timeToReady = 0
aura_env.timeOffset = 0

aura_env.targets = {}
aura_env.targetCount = 0

aura_env.talents = {
    chi_burst = { 1, 1, 1 },
    chi_wave = { 1, 3, 1 },
    black_ox_brew = { 3, 2, 1 },
    blackout_combo = { 7, 2, 1 },
    hight_tolerance = { 7, 3, 1 }
}

aura_env.talented = {}

aura_env.abilities = {
    keg_smash = 121253,
    expel_harm = 115072,
    blackout_strike = 205523,
    ironskin_brew = 115308,
    purifying_brew = 119582,
    breath_of_fire = 115181,
    chi_burst = 123986,
    tiger_palm = 100780,
    roll = 109132,
    tigers_lust = 116841,
    black_ox_brew = 115399
}

aura_env.chargedAbilities = {
    ironskin_brew = 115308
}

aura_env.abilityNames = {}

for k,v in pairs( aura_env.abilities ) do
    aura_env.abilityNames[ v ] = GetSpellInfo( v )
end

aura_env.cooldowns = {
    keg_smash = 121253,
    blackout_strike = 205523,
    chi_burst = 123986
}

aura_env.charges = {}
aura_env.chargeTime = {}
aura_env.chargesMax = {}

aura_env.buffs = {    
    ironskin_brew = 215479,
    elusive_brawler = 218825,
    blackout_combo = 228563,
}

aura_env.buffNames = {
    ironskin_brew = 215479
}

for k,v in pairs( aura_env.buffs ) do
    aura_env.buffNames[ v ] = GetSpellInfo( v )
end

aura_env.buffRemains = {}

aura_env.debuffs = {}

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

function aura_env.chargeCt( spell )
    local rounded = tonumber( format( "%.1f", aura_env.timeOffset ) ) - 0.1
    return min( aura_env.chargesMax[ spell ], aura_env.charges[ spell ] + rounded / aura_env.chargeTime[ spell ] )
end


function aura_env.cdLeft( spell )
    return max( 0, aura_env.cooldowns[ spell ] - aura_env.timeOffset )
end
