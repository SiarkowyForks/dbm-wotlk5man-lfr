local mod	= DBM:NewMod("Gluth", "DBM-Naxx", 2)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 2869 $"):sub(12, -3))
mod:SetCreatureID(15932)
mod:SetUsedIcons(7, 8)

mod:RegisterCombat("combat")

mod:EnableModel()

mod:RegisterEvents(
	"SPELL_DAMAGE",
	"SPELL_AURA_APPLIED",
	"SPELL_AURA_REMOVED"
)


local warnDecimateSoon	= mod:NewSoonAnnounce(54426, 2)
local warnDecimateNow	= mod:NewSpellAnnounce(54426, 3)
local specwarnFleshRip	= mod:NewSpecialWarning("SpecialWarningFleshRip")
local warnFleshRip		= mod:NewTargetAnnounce(40199, 2)

local enrageTimer		= mod:NewBerserkTimer(420)
local timerDecimate		= mod:NewCDTimer(104, 54426)

mod:AddBoolOption("SetIconOnFleshRipTarget", true)

local fleshripIcons = {}

function mod:OnCombatStart(delay)
	timerDecimate:Start(110 - delay)
	warnDecimateSoon:Schedule(100 - delay)
	if self:IsDifficulty("heroic25") then
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

function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(40199) then
		warnFleshRip:Show(args.destName)
		if args:IsPlayer() then
			specwarnFleshRip:Show()
		end
		if self.Options.SetIconOnFleshRipTarget then
			table.insert(fleshripIcons, args.destName)
			addIcon()
		end
	end
end

function mod:SPELL_AURA_REMOVED(args)
	if args:IsSpellID(40199) and self.Options.SetIconOnInjectionTarget then
		removeIcon(args.destName)
	end
end

local function addIcon()
	for i,j in ipairs(fleshripIcons) do
		local icon = 9 - i
		SetIcon(j, icon)
	end
end

local function removeIcon(target)
	for i,j in ipairs(fleshripIcons) do
		if j == target then
			table.remove(fleshripIcons, i)
			SetIcon(target, 0)
		end
	end
	addIcon()
end

function mod:OnCombatEnd()
    for i,j in ipairs(fleshripIcons) do
       self:SetIcon(j, 0)
    end
end

