local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "icyveins_paladin_protection"
    local desc = "[8.0.1] Icy-Veins: Paladin Protection"
    local code = [[
Include(ovale_common)
Include(ovale_trinkets_mop)
Include(ovale_trinkets_wod)
Include(ovale_paladin_spells)

#temp fix
SpellInfo(hammer_of_the_righteous replace=hammer_of_the_righteous)

AddCheckBox(opt_interrupt L(interrupt) default specialization=protection)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=protection)
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
	if CheckBoxOn(opt_melee_range) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction ProtectionDefaultShortCDActions
{
	PaladinHealMe()
	#bastion_of_light,if=talent.bastion_of_light.enabled&action.shield_of_the_righteous.charges<1
	if Charges(shield_of_the_righteous) < 1 Spell(bastion_of_light)
	#seraphim,if=talent.seraphim.enabled&action.shield_of_the_righteous.charges>=2
	if Charges(shield_of_the_righteous) >= 2 Spell(seraphim)

	ProtectionGetInMeleeRange()
	
	#max sotr charges
	if (Charges(shield_of_the_righteous) >= SpellMaxCharges(shield_of_the_righteous)) Spell(shield_of_the_righteous text=max)
	
    if not ProtectionHasProtectiveCooldown() 
    {
        #shield_of_the_righteous (no Bastion and no seraphim) -- always bank 1 charge
        if Charges(shield_of_the_righteous) >= 2+Talent(seraphim_talent) Spell(shield_of_the_righteous)
        #shield_of_the_righteous,if=(talent.bastion_of_light.enabled&talent.seraphim.enabled&buff.seraphim.up&cooldown.bastion_of_light.up)&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
        if Talent(bastion_of_light_talent) and Talent(seraphim_talent) and BuffPresent(seraphim_buff) and SpellCooldown(bastion_of_light) == 0 Spell(shield_of_the_righteous)
        #shield_of_the_righteous,if=(talent.bastion_of_light.enabled&!talent.seraphim.enabled&cooldown.bastion_of_light.up)&!(debuff.eye_of_tyr.up|buff.aegis_of_light.up|buff.ardent_defender.up|buff.guardian_of_ancient_kings.up|buff.divine_shield.up|buff.potion.up)
        if Talent(bastion_of_light_talent) and not Talent(seraphim_talent) and SpellCooldown(bastion_of_light) == 0 Spell(shield_of_the_righteous)
    }
}

AddFunction ProtectionDefaultMainActions
{
    Spell(judgment_prot)
	if Speed() == 0 and not BuffPresent(consecration_buff) Spell(consecration)
    Spell(avengers_shield)
    Spell(hammer_of_the_righteous)
    Spell(consecration)
}

AddFunction ProtectionDefaultAoEActions
{
    if Speed() == 0 and not BuffPresent(consecration_buff) Spell(consecration)
    Spell(avengers_shield)
    Spell(judgment_prot)
    if BuffPresent(consecration_buff) Spell(hammer_of_the_righteous)
    Spell(consecration)
    Spell(hammer_of_the_righteous)
}

AddCheckBox(opt_avenging_wrath SpellName(avenging_wrath) default specialization=protection)
AddFunction ProtectionDefaultCdActions
{
	ProtectionInterruptActions()
	if CheckBoxOn(opt_avenging_wrath) and (not Talent(seraphim_talent) or BuffPresent(seraphim_buff)) Spell(avenging_wrath)
	
	Item(Trinket0Slot usable=1 text=13)
	Item(Trinket1Slot usable=1 text=14)
	
	if ProtectionCooldownTreshold() 
    {
        Spell(divine_protection)
        Spell(ardent_defender)
        Spell(guardian_of_ancient_kings)
        Spell(aegis_of_light)
        if Talent(final_stand_talent) Spell(divine_shield)
        if not DebuffPresent(forbearance_debuff) and HealthPercent() < 15 Spell(lay_on_hands)
    }

	if ProtectionCooldownTreshold() and CheckBoxOn(opt_use_consumables) Item(unbending_potion usable=1)
	if ProtectionCooldownTreshold() UseRacialSurvivalActions()
}

AddFunction ProtectionInterruptActions
{
	if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.IsInterruptible()
	{
		if target.InRange(rebuke) Spell(rebuke)
		if target.InRange(avengers_shield) Spell(avengers_shield)
		if not target.Classification(worldboss)
		{
			if target.InRange(hammer_of_justice) Spell(hammer_of_justice)
			if target.Distance(less 10) Spell(blinding_light)
			if target.Distance(less 8) Spell(war_stomp)
			if target.InRange(quaking_palm) Spell(quaking_palm)
		}
	}
}

AddIcon help=shortcd specialization=protection
{
	ProtectionDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=protection
{
	ProtectionDefaultMainActions()
}

AddIcon help=aoe specialization=protection
{
	ProtectionDefaultAoEActions()
}

AddIcon help=cd specialization=protection
{
	#if not InCombat() ProtectionPrecombatCdActions()
	ProtectionDefaultCdActions()
}
	]]
    OvaleScripts:RegisterScript("PALADIN", "protection", name, desc, code, "script")
end