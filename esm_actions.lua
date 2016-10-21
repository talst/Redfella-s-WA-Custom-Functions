aura_env.updateInterval = 0.03
aura_env.lastUpdate = GetTime()
aura_env.targetWipeInterval = 5

aura_env.danger_treshold = 50
aura_env.critical_treshold = 30

if aura_env.in_combat == nil then aura_env.in_combat = false end

aura_env.showCooldownRing = true
aura_env.invertCooldownRing = false
aura_env.showRangeHighlight = true

aura_env.recommended = 208175
aura_env.timeToReady = 0
aura_env.timeOffset = 0

aura_env.targets = {}
aura_env.targetCount = 0

aura_env.talents = {
    windsong = { 1, 1, 1 },
    hot_hand = { 1, 2, 1 },
    boulderfist = { 1, 3, 1 },

    rainfall = { 2, 1, 1 },
    feral_lunge = { 2, 2, 1 },
    wind_rush_totem = { 2, 3, 1 },

    lightning_surge_totem = { 3, 1, 1 },
    earthgrab_totem = { 3, 2, 1 },
    voodoo_totem = { 3, 3, 1 },

    lightning_shield = { 4, 1, 1 },
    ancestral_swiftness = { 4, 2, 1 },
    hailstorm = { 4, 3, 1 },

    tempest = { 5, 1, 1 },
    overcharge = { 5, 2, 1 },
    empowered_stormlash = { 5, 3, 1 },

    crashing_storm = {6, 1, 1 },
    fury_of_air = { 6, 2, 1 },
    sundering = { 6, 3, 1 },

    ascendance = { 7, 1, 1 },
    landslide = { 7, 2, 1 },
    earthen_spike = {7, 3, 1 }
}

aura_env.talented = {}

aura_env.abilities = {
    ascendance = 114051,
    earthen_spike = 188089,
    landslide = 197992,
    fury_of_air = 197211,
    sundering = 197214,
    empowered_stormlash = 210731,
    overcharge = 210727,
    tempest = 192234,
    spirit_walk = 58875,
    ancestral_swiftness = 192087,
    hailstorm = 210853,
    lightning_shield = 192106,
    feral_spirit = 51533,
    feral_lunge = 196884,
    rainfall = 215864,
    crash_lightning = 187874,
    stormstrike = 17364,
    wind_shear = 57994,
    frostbrand = 196834,
    cleanse_spirit = 51886,
    boulderfist = 201897,
    windsong = 201898,
    flametongue = 193796,
    lava_lash = 60103,
    rockbiter = 193786,
    healing_surge = 188070,
    lightning_bolt = 187837,
    doom_winds = 204945
}

aura_env.chargedAbilities = {
    boulderfist = 201897
}

aura_env.abilityNames = {}

for k,v in pairs( aura_env.abilities ) do
    aura_env.abilityNames[ v ] = GetSpellInfo( v )
end

aura_env.cooldowns = {
    feral_spirit = 51533,
    windsong = 201898,
    doom_winds = 204945
}

aura_env.charges = {}
aura_env.chargeTime = {}
aura_env.chargesMax = {}

aura_env.buffs = {
    boulderfist = 218825,
    landslide = 202004,
    stormlash = 195222,
    stormbringer = 201846,
    wind_strikes = 198293,
    frostbrand = 196834,
    flametongue = 194084,
    gathering_storms = 198300,
    astral_shift = 108271
    spirit_walk = 58875,
    doom_winds = 204945
}

aura_env.buffNames = {}

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

function aura_env.health_percentage()
    return math.ceil( (UnitHealth("player") / UnitHealthMax("player") * 100) )
end


function aura_env.get_artifact_multiplier()
    local devour_souls_rank = 0
    local tormented_souls_rank = 0

    local loaded = IsAddOnLoaded("LibArtifactData-1.0") or LoadAddOn("LibArtifactData-1.0")
    if loaded then
        aura_env.LAD = aura_env.LAD or LibStub("LibArtifactData-1.0")

        if not aura_env.LAD:GetActiveArtifactID() then
            aura_env.LAD:ForceUpdate()
        end

        local _, traits = aura_env.LAD:GetArtifactTraits()
        if traits then
            for _,v in ipairs(traits) do
                if v.spellID == 212821 then
                    devour_souls_rank = v.currentRank
                    break
                end
                if v.spellID == 216695 then
                    tormented_souls_rank = v.currentRank
                    break
                end
            end
        end
    else
        print("You have not installed LibArtifactData-1.0, it is required for this WeakAura to function properly. Please DL it from https://www.wowace.com/addons/libartifactdata-1-0/");
    end


    -- Devour souls multiplier is 3% * rank
    local multiplier = 1 + devour_souls_rank * 0.03
    -- Tormented Souls multiplier is 10% * rank
    multiplier = multiplier * (1 + tormented_souls_rank * 0.1)
    return multiplier
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
