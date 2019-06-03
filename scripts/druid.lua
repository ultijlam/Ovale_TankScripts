local __Scripts = LibStub:GetLibrary("ovale/Scripts")
local OvaleScripts = __Scripts.OvaleScripts
do
    local name = "icyveins_druid_guardian"
    local desc = "[8.1.0] Icy-Veins: Druid Guardian"
    local code = [[
Include(ovale_common)
Include(ovale_druid_spells)

AddCheckBox(opt_interrupt L(interrupt) default specialization=guardian)
AddCheckBox(opt_dispel L(dispel) default specialization=guardian)
AddCheckBox(opt_melee_range L(not_in_melee_range) specialization=guardian)
AddCheckBox(opt_druid_guardian_aoe L(AOE) default specialization=guardian)
AddCheckBox(opt_use_consumables L(opt_use_consumables) default specialization=guardian)

AddFunction GuardianHealMeShortCd
{
    unless(DebuffPresent(healing_immunity_debuff)) 
    {
        if BuffExpires(frenzied_regeneration_buff) and HealthPercent() <= 70 
        {
            if (SpellCharges(frenzied_regeneration)>=2 or HealthPercent() <= 50) Spell(frenzied_regeneration)
        }
        
        if HealthPercent() < 35 UseHealthPotions()
    }
}

AddFunction GuardianHealMeMain
{
    unless(DebuffPresent(healing_immunity_debuff)) 
    {
        if HealthPercent() <= 50 Spell(lunar_beam)
        if HealthPercent() <= 80 and not InCombat() Spell(regrowth)
    }
}

AddFunction GuardianGetInMeleeRange
{
    if CheckBoxOn(opt_melee_range) and (Stance(druid_bear_form) and not target.InRange(mangle) or { Stance(druid_cat_form) or Stance(druid_claws_of_shirvallah) } and not target.InRange(shred))
    {
        if target.InRange(wild_charge) Spell(wild_charge)
        Texture(misc_arrowlup help=L(not_in_melee_range))
    }
}

AddFunction GuardianDefaultShortCDActions
{
    GuardianHealMeShortCd()
    if (IncomingDamage(5 physical=1) and (BuffExpires(ironfur 1) or RageDeficit() <= 20))
    {
        if PowerCost(ironfur)<=0 Spell(ironfur text=free) Spell(ironfur)
    }
    GuardianGetInMeleeRange()
}

#
# Single-Target
#

AddFunction GuardianDefaultMainActions
{
    GuardianHealMeMain()
    if not Stance(druid_bear_form) Spell(bear_form)
    if (RageDeficit() <= 20 and (IncomingDamage(5) == 0 or (SpellCharges(ironfur)==0 and SpellCharges(frenzied_regeneration) == 0) or not UnitInParty())) Spell(maul)

    if (target.DebuffRefreshable(moonfire_debuff)) Spell(moonfire)
    if ((target.DebuffStacks(thrash_bear_debuff) < 3) or (target.DebuffRefreshable(thrash_bear_debuff)) or (Talent(earthwarden_talent) and BuffStacks(earthwarden_buff)<3)) Spell(thrash_bear)
    if (BuffRefreshable(pulverize_buff)) Spell(pulverize)
    Spell(mangle)
    Spell(thrash_bear)
    if not BuffExpires(galactic_guardian_buff) Spell(moonfire)
    if (RageDeficit() <= 20 or IncomingDamage(5 physical=1) == 0 or not UnitInParty()) Spell(maul)
    Spell(swipe)
}

#
# AOE
#

AddFunction GuardianDefaultAoEActions
{
    GuardianHealMeMain()
    if not Stance(druid_bear_form) Spell(bear_form)
    if (RageDeficit() <= 20 and (IncomingDamage(5) == 0 or (SpellCharges(ironfur)==0 and SpellCharges(frenzied_regeneration) == 0) or not UnitInParty())) Spell(maul)
    if Speed() == 0 and Enemies() >= 4 Spell(lunar_beam)
    
    if not BuffExpires(incarnation_guardian_of_ursoc_buff) 
    {
        if (BuffRefreshable(pulverize_buff)) Spell(pulverize)
        if ((target.DebuffStacks(thrash_bear_debuff) < 3) or (target.DebuffRefreshable(thrash_bear_debuff)) or (Talent(earthwarden_talent) and BuffStacks(earthwarden_buff)<=1)) Spell(thrash_bear)
        if (Enemies() <= 3) Spell(mangle)
        Spell(thrash_bear)
    }
    
    if (DebuffCountOnAny(moonfire_debuff) < 2 and target.DebuffRefreshable(moonfire_debuff)) Spell(moonfire)
    Spell(thrash_bear)
    if (Enemies() <= 2 and BuffRefreshable(pulverize_buff)) Spell(pulverize)
    if (Enemies() <= 4) Spell(mangle)
    if (DebuffCountOnAny(moonfire_debuff) < 3 and not BuffExpires(galactic_guardian_buff)) Spell(moonfire)
    if (Enemies() <= 3 and (RageDeficit() <= 20 or IncomingDamage(5) == 0 or not UnitInParty())) Spell(maul)
    Spell(swipe)
}

AddFunction GuardianDefaultCdActions 
{
    if not CheckBoxOn(opt_druid_guardian_offensive) { GuardianDefaultOffensiveActions() }
    
    Item(Trinket0Slot usable=1 text=13)
    Item(Trinket1Slot usable=1 text=14)

    if BuffExpires(bristling_fur_buff) and BuffExpires(survival_instincts_buff) and BuffExpires(barkskin_buff) and BuffExpires(potion_buff)
    {
        Spell(bristling_fur)
        Spell(barkskin)
        Spell(survival_instincts)
        if CheckBoxOn(opt_use_consumables) 
        {
            Item(item_battle_potion_of_agility usable=1)
            Item(item_steelskin_potion usable=1)
            Item(item_battle_potion_of_stamina usable=1)
        }
    }
}

AddFunction GuardianDefaultOffensiveActions
{
    GuardianInterruptActions()
    GuardianDispelActions()
    GuardianDefaultOffensiveCooldowns()
}

AddFunction GuardianInterruptActions
{
    if CheckBoxOn(opt_interrupt) and not target.IsFriend() and target.Casting()
    {
        if target.InRange(skull_bash) and target.IsInterruptible() Spell(skull_bash)
        if not target.Classification(worldboss)
        {
            Spell(mighty_bash)
            if target.Distance(less 8) Spell(war_stomp)
            if target.Distance(less 15) Spell(typhoon)
        }
    }
}

AddFunction GuardianDispelActions
{
    if CheckBoxOn(opt_dispel) 
    {
        if (player.HasDebuffType(poison curse) and (not InCombat() or not Stance(druid_bear_form))) Spell(remove_corruption)
        if (target.HasDebuffType(enrage)) Spell(soothe)
    }
}

AddFunction GuardianDefaultOffensiveCooldowns
{
    Spell(incarnation_guardian_of_ursoc)
}

AddIcon help=shortcd specialization=guardian
{
    GuardianDefaultShortCDActions()
}

AddIcon enemies=1 help=main specialization=guardian
{
    GuardianDefaultMainActions()
}

AddIcon checkbox=opt_druid_guardian_aoe help=aoe specialization=guardian
{
    GuardianDefaultAoEActions()
}

AddIcon help=cd specialization=guardian
{
    GuardianDefaultCdActions()
}

AddCheckBox(opt_druid_guardian_offensive L(seperate_offensive_icon) default specialization=guardian)
AddIcon checkbox=opt_druid_guardian_offensive size=small specialization=guardian
{
    GuardianDefaultOffensiveActions()
}
]]
    OvaleScripts:RegisterScript("DRUID", "guardian", name, desc, code, "script")
end