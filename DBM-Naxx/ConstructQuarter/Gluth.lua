local mod	= DBM:NewMod("Gluth", "DBM-Naxx", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4451 $"):sub(12, -3))
mod:SetCreatureID(15932)

mod:RegisterCombat("combat")

mod:EnableModel()

mod:RegisterEvents(
	"SPELL_DAMAGE"
)


local warnDecimateSoon	= mod:NewSoonAnnounce(54426, 2)
local warnDecimateNow	= mod:NewSpellAnnounce(54426, 3)

local enrageTimer		= mod:NewBerserkTimer(420)
local timerDecimate		= mod:NewCDTimer(104, 54426)

function mod:OnCombatStart(delay)
	timerDecimate:Start(110 - delay)
	warnDecimateSoon:Schedule(100 - delay)
	if mod:IsDifficulty("heroic25") then
		enrageTimer:Start(480 - delay)
	else
	enrageTimer:Start(420 - delay)
	end
end

local decimateSpam = 0
function mod:SPELL_DAMAGE(args)
	if args:IsSpellID(28375) and (GetTime() - decimateSpam) > 20 then
		decimateSpam = GetTime()
		warnDecimateNow:Show()
		timerDecimate:Start()
		warnDecimateSoon:Schedule(96)
	end
end


