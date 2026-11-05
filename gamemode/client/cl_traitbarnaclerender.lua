local gm = GM or GAMEMODE
local previous = gm.ZSBarnacleRenderer
if previous then previous.Shutdown() end
local state = {entries = {}}
gm.ZSBarnacleRenderer = state
local hidden = CreateMaterial("zs_barnacle_cached_hidden", "UnlitGeneric", {["$basetexture"] = "models/barnacle/tongue", ["$model"] = "1", ["$no_draw"] = "1"})
hidden:SetInt("$flags", bit.bor(hidden:GetInt("$flags"), 4))
local material = Material("models/barnacle/tongue")
local radial = {}
for index = 0, 8 do radial[index] = {math.cos(index * math.pi / 4), math.sin(index * math.pi / 4)} end
local function Release(entry)
	if entry.mesh then entry.mesh:Destroy() entry.mesh = nil end
	entry.frame = nil
end
local function Remove(ent)
	local entry = state.entries[ent]
	if not entry then return end
	if IsValid(ent) and ent.RenderOverride == entry.draw then ent.RenderOverride = nil end
	Release(entry)
	state.entries[ent] = nil
end
function state.Shutdown()
	for ent in pairs(state.entries) do Remove(ent) end
end
local function Geometry(ent, entry, origin, blend)
	local model, lookup = ent:GetModel(), ent.LookupBone
	if model ~= "models/barnacle.mdl" then Release(entry) return end
	if entry.model ~= model or entry.lookup ~= lookup or not entry.bones then
		Release(entry)
		entry.model, entry.lookup, entry.bones = model, lookup, {}
		for index = 1, 8 do
			local bone = lookup(ent, "Barnacle.tongue" .. index)
			if bone == nil then entry.bones = nil return end
			entry.bones[index] = bone
		end
	end
	if not entry.bones then return end
	local frame = FrameNumber()
	if entry.frame == frame and entry.x == origin.x and entry.y == origin.y and entry.z == origin.z and entry.blend == blend then return true end
	ent:SetupBones()
	local positions = entry.positions
	if not positions then positions = {} entry.positions = positions end
	for index = 1, 8 do
		local matrix = ent:GetBoneMatrix(entry.bones[index])
		if not matrix then entry.frame = nil return end
		positions[index] = matrix:GetTranslation()
	end
	if not entry.mesh then
		entry.mesh = Mesh(material)
		entry.vertexPosition, entry.vertexNormal = Vector(), Vector()
	end
	local position, normal = entry.vertexPosition, entry.vertexNormal
	mesh.Begin(entry.mesh, MATERIAL_TRIANGLES, 224)
	for index = 1, 7 do
		local from, to = positions[index], positions[index + 1]
		local direction = to - from
		local angle = direction:Angle()
		local right, up = -angle:Right(), angle:Up()
		local function Vertex(fraction, side, radius)
			local pair = radial[side]
			local x, y, z = right.x * pair[1] + up.x * pair[2], right.y * pair[1] + up.y * pair[2], right.z * pair[1] + up.z * pair[2]
			position:SetUnpacked(from.x + direction.x * fraction + x * radius, from.y + direction.y * fraction + y * radius, from.z + direction.z * fraction + z * radius)
			normal:SetUnpacked(x, y, z)
			mesh.Position(position) mesh.Normal(normal) mesh.TexCoord(0, side / 8, fraction) mesh.Color(255, 255, 255, 255) mesh.AdvanceVertex()
		end
		local function Radius(fraction)
			local x, y, z = from.x + direction.x * fraction - origin.x, from.y + direction.y * fraction - origin.y, from.z + direction.z * fraction - origin.z
			return 1 - (1 - math.min(math.sqrt(x * x + y * y + z * z) / 256, 1)) * blend
		end
		local length = direction.x * direction.x + direction.y * direction.y + direction.z * direction.z
		local nearest = length > 0 and math.Clamp(((origin.x - from.x) * direction.x + (origin.y - from.y) * direction.y + (origin.z - from.z) * direction.z) / length, 0, 1) or 0.5
		local x0, r0 = 0, Radius(0)
		for span = 1, 2 do
			local x1 = span == 1 and nearest or 1
			local r1 = Radius(x1)
			for side = 0, 7 do
				Vertex(x0, side, r0) Vertex(x1, side + 1, r1) Vertex(x1, side, r1)
				Vertex(x0, side, r0) Vertex(x0, side + 1, r0) Vertex(x1, side + 1, r1)
			end
			x0, r0 = x1, r1
		end
	end
	mesh.End()
	entry.frame, entry.x, entry.y, entry.z, entry.blend = frame, origin.x, origin.y, origin.z, blend
	return true
end
local function Draw(ent, flags)
	local entry = state.entries[ent]
	if not entry then ent:DrawModel(flags) return end
	if not IsValid(ent:GetNW2Entity("zs_barnacle_owner")) then Remove(ent) ent:DrawModel(flags) return end
	local origin, root = EyePos(), ent:GetPos()
	local dx, dy = origin.x - root.x, origin.y - root.y
	local distance = dx * dx + dy * dy
	if distance >= 4096 or origin.z > root.z or origin.z < root.z - 2112 or not Geometry(ent, entry, origin, math.Clamp((64 - math.sqrt(distance)) / 32, 0, 1)) then ent:DrawModel(flags) return end
	local oldMaterial = ent:GetSubMaterial(2)
	ent:SetSubMaterial(2, "!zs_barnacle_cached_hidden")
	local ok, failure = pcall(ent.DrawModel, ent, flags)
	if IsValid(ent) then ent:SetSubMaterial(2, oldMaterial) end
	if not ok then error(failure, 0) end
	if not IsValid(ent) or state.entries[ent] ~= entry then return end
	if not IsValid(ent:GetNW2Entity("zs_barnacle_owner")) then Remove(ent) return end
	render.SetMaterial(material)
	entry.mesh:Draw()
end
local function Update(ent, owner)
	if not IsValid(ent) or ent:GetClass() ~= "npc_barnacle" then return end
	if owner == nil then owner = ent:GetNW2Entity("zs_barnacle_owner") end
	if not IsValid(owner) then Remove(ent) return end
	local entry = state.entries[ent]
	if entry and ent.RenderOverride == entry.draw then return end
	if entry then Remove(ent) end
	if ent.RenderOverride ~= nil then return end
	entry = {draw = Draw}
	state.entries[ent], ent.RenderOverride = entry, Draw
end
hook.Add("EntityNetworkedVarChanged", "ZSTraitBarnacleCachedRenderer", function(ent, name, _, value)
	if name == "zs_barnacle_owner" then Update(ent, value) end
end)
hook.Add("NetworkEntityCreated", "ZSTraitBarnacleCachedRenderer", function(ent)
	timer.Simple(0, function() Update(ent) end)
end)
hook.Add("NotifyShouldTransmit", "ZSTraitBarnacleCachedRenderer", function(ent, transmitting)
	if transmitting then Update(ent) else Remove(ent) end
end)
hook.Add("EntityRemoved", "ZSTraitBarnacleCachedRenderer", Remove)
hook.Add("PreCleanupMap", "ZSTraitBarnacleCachedRenderer", state.Shutdown)
hook.Add("InitPostEntity", "ZSTraitBarnacleCachedRenderer", function()
	for _, ent in ipairs(ents.FindByClass("npc_barnacle")) do Update(ent) end
end)

