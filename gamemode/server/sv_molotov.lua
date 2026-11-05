function GM:IgniteMolotovTarget(ent, owner, duration, crafter)
	ent:Ignite(duration)
	for _, fire in ipairs(ent:GetChildren()) do
		if IsValid(fire) and fire:GetClass() == "entityflame" and fire:GetParent() == ent
			and (fire.ZSMolotovOwner ~= owner or fire.ZSCrafter ~= crafter) then
			fire:SetOwner(owner); fire:SetPhysicsAttacker(owner)
			fire.ZSMolotovOwner, fire.ZSCrafter = owner, crafter
		end
	end
end
