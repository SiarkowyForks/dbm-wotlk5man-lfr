local mod	= DBM:NewMod("Sapphiron", "DBM-Naxx", 5)
local L		= mod:GetLocalizedStrings()

mod:SetRevision(("$Revision: 4448 $"):sub(12, -3))
mod:SetCreatureID(15989)

mod:RegisterCombat("combat")

mod:EnableModel()

mod:RegisterEvents(
	"SPELL_AURA_APPLIED",
	"CHAT_MSG_MONSTER_EMOTE",
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"SPELL_CAST_SUCCESS"
)

local warnDrainLifeNow	= mod:NewSpellAnnounce(28542, 2)
local warnDrainLifeSoon	= mod:NewSoonAnnounce(28542, 1)
local warnAirPhaseSoon	= mod:NewAnnounce("WarningAirPhaseSoon", 3, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp")
local warnAirPhaseNow	= mod:NewAnnounce("WarningAirPhaseNow", 4, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp")
local warnLanded		= mod:NewAnnounce("WarningLanded", 4, "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp")
local warnFrozenOrb		= mod:NewAnnounce("WarningFrozenOrb", 4, 72081)

local warnDeepBreath	= mod:NewSpecialWarning("WarningDeepBreath")

mod:AddBoolOption("WarningIceblock", true, "announce")

local timerDrainLife	= mod:NewCDTimer(22, 28542)
local timerAirPhase		= mod:NewTimer(66, "TimerAir", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendUnBurrow.blp")
local timerLanding		= mod:NewTimer(28.5, "TimerLanding", "Interface\\AddOns\\DBM-Core\\textures\\CryptFiendBurrow.blp")
local timerIceBlast		= mod:NewTimer(8.2, "TimerIceBlast", 15876)
local timerFrozenOrb 	= mod:NewTimer(30, "TimerFrozenOrb", 72081)

local noTargetTime = 0
local isFlying = false

mod:AddBoolOption("PlaySoundOnIceBlast", false)

function mod:OnCombatStart(delay)
	if mod:IsDifficulty("heroic25") then
		timerFrozenOrb:Start(-delay)
		warnFrozenOrb:Schedule(30 - delay)
	end
	noTargetTime = 0
	isFlying = false
	warnAirPhaseSoon:Schedule(38.5 - delay)
	timerAirPhase:Start(48.5 - delay)
end


function mod:SPELL_AURA_APPLIED(args)
	if args:IsSpellID(28522) and args:IsPlayer() and self.Options.WarningIceblock then
		SendChatMessage(L.WarningYellIceblock, "YELL")
	end
end

function mod:SPELL_CAST_SUCCESS(args)
	if args:IsSpellID(28542, 55665) then -- Life Drain
		warnDrainLifeNow:Show()
		warnDrainLifeSoon:Schedule(18.5)
		timerDrainLife:Start()
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(msg)
	if msg == L.EmoteBreath or msg:find(L.EmoteBreath) then
		self:SendSync("DeepBreath")
	end
end

mod.CHAT_MSG_RAID_BOSS_EMOTE = mod.CHAT_MSG_MONSTER_EMOTE -- used to be a normal emote

function mod:OnSync(event)
	if event == "DeepBreath" then
		if self.Options.PlaySoundOnIceBlast then
			PlaySoundFile("Sound\\Creature\\HeadlessHorseman\\Horseman_Beckon_01.wav")
		end
		if mod:IsDifficulty("heroic25") then
			timerIceBlast:Start(7.8)
		else
			timerIceBlast:Show()
		end
		timerLanding:Update(14)
		self:ScheduleMethod(14.5, "Landing")
		warnDeepBreath:Show()
	end
end

function mod:Landing()
	if mod:IsDifficulty("heroic25") then
		timerFrozenOrb:Start()
		timerFrozenOrb:Schedule(30, 25)
		warnFrozenOrb:Schedule(30)
		warnFrozenOrb:Schedule(55)
	end
	warnAirPhaseSoon:Schedule(56)
	warnLanded:Show()
	timerAirPhase:Start()
end

local function resetIsFlying()
	isFlying = false
end

mod:RegisterOnUpdateHandler(function(self, elapsed)
	if not self:IsInCombat() then return end
		local foundBoss, target
		for i = 1, GetNumRaidMembers() do
			local uId = "raid"..i.."target"
			if self:GetUnitCreatureId(uId) == 15989 and UnitAffectingCombat(uId) then
				target = UnitName(uId.."target")
				foundBoss = true
				break
			end
		end
		if foundBoss and not target then
			noTargetTime = noTargetTime + elapsed
		elseif foundBoss then
			noTargetTime = 0
		end
		if noTargetTime > 0.5 and not isFlying then
			noTargetTime = 0
			isFlying = true
			self:Schedule(60, resetIsFlying)
			timerDrainLife:Cancel()
			timerAirPhase:Cancel()
			warnAirPhaseNow:Show()
			timerLanding:Start()
		end
end, 0.2)
