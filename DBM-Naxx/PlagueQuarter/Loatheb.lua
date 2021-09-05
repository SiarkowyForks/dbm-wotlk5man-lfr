local mod	= DBM:NewMod("Loatheb", "DBM-Naxx", 3)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4444 $"):sub(12, -3))
mod:SetCreatureID(16011)

mod:RegisterCombat("combat")

mod:EnableModel()

mod:RegisterEvents(
	"SPELL_CAST_SUCCESS",
	"SPELL_DAMAGE",
	"SWING_DAMAGE"
)

local warnSporeNow		= mod:NewSpellAnnounce(32329, 2)
local warnSporeSoon		= mod:NewSoonAnnounce(32329, 1)
local warnDoomNow		= mod:NewSpellAnnounce(29204, 3)
local warnHealSoon		= mod:NewAnnounce("WarningHealSoon", 4, 48071)
local warnHealNow		= mod:NewAnnounce("WarningHealNow", 1, 48071, false)
local warnHealthySoon 	= mod:NewAnnounce("Warning Healthy Spore Soon", 5, 35336)
local warnHealthyNow 	= mod:NewAnnounce("Warning Healthy Spore Now", 1, 35336)

local timerHealthy 	= mod:NewNextTimer(15, 35336)
local timerSpore	= mod:NewNextTimer(36, 32329)
local timerDoom		= mod:NewNextTimer(180, 29204)
local timerAura		= mod:NewBuffActiveTimer(17, 55593)

mod:AddBoolOption("SporeDamageAlert", false)

local healthyTimer 	= 6
local doomCounter	= 0
local sporeTimer	= 36
local auraTimer		= 17
local doomTimer		= 120

function mod:OnCombatStart(delay)
	doomCounter = 0
	if mod:IsDifficulty("heroic25") then
		sporeTimer = 18
		auraTimer = 15
		doomTimer = 90
		timerAura:Start(auraTimer + 2 - delay)
		timerHealthy:Start(auraTimer + 8 - delay)
	else
		sporeTimer = 36
		auraTimer = 17
		doomTimer = 120
	end
	timerSpore:Start(sporeTimer - delay)
	warnSporeSoon:Schedule(sporeTimer - 5 - delay)
	timerDoom:Start(120 - delay, doomCounter + 1)
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(29234) then
		if mod:IsDifficulty("heroic25") then
			timerSpore:Start(sporeTimer - 3)
			warnSporeNow:Show()
			warnSporeSoon:Schedule(sporeTimer - 8)
		else
			timerSpore:Start(sporeTimer)
			warnSporeNow:Show()
			warnSporeSoon:Schedule(sporeTimer - 5)
		end
	elseif args:IsSpellID(29204, 55052) then  -- Inevitable Doom
		doomCounter = doomCounter + 1
		local timer = 30
		if doomCounter >= 7 then
			if doomCounter % 2 == 0 then timer = 17
			else timer = 12 end
		end
		warnDoomNow:Show(doomCounter)
		timerDoom:Start(timer, doomCounter + 1)
	elseif args:IsSpellID(55593) then
		if mod:IsDifficulty("normal10") then
			warnHealSoon:Schedule(14)
			warnHealNow:Schedule(17)
		else
			warnHealthySoon:Schedule(healthyTimer - 3)
			warnHealthyNow:Schedule(healthyTimer)
			timerHealthy:Start(healthyTimer)
		end
		timerAura:Start(auraTimer)
	end
end

--Spore loser function. Credits to Forte guild and their old discontinued dbm plugins. Sad to see that guild disband, best of luck to them!
function mod:SPELL_DAMAGE(args)
	if self.Options.SporeDamageAlert and args.destName == "Spore" and args.spellId ~= 62124 and self:IsInCombat() then
		SendChatMessage(args.sourceName..", You are damaging a Spore!!! ("..args.amount.." damage)", "RAID_WARNING")
		SendChatMessage(args.sourceName..", You are damaging a Spore!!! ("..args.amount.." damage)", "WHISPER", nil, args.sourceName)
	end
end

function mod:SWING_DAMAGE(args)
	if self.Options.SporeDamageAlert and args.destName == "Spore" and self:IsInCombat() then
		SendChatMessage(args.sourceName..", You are damaging a Spore!!! ("..args.amount.." damage)", "RAID_WARNING")
		SendChatMessage(args.sourceName..", You are damaging a Spore!!! ("..args.amount.." damage)", "WHISPER", nil, args.sourceName)
	end
end
