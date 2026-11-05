ENT.Type = "anim"
ENT.Base = "status__base"

AccessorFuncDT(ENT, "ObjectMass", "Int", 0)

local movementEpoch
local movementClock = CLIENT and FrameNumber or engine.TickCount
local movementOwners = setmetatable({}, {__mode = "k"})
local movementLists = {}
local entityMeta = FindMetaTable("Entity")
local ownerBinding = rawget(entityMeta, "ZSHoldingMovementBinding")
if not ownerBinding then
	ownerBinding = {setOwner = entityMeta.SetOwner}
	ownerBinding.wrapper = function(entity, owner)
		local holding = entity.ZSHoldingMovement
		ownerBinding.setOwner(entity, owner)
		if holding then ownerBinding.invalidate() end
	end
	entityMeta.ZSHoldingMovementBinding = ownerBinding
	entityMeta.SetOwner = ownerBinding.wrapper
end

local function HoldingMovement(pl, move)
	local epoch = movementClock()
	if movementEpoch ~= epoch then
		if not GAMEMODE or not GAMEMODE.GetZSEquipmentEntities then return end
		for i = #movementLists, 1, -1 do
			local list = movementLists[i]
			for j = #list, 1, -1 do list[j] = nil end
			movementLists[i] = nil
		end
		local live = 0
		for _, status in ipairs(GAMEMODE:GetZSEquipmentEntities("status_human_holding")) do
			if IsValid(status) and not status.Removing and not status:IsMarkedForDeletion() then
				live = live + 1
				local owner = status:GetOwner()
				if IsValid(owner) then
					local list = movementOwners[owner]
					if not list then list = {} movementOwners[owner] = list end
					if #list == 0 then movementLists[#movementLists + 1] = list end
					list[#list + 1] = status
				end
			end
		end
		movementEpoch = epoch
		if live == 0 then hook.Remove("Move", "ZSHoldingMovement") return end
	end
	local list = movementOwners[pl]
	if list then
		for _, status in ipairs(list) do
			if IsValid(status) and not status.Removing and not status:IsMarkedForDeletion() then status:Move(pl, move) end
		end
	end
end

function ENT:InvalidateHoldingMovement()
	self.ZSHoldingMovement = true
	movementEpoch = nil
	hook.Add("Move", "ZSHoldingMovement", HoldingMovement)
end

ownerBinding.invalidate = function()
	movementEpoch = nil
	hook.Add("Move", "ZSHoldingMovement", HoldingMovement)
end

function ENT:Move(pl, mv)
	if self.Removing or pl ~= self:GetOwner() then return end

	local object = self:GetObject()
	if object:IsValid() then
		local maximum = mv:GetMaxSpeed()
		local speed = math.max(maximum / 4, maximum - self:GetObjectMass() * CARRY_SPEEDLOSS_PERKG)
		mv:SetMaxSpeed(speed)
		mv:SetMaxClientSpeed(speed)
	end
end

local defaultcolor = Vector( 62.0/255.0, 88.0/255.0, 106.0/255.0 )
function ENT:GetPlayerColor()
	local owner = self:GetOwner()
	if owner and owner:IsValid() and owner.GetPlayerColor then
		return owner:GetPlayerColor()
	end

	return defaultcolor
end

function ENT:GetObject()
	return self:GetDTEntity(0)
end

function ENT:SetObject(object)
	local previous = self:GetObject()
	if IsValid(previous) then previous.ZSHoldingStatus = nil end
	if IsValid(object) then object.ZSHoldingStatus = nil end
	self:SetDTEntity(0, object)
end

function ENT:SetIsHeavy(heavy)
	self:SetDTBool(0, heavy)
end

function ENT:GetIsHeavy()
	return self:GetDTBool(0)
end

function ENT:GetPullPos()
	local owner = self:GetOwner()
	if owner:IsValid() then
		return owner:EyePos() + owner:GetAimVector() * 48
	end

	return self:GetObjectPos()
end

function ENT:GetObjectPos()
	local object = self:GetObject()
	if object:IsValid() then
		return object:GetPos()
	end

	return self:GetPos()
end

function ENT:SetHingePos(pos)
	local object = self:GetObject()
	if object:IsValid() then
		self:SetDTVector(0, object:WorldToLocal(pos))
	end
end

function ENT:GetHingePos()
	local object = self:GetObject()
	if object:IsValid() then
		return object:LocalToWorld(self:GetDTVector(0))
	end

	return self:GetObjectPos()
end

if hook.GetTable then
	for id in pairs(hook.GetTable().Move or {}) do
		if IsValid(id) and id.GetClass and id:GetClass() == "status_human_holding" then
			id.ZSHoldingMovement = true
			hook.Remove("Move", id)
		end
	end
end
hook.Add("Move", "ZSHoldingMovement", HoldingMovement)
