local _, Private = ...

if Private.initialized then
    local name = "ovale_tankscripts_paladin_protection"
    local desc = string.format("[9.0.2] %s: Paladin Protection", Private.name)
    local code = [[
Include(ovale_common)
Include(ovale_tankscripts_common)
Include(ovale_paladin_spells)

Define(blessed_hammer_talent 23469) 
Define(final_stand_talent 22645)
Define(moment_of_glory_talent 23468)
Define(sanctified_wrath_talent_protection 23457)
Define(unbreakable_spirit_talent 22433)

Define(arcane_torrent 155145)
    SpellInfo(arcane_torrent cd=120 gcd=1 holypower=-1)
Define(ardent_defender 31850)
    SpellInfo(ardent_defender cd=120)
    SpellRequire(ardent_defender cd percent=70 enabled=(hastalent(unbreakable_spirit_talent)))
Define(avengers_shield 31935)
    SpellInfo(avengers_shield holypower=-1)
Define(blessed_hammer 204019)
    SpellInfo(blessed_hammer cd=6)
Define(blessing_of_protection 1022)
    SpellInfo(blessing_of_protection cd=300)
    SpellRequire(blessing_of_protection replaced_by set=blessing_of_spellwarding enabled=(hastalent(blessing_of_spellwarding_talent)))
Define(blessing_of_spellwarding 204018)
    SpellInfo(blessing_of_spellwarding cd=300)    
Define(blessing_of_spellwarding_talent 22435)
Define(cleanse_toxins 213644)
    SpellInfo(cleanse_toxins cd=8)
Define(consecration_buff 188370)
Define(consecration_prot 26573)
    SpellInfo(consecration_prot cd=4 totem=1 buff_totem=consecration_buff)
Define(blinding_light 115750)
    SpellRequire(blinding_light unusable set=1 enabled=(not HasTalent(blinding_light_talent)))
Define(blinding_light_talent 21811)
Define(guardian_of_ancient_kings 86659)
    SpellInfo(guardian_of_ancient_kings cd=300)
Define(judgment_prot 275779)
    SpellInfo(judgment_prot holypower=-1)
Define(judgment_prot_debuff 197277)
    SpellAddTargetDebuff(judgment_prot judgment_prot_debuff add=1)
    SpellAddTargetDebuff(shield_of_the_righteous judgment_prot_debuff set=0)
Define(hammer_of_the_righteous 53595)
    SpellInfo(hammer_of_the_righteous cd=6)
    SpellRequire(hammer_of_the_righteous replaced_by set=blessed_hammer enabled=(hastalent(blessed_hammer_talent)))
Define(moment_of_glory 327193)
    SpellRequire(moment_of_glory unusable set=1 enabled=(not HasTalent(moment_of_glory_talent)))
Define(shining_light_buff 327510)
    SpellInfo(shining_light_buff duration=30)
    SpellRequire(word_of_glory holypower percent=0 enabled=(buffpresent(shining_light_buff)))

AddCheckBox(opt_interrupt L(interrupt) default enabled=(specialization(protection)))
AddCheckBox(opt_dispel L(dispel) default enabled=(specialization(protection)))
AddCheckBox(opt_melee_range L(not_in_melee_range) enabled=(specialization(protection)))
AddCheckBox(opt_paladin_protection_aoe L(AOE) default enabled=(specialization(protection)))
AddCheckBox(opt_use_consumables L(opt_use_consumables) default enabled=(specialization(protection)))
AddCheckBox(opt_paladin_protection_offensive L(seperate_offensive_icon) default enabled=(specialization(protection)))

AddFunction PaladinHealMe
{
    if (HealthPercent() <= 50) Spell(word_of_glory)
    if (HealthPercent() < 35) UseHealthPotions()
    CovenantShortCDHealActions()
}

AddFunction ProtectionGetInMeleeRange
{
    if CheckBoxOn(opt_melee_range) and SpellKnown(rebuke) and not target.InRange(rebuke) Texture(misc_arrowlup help=L(not_in_melee_range))
}

AddFunction ProtectionDefaultShortCDActions
{
    PaladinHealMe()
    ProtectionGetInMeleeRange()
    
    if (IncomingPhysicalDamage(5)>0 and (BuffRemaining(shield_of_the_righteous_buff) <= 2)) Spell(shield_of_the_righteous)
    if (target.DebuffPresent(judgment_prot_debuff)) Spell(shield_of_the_righteous)
    if (HolyPower()>=5 or BuffPresent(holy_avenger) or (Talent(sanctified_wrath_talent_protection) and HolyPower()>=5-BuffPresent(avenging_wrath))) Spell(shield_of_the_righteous)

    #necrolord covenant ability perl, not worth it
    #if (BuffPresent(vanquishers_hammer)) Spell(word_of_glory)
}

AddFunction ProtectionDefaultMainActions
{
    if (target.IsInterruptible()) Spell(avengers_shield)
    if (((Speed() == 0 and InCombat()) or target.InRange(rebuke)) and not TotemPresent(consecration_prot)) Spell(consecration_prot)
    if (Enemies()>=3) Spell(avengers_shield)
    Spell(vanquishers_hammer)
    if not target.DebuffPresent(judgment_prot_debuff) Spell(judgment_prot)
    Spell(hammer_of_wrath)
    Spell(avengers_shield)
    Spell(hammer_of_the_righteous)
    Spell(consecration_prot)
    Spell(judgment_prot)
}

AddFunction ProtectionDefaultAoEActions
{
    ProtectionDefaultMainActions()
}

AddFunction ProtectionDefaultCdActions
{
    if not CheckBoxOn(opt_paladin_protection_offensive) { ProtectionDefaultOffensiveActions() }
    
    if not DebuffPresent(forbearance_debuff) and HealthPercent() <= 15 Spell(lay_on_hands)
    
    Item(Trinket0Slot usable=1 text=13)
    Item(Trinket1Slot usable=1 text=14)
    
    Spell(ardent_defender)
    Spell(guardian_of_ancient_kings)
    if (Talent(final_stand_talent) or not UnitInParty()) Spell(divine_shield)
    if (not UnitInParty() and IncomingPhysicalDamage(5)>0 and not HasTalent(blessing_of_spellwarding_talent) and not DebuffPresent(forbearance_debuff)) Spell(blessing_of_protection)
    if (IncomingMagicDamage(5)>0 and HasTalent(blessing_of_spellwarding_talent) and not DebuffPresent(forbearance_debuff)) Spell(blessing_of_spellwarding)
    if (CheckBoxOn(opt_use_consumables)) 
    {
        Item(item_steelskin_potion usable=1)
        Item(item_battle_potion_of_stamina usable=1)
    }
}

AddFunction ProtectionDefaultOffensiveActions
{
    ProtectionInterruptActions()
    ProtectionDispelActions()
    ProtectionDefaultOffensiveCooldowns()
}

AddFunction ProtectionInterruptActions
{
    if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
    {
        if target.InRange(rebuke) and target.IsInterruptible() Spell(rebuke)
        if target.IsInterruptible() Spell(divine_toll)
        if not target.Classification(worldboss)
        {
            if target.InRange(hammer_of_justice) Spell(hammer_of_justice)
            if (target.Distance() < 10) Spell(blinding_light)
            if (target.Distance() < 8) Spell(war_stomp)
        }
    }
}

AddFunction ProtectionDispelActions
{
    if CheckBoxOn(opt_dispel) 
    {
        if Spell(arcane_torrent) and target.HasDebuffType(magic) Spell(arcane_torrent)
        if Spell(fireblood) and player.HasDebuffType(poison disease curse magic) Spell(fireblood)
        if player.HasDebuffType(poison disease) Spell(cleanse_toxins)
        CovenantDispelActions()
    }
}

AddFunction ProtectionDefaultOffensiveCooldowns
{
    if (not player.BuffPresent(avenging_wrath)) Spell(avenging_wrath)
    Spell(seraphim)
    if (SpellCooldown(avengers_shield) > GCD()) Spell(moment_of_glory)
    Spell(holy_avenger)
    
    if (HolyPowerDeficit()>=Enemies() or HolyPower()<=0) Spell(divine_toll)
    Spell(ashen_hallow)
}

AddIcon help=shortcd enabled=(specialization(protection))
{
    ProtectionDefaultShortCDActions()
}

AddIcon enemies=1 help=main enabled=(specialization(protection))
{
    ProtectionDefaultMainActions()
}

AddIcon help=aoe enabled=(checkboxon(opt_paladin_protection_aoe) and specialization(protection))
{
    ProtectionDefaultAoEActions()
}

AddIcon help=cd enabled=(specialization(protection))
{
    #if not InCombat() ProtectionPrecombatCdActions()
    ProtectionDefaultCdActions()
}

AddIcon size=small enabled=(checkboxon(opt_paladin_protection_offensive) and specialization(protection))
{
    ProtectionDefaultOffensiveActions()
}
    ]]
    Private.scripts:registerScript("PALADIN", "protection", name, desc, code, "script")
end