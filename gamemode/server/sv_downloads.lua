local contentWorkshop = CreateConVar("zs_content_workshop", "", FCVAR_ARCHIVE, "Workshop ID of this server's Zombie Survival content pack.")
local gamemodeWorkshop = CreateConVar("zs_gamemode_workshop", "", FCVAR_ARCHIVE, "Workshop ID of this server's Zombie Survival gamemode.")

function GM:AddResources()
	local content = string.Trim(contentWorkshop:GetString())
	local gamemode = string.Trim(gamemodeWorkshop:GetString())
	if #content <= 20 and string.match(content, "^[1-9]%d*$") then resource.AddWorkshop(content) end
	if gamemode ~= content and #gamemode <= 20 and string.match(gamemode, "^[1-9]%d*$") then resource.AddWorkshop(gamemode) end
	AddContentFiles(self.FolderName .. "/content/")
end

function AddContentFiles(root)
	local seen = {}
	local function walk(path)
		local files, dirs = file.Find(path .. "*", "LUA")
		for _, filename in ipairs(files or {}) do
			local relative = string.sub(path .. filename, #root + 1)
			if not seen[relative] then
				seen[relative] = true
				resource.AddSingleFile(relative)
			end
		end
		for _, dir in ipairs(dirs or {}) do
			if dir ~= "data" and dir ~= "lua" then walk(path .. dir .. "/") end
		end
	end
	walk(root)
end
