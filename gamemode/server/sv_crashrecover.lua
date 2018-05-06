CreateConVar("max_crash_count", "2", FCVAR_ARCHIVE + FCVAR_NOTIFY, "Max times the server can crash before choosing the next map or a random map")

local OldRunConsoleCommand = RunConsoleCommand
function RunConsoleCommand(cvar, ...)
	if cvar == "changelevel" then
		local map = tostring(select(1,...))
		GameTravel(map)
	end
	
	OldRunConsoleCommand(cvar, ...)
end

local OldConsoleCommand = game.ConsoleCommand
function game.ConsoleCommand(stringCommand)
	local split = string.Split(stringCommand, " ")

	if not split or not split[1] or not split[2] then return end

	if split[1] == "changelevel" then
		local map = split[2]
		GameTravel(map)
	end
	
	OldConsoleCommand(stringCommand)
end

function GameTravel(map)
	if game.GetMap() == map then return end
	
	local tab = {
		["map"] = map,
		["crash_count"] = 0
	}
	if file.Exists("gmod_crashrecover.txt", "DATA") then
		tab = util.JSONToTable(file.Read("gmod_crashrecover.txt", "DATA"))
		tab["map"] = map
	end
	
	file.Write("gmod_crashrecover.txt", util.TableToJSON(tab))
end

local function RealMap(map)
	return string.match(map, "(.+)%.bsp")
end

// Change this to the map prefixes you wish to use such as zs_, zm_, or de_
local map_prefixes = {"zs_"}
hook.Add("InitPostEntity", "InitPostEntity.CrashRecover", function()
	if file.Exists("gmod_crashrecover.txt", "DATA") then
		local tab = util.JSONToTable(file.Read("gmod_crashrecover.txt", "DATA"))
		local count = tab["crash_count"]
	
		if count >= (GetConVar("max_crash_count"):GetInt() or 2) then
			tab["crash_count"] = 0
			file.Write("gmod_crashrecover.txt", util.TableToJSON(tab))
			
			if file.Exists(GetConVarString("mapcyclefile"), "GAME") then
				game.LoadNextMap()
			else
				local maps = {}
				for _, prefix in pairs(map_prefixes) do
					maps = table.Add(maps, file.Find("maps/"..prefix.."*.bsp", "GAME"))
				end
				table.sort(maps)
				if #maps > 0 then
					local currentmap = game.GetMap()
					for i, map in ipairs(maps) do
						local lowermap = string.lower(map)
						local realmap = RealMap(lowermap)
						if realmap == currentmap then
							if maps[i + 1] then
								local nextmap = RealMap(maps[i + 1])
								if nextmap then
									RunConsoleCommand("changelevel", nextmap)
								end
							else
								local nextmap = RealMap(maps[1])
								if nextmap then
									RunConsoleCommand("changelevel", nextmap)
								end
							end

							break
						end
					end
				end
			end
			
			return
		end
		
		local map = tab["map"]
		if game.GetMap() ~= map then
			tab["crash_count"] = count + 1
			file.Write("gmod_crashrecover.txt", util.TableToJSON(tab))
			OldRunConsoleCommand("changelevel", map)
		else
			tab["crash_count"] = 0
			file.Write("gmod_crashrecover.txt", util.TableToJSON(tab))
		end
	end
end)