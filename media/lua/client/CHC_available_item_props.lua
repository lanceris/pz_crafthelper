require 'CHC_config'


CHC_settings.itemPropsByType = {
    -- source: zombie\scripting\objects\Item.java InstanceItem()
    WeaponPart = {
        { name = 'getDamage', default = 0, ignoreDefault = true },
        { name = 'getClipSize', default = 0, ignoreDefault = true },
        { name = 'getMaxRange', default = 0, ignoreDefault = true },
        { name = 'getMinRangeRanged', default = 0, ignoreDefault = true },
        { name = 'getRecoilDelay', default = 0, ignoreDefault = true },
        { name = 'getMountOn' },
        { name = 'getPartType' },
        { name = 'getReloadTime', default = 0, ignoreDefault = true },
        { name = 'getAimingTime', default = 0, ignoreDefault = true },
        { name = 'getHitChance', default = 0, ignoreDefault = true },
        { name = 'getAngle', default = 0, ignoreDefault = true },
        { name = 'getWeightModifier', default = 0, ignoreDefault = true },
    },
    Key = {
        { name = 'isDigitalPadlock' },
        { name = 'isPadlock' }
    },
    Container = {
        { name = 'getItemCapacity', default = 0, ignoreDefault = true },
        { name = 'getCapacity', default = 0, ignoreDefault = true },
        { name = 'getWeightReduction', default = 0, ignoreDefault = true },
        { name = 'canBeEquipped' },
        -- { name = 'getPutInSound' },
        -- { name = 'getCloseSound' },
        -- { name = 'getOpenSound' },
        -- { name = 'getOnlyAcceptCategory' },
        -- { name = 'getAcceptItemFunction' },
    },
    Food = {
        { name = 'getPoisonLevelForRecipe' },
        { name = 'getPoisonDetectionLevel', default = -1, ignoreDefault = true },
        { name = 'isPoison' },
        { name = 'getFoodType' },
        { name = 'getPoisonPower', default = 0, ignoreDefault = true },
        { name = 'getUseForPoison', default = 0, ignoreDefault = true },
        { name = 'getThirstChange', mul = 100, default = 0, ignoreDefault = true },
        { name = 'getHungChange', mul = 100, default = 0, ignoreDefault = true },
        { name = 'getBaseHunger', mul = 100, default = 0, ignoreDefault = true },
        { name = 'getEndChange', mul = 100, default = 0, ignoreDefault = true },
        { name = 'getOffAge', default = 1000000000, ignoreDefault = true },
        { name = 'getOffAgeMax', default = 1000000000, ignoreDefault = true },
        { name = 'isCookable' },
        { name = 'getMinutesToCook', default = 60, ignoreDefault = false },
        { name = 'getMinutesToBurn', default = 120, ignoreDefault = false },
        { name = 'isbDangerousUncooked' },
        --{ name = 'getReplaceOnUse' },
        { name = 'getReplaceOnCooked' },
        { name = 'isSpice' },
        { name = 'getSpices' },
        { name = 'isRemoveNegativeEffectOnCooked' },
        { name = 'getCustomEatSound' },
        { name = 'getOnCooked' },
        { name = 'getFluReduction', default = 0, ignoreDefault = true },
        { name = 'getReduceFoodSickness', default = 0, ignoreDefault = true },
        { name = 'getPainReduction', default = 0, ignoreDefault = true },
        { name = 'getHerbalistType' },
        { name = 'getCarbohydrates', default = 0, ignoreDefault = true },
        { name = 'getLipids', default = 0, ignoreDefault = true },
        { name = 'getProteins', default = 0, ignoreDefault = true },
        { name = 'getCalories', default = 0, ignoreDefault = false },
        { name = 'isPackaged' },
        { name = 'canBeFrozen' },
        { name = 'getReplaceOnRotten' },
        { name = 'getOnEat' },
        { name = 'isBadInMicrowave' },
        { name = 'isGoodHot' },
        { name = 'isBadCold' },
    },
    Literature = {
        --{ name = 'getReplaceOnUse' },
        { name = 'getNumberOfPages', default = -1, ignoreDefault = true },
        { name = 'getAlreadyReadPages', default = 0, ignoreDefault = true },
        { name = 'getSkillTrained' },
        { name = 'getLvlSkillTrained', default = -1, ignoreDefault = true },
        { name = 'getNumLevelsTrained', default = 1, ignoreDefault = false },
        { name = 'canBeWrite' },
        { name = 'getPageToWrite', default = 0, ignoreDefault = true },
        { name = 'getTeachedRecipes' },
    },
    AlarmClock = {
        { name = 'getAlarmSound' },
        { name = 'getSoundRadius', default = 0, ignoreDefault = true },
    },
    AlarmClockClothing = {
        { name = 'getTemperature', default = 0, ignoreDefault = true },
        { name = 'getInsulation', default = 0, ignoreDefault = true },
        { name = 'getConditionLowerChance', default = 1000000, ignoreDefault = false },
        { name = 'getStompPower', default = 1, ignoreDefault = true },
        { name = 'getRunSpeedModifier', default = 1, ignoreDefault = true },
        { name = 'getCombatSpeedModifier', default = 1, ignoreDefault = true },
        { name = 'isRemoveOnBroken' },
        { name = 'getCanHaveHoles' },
        { name = 'getWeightWet', default = 0, ignoreDefault = true },
        { name = 'getBiteDefense', default = 0, ignoreDefault = true },
        { name = 'getBulletDefense', default = 0, ignoreDefault = true },
        { name = 'getNeckProtectionModifier', default = 1, ignoreDefault = true },
        { name = 'getScratchDefense', default = 0, ignoreDefault = true },
        { name = 'getChanceToFall', default = 0, ignoreDefault = true },
        { name = 'getWindresistance', default = 0, ignoreDefault = true },
        { name = 'getWaterResistance', default = 0, ignoreDefault = true },
        { name = 'getAlarmSound' },
        { name = 'getSoundRadius', default = 0, ignoreDefault = true },
    },
    Weapon = {
        { name = 'isMultipleHitConditionAffected' },
        { name = 'getConditionLowerChance', default = 1000000, ignoreDefault = false },
        { name = 'getSplatSize', default = 1, ignoreDefault = true },
        { name = 'getAimingMod', default = 1, ignoreDefault = true },
        { name = 'getMinDamage', default = 0, ignoreDefault = false },
        { name = 'getMaxDamage', default = 1.5, ignoreDefault = false },
        { name = 'getBaseSpeed', default = 1, ignoreDefault = true },
        { name = 'getPhysicsObject' },
        { name = 'getOtherHandRequire' },
        { name = 'isOtherHandUse' },
        { name = 'getMaxRange', default = 1, ignoreDefault = false },
        { name = 'getMinRange', default = 0, ignoreDefault = false },
        { name = 'isShareEndurance' },
        { name = 'getKnockdownMod', default = 1, ignoreDefault = true },
        { name = 'isAimedFirearm' },
        { name = 'getRunAnim' },
        -- { name = 'IdleAnim' },
        -- { name = 'HitAngleMod' , default = 0, ignoreDefault = true },
        { name = 'isAimedHandWeapon' },
        { name = 'isCantAttackWithLowestEndurance' },
        { name = 'isAlwaysKnockdown' },
        { name = 'getEnduranceMod', default = 1, ignoreDefault = true },
        { name = 'isUseSelf' },
        { name = 'getMaxHitCount', default = 1000, ignoreDefault = true },
        { name = 'getMinimumSwingTime', default = 0, ignoreDefault = true },
        { name = 'getSwingTime', default = 1, ignoreDefault = false },
        { name = 'getDoSwingBeforeImpact', default = 0, ignoreDefault = true },
        { name = 'getMinAngle', default = 1, ignoreDefault = true },
        { name = 'getDoorDamage', default = 1, ignoreDefault = true },
        { name = 'getTreeDamage', default = 0, ignoreDefault = true },
        { name = 'getDoorHitSound' },
        { name = 'getHitFloorSound' },
        { name = 'getZombieHitSound' },
        { name = 'getPushBackMod', default = 1, ignoreDefault = true },
        -- { name = 'getWeight', default = 1, ignoreDefault = false },
        { name = 'getImpactSound' },
        { name = 'getSplatNumber', default = 2, ignoreDefault = true },
        { name = 'isKnockBackOnNoDeath' },
        { name = 'isSplatBloodOnNoDeath' },
        { name = 'getSwingSound' },
        { name = 'getBulletOutSound' },
        { name = 'getShellFallSound' },
        { name = 'isAngleFalloff' },
        { name = 'getSoundVolume', default = 0, ignoreDefault = true },
        { name = 'getSoundRadius', default = 0, ignoreDefault = true },
        { name = 'getToHitModifier', default = 1, ignoreDefault = true },
        { name = 'getOtherBoost', default = 1, ignoreDefault = true },
        { name = 'isRanged' },
        { name = 'isRangeFalloff' },
        { name = 'isUseEndurance' },
        { name = 'getCriticalChance', default = 20, ignoreDefault = false },
        { name = 'getCritDmgMultiplier', default = 0, ignoreDefault = true },
        { name = 'isShareDamage' },
        { name = 'isCanBarracade' },
        { name = 'getWeaponSprite' },
        { name = 'getOriginalWeaponSprite' },
        { name = 'getSubCategory' },
        { name = 'getCategories' },
        { name = 'getSoundGain', default = 1, ignoreDefault = true },
        { name = 'getAimingPerkCritModifier', default = 0, ignoreDefault = true },
        { name = 'getAimingPerkRangeModifier', default = 0, ignoreDefault = true },
        { name = 'getAimingPerkHitChanceModifier', default = 0, ignoreDefault = true },
        { name = 'getHitChance', default = 0, ignoreDefault = true },
        { name = 'getRecoilDelay', default = 0, ignoreDefault = true },
        { name = 'getAimingPerkMinAngleModifier', default = 0, ignoreDefault = true },
        { name = 'isPiercingBullets' },
        { name = 'getClipSize', default = 0, ignoreDefault = true },
        { name = 'getReloadTime', default = 0, ignoreDefault = true },
        { name = 'getAimingTime', default = 0, ignoreDefault = true },
        { name = 'getTriggerExplosionTimer', default = 0, ignoreDefault = true },
        { name = 'getSensorRange', default = 0, ignoreDefault = true },
        -- { name = 'getWeaponLength' , default = 0.4, ignoreDefault = true },
        { name = 'getPlacedSprite' },
        { name = 'getExplosionTimer', default = 0, ignoreDefault = true },
        { name = 'canBePlaced' },
        { name = 'canBeReused' },
        { name = 'getExplosionRange', default = 0, ignoreDefault = true },
        { name = 'getExplosionPower', default = 0, ignoreDefault = true },
        { name = 'getFireRange', default = 0, ignoreDefault = true },
        { name = 'getFirePower', default = 0, ignoreDefault = true },
        { name = 'getSmokeRange', default = 0, ignoreDefault = true },
        { name = 'getNoiseRange', default = 0, ignoreDefault = true },
        { name = 'getExtraDamage', default = 0, ignoreDefault = true },
        { name = 'getAmmoBox' },
        { name = 'getRackSound' },
        { name = 'getClickSound' },
        { name = 'getMagazineType' },
        { name = 'getWeaponReloadType' },
        { name = 'isInsertAllBulletsReload' },
        { name = 'isRackAfterShoot' },
        { name = 'getJamGunChance', default = 1, ignoreDefault = true },
        { name = 'getModelWeaponPart', forceIgnore = true },
        { name = 'haveChamber' },
        { name = 'getDamageCategory' },
        { name = 'isDamageMakeHole' },
        { name = 'getFireMode' },
        { name = 'getFireModePossibilities' },
    },
    Normal = {},
    Clothing = {
        { name = 'getTemperature', default = 0, ignoreDefault = true },
        { name = 'getInsulation', default = 0, ignoreDefault = true },
        { name = 'getConditionLowerChance', default = 1000000, ignoreDefault = true },
        { name = 'getStompPower', default = 1, ignoreDefault = true },
        { name = 'getRunSpeedModifier', default = 1, ignoreDefault = true },
        { name = 'getCombatSpeedModifier', default = 1, ignoreDefault = true },
        { name = 'isRemoveOnBroken' },
        { name = 'getCanHaveHoles' },
        { name = 'getWeightWet', default = 0, ignoreDefault = true },
        { name = 'getBiteDefense', default = 0, ignoreDefault = true },
        { name = 'getBulletDefense', default = 0, ignoreDefault = true },
        { name = 'getNeckProtectionModifier', default = 1, ignoreDefault = true },
        { name = 'getScratchDefense', default = 0, ignoreDefault = true },
        { name = 'getChanceToFall', default = 0, ignoreDefault = true },
        { name = 'getWindresistance', default = 0, ignoreDefault = true },
        { name = 'getWaterResistance', default = 0, ignoreDefault = true },
        -- { name = 'getPaletteChoices' },
    },
    Drainable = {
        { name = 'isUseWhileEquiped' },
        { name = 'isUseWhileUnequiped' },
        { name = 'getTicksPerEquipUse', default = 30, ignoreDefault = false },
        { name = 'getUseDelta', default = 0.03125, ignoreDefault = false },
        { name = 'getReplaceOnDeplete' },
        { name = 'isIsCookable' },
        { name = 'getReplaceOnCooked' },
        { name = 'getMinutesToCook', default = 60, ignoreDefault = false },
        { name = 'getOnCooked' },
        { name = 'getRainFactor', default = 0, ignoreDefault = true },
        { name = 'canConsolidate' },
        { name = 'getWeightEmpty', default = 0, ignoreDefault = true },
    },
    Radio = {
        { name = 'getIsTwoWay' },
        { name = 'getTransmitRange', default = 0, ignoreDefault = true },
        { name = 'getMicRange', default = 0, ignoreDefault = true },
        { name = 'getBaseVolumeRange', default = 0, ignoreDefault = true },
        { name = 'getIsPortable' },
        { name = 'getIsTelevision' },
        { name = 'getMinChannelRange', default = 88000, ignoreDefault = false },
        { name = 'getMaxChannelRange', default = 108000, ignoreDefault = false },
        { name = 'getIsBatteryPowered' },
        { name = 'getIsHighTier' },
        { name = 'getUseDelta', default = 0.03125, ignoreDefault = false },
        { name = 'getMediaType', default = -1, ignoreDefault = true },
        { name = 'isNoTransmit' },
    },
    Moveable = {},
    Map = {},
    Common = {
        { name = 'getAlcoholPower', default = 0, ignoreDefault = true },
        { name = 'getConditionMax' },
        --{ name = 'getCondition' },
        { name = 'canBeActivated' },
        { name = 'getLightStrength', default = 0, ignoreDefault = true },
        { name = 'isTorchCone' },
        { name = 'getLightDistance', default = 0, ignoreDefault = true },
        { name = 'getActualWeight' },
        { name = 'getWeight' },
        { name = 'getUses', default = 1, ignoreDefault = true },
        { name = 'getBoredomChange', default = 0, ignoreDefault = true },
        { name = 'getStressChange', mul = 100, default = 0, ignoreDefault = true },
        { name = 'getUnhappyChange', default = 0, ignoreDefault = true },
        { name = 'getReplaceOnUseOn' },
        { name = 'getRequireInHandOrInventory' },
        { name = 'getAttachmentsProvided' },
        { name = 'getAttachmentReplacement' },
        { name = 'isWaterSource' },
        { name = 'getMetalValue', default = 0, ignoreDefault = true },
        { name = 'canStoreWater' },
        -- { name = 'CanStack' },
        { name = 'getCount', default = 1, ignoreDefault = true },
        { name = 'getFatigueChange', mul = 100, default = 0, ignoreDefault = true },
        { name = 'getTooltip' },
        { name = 'getDisplayCategory' },
        { name = 'isAlcoholic' },
        { name = 'isRequiresEquippedBothHands' },
        { name = 'getBreakSound' },
        { name = 'getReplaceOnUse' },
        { name = 'getBandagePower', default = 0, ignoreDefault = true },
        { name = 'getReduceInfectionPower', default = 0, ignoreDefault = true },
        { name = 'canBeRemote' },
        { name = 'isRemoteController' },
        { name = 'getRemoteRange', default = 0, ignoreDefault = true },
        { name = 'getCountDownSound' },
        { name = 'getExplosionSound' },
        { name = 'getColorRed', mul = 255, default = 255, ignoreDefault = true },
        { name = 'getColorGreen', mul = 255, default = 255, ignoreDefault = true },
        { name = 'getColorBlue', mul = 255, default = 255, ignoreDefault = true },
        { name = 'getEvolvedRecipeName' },
        { name = 'isWet' },
        { name = 'getWetCooldown', default = 0, ignoreDefault = true },
        { name = 'getItemWhenDry' },
        -- { name = 'keepOnDeplete' },
        -- { name = 'getItemCapacity' },
        { name = 'getMaxCapacity', default = -1, ignoreDefault = true },
        { name = 'getBrakeForce', default = 0, ignoreDefault = true },
        { name = 'getChanceToSpawnDamaged', default = 0, ignoreDefault = true },
        { name = 'getConditionLowerNormal', default = 0, ignoreDefault = true },
        { name = 'getConditionLowerOffroad', default = 0, ignoreDefault = true },
        { name = 'getWheelFriction', default = 0, ignoreDefault = true },
        { name = 'getSuspensionCompression', default = 0, ignoreDefault = true },
        { name = 'getEngineLoudness', default = 0, ignoreDefault = true },
        { name = 'getSuspensionDamping', default = 0, ignoreDefault = true },
        { name = 'getCustomMenuOption' },
        { name = 'getIconsForTexture' },
        { name = 'getBloodClothingType' },
        -- { name = 'CloseKillMove' },
        { name = 'getAmmoType' },
        { name = 'getMaxAmmo', default = 0, ignoreDefault = true },
        { name = 'getGunType' },
        { name = 'getAttachmentType' },
        { name = 'getTags',                    default = "[]", ignoreDefault = true }
    },
    Integrations = {
        CraftingEnhanced = {
            { name = 'Capacity',           path = 'container',         path2 = "capacity" },
            { name = 'containerType',      path = 'container',         path2 = "type" },
            { name = 'craftingSound',      path = 'craftingSound',     default = nil,     ignoreDefault = true },
            { name = 'requireTool',        path = 'requireTool' },
            { name = 'maxTime',            path = 'maxTime' },
            { name = 'size',               path = 'size' },
            { name = 'tooltipDescription', path = 'tooltipDescription' },
            { name = 'tooltipTexture',     path = 'tooltipTexture' },
            { name = 'tooltipTitle',       path = 'tooltipTitle' },
            { name = 'icon',               path = 'icon',              default = '""',    ignoreDefault = true },
            { name = 'recipe',             path = 'recipe',            forceIgnore = true },
        }
    }
}
