local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "ovale_tankscripts_paladin_protection"
    local desc = "[8.2.0] Ovale_TankScripts: Paladin Protection"
    local code = [[
Include(ovale_common)
Include(ovale_tankscripts_common)
Include(ovale_paladin_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=protection)
AddCheckBox(opt_dispel L(dispel) default specialization=protection)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=protection)
AddCheckBox(opt_paladin_protection_aoe L(AOE) default specialization=protection)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=protection)

AddFunction PaladinHealMe
{
    unless(DebuffPresent(healing_immunity_debuff)) 
    {
        if (HealthPercent() <= 50) Spell(light_of_the_protector)
        if (HealthPercent() < 35) UseHealthPotions()
    }
}

AddFunction ProtectionHasProtectiveCooldown
{
    BuffPresent(aegis_of_light_buff) or BuffPresent(ardent_defender_buff) or BuffPresent(guardian_of_ancient_kings_buff) or BuffPresent(divine_shield_buff) or BuffPresent(potion_buff)
}

AddFunction ProtectionCooldownTreshold
{
    HealthPercent() <= 100 and not ProtectionHasProtectiveCooldown()
}

AddFunction ProtectionGetInMeleeRange
{
    if CheckBoxOn(opt_melee_range) and SpellKnown(rebuke) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction ProtectionDefaultShortCDActions
{
    PaladinHealMe()
    #bastion_of_light,if=talent.bastion_of_light.enabled&action.shield_of_the_righteous.charges<1
    if Charges(shield_of_the_righteous count=0) < 0.8 Spell(bastion_of_light)

    ProtectionGetInMeleeRange()
    
    if (BuffRemaining(shield_of_the_righteous_buff) < 2*BaseDuration(shield_of_the_righteous_buff)) 
    {
        #max sotr charges
        if (SpellCharges(shield_of_the_righteous count=0) >= SpellMaxCharges(shield_of_the_righteous)-0.2) Spell(shield_of_the_righteous text=max)
        
        if not ProtectionHasProtectiveCooldown() 
            and BuffPresent(avengers_valor_buff) 
            and (IncomingDamage(5 physical=1) > 0 or (IncomingDamage(5) > 0 and Talent(holy_shield_talent)))
            and (not HasAzeriteTrait(inner_light_trait) or not BuffPresent(shield_of_the_righteous_buff))
        {
            # Dumping SotR charges
            if (Talent(bastion_of_light_talent) and SpellCooldown(bastion_of_light) == 0) Spell(shield_of_the_righteous)
            if (SpellCharges(shield_of_the_righteous count=0) >= 1.8 and (not Talent(seraphim_talent) or SpellFullRecharge(shield_of_the_righteous) < SpellCooldown(seraphim))) Spell(shield_of_the_righteous)
        }
    }
}

AddFunction ProtectionDefaultMainActions
{
    AzeriteEssenceMain()
    if target.IsInterruptible() Spell(avengers_shield)
    Spell(judgment_prot)
    if (Speed() == 0 or target.InRange(rebuke)) and not BuffPresent(consecration_buff) Spell(consecration)
    Spell(avengers_shield)
    Spell(hammer_of_the_righteous)
    Spell(consecration)
}

AddFunction ProtectionDefaultAoEActions
{
    AzeriteEssenceMain()
    Spell(avengers_shield)
    if (Speed() == 0 or target.InRange(rebuke)) and not BuffPresent(consecration_buff) Spell(consecration)
    Spell(judgment_prot)
    if (Talent(blessed_hammer_talent) or BuffPresent(consecration_buff)) Spell(hammer_of_the_righteous)
    Spell(consecration)
    Spell(hammer_of_the_righteous)
    Spell(lights_judgment)
}

AddFunction ProtectionDefaultCdActions
{
    if not CheckBoxOn(opt_paladin_protection_offensive) { ProtectionDefaultOffensiveActions() }
    
    if not DebuffPresent(forbearance_debuff) and HealthPercent() <= 15 Spell(lay_on_hands)
    
    Item(Trinket0Slot usable=1 text=13)
    Item(Trinket1Slot usable=1 text=14)
    
    AzeriteEssenceDefensiveCooldowns()
    
    if ProtectionCooldownTreshold() 
    {
        Spell(divine_protection)
        Spell(ardent_defender)
        Spell(guardian_of_ancient_kings)
        if (Talent(final_stand_talent) or not UnitInParty()) Spell(divine_shield)
        if (CheckBoxOn(opt_use_consumables)) 
        {
            Item(item_steelskin_potion usable=1)
            Item(item_battle_potion_of_stamina usable=1)
        }
        Spell(aegis_of_light)
        UseRacialSurvivalActions()
    }
}

AddFunction ProtectionDefaultOffensiveActions
{
    ProtectionInterruptActions()
    ProtectionDispelActions()
    AzeriteEssenceOffensiveCooldowns()
    ProtectionDefaultOffensiveCooldowns()
}

AddFunction ProtectionInterruptActions
{
    if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
    {
        if target.InRange(rebuke) and target.IsInterruptible() Spell(rebuke)
        if not target.Classification(worldboss)
        {
            if target.InRange(hammer_of_justice) Spell(hammer_of_justice)
            if target.Distance(less 10) Spell(blinding_light)
            if target.Distance(less 8) Spell(war_stomp)
        }
    }
}

AddFunction ProtectionDispelActions
{
    if CheckBoxOn(opt_dispel) 
    {
        if player.HasDebuffType(poison disease) Spell(cleanse_toxins)
        if Spell(arcane_torrent_holy) and target.HasDebuffType(magic) Spell(arcane_torrent_holy)
        if Spell(fireblood) and player.HasDebuffType(poison disease curse magic) Spell(fireblood)
    }
}

AddFunction ProtectionDefaultOffensiveCooldowns
{
    if (Charges(shield_of_the_righteous) >= 2) Spell(seraphim)
    if (not Talent(seraphim_talent) or SpellCooldown(seraphim) <= 4 or BuffPresent(seraphim)) Spell(avenging_wrath)
}

AddIcon help=shortcd specialization=protection
{
    ProtectionDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=protection
{
    ProtectionDefaultMainActions()
}

AddIcon checkbox=opt_paladin_protection_aoe help=aoe specialization=protection
{
    ProtectionDefaultAoEActions()
}

AddIcon help=cd specialization=protection
{
    #if not InCombat() ProtectionPrecombatCdActions()
    ProtectionDefaultCdActions()
}

AddCheckBox(opt_paladin_protection_offensive L(seperate_offensive_icon) default specialization=protection)
AddIcon checkbox=opt_paladin_protection_offensive size=small specialization=protection
{
    ProtectionDefaultOffensiveActions()
}
    ]]
    OvaleScripts:RegisterScript("PALADIN", "protection", name, desc, code, "script")
end