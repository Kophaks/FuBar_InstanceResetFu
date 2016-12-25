local Tablet = AceLibrary("Tablet-2.0")

local resetsleft = 5
local ServerName = GetRealmName()
local locale = GetLocale()
local resetText = format(INSTANCE_RESET_SUCCESS, "(.+)")

InstanceResetFu = AceLibrary("AceAddon-2.0"):new("AceEvent-2.0", "FuBarPlugin-2.0")

InstanceResetFu.name = "FuBar_InstanceResetFu"
InstanceResetFu.version = "1.0." .. string.sub("$Revision: 1000 $", 12, -3)
InstanceResetFu.hasIcon = false
InstanceResetFu.defaultPosition = 'LEFT'
InstanceResetFu.defaultMinimapPosition = 180
InstanceResetFu.canHideText = false
InstanceResetFu.hasNoColor = true
InstanceResetFu.cannotDetachTooltip = true

StaticPopupDialogs["RESET_ALL_INSTANCES"] = {
	text = "Do you really want to reset all instances?",
	button1 = "OK",
	button2 = "Cancel",
	OnAccept = function()
		ResetInstances()
	end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1
}

function InstanceResetFu:OnInitialize()
	local currentTime = time()
	if InstanceResetFuDB then
		if InstanceResetFuDB[ServerName] then
			for key,value in pairs(InstanceResetFuDB[ServerName]) do
				if (currentTime - value) >= 3600 then
					InstanceResetFuDB[ServerName][key] = nil
				else
					resetsleft = resetsleft - 1
					self:ScheduleEvent("Cleanup"..value, self.UpdateTimers, (3600 -(currentTime - value)), self)
				end
			end
		else
			InstanceResetFuDB[ServerName] = {}
		end
	else
		InstanceResetFuDB = {}
		InstanceResetFuDB[ServerName] = {}
	end
	if resetsleft == 0 then
		self:ScheduleRepeatingEvent("FIR_UpdateText", self.UpdateText, 1, self)
	end
	self:RegisterEvent("CHAT_MSG_SYSTEM")
end

function InstanceResetFu:UpdateTimers()
	resetsleft = 5
	local currentTime = time()
	for key,value in pairs(InstanceResetFuDB[ServerName]) do
		if (currentTime - value) >= 3600 then
			InstanceResetFuDB[ServerName][key] = nil
		else
			resetsleft = resetsleft - 1
		end
	end
	if resetsleft == 0 then
		self:ScheduleRepeatingEvent("FIR_UpdateText", self.UpdateText, 1, self)
	else
		if self:IsEventScheduled("FIR_UpdateText") then
			self:CancelScheduledEvent("FIR_UpdateText")
		end
	end
	self:UpdateText()
end

function InstanceResetFu:OnClick()
	if not (UnitInRaid("player") or GetNumPartyMembers() > 0) or UnitIsPartyLeader("player") then
		StaticPopup_Show("RESET_ALL_INSTANCES")
	end
end

function InstanceResetFu:OnTextUpdate()
	if resetsleft > 0 then
		self:SetText("Instances left: "..resetsleft)
	else
		local expireTime = 3600
		local currentTime = time()
		for key,value in pairs(InstanceResetFuDB[ServerName]) do
			if (3600 - (currentTime - value)) < expireTime then
				expireTime = (3600 - (currentTime - value))
			end
		end
		local seconds = mod(expireTime,60)
		if strlen(seconds) == 1 then
			seconds = "0"..seconds
		end
		self:SetText("First lockout clears in "..math.floor(expireTime/60)..":"..seconds)
	end
end

function InstanceResetFu:OnTooltipUpdate()
	Tablet:SetHint("Click to reset instances.")
end

function InstanceResetFu:CHAT_MSG_SYSTEM()
	local _,_,instance = string.find(arg1, resetText)
	if instance then
		tinsert(InstanceResetFuDB[ServerName],time())
	end
	self:UpdateTimers()
end