--[[
One-Shot Protection, written by [aka]bomb.
Kindly see the README.
]]

local hook_Run = hook.Run
local math_max = math.max
local tonumber = tonumber

local mp_one_shot_protection = CreateConVar(
	"mp_one_shot_protection", "1",
	bit.bor(FCVAR_REPLICATED, FCVAR_NOTIFY),
	"One-shot protection is enabled.",
	0, 1
)
local mp_one_shot_invuln_period = CreateConVar(
	"mp_one_shot_invuln_period", "0.1",
	bit.bor(FCVAR_REPLICATED, FCVAR_NOTIFY),
	"Period in seconds of invulnerability after a one-shot protection.",
	0, nil
)
local mp_one_shot_health_threshold = CreateConVar(
	"mp_one_shot_health_threshold", "0.8",
	bit.bor(FCVAR_REPLICATED, FCVAR_NOTIFY),
	"Multiplier of the maximum effective health which dictates the minimum amount required for one-shot protection.",
	0, nil
)
local mp_one_shot_health_protected = CreateConVar(
	"mp_one_shot_health_protected", "0.2",
	bit.bor(FCVAR_REPLICATED, FCVAR_NOTIFY),
	"Multiplier of the maximum effective health which dictates the amount left after a one-shot protection. The resulting health will never be less than 1.",
	0, nil
)

local player_old_armor = GetConVar("player_old_armor")

hook.Add(
	"EntityTakeDamage", "OneShotProtection.DoProtection",
	--- @param target Entity|Player
	--- @param dmg_info CTakeDamageInfo
	function (target, dmg_info)
		if not mp_one_shot_protection:GetBool() then return end
		if
			CurTime() <= target:GetNW2Float("OneShotProtection_InvulnTime", 0.0)
		then
			return true
		end

		local is_protected = hook_Run(
			"OneShotProtection_IsProtected", target, dmg_info
		)
		if is_protected == nil then
			is_protected = target:IsPlayer()
		end
		if not is_protected then return end

		local health, health_max = hook_Run(
			"OneShotProtection_CalcEffectiveHealth", target
		)
		health, health_max = tonumber(health), tonumber(health_max)
		if not (health and health_max) then
			health, health_max = target:Health(), target:GetMaxHealth()
			if target:IsPlayer() then
				local armor_multiplier = player_old_armor:GetBool() and 2 or 1
				health = health + target:Armor() * armor_multiplier
				health_max = health_max + target:GetMaxArmor() * armor_multiplier
			end
		end

		do
			local health_threshold = tonumber((hook_Run(
				"OneShotProtection_CalcHealthThreshold",
				health_max, target, health
			)))
			if not health_threshold then
				health_threshold =
					health_max * mp_one_shot_health_threshold:GetFloat()
			end
			if health < health_threshold then return end
		end

		local health_protected = tonumber((hook_Run(
			"OneShotProtection_CalcHealthProtected",
			health_max, target, health
		)))
		if not health_protected then
			health_protected = math_max(
				1, health_max * mp_one_shot_health_protected:GetFloat()
			)
		end

		local result = hook_Run(
			"OneShotProtection_DoProtect",
			dmg_info, health, health_protected
		)
		if result == nil then
			if (health - dmg_info:GetDamage()) < health_protected then
				dmg_info:SetDamage(health - health_protected)
				result = true
			else
				result = false
			end
		end

		if result == false then
			return
		end

		local invuln_time = tonumber((hook_Run(
			"OneShotProtection_CalcInvulnTime",
			target, dmg_info, health, health_max, health_protected
		)))
		if not invuln_time then
			invuln_time = CurTime() + mp_one_shot_invuln_period:GetFloat()
		end
		target:SetNW2Float(
			"OneShotProtection_InvulnTime",
			invuln_time
		)

		hook_Run(
			"OneShotProtection_Protected",
			target, dmg_info, health, health_max, health_protected
		)

		if result == "block" then
			return true
		end
	end
)
