function GM:FireRicochetBullets(attacker,bullet)
 if not IsValid(attacker)then return end
 local previous=attacker.RicochetBullet
 attacker.RicochetBullet=true
 local ok,failure=pcall(attacker.FireBullets,attacker,bullet)
 if IsValid(attacker)then attacker.RicochetBullet=previous end
 if not ok then error(failure,0)end
end
