local mod	= DBM:NewMod("Horsemen", "DBM-Naxx", 4)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2248 $"):sub(12, -3))
mod:SetCreatureID(16063, 16064, 16065, 30549)

mod:RegisterCombat("combat", 16063, 16064, 16065, 30549)

mod:EnableModel()

mod:RegisterEvents(
	"SPELL_CAST_SUCCESS",
	"SPELL_AURA_APPLIED_DOSE",
	"CHAT_MSG_MONSTER_YELL",
	"SPELL_SUMMON",
	"SPELL_CAST_START",
	"SPELL_DAMAGE"
)

local warnMarkSoon			= mod:NewAnnounce("WarningMarkSoon", 1, 28835, false)
local warnMarkNow			= mod:NewAnnounce("WarningMarkNow", 2, 28835)

local specWarnMarkOnPlayer	= mod:NewSpecialWarning("SpecialWarningMarkOnPlayer", nil, false, true)

mod:AddBoolOption("HealthFrame", true)
mod:AddBoolOption("ShowRange", true)

local timerBlaumeux			= mod:NewTimer(309, "TimerLadyBlaumeuxEnrage", 72143)
local timerZeliek			= mod:NewTimer(309, "TimerSirZeliekEnrage", 72143)
local timerKorthazz			= mod:NewTimer(309, "TimerThaneKorthazzEnrage", 72143)
local timerRivendare		= mod:NewTimer(309, "TimerBaronRivendareEnrage", 72143)
local timerVoidZone			= mod:NewCDTimer(12, 36119)
local timerMeteor			= mod:NewCDTimer(12, 28884)
local timerHolyWrath		= mod:NewCDTimer(12, 57466)

mod:SetBossHealthInfo(
	16064, L.Korthazz,
	30549, L.Rivendare,
	16065, L.Blaumeux,
	16063, L.Zeliek
)

local markCounter = 0

function mod:OnCombatStart(delay)
	timerVoidZone:Start(16 - delay)
	markCounter = 0
	timerBlaumeux:Start()
	timerRivendare:Start()
end

local markSpam = 0
function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(28832, 28833, 28834, 28835) and (GetTime() - markSpam) > 5 then
		markSpam = GetTime()
		markCounter = markCounter + 1
	end
end

function mod:CHAT_MSG_MONSTER_YELL(msg)
	if msg == "Death... will not stop me." or msg:find("Death... will not stop me.") then
		timerKorthazz:Start()
		timerRivendare:Stop()
		timerMeteor:Start(30)
	elseif msg == "Touche..." or msg:find("Touche...") then
		if mod:IsDifficulty("normal10")	then
			timerVoidZone:Stop()
		end
		if self.Options.ShowRange then
			self:RangeToggle(true)
		end
		timerZeliek:Start()
		timerHolyWrath:Start()
		timerBlaumeux:Stop()
	elseif msg == "It is... as it should be." or msg:find("It is... as it should be.") then
		if self.Options.ShowRange then
			self:RangeToggle(false)
		end
		timerZeliek:Stop()
		timerHolyWrath:Stop()
	elseif msg == "What a bloody waste this is!" or msg:find("What a bloody waste this is!") then
		timerKorthazz:Stop()
	end
end

function mod:SPELL_AURA_APPLIED_DOSE(args)
	if args:IsSpellID(28832, 28833, 28834, 28835) and args:IsPlayer() then
		if args.amount >= 4 then
			specWarnMarkOnPlayer:Show(args.spellName, args.amount)
		end
	end
end

function mod:SPELL_SUMMON(args)
	if args:IsSpellName("Void Zone") then
		timerVoidZone:Start()
	end
end

function mod:SPELL_CAST_START(args)
	if args:IsSpellName("Meteor") then
		timerMeteor:Start()
	end
end

function mod:SPELL_DAMAGE(args)
	if args:IsSpellName("Holy Wrath") then
		timerHolyWrath:Start()
	end
end

function mod:RangeToggle(show)
	if show then
		DBM.RangeCheck:Show(10)
	else
		DBM.RangeCheck:Hide()
	end
end

function mod:OnCombatEnd()
	if self.Options.ShowRange then
		self:RangeToggle(false)
	end
end