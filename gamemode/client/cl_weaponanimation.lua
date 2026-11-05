ZSWeaponAnimation = {}
local api = ZSWeaponAnimation
local states = setmetatable({}, {__mode = "k"})
local lookups = setmetatable({}, {__mode = "k"})
local matrices = setmetatable({}, {__mode = "k"})
local unit = Vector(1, 1, 1)
local zero = Vector(0, 0, 0)
local angles = Angle(0, 0, 0)

function api.RemoveModel(element)
	local model = element.modelEnt
	element.modelEnt = nil
	if IsValid(model) then model:Remove() end
end

function api.RemoveModels(weapon)
	if weapon.VElements then
		for _, element in pairs(weapon.VElements) do api.RemoveModel(element) end
	end
	if weapon.WElements then
		for _, element in pairs(weapon.WElements) do api.RemoveModel(element) end
	end
end

local function stateFor(vm)
	local model, count = vm:GetModel(), vm:GetBoneCount()
	if not count or count <= 0 then return end
	local state = states[vm]
	if state and state.model == model and state.count == count then return state end
	state = {model = model, count = count, bones = {}, names = {}, items = {}}
	for bone = 0, count - 1 do
		local name = vm:GetBoneName(bone)
		if name then state.names[name] = vm:LookupBone(name) end
		state.bones[bone] = {name = name, scale = Vector(1, 1, 1), parents = {}}
	end
	for bone = 0, count - 1 do
		local parents, parent = state.bones[bone].parents, vm:GetBoneParent(bone)
		local seen = {[bone] = true}
		while parent and parent >= 0 and parent < count and not seen[parent] do
			seen[parent] = true
			parents[#parents + 1] = state.bones[parent].name
			parent = vm:GetBoneParent(parent)
		end
	end
	for name, bone in pairs(state.names) do
		if bone and state.bones[bone] then
			local item = state.bones[bone]
			item.name, item.bone = name, bone
			state.items[#state.items + 1] = item
		end
	end
	states[vm] = state
	return state
end

local function apply(vm, bone, scale, angle, pos)
	if vm:GetManipulateBoneScale(bone) ~= scale then vm:ManipulateBoneScale(bone, scale) end
	if vm:GetManipulateBoneAngles(bone) ~= angle then vm:ManipulateBoneAngles(bone, angle) end
	if vm:GetManipulateBonePosition(bone) ~= pos then vm:ManipulateBonePosition(bone, pos) end
end

function api.Reset(vm)
	vm:SetColor(color_white)
	vm:SetMaterial("")
	local count = vm:GetBoneCount()
	if not count then return end
	for bone = 0, count - 1 do apply(vm, bone, unit, angles, zero) end
end

function api.Update(weapon, vm, inheritScale)
	local mods = weapon.ViewModelBoneMods
	if not mods then return weapon:ResetBonePositions(vm) end
	local state = stateFor(vm)
	if not state then return end
	if inheritScale then
		local changed = state.scaleMods ~= mods
		for bone = 0, state.count - 1 do
			local item = state.bones[bone]
			local mod = item.name and mods[item.name]
			local x, y, z = 1, 1, 1
			if mod then
				local scale = mod.scale
				x, y, z = scale.x, scale.y, scale.z
			end
			if item.sourceX ~= x or item.sourceY ~= y or item.sourceZ ~= z then changed = true end
			item.sourceX, item.sourceY, item.sourceZ = x, y, z
		end
		state.scaleMods = mods
		for index = 1, #state.items do
			local item = state.items[index]
			local bone = item.bone
			local mod = mods[item.name]
			if changed then
				local x, y, z = 1, 1, 1
				for i = 1, #item.parents do
					local parent = mods[item.parents[i]]
					if parent then
						x, y, z = x * parent.scale.x, y * parent.scale.y, z * parent.scale.z
					end
				end
				local scale = mod and mod.scale or unit
				item.scale.x, item.scale.y, item.scale.z = scale.x * x, scale.y * y, scale.z * z
			end
			apply(vm, bone, item.scale, mod and mod.angle or angles, mod and mod.pos or zero)
		end
	else
		for name, mod in pairs(mods) do
			local bone = state.names[name]
			if bone == nil then
				bone = vm:LookupBone(name)
				state.names[name] = bone or false
			end
			if bone then apply(vm, bone, mod.scale, mod.angle, mod.pos) end
		end
	end
end

function api.LookupBone(ent, name)
	local model, count = ent:GetModel(), ent:GetBoneCount()
	if not count or count <= 0 then return ent:LookupBone(name) end
	local state = lookups[ent]
	if not state or state.model ~= model or state.count ~= count then
		state = {model = model, count = count, names = {}}
		lookups[ent] = state
	end
	local bone = state.names[name]
	if bone == nil then
		bone = ent:LookupBone(name)
		state.names[name] = bone or false
	end
	return bone or nil
end

function api.LookupBoneSet(ent, names)
	local model, count = ent:GetModel(), ent:GetBoneCount()
	local state
	if count and count > 0 then
		state = lookups[ent]
		if not state or state.model ~= model or state.count ~= count then
			state = {model = model, count = count, names = {}}
			lookups[ent] = state
		end
		state.sets = state.sets or {}
		if state.sets[names] then return state.sets[names] end
	end
	local bones = {}
	for i = 1, #names do
		local name = names[i]
		local bone = state and state.names[name]
		if bone == nil then
			bone = ent:LookupBone(name) or false
			if state then state.names[name] = bone end
		end
		bones[i] = bone
	end
	if state then state.sets[names] = bones end
	return bones
end

local boneScaleMasks = setmetatable({}, {__mode = "k"})
function api.ResetWithBoneScales(ent, names, scale)
	local bones = api.LookupBoneSet(ent, names)
	local mask = boneScaleMasks[bones]
	if not mask then
		mask = {}
		for _, bone in ipairs(bones) do if bone and bone > 0 then mask[bone] = true end end
		boneScaleMasks[bones] = mask
	end
	for bone = 0, ent:GetBoneCount() - 1 do
		ent:ManipulateBoneScale(bone, mask[bone] and scale or unit)
		ent:ManipulateBoneAngles(bone, angles)
		ent:ManipulateBonePosition(bone, vector_origin)
	end
end

function api.BoneTransform(ent, name)
	local bone = api.LookupBone(ent, name)
	if not bone then return end
	local matrix = ent:GetBoneMatrix(bone)
	if matrix then return matrix:GetTranslation(), matrix:GetAngles() end
	return Vector(0, 0, 0), Angle(0, 0, 0)
end

function api.ScaleMatrix(element)
	local size = element.size
	local state = matrices[element]
	if not state then
		state = {matrix = Matrix()}
		matrices[element] = state
	end
	if state.x ~= size.x or state.y ~= size.y or state.z ~= size.z then
		state.matrix:Identity()
		state.matrix:Scale(size)
		state.x, state.y, state.z = size.x, size.y, size.z
	end
	return state.matrix
end
