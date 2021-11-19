local module = {}
module.owner = {}
module.admin = {}
module.mods = {}
module.all = {}

local lib = require(script.Parent.Parent.lib.aaadddLib)
local bin = script.Parent.Parent.bin
local vim = require(script.Parent.Parent.lib.VIM2)
local log = require(script.Parent.Parent.lib.Log)
local trello = require(game.ServerScriptService:FindFirstChild("TrelloAPI"))
local tBoardId = game.ServerScriptService:WaitForChild("TrelloAPI").BoardID.Value

local cc = game.ServerScriptService:FindFirstChild("ConsoleCommands") or game.ServerScriptService:WaitForChild("ConsoleCommands")
local cfg = cc.Configuration
local _settings = require(cfg.Settings) --settings are packed to contain both the settings and the admin list
local Settings,adminList = _settings[1],_settings[2]

do		--Owners
	module.owner["removeallitems"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot remove items from a non-player!") end
			local skydata = v:FindFirstChild("skyData")
			if not skydata then error("SkyData not found!") end
			skydata.inventory:ClearAllChildren()
			v.Backpack:ClearAllChildren()
			output[#output+1] = string.char(130).."Cleared inventory for: "..v.Name
		end
		return table.concat(output,"\n")
	end,
	[[Removes all items from the targets inventory. If the optional argument “player” is made,
]]..string.char(133)..[[will transfer all items to speakers inventory. Does not affect gold.]],
	[[removeallitems [target] [player] ]]}
	module.owner["resetinventory"] = module.owner["removeallitems"]
	module.owner["removeitems"] = module.owner["removeallitems"]
	module.owner["clearinventory"] = module.owner["removeallitems"]
	module.owner["wipe"] = module.owner["removeallitems"]
	
	module.owner["killall"] = {function(player,target,params)
		local output = {}
		local humanoids = lib.allChildsMatching(workspace,function(a) return a:IsA("Humanoid") and not game.Players:GetPlayerFromCharacter(a.Parent) end)
		for k,v in pairs(humanoids) do
			local isPlayer = game.Players:GetPlayerFromCharacter(v.Parent)
			if isPlayer then output[#output+1] = string.char(133).."Killed Player: "..v.Parent.Name; v.Health = 0
			else output[#output+1] = string.char(135).."Killed NPC: "..v.Parent.Name; v.Health = 0
			end
		end
		return table.concat(output,"\n")
	end,
	[[Instantly kills all players and NPCs.]],
	[[killall]]}
	module.owner["genocide"] = module.owner["killall"]
	module.owner["お前わも。。。しんでる"] = module.owner["killall"] --omae wa mo... shinderu
	
	module.owner["admin"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot admin a non-player!") end
			local lists = trello:GetLists(tBoardId)
			for q,e in next,lists do
				if lists[q] ~= nil then
					if lists[q]["name"] == "Admin List" then
						local cards = trello:GetCardsInList(lists[q]["id"])
						local pattern = "(%w+):?(%d+)"
						for _,c in next,cards do --Precheck to see if user is already admin
							local n,i = c["name"]:match(pattern)
							if v.Name == tostring(n) or v.UserId == tonumber(i) or lib.isInList(v.UserId,adminList.admins) then
								error(v.Name.." is already an admin!")
							end
						end
						if not lib.isInList(v.UserId,adminList.admins) then
							trello:AddCard((v.Name..":"..v.UserId),"",trello:GetListID("Admin List",tBoardId))
							table.insert(adminList.admins,tostring(v.UserId))
							output[#output+1] = "Gave permanent admin to ".. v.Name
						end
					end
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Gives the target permanent admin.]],
	[[admin [target] ]]}
	
	module.owner["tempadmin"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot admin a non-player!") end
			if not lib.isInList(v.UserId,adminList.admins) then
				table.insert(adminList.admins,tostring(v.UserId))
				output[#output+1] = "Gave temporary admin to ".. v.Name
			end
		end
		return table.concat(output,"\n")
	end,
	[[Gives the target temporary admin (Lasts as long as the current server is alive).]],
	[[tempadmin [target] ]]}
	module.owner["tadmin"] = module.owner["tempadmin"]
	
	module.owner["radmin"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot remove admin from a non-player!") end
			local index = lib.isInList(v.UserId,adminList.admins)
			if index then
				table.remove(adminList.admins,index)
			end
			local lists = trello:GetLists(tBoardId)
			for q,e in next,lists do
				if lists[q] ~= nil then
					if lists[q]["name"] == "Delete Queue" then
						local cards = trello:GetCardsInList(lists[q]["id"])
						local pattern = "(%w+):?(%d+)"
						for _,c in next,cards do --Precheck to see if user is already admin
							local n,i = c["name"]:match(pattern)
							if v.Name == tostring(n) or v.UserId == tonumber(i) or lib.isInList(v.UserId,adminList.delQ) then
								error(v.Name.." is already queued for deletion!")
							end
						end
						if not lib.isInList(v.UserId,adminList.admins) then
							trello:AddCard((v.Name..":"..v.UserId),"",trello:GetListID("Delete Queue",tBoardId))
							table.insert(adminList.delQ,tostring(v.UserId))
							output[#output+1] = "Removed admin from ".. v.Name
							output[#output+1] = string.char(131).."Remember to update the cards in Trello!"
						end
					end
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Removes admin from the target player, if they currently have it.]],
	[[radmin [target] ]]}
	module.owner["removeadmin"] = module.owner["radmin"]
	module.owner["unadmin"] = module.owner["radmin"]
	
	module.owner["shutdown"] = {function(player,target,params)
		local players = game.Players:GetPlayers()
		for i=1,#players do
			players[i]:kick("This server has been shutdown.")
		end
	end,
	[[Shuts down the current server.]],
	[[shutdown ]]}
	
	module.owner["serverlock"] = {function(player,target,params)
		local output = {}
		_G.isServerLocked = not _G.isServerLocked
		output[#output+1] = "Toggled Server Lock => ".. tostring(_G.isServerLocked)
		return table.concat(output,"\n")
	end,
	[[Locks the current server so no one except owner-level admins can enter. Togglable.]],
	[[serverlock ]]}
	
--	module.owner["settings"] = {function(player,target,params)
--		return "TODO"
--	end,
--	[[Temporarily changes the given setting to the given value. ]],
--	[[settings [setting] [value] ]]}
	
	module.owner["commandlog"] = {function(player,target,params)
		local output = {}
		local cLogGui = player.PlayerGui:FindFirstChild("CommandLog") --bin.CommandLog:Clone()
		if not cLogGui then 
			cLogGui = bin.CommandLog:Clone()
			cLogGui.Parent = player.PlayerGui
		else
			error("Command Log already open.")
		end
		local currentYOffset = 0
		for k,v in pairs(log.getcmdlog()) do
			local label = cLogGui.Frame.MessageTemplate:Clone()
			label.Parent = cLogGui.Frame.Log
			label.Visible = true
			label.Text = "[".. v.timestamp .."] ".. v.speaker ..": ".. v.command
			label.Name = tostring(k)
			label.Position = UDim2.fromOffset(15,currentYOffset)
			local lines = math.ceil(string.len(label.Text)/50)
			label.Size = UDim2.new(1,0,0,lines*25)
			currentYOffset = currentYOffset+25
		end
		cLogGui.Frame.Log.CanvasSize = UDim2.fromOffset(0,currentYOffset)
		cLogGui.Enabled = true
		output[#output+1] = "Gave Command Logs to "..player.Name
		return table.concat(output,"\n")
	end,
	[[Gives the speaker a GUI that has all the sent commands since the server started.]],
	[[commandlog ]]}
	module.owner["clog"] = module.owner["commandlog"]
	
	module.owner["clearchatlogs"] = {function(player,target,params)
		local output = {}
		log.clearchatlog()
		output[#output+1] = string.char(131).."Cleared all chat logs."
		return table.concat(output,"\n")
	end,
	[[Clears the chat logs. ]],
	[[clearlogs ]]}
	module.owner["clearlogs"] = module.owner["clearchatlogs"]
	
	module.owner["clearcommandlogs"] = {function(player,target,params)
		local output = {}
		log.clearcmdlog()
		output[#output+1] = string.char(131).."Cleared all command logs."
		return table.concat(output,"\n")
	end,
	[[Clears the command logs. ]],
	[[clearlogs ]]}
	module.owner["clearclogs"] = module.owner["clearcommandlogs"]
end

do		--Admins
	module.admin["tcl"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall( function() char = v.Character end )
			if not char then char = v end
			local humanoid = char:FindFirstChild("Humanoid")
			local playerVals = v:FindFirstChild("CCACPlayerVals")
			if humanoid and playerVals then
				if not playerVals.IsNoclip.Value then
					playerVals.IsNoclip.Value = true
					for _,p in pairs(char:GetChildren()) do
						if p:IsA("BasePart") or p:IsA("MeshPart") then
							game:GetService("PhysicsService"):SetPartCollisionGroup(p,"noclip")
						end
						if p:IsA("Accessory") then --Collision groups dont wory on accessories so we have to get its children as well
							for _,h in pairs(p:GetChildren()) do
								if h:IsA("BasePart") or h:IsA("MeshPart") then
									game:GetService("PhysicsService"):SetPartCollisionGroup(h,"noclip")
								end
							end
						end
						if p:IsA("Model") then --Model check
							for _,pp in pairs(p:GetChildren()) do
								if pp:IsA("BasePart") or pp:IsA("MeshPart") then
									game:GetService("PhysicsService"):SetPartCollisionGroup(pp,"noclip")
								end
								if pp:IsA("Accessory") then --There shouldnt be any acc's in a model in the player but just in case
									for _,hh in pairs(pp:GetChildren()) do
										if hh:IsA("BasePart") or hh:IsA("MeshPart") then
											game:GetService("PhysicsService"):SetPartCollisionGroup(hh,"noclip")
										end
									end
								end
							end
						end	
					end
					local fly = bin.LocalScripts.CCNoclip:Clone()
					fly.Parent = char
				elseif playerVals.IsNoclip.Value then
					playerVals.IsNoclip.Value = false
					for _,p in pairs(char:GetChildren()) do
						if p:IsA("BasePart") or p:IsA("MeshPart") then
							game:GetService("PhysicsService"):SetPartCollisionGroup(p,"players")
						end
						if p:IsA("Accessory") then --Collision groups dont wory on accessories so we have to get its children as well
							for _,h in pairs(p:GetChildren()) do
								if h:IsA("BasePart") or h:IsA("MeshPart") then
									game:GetService("PhysicsService"):SetPartCollisionGroup(h,"players")
								end
							end
						end
						if p:IsA("Model") then --Model check
							for _,pp in pairs(p:GetChildren()) do
								if pp:IsA("BasePart") or pp:IsA("MeshPart") then
									game:GetService("PhysicsService"):SetPartCollisionGroup(pp,"players")
								end
								if pp:IsA("Accessory") then --There shouldnt be any acc's in a model in the player but just in case
									for _,hh in pairs(pp:GetChildren()) do
										if hh:IsA("BasePart") or hh:IsA("MeshPart") then
											game:GetService("PhysicsService"):SetPartCollisionGroup(hh,"players")
										end
									end
								end
							end
						end	
					end
					local fly = char:FindFirstChild("CCNoclip")
					fly:Destroy()
				else
					error("Cannot toggle clipping on a non-humanoid entity.")
				end
				output[#output+1] = "Toggled No-Clipping on ".. tostring(v) .. " => ".. tostring(playerVals.IsNoclip.Value)
			end
		end
		return table.concat(output,"\n")
	end,
	[[Toggles collision/noclip on the target.]],
	[[tcl [target] ]]}
	module.admin["togglenoclip"] = module.admin["tcl"]
	module.admin["toggleclip"] = module.admin["tcl"]
	module.admin["noclip"] = module.admin["tcl"]
	module.admin["clip"] = module.admin["tcl"]
	
	module.admin["tfc"] = {function(player,target,params)
		local output = {}
		local playerVals = player:FindFirstChild("CCACPlayerVals")
		if not playerVals then error("Target not a player.") end
		local freecam = player.Character:FindFirstChild("CCFreecam")
		if not freecam then
			playerVals.IsFreecam.Value = true
			freecam = bin.LocalScripts.CCFreecam:Clone()
			freecam.Parent = player.Character
		else
			playerVals.IsFreecam.Value = false
			freecam:Destroy()
		end
		output[#output+1] = "Toggled free camera on ".. player.Name .. " => ".. tostring(playerVals.IsFreecam.Value)
		return table.concat(output,"\n")
	end,
	[[Toggles freecam for the speaker only.]],
	[[tfc ]]}
	module.admin["togglefreecam"] = module.admin["tfc"]
	module.admin["freecam"] = module.admin["tfc"]
	
	module.admin["sucsm"] = {function(player,target,params)
		local output = {}
		local paras = vim.argsplit(params)
		local value = paras[#paras]
		if not value then value = 1 end --Set back to default speed
		if not tonumber(value) then error("Given value not a number!") end
		value = tonumber(value)
		local playerVals = player:FindFirstChild("CCACPlayerVals")
		if not playerVals then error("Target not a player.") end
		local freecam = player.Character:FindFirstChild("CCFreecam")
		if not freecam then
			error("No free camera detected.")
		else
			freecam.SpeedEvent:FireClient(player,value)
		end
		output[#output+1] = "Set free camera speed to ".. tostring(value)
		return table.concat(output,"\n")
	end,
	[[Set the speed of the freecam.]],
	[[sucsm [value] ]]}
	module.admin["camspeed"] = module.admin["sucsm"]
	module.admin["setufocamspeedmodifier"] = module.admin["sucsm"]
	
	module.admin["tgm"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall( function() char =  v.Character end)
			if not char then char = v end
			local humanoid = char:FindFirstChild("Humanoid")
			local playerVals = v:FindFirstChild("CCACPlayerVals")
			if humanoid and playerVals then 
				if not playerVals.IsGodMode.Value then
					playerVals.IsGodMode.Value = true
					humanoid.MaxHealth = "inf"
					humanoid.Health = "inf"
				elseif playerVals.IsGodMode.Value then
					playerVals.IsGodMode.Value = false
					humanoid.MaxHealth = 100
					humanoid.Health = 100
				end
			else
				error("Cannot toggle god-mode on a non-humanoid entity.")
			end
			output[#output+1] = "Toggled God-Mode on ".. tostring(v) .. " => ".. tostring(playerVals.IsGodMode.Value)
		end
		return table.concat(output,"\n")
	end,
	[[Toggles god-mode on the target.]],
	[[tgm [target] ]]}
	module.admin["togglegodmode"] = module.admin["tgm"]
	module.admin["godmode"] = module.admin["tgm"]
	module.admin["god"] = module.admin["tgm"]
	module.admin["setessential"] = module.admin["tgm"]
	
	module.admin["disable"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall( function() char =  v.Character end)
			if not char then char = v end
			if not game.Lighting:FindFirstChild("CCACDisabled") then --Checks for disabled folder; Creates one if not found
				local disFolder = Instance.new("Folder",game.Lighting)
				disFolder.Name = "CCACDisabled"
			end
			char.Humanoid:UnequipTools()
			local mute = bin.LocalScripts:FindFirstChild("CCMute"):Clone()
			mute.Parent = char
			local itemBackup = Instance.new("Folder",v)
			itemBackup.Name = "ItemBackup"
			local playerInv = v.Backpack:GetChildren()
			for _,i in pairs(playerInv) do
				i.Parent = itemBackup
			end
			char.Parent = game.Lighting:FindFirstChild("CCACDisabled")
			output[#output+1] = "Disabled ".. tostring(v)
		end
		return table.concat(output,"\n")
	end,
	[[“Disables” the player by reparenting their character to Lighting>Disabled.
]]..string.char(133)..[[Locks their Chat and Backpack Guis. Does nothing if a target is not given.]],
	[[disable [target] ]]}
	module.admin["jail"] = module.admin["disable"]
	
	module.admin["enable"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall( function() char =  v.Character end)
			if not char then char = v end
			local disFolder = game.Lighting:FindFirstChild("CCACDisabled")
			if not disFolder then error("Nothing to enable!") end
			local plr = disFolder:FindFirstChild(v.Name)
			if not disFolder:FindFirstChild(v.Name) then error("Player not disabled!") end
			char.Parent = workspace
			local mute = char:FindFirstChild("CCMute")
			mute:Destroy()
			local itemBackup = v:FindFirstChild("ItemBackup")
			for _,i in pairs(itemBackup:GetChildren()) do
				i.Parent = v.Backpack
			end
			itemBackup:Destroy()
			output[#output+1] = "Enabled ".. tostring(v)
		end
		return table.concat(output,"\n")
	end,
	[[“Enables” a disabled player by reparenting their character from Lighting>Disabled into workspace.
]]..string.char(133)..[[Also reenables their Chat and Backpack Guis. Does nothing if a target is not given, or
]]..string.char(133)..[[if the target does not exist in Lighting>Disabled.]],
	[[enable [target] ]]}
	module.admin["unjail"] = module.admin["enable"]
	
	module.admin["forceav"] = {function(player,target,params)
		local targs = vim.selectargs(player,target,params)
		local paras = vim.argsplit(params)
		local av,value = paras[#paras-1],paras[#paras]
		if (not tostring(av)) or (not tonumber(value)) then error("invalid parameters") end
		av = string.lower(av)
		if av ~= "health" and av ~= "maxhealth" and av ~= "stamina" and av ~= "maxstamina" and av ~= "magicka" and av ~= "maxmagicka" then error("actor value \""..av .. "\" does not exist" ) end
		local output = {}
		for k,v in pairs(targs) do
			local sh = v:FindFirstChild("skyHealth")
			local char = v.Character
			if not char then error(v.Name .. " has no character!") end
			if not sh then error(v.Name .. " has no skyHealth!") end
			
			if av == "health" or av == "maxhealth" then
				local hu = char.Humanoid
				if av == "health" then hu.Health = value else hu.MaxHealth = value end
			end
			
			if av == "stamina" or av == "maxstamina" then
				--local val = sh.stamina
				if av == "stamina" then sh.stamina.Value = value else sh.stamina.max.Value = value end
			end
			
			if av == "magicka" or av == "maxmagicka" then
				--local val = sh.magicka
				if av == "magicka" then sh.magicka.Value = value else sh.magicka.max.Value = value end
			end
			
			table.insert(output,string.char(136)..v.Name.."'s "..av.." has been set to "..value)
		end
		return table.concat(output,"\n")
	end,
	[[Changes the targets value to the given amount. Does nothing if no amount is given. This function does not work on NPCs]],
	[[forceav [target] [value] [amount] ]]}
	module.admin["forceactorvalue"] = module.admin["forceav"]
	module.admin["fav"] = module.admin["forceav"]
	module.admin["setav"] = module.admin["forceav"]
	
	module.admin["modav"] = {function(player,target,params)
		local targs = vim.selectargs(player,target,params)
		local paras = vim.argsplit(params)
		local av,value = paras[#paras-1],paras[#paras]
		if (not tostring(av)) or (not tonumber(value)) then error("invalid parameters") end
		av = string.lower(av)
		if av ~= "health" and av ~= "maxhealth" and av ~= "stamina" and av ~= "maxstamina" and av ~= "magicka" and av ~= "maxmagicka" then error("actor value \""..av .. "\" does not exist" ) end
		local output = {}
		for k,v in pairs(targs) do
			local sh = v:FindFirstChild("skyHealth")
			local char = v.Character
			if not char then error(v.Name .. " has no character!") end
			if not sh then error(v.Name .. " has no skyHealth!") end
			
			if av == "health" or av == "maxhealth" then
				local hu = char.Humanoid
				if av == "health" then hu.Health = hu.Health + value else hu.MaxHealth = hu.MaxHealth + value end
			end
			
			if av == "stamina" or av == "maxstamina" then
				local val = sh.stamina
				if av == "stamina" then sh.stamina.Value = sh.stamina.Value + value else sh.stamina.max.Value = sh.stamina.max.Value + value end
			end
			
			if av == "magicka" or av == "maxmagicka" then
				local val = sh.stamina
				if av == "magicka" then sh.magicka.Value = sh.magicka.Value + value else sh.magicka.max.Value = sh.magicka.max.Value + value end
			end
			
			table.insert(output,string.char(136)..v.Name.."'s "..av.." has been set to "..value)
		end
		return table.concat(output,"\n")
	end,
	[[Changes the targets value by the given amount. Does nothing if no amount is given.]],
	[[modav [target] [value] [amount] ]]}
	module.admin["modifyactorvalue"] = module.admin["modav"]
	module.admin["mav"] = module.admin["modav"]
	
	module.admin["damageactorvalue"] = {function(player,target,params)
		local targs = vim.selectargs(player,target,params)
		local paras = vim.argsplit(params)
		local av,value = paras[#paras-1],paras[#paras]
		if (not tostring(av)) or (not tonumber(value)) then error("Invalid parameters") end
		av = string.lower(av)
		if av ~= "health" and av ~= "maxhealth" and av ~= "stamina" and av ~= "maxstamina" and av ~= "magicka" and av ~= "maxmagicka" then error("actor value \""..av .. "\" does not exist" ) end
		local output = {}
		for k,v in pairs(targs) do
			local sh = v:FindFirstChild("skyHealth")
			local char = v.Character
			if not char then error(v.Name .. " has no character!") end
			if not sh then error(v.Name .. " has no skyHealth!") end
			
			if av == "health" or av == "maxhealth" then
				local hu = char.Humanoid
				if av == "health" then hu.Health = hu.Health - value else hu.MaxHealth = hu.MaxHealth - value end
			end
			
			if av == "stamina" or av == "maxstamina" then
				local val = sh.stamina
				if av == "stamina" then sh.stamina.Value = sh.stamina.Value - value else sh.stamina.max.Value = sh.stamina.max.Value - value end
			end
			
			if av == "magicka" or av == "maxmagicka" then
				local val = sh.stamina
				if av == "magicka" then sh.magicka.Value = sh.magicka.Value - value else sh.magicka.max.Value = sh.magicka.max.Value - value end
			end
			
			table.insert(output,string.char(136)..v.Name.."'s "..av.." has been set to "..value)
		end
		return table.concat(output,"\n")
	end,
	[[Damages the value by the given amount. Does nothing if no amount is given.]],
	[[damageactorvalue [target] [value] [amount] ]]}
	module.admin["damagevalue"] = module.admin["damageactorvalue"]
	module.admin["restoreactorvalue"] = module.admin["damageactorvalue"]
	module.admin["dav"] = module.admin["damageactorvalue"]
	module.admin["rav"] = module.admin["damageactorvalue"]

	module.admin["kill"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall( function() char =  v.Character end)
			if not char then char = v end
			local humanoid = char:FindFirstChild("Humanoid")
			if humanoid then humanoid.Health = 0 else error("Cannot kill a non entity") end
			output[#output+1] = "Killed ".. tostring(v)
		end
		return table.concat(output,"\n")
	end,
	[[Kills the target.]],
	[[kill [target] ]]}
	module.admin["oof"] = module.admin["kill"]
	
	module.admin["setghost"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		local amount = tonumber(para[#para])
		for k,v in pairs(args) do
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			if amount == 1 then
				local bodycolsbackup = char:FindFirstChild("Body Colors"):Clone() --backup the players body cols for later
				bodycolsbackup.Parent = v
				local blue = Color3.fromRGB(51, 150, 236)
				local bodycols = char:FindFirstChild("Body Colors")
				bodycols:remove()
				--bodycols.HeadColor3,bodycols.LeftArmColor3,bodycols.LeftLegColor3,bodycols.RightArmColor3,bodycols.RightLegColor3,bodycols.TorsoColor3 = blue,blue,blue,blue,blue,blue
				--print(bodycols.HeadColor3 == blue)
				for _,p in pairs(char:GetChildren()) do
					if p:IsA("BasePart") or p:IsA("MeshPart") then
						game:GetService("PhysicsService"):SetPartCollisionGroup(p, "ghosts")
						p.Material = Enum.Material.ForceField
						p.Color = blue
					end
					if p:IsA("Accessory") then --collision groups dont work on accessories, so we gotta do something else
						for _,h in pairs(p:GetChildren()) do
							if h:IsA("BasePart") or h:IsA("MeshPart") then
								game:GetService("PhysicsService"):SetPartCollisionGroup(h, "ghosts")
								h.Material = Enum.Material.ForceField
								h.Color = blue
							end
						end
					end
					if p:IsA("Model") then
						for _,pp in pairs(p:GetChildren()) do
							if pp:IsA("BasePart") or pp:IsA("MeshPart") then
								game:GetService("PhysicsService"):SetPartCollisionGroup(pp, "ghosts")
								pp.Material = Enum.Material.ForceField
								pp.Color = blue
							end
							if pp:IsA("Accessory") then --there shouldnt be accessories in a model in the player, but just in case
								for _,hh in pairs(pp:GetChildren()) do
									if hh:IsA("BasePart") or h:IsA("MeshPart") then
										game:GetService("PhysicsService"):SetPartCollisionGroup(hh, "ghosts")
										hh.Material = Enum.Material.ForceField
										hh.Color = blue
									end
								end
							end
						end
					end
				end
				output[#output+1] = "Set ".. tostring(v) .." as ghost."
			elseif amount == 0 then
				--local bodycols = char:FindFirstChild("Body Colors")
				local bcBack = v:FindFirstChild("Body Colors")
				if not bcBack then error("No 'Body Colors' backup found in player; May not be currently ghosted.") end
				bcBack.Parent = char
				--bodycols.HeadColor3,bodycols.LeftArmColor3,bodycols.LeftLegColor3,bodycols.RightArmColor3,bodycols.RightLegColor3,bodycols.TorsoColor3 = bcBack.HeadColor3,bcBack.LeftArmColor3,bcBack.LeftLegColor3,bcBack.RightArmColor3,bcBack.RightLegColor3,bcBack.TorsoColor3
				for _,p in pairs(char:GetChildren()) do
					if p:IsA("BasePart") or p:IsA("MeshPart") then
						game:GetService("PhysicsService"):SetPartCollisionGroup(p, "players")
						p.Material = Enum.Material.Plastic
					end
					if p:IsA("Accessory") then
						for _,h in pairs(p:GetChildren()) do
							if h:IsA("BasePart") or h:IsA("MeshPart") then
								game:GetService("PhysicsService"):SetPartCollisionGroup(h, "players")
								h.Material = Enum.Material.Plastic
							end
						end
					end
					if p:IsA("Model") then
						for _,pp in pairs(p:GetChildren()) do
							if pp:IsA("BasePart") or pp:IsA("MeshPart") then
								game:GetService("PhysicsService"):SetPartCollisionGroup(pp, "players")
								pp.Material = Enum.Material.Plastic
							end
							if pp:IsA("Accessory") then
								for _,h in pairs(pp:GetChildren()) do
									if h:IsA("BasePart") or h:IsA("MeshPart") then
										game:GetService("PhysicsService"):SetPartCollisionGroup(h, "players")
										h.Material = Enum.Material.Plastic
									end
								end
							end
						end
					end
					bcBack:Destroy()
					if v:FindFirstChild("ACCAccStorage") then v.ACCAccStorage:Destroy() end
				end
				output[#output+1] = "Returned ".. tostring(v) .." to normal."
			else error("Final argument must be 0 or 1!") end
		end
		return table.concat(output,"\n")
	end,
	[[Makes the target either tangible or intangible, by setting their collisions, and
]]..string.char(133)..[[changing their basepart types to ‘Forcefield’. Amount ranges from 0-1;
]]..string.char(133)..[[0 Makes them tangible, 1 makes them intangible.]],
	[[setghost [target] [0-1] ]]}
	
	module.admin["coc"] = {function(player,target,params) --TODO: hook in future cart network to allow for name usage (ex: coc all whiterun)
		local output = {}
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		local targPlace = tonumber(para[#para])
		local targName = game:GetService("MarketplaceService"):GetProductInfo(targPlace).Name
		for k,v in pairs(args) do
			pcall(function()
				game:GetService("TeleportService"):Teleport(targPlace,v)
				output[#output+1] = "Sending ".. tostring(v) .." to: "..targName.." (".. tostring(targPlace) ..")"
			end)
		end
		return table.concat(output,"\n")
	end,
	[[Teleports the target to a place connected inside the cart network,
]]..string.char(133)..[[with the place name acting as the value.]],
	[[coc [target] [value] ]]}
	module.admin["centeroncell"] = module.admin["coc"]
	module.admin["tpplace"] = module.admin["coc"]
	
	module.admin["mod"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot mod a non-player!") end
			local lists = trello:GetLists(tBoardId)
			for q,e in next,lists do
				if lists[q] ~= nil then
					if lists[q]["name"] == "Mod List" then
						local cards = trello:GetCardsInList(lists[q]["id"])
						local pattern = "(%w+):?(%d+)"
						for _,c in next,cards do --Precheck to see if user is already admin
							local n,i = c["name"]:match(pattern)
							if v.Name == tostring(n) or v.UserId == tonumber(i) or lib.isInList(v.UserId,adminList.mods) then
								error(v.Name.." is already a mod!")
							end
						end
						if not lib.isInList(v.UserId,adminList.mods) then
							trello:AddCard((v.Name..":"..v.UserId),"",trello:GetListID("Mod List",tBoardId))
							table.insert(adminList.mods,tostring(v.UserId))
							output[#output+1] = "Gave permanent mod to ".. v.Name
						end
					end
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Gives the target permanent mod.]],
	[[mod [target] ]]}
	
	module.admin["tempmod"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot mod a non-player!") end
			if not lib.isInList(v.UserId,adminList.mods) then
				table.insert(adminList.mods,tostring(v.UserId))
				output[#output+1] = "Gave temporary mod to ".. v.Name
			end
		end
		return table.concat(output,"\n")
	end,
	[[Gives the target temporary mod (Lasts as long as the current server is alive).]],
	[[tempmod [target] ]]}
	module.admin["tmod"] = module.admin["tempmod"]
	
	module.admin["rmod"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot remove mod from a non-player!") end
			local index = lib.isInList(v.UserId,adminList.mods)
			if index then
				table.remove(adminList.mods,index)
			end
			local lists = trello:GetLists(tBoardId)
			for q,e in next,lists do
				if lists[q] ~= nil then
					if lists[q]["name"] == "Delete Queue" then
						local cards = trello:GetCardsInList(lists[q]["id"])
						local pattern = "(%w+):?(%d+)"
						for _,c in next,cards do --Precheck to see if user is already admin
							local n,i = c["name"]:match(pattern)
							if v.Name == tostring(n) or v.UserId == tonumber(i) or lib.isInList(v.UserId,adminList.delQ) then
								error(v.Name.." is already queued for deletion!")
							end
						end
						if not lib.isInList(v.UserId,adminList.mods) then
							trello:AddCard((v.Name..":"..v.UserId),"",trello:GetListID("Delete Queue",tBoardId))
							table.insert(adminList.delQ,tostring(v.UserId))
							output[#output+1] = "Removed mod from ".. v.Name
							output[#output+1] = string.char(131).."Remember to update the cards in Trello!"
						end
					end
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Removes mod from the target if they already have it.]],
	[[rmod [target] ]]}
	module.admin["removemod"] = module.admin["rmod"]
	module.admin["unmod"] = module.admin["rmod"]
	
	module.admin["ban"] = {function(player,target,params)
		local reason = [[You have been banned from this game.
Reason: Inappropriate behavior.]]
		local output = {}
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		if para[#para] ~= nil then
			reason = [[You have been banned from this game.
Reason: ]].. tostring(table.concat(para, " "))
		end
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot ban a non-player!") end
			local lists = trello:GetLists(tBoardId)
			for q,e in next,lists do
				if lists[q] ~= nil then
					if lists[q]["name"] == "Ban List" then
						if not lib.isInList(v.UserId,adminList.banned) then
							trello:AddCard((v.Name..":"..v.UserId),"Banned by: "..player.Name.."\nReason: "..tostring(table.concat(para, " ")),trello:GetListID("Ban List",tBoardId))
							table.insert(adminList.banned,tostring(v.UserId))
							v:Kick(reason)
							if para[#para] ~= nil then
								output[#output+1] = "Banned ".. v.Name .. ", Reason: ".. tostring(table.concat(para, " "))
							else
								output[#output+1] = "Banned ".. v.Name .. ", Reason: Inappropriate behavior"
							end
						end
					end
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Permanently bans the target from all genre places that run Console Commands.]],
	[[ban [target] [reason] ]]}
	
	module.admin["tempban"] = {function(player,target,params)
		local reason = [[You have been temporarily banned from this game.
Reason: Inappropriate behavior.]]
		local output = {}
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		if para[#para] ~= nil then
			reason = [[You have been temporarily banned from this game.
Reason: ]].. tostring(table.concat(para, " "))
		end
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot ban a non-player!") end
			if not lib.isInList(v.UserId,adminList.banned) then
				table.insert(adminList.banned,tostring(v.UserId))
				v:Kick(reason)
				if para[#para] ~= nil then
					output[#output+1] = "Temporarily banned ".. v.Name .. ", Reason: ".. tostring(table.concat(para, " "))
				else
					output[#output+1] = "Temporarily banned ".. v.Name .. ", Reason: Inappropriate behavior"
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Temporarily bans the target from the current place, in that server, until the server is shutdown.]],
	[[tempban [target] [reason] ]]}
	module.admin["tban"] = module.admin["tempban"]
	
	module.admin["tff"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall( function() char =  v.Character end)
			if not char then char = v end
			if not char:FindFirstChild("ForceField") then
				local ff = Instance.new("ForceField",char)
				ff.Visible = true
				output[#output+1] = "Gave ForceField to ".. tostring(v)
			else
				local ff = char:FindFirstChild("ForceField")
				ff:Destroy()
				output[#output+1] = "Removed ForceField from ".. tostring(v)
			end
		end
		return table.concat(output,"\n")
	end,
	[[Toggles a classic forcefield on/off on the target. Defaults to speaker if no target is given.]],
	[[tff [target] ]]}
	module.admin["toggleforcefield"] = module.admin["tff"]
	module.admin["forcefield"] = module.admin["tff"]
	
	module.admin["cwp"] = {function(player,target,params)
		local name = nil
		local output = {}
		local args = vim.selectargs(player,target,params)
		if #args > 1 then error("Can only make one waypoint at a time; Select less targets!") end
		local para = vim.argsplit(params)
		if para[#para] ~= nil then
			name = tostring(table.concat(para, " "))
		else
			error("Waypoint needs a name!")
		end
		for k,v in pairs(args) do
			local waypoints = workspace:FindFirstChild("CCWaypoints")
			if not waypoints then
				waypoints = Instance.new("Folder",workspace)
				waypoints.Name = "CCWaypoints"
			end
			for _,v in pairs(waypoints:GetChildren()) do
				if string.lower(v.Name) == string.lower(name) then
					error("Waypoint needs a unique name!")
				end
			end
			local wp = v.Character:FindFirstChild("HumanoidRootPart"):Clone()
			wp.Name = name:lower(); wp.Parent = waypoints; wp:ClearAllChildren(); wp.CanCollide = false; wp.Anchored = true
			output[#output+1] = "Created waypoint \"".. wp.Name .. "\", Coords: ".. tostring(wp.Position)
		end
		return table.concat(output,"\n")
	end,
	[[Creates a waypoint with the name argument at the speakers current location.]],
	[[cwp [name] ]]}
	module.admin["createwaypoint"] = module.admin["cwp"]
	module.admin["wpt"] = module.admin["cwp"]
	
	module.admin["rwp"] = {function(player,target,params)
		local name = nil
		local output = {}
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		if para[#para] ~= nil then
			name = tostring(table.concat(para, " "))
		else
			error("Argument 'name' missing!")
		end
		local hasRemoved = false
		for k,v in pairs(args) do
			local waypoints = workspace:FindFirstChild("CCWaypoints")
			if not waypoints then error("No waypoints to remove!") end
			for _,w in pairs(waypoints:GetChildren()) do
				if string.lower(w.Name) == string.lower(name) then
					hasRemoved = true
					output[#output+1] = "Removed waypoint \"".. w.Name .. "\", Coords: ".. tostring(w.Position)
					w:Destroy()
				end
			end
		end
		if hasRemoved == false then error("No waypoint with that name!") end
		return table.concat(output,"\n")
	end,
	[[Removes the waypoint with the given name, if it exists.]],
	[[rwp [name] ]]}
	module.admin["removewaypoint"] = module.admin["rwp"]
	
	module.admin["wpl"] = {function(player,target,params)
		local output = {}
		local waypoints = workspace:FindFirstChild("CCWaypoints")
		if not waypoints then error("No waypoints to list!") end
		for _,w in pairs(waypoints:GetChildren()) do
			output[#output+1] = "Waypoint \"".. w.Name .. "\", Coords: ".. tostring(w.Position)
		end
		return table.concat(output,"\n")
	end,
	[[Prints out a list of all the waypoints into the output console.]],
	[[wpl ]]}
	module.admin["waypointlist"] = module.admin["wpl"]
	module.admin["waypoints"] = module.admin["wpl"]
	
	module.admin["name"] = {function(player,target,params)
		return "TODO"
	end,
	[[Gives the target a fake nameplate with the name being the given value.]],
	[[name [target] [value] ]]}
	module.admin["fakename"] = module.admin["name"]
	
	module.admin["rname"] = {function(player,target,params)
		return "TODO"
	end,
	[[Removes the fake nameplate from the target if it exists.]],
	[[rname [target] ]]}
	module.admin["removename"] = module.admin["rname"]
	module.admin["removefakename"] = module.admin["rname"]
	
	module.admin["music"] = {function(player,target,params)
		local output = {}
		
		--Find SkyMusic on speaker
		if player.PlayerGui:FindFirstChild("SkyMusic") then --If skymusic is found, pause for all clients
			output[#output+1] = string.char(131).."Detected SkyMusic; Pausing for all clients."
			for _,v in pairs(game.Players:GetPlayers()) do
				v.PlayerGui:FindFirstChild("SkyMusic").Pause:FireClient(v,true)
			end
			output[#output+1] = string.char(129).."SkyMusic paused on all clients."
		end
		
		local musicList = {}
		local idList = {}
		local para = vim.argsplit(params)
		local desiredTrack = 0
		if para[#para] ~= nil then
			desiredTrack = tostring(table.concat(para, " "))
		else
			error("Argument 'ID or Name' missing!")
		end
		local idCheck = desiredTrack:match("^[+-]?%d+$")
		
		if idCheck ~= nil then
			local targSound = idCheck
			local music = game.Workspace:FindFirstChild("CCACMusic")
			if not music then
				music = Instance.new("Sound",game.Workspace)
				music.Name = "CCACMusic"
				music.Looped = true
				music.SoundId = "rbxassetid://"..targSound
				music:Play()
			else
				music:Stop()
				music.Looped = true
				music.SoundId = "rbxassetid://"..targSound
				music:Play()
			end
			output[#output+1] = "Playing new music: ".. tostring(desiredTrack)
		else
			local lists = trello:GetLists(tBoardId) --Get the board
			for q,e in next,lists do
				if lists[q] ~= nil then
					if lists[q]["name"] == "Music List" then
						local cards = trello:GetCardsInList(lists[q]["id"])
						local pattern = "(.+%p):?(%d+)"
						for _,c in next,cards do
							local n,i = c["name"]:match(pattern)
							n = string.sub(n,1,string.len(n)-1)
							n = string.gsub(n,"%s"," ")
							table.insert(musicList,string.lower(n))
							table.insert(idList,i)
						end
					end
				end
			end
			for k,v in pairs(musicList) do
				if (string.lower(desiredTrack) == tostring(musicList[k])) then
					local music = game.Workspace:FindFirstChild("CCACMusic")
					if not music then
						music = Instance.new("Sound",game.Workspace)
						music.Name = "CCACMusic"
						music.Looped = true
						music.SoundId = "rbxassetid://"..idList[k]
						music:Play()
					else
						music:Stop()
						music.Looped = true
						music.SoundId = "rbxassetid://"..idList[k]
						music:Play()
					end
					output[#output+1] = "Playing new music: ".. tostring(desiredTrack) .." (".. tostring(idList[k]) ..")"
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Starts playing the music with the given ID, or name (from Trello) on loop.
]]..string.char(133)..[[Should pause SkyMusic entirely until stopped.]],
	[[music [ID or name] ]]}
	
	module.admin["sound"] = {function(player,target,params)
		local output = {}
		
		--Find SkyMusic on speaker
		if player.PlayerGui:FindFirstChild("SkyMusic") then --If skymusic is found, pause for all clients
			output[#output+1] = string.char(131).."Detected SkyMusic; Pausing for all clients."
			for _,v in pairs(game.Players:GetPlayers()) do
				v.PlayerGui:FindFirstChild("SkyMusic").Pause:FireClient(v,true)
			end
			output[#output+1] = string.char(129).."SkyMusic paused on all clients."
		end
		
		local musicList = {}
		local idList = {}
		local para = vim.argsplit(params)
		local desiredTrack = 0
		if para[#para] ~= nil then
			desiredTrack = tostring(table.concat(para, " "))
		else
			error("Argument 'ID or Name' missing!")
		end
		local idCheck = desiredTrack:match("^[+-]?%d+$")
		
		if idCheck ~= nil then
			local targSound = idCheck
			local music = game.Workspace:FindFirstChild("CCACMusic")
			if not music then
				music = Instance.new("Sound",game.Workspace)
				music.Name = "CCACMusic"
				music.Looped = false
				music.SoundId = "rbxassetid://"..targSound
				music:Play()
			else
				music:Stop()
				music.Looped = false
				music.SoundId = "rbxassetid://"..targSound
				music:Play()
			end
			output[#output+1] = "Playing new music: ".. tostring(desiredTrack)
		else
			local lists = trello:GetLists(tBoardId) --Get the board
			for q,e in next,lists do
				if lists[q] ~= nil then
					if lists[q]["name"] == "Music List" then
						local cards = trello:GetCardsInList(lists[q]["id"])
						local pattern = "(.+%p):?(%d+)"
						for _,c in next,cards do
							local n,i = c["name"]:match(pattern)
							n = string.sub(n,1,string.len(n)-1)
							n = string.gsub(n,"%s"," ")
							table.insert(musicList,string.lower(n))
							table.insert(idList,i)
						end
					end
				end
			end
			for k,v in pairs(musicList) do
				if (string.lower(desiredTrack) == tostring(musicList[k])) then
					local music = game.Workspace:FindFirstChild("CCACMusic")
					if not music then
						music = Instance.new("Sound",game.Workspace)
						music.Name = "CCACMusic"
						music.Looped = false
						music.SoundId = "rbxassetid://"..idList[k]
						music:Play()
					else
						music:Stop()
						music.Looped = false
						music.SoundId = "rbxassetid://"..idList[k]
						music:Play()
					end
					output[#output+1] = "Playing new music: ".. tostring(desiredTrack) .." (".. tostring(idList[k]) ..")"
				end
			end
		end
		coroutine.wrap(function()
			wait()
			local music = game.Workspace:FindFirstChild("CCACMusic")
			if music then
				wait(music.TimeLength)
				music:Destroy()
				if player.PlayerGui:FindFirstChild("SkyMusic") then --If skymusic is found, pause for all clients
					output[#output+1] = string.char(131).."Detected SkyMusic; Resuming for all clients."
					for _,v in pairs(game.Players:GetPlayers()) do
						v.PlayerGui:FindFirstChild("SkyMusic").Pause:FireClient(v,false)
					end
					output[#output+1] = string.char(129).."SkyMusic resumed on all clients."
				end
			end
		end)()
		return table.concat(output,"\n")
	end,
	[[Starts playing the sound with the given ID, or name (from Trello) once.
]]..string.char(133)..[[Should pause SkyMusic entirely until done.]],
	[[sound [ID or name] ]]}
	
	module.admin["pitch"] = {function(player,target,params)
		local output = {}
		local para = vim.argsplit(params)
		local targPitch = para[#para]
		if not string.match(targPitch,"%d+") then warn("Argument 'number' missing or Not A Number; Assuming 1");targPitch=1 end
		local music = game.Workspace:FindFirstChild("CCACMusic")
		if music then
			local EQ = music:FindFirstChild("peq")
			if not EQ then
				EQ = Instance.new("PitchShiftSoundEffect",music)
				EQ.Name = "peq"
				EQ.Octave = targPitch
			else
				EQ.Octave = targPitch
			end
			output[#output+1] = "Changed pitch of current sound to ".. tostring(targPitch) .."."
		end
		return table.concat(output,"\n")
	end,
	[[Changes the pitch of the current sound to the given number.
]]..string.char(133)..[[Defaults to 1 if no number is given.]],
	[[pitch [number] ]]}
	
	module.admin["playbackspeed"] = {function(player,target,params)
		local output = {}
		local para = vim.argsplit(params)
		local targSpeed = para[#para]
		if not string.match(targSpeed,"%d+") then warn("Argument 'number' missing or Not A Number; Assuming 1");targSpeed=1 end
		local music = game.Workspace:FindFirstChild("CCACMusic")
		if music then
			music.PlaybackSpeed = targSpeed
			output[#output+1] = "Changed PlaybackSpeed of current sound to ".. tostring(targSpeed) .."."
		end
		return table.concat(output,"\n")
	end,
	[[Changes the speed of the currently playing sound to the given number.
]]..string.char(133)..[[Defaults to 1 if no number is given.]],
	[[playbackspeed [number] ]]}
	module.admin["pbspeed"] = module.admin["playbackspeed"]
	module.admin["musicspeed"] = module.admin["playbackspeed"]
	module.admin["mspeed"] = module.admin["playbackspeed"]
	
	module.admin["vol"] = {function(player,target,params)
		local output = {}
		local para = vim.argsplit(params)
		local targVol = para[#para]
		if not string.match(targVol,"%d+") then warn("Argument 'number' missing or Not A Number; Assuming 1");targVol=1 end
		local music = game.Workspace:FindFirstChild("CCACMusic")
		if music then
			music.Volume = targVol
			output[#output+1] = "Changed Volume of current sound to ".. tostring(targVol) .."."
		end
		return table.concat(output,"\n")
	end,
	[[Changes the volume of the currently playing sound to the given number.
]]..string.char(133)..[[Defaults to 1 if no number is given.]],
	[[vol [number] ]]}
	module.admin["volume"] = module.admin["vol"]
	module.admin["loudness"] = module.admin["vol"]
	
	module.admin["eq"] = {function(player,target,params)
		local output = {}
		local para = vim.argsplit(params)
		local targBass = para[#para-2]
		local targMid = para[#para-1]
		local targTreb = para[#para]
		if not string.match(targBass,"%d+") then warn("Argument 'bass' missing or Not A Number; Assuming 1");targBass=1 end
		if not string.match(targMid,"%d+") then warn("Argument 'mid' missing or Not A Number; Assuming 1");targMid=1 end
		if not string.match(targTreb,"%d+") then warn("Argument 'treb' missing or Not A Number; Assuming 1");targTreb=1 end
		local music = game.Workspace:FindFirstChild("CCACMusic")
		if music then
			local EQ = music:FindFirstChild("eq")
			if not EQ then
				EQ = Instance.new("EqualizerSoundEffect",music)
				EQ.Name = "eq"
				EQ.LowGain = targBass
				EQ.MidGain = targMid
				EQ.HighGain = targTreb
			else
				EQ.LowGain = targBass
				EQ.MidGain = targMid
				EQ.HighGain = targTreb
			end
			output[#output+1] = "Changed EQ of current sound to ".. tostring(targBass) ..",".. tostring(targMid) ..",".. tostring(targTreb)
		end
		return table.concat(output,"\n")
	end,
	[[Changes the EQ of the currently playing sound to the given values.
]]..string.char(133)..[[All values default to 1 if omitted.]],
	[[eq [bass][mid][treble] ]]}
	module.admin["equalizer"] = module.admin["eq"]
	
	module.admin["stopmusic"] = {function(player,target,params)
		local output = {}
		local hasMusic = false
		local music = game.Workspace:FindFirstChild("CCACMusic")
		if music then
			music:Destroy()
			output[#output+1] = "Stopped music."
			hasMusic = true
		else
			output[#output+1] = string.char(130).."No music is currently playing."
		end
		--Find SkyMusic on speaker
		if hasMusic then
			if player.PlayerGui:FindFirstChild("SkyMusic") then --If skymusic is found, pause for all clients
				output[#output+1] = string.char(131).."Detected SkyMusic; Resuming for all clients."
				for _,v in pairs(game.Players:GetPlayers()) do
					v.PlayerGui:FindFirstChild("SkyMusic").Pause:FireClient(v,false)
				end
				output[#output+1] = string.char(129).."SkyMusic resumed on all clients."
			end
		end
		return table.concat(output,"\n")
	end,
	[[Stops the currently playing sound.]],
	[[stopmusic ]]}
	
	module.admin["summon"] = {function(player,target,params)
		local output = {}
		local summonables = bin.Summons
		if #summonables:GetChildren() == 0 then error("No objects available to summon!") end
		local summonHolder = workspace:FindFirstChild("CCACSummons")
		if not summonHolder then
			summonHolder = Instance.new("Folder",workspace)
			summonHolder.Name = "CCACSummons"
		end
		local para = vim.argsplit(params)
		local pattern = "(%a+)#(%d+)"
		for k,v in pairs(para) do
			local targ,amt = string.match(v,pattern)
			if not targ then targ = v; amt = 1 end --catch if no # is given
			local targSummon = summonables:FindFirstChild(string.lower(tostring(targ)))
			if not targSummon then error("Target not a summonable object.") end
			local AddedOffset = 0	
			for i=1,amt do
				local m = targSummon:Clone()
				local offset = m._SummonOffset.Value
				m.Parent = summonHolder
				m:MakeJoints()
				local cf = CFrame.new(offset.X,offset.Y,offset.Z+AddedOffset)
				m:SetPrimaryPartCFrame(player.Character.HumanoidRootPart.CFrame:toWorldSpace(cf))
				m:MakeJoints()
				AddedOffset = AddedOffset+targSummon._AddedOffset.Value
				wait()
			end
			if tonumber(amt)>1 then output[#output+1] = "Summoned ".. tostring(amt) .." ".. targ .."s." else output[#output+1] = "Summoned ".. targ .."." end 
		end
		return table.concat(output,"\n")
	end,
	[[Summons the target object in front of the speaker.]],
	[[summon [object] ]]}
	
	module.admin["summonlist"] = {function(player,target,params)
		local output = {}
		local summonables = bin.Summons
		if #summonables:GetChildren() == 0 then error("No objects available to summon!") end
		for k,v in pairs(summonables:GetChildren()) do
			output[#output+1] = v.Name..", Type: "..v.ClassName 
		end
		return table.concat(output,"\n")
	end,
	[[Outputs a list of all summonable objects to the output console.]],
	[[summonlist ]]}
	module.admin["summonables"] = module.admin["summonlist"]
	module.admin["slist"] = module.admin["summonlist"]
	
	module.admin["clone"] = {function(player,target,params)
		local output = {}
		local cloneHolder = workspace:FindFirstChild("CCACClones")
		if not cloneHolder then
			cloneHolder = Instance.new("Folder",workspace)
			cloneHolder.Name = "CCACClones"
		end
		local para = vim.argsplit(params)
		local targAmt = para[#para]
		if not string.match(targAmt,"%d+") then warn("Argument 'number' missing or Not A Number; Assuming 1");targAmt=1 end
		local offset = -2
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			for i=1,tonumber(targAmt) do
				local char = nil; pcall(function() char = v.Character end)
				if not char then char = v end
				if not char:FindFirstChild("Humanoid") then error("Cannot clone a non-humanoid object.") end --catch for non-NPCs & non-Players
				char.Archivable = true
				local d = char:Clone()
				d.Parent = cloneHolder
				local cf = CFrame.new(Vector3.new(0,0,offset),Vector3.new(0,0,0))
				d.HumanoidRootPart.CFrame = char.HumanoidRootPart.CFrame:toWorldSpace(cf)
				d.HumanoidRootPart:MakeJoints()
				char.Archivable = false
				offset = offset-2 --Funny results if the player makes a large amount of clones and starts to turn/spin
				wait()
			end
			if tonumber(targAmt)>1 then output[#output+1] = "Made ".. targAmt .." clones of ".. v.Name.. "." else output[#output+1] = "Cloned ".. v.Name .."." end
		end
		return table.concat(output,"\n")
	end,
	[[Creates the given number of clones of the target. Target defaults to speaker if
]]..string.char(133)..[[omitted, number defaults to 1 if omitted.]],
	[[clone [target] [number] ]]}
	module.admin["dummy"] = module.admin["clone"]
	
	module.admin["freeze"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot freeze a non-player!") end
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			char.Humanoid.PlatformStand = true
			for _,p in pairs(char:GetChildren()) do
				if p:IsA("BasePart") then p.Anchored = true end
			end
			char.Humanoid:UnequipTools() --Force player to unequip tools
			local itemBackup = Instance.new("Folder")
			itemBackup.Name = "ItemBackup"
			itemBackup.Parent = v
			local playerItems = v.Backpack:GetChildren()
			for _,i in pairs(playerItems) do i.Parent = itemBackup end
			output[#output+1] = "Froze "..v.Name
		end
		return table.concat(output,"\n")
	end,
	[[Freezes the target and removes their items (Does not delete items).]],
	[[freeze [target] ]]}
	module.admin["halt"] = module.admin["freeze"]
	
	module.admin["unfreeze"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot unfreeze a non-player!") end
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			char.Humanoid.PlatformStand = false
			for _,p in pairs(char:GetChildren()) do
				if p:IsA("BasePart") then p.Anchored = false end
			end
			local itemBackup = v:FindFirstChild("ItemBackup")
			local playerItems = itemBackup:GetChildren()
			for _,i in pairs(playerItems) do i.Parent = v.Backpack end
			output[#output+1] = "Unfroze "..v.Name
		end
		return table.concat(output,"\n")
	end,
	[[Unfreezes the target and restores their items, if they were frozen.]],
	[[unfreeze [target] ]]}
	module.admin["release"] = module.admin["unfreeze"]
	module.admin["thaw"] = module.admin["unfreeze"]
	
	module.admin["view"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		if #args>1 then error("Can only view a single target.") end --dunno if this works
		local targ = nil
		for k,v in pairs(args) do
			targ = v
		end
		local view = player.Character:FindFirstChild("CCView")
		if not view then
			view = bin.LocalScripts.CCView:Clone()
			view.Parent = player.Character
			view.ViewEvent:FireClient(player,targ)
			view.LastTarget.Value = targ
			output[#output+1] = "Changed camera target to view ".. tostring(targ)
		elseif (targ ~= view.LastTarget.Value and targ ~= player) then 
			view.ViewEvent:FireClient(player,targ)
			view.LastTarget.Value = targ
			output[#output+1] = "Changed camera target to view ".. tostring(targ)
		else 
			view:Destroy() 
			output[#output+1] = "Returned camera target to ".. player.Name
		end
		return table.concat(output,"\n")
	end,
	[[Changes the speakers camera to follow the target. Target defaults to speaker if
]]..string.char(133)..[[omitted, thus resetting the players camera.]],
	[[view [target] ]]}
	module.admin["unview"] = module.admin["view"]
	
	module.admin["f3x"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot give F3X to a non-player!") end
			local tool = bin.Tools:FindFirstChild("F3X")
			if tool then tool = tool:Clone(); tool.Parent = v.Backpack else error("F3X tool not found!") end
			output[#output+1] = "Gave F3X to "..v.Name
		end
		return table.concat(output,"\n")
	end,
	[[Gives the target F3X building tools.]],
	[[f3x [target] ]]}
	module.admin["btools"] = module.admin["f3x"]
	module.admin["buildtools"] = module.admin["f3x"]
	
	module.admin["chatlog"] = {function(player,target,params)
		local output = {}
		local logGui = player.PlayerGui:FindFirstChild("ChatLog") --bin.ChatLog:Clone()
		if not logGui then
			logGui = bin.ChatLog:Clone()
			logGui.Parent = player.PlayerGui
		else
			error("Chat log already open.")
		end
		local currentYOffset = 0
		for k,v in pairs(log.getchatlog()) do
			local label = logGui.Frame.MessageTemplate:Clone()
			label.Parent = logGui.Frame.Log
			label.Visible = true
			label.Text = "[".. v.timestamp .."] ".. v.speaker ..": ".. v.message
			label.Name = tostring(k)
			label.Position = UDim2.fromOffset(15,currentYOffset)
			local lines = math.ceil(string.len(label.Text)/50)
			label.Size = UDim2.new(1,0,0,lines*25)-- UDim2.fromOffset(15,lines*25)
			currentYOffset = currentYOffset+(lines*25)
		end
		logGui.Frame.Log.CanvasSize = UDim2.fromOffset(0,currentYOffset)
		logGui.Enabled = true
		output[#output+1] = "Gave Chat Logs to "..player.Name
		return table.concat(output,"\n")
	end,
	[[Gives the speaker a GUI that has all the chats that have been sent since the server started.]],
	[[chatlog ]]}
	module.admin["log"] = module.admin["chatlog"]
end

do		--Mods
	module.mods["additem"] = {function(player,target,params)
		return "TODO"
	end,
	[[Adds the amount of the selected item to the target. Target defaults to speaker;
]]..string.char(133)..[[Amount  defaults to 1 if omitted.]],
	[[additem [target] [item] [amount] ]]}
	module.mods["giveitem"] = module.mods["additem"]
	module.mods["grant"] = module.mods["additem"]
	
	module.mods["removeitem"] = {function(player,target,params)
		return "TODO"
	end,
	[[Removes the amount of the selected item to the target. Target defaults to speaker;
]]..string.char(133)..[[Amount  defaults to 1 if omitted.]],
	[[additem [target] [item] [amount] ]]}
	module.mods["remove"] = module.mods["removeitem"]
	module.mods["take"] = module.mods["removeitem"]
	
	module.mods["viewinventory"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			output[#output+1] = string.char(135).."Current Target: ".. v.Name
			pcall(function() if v.Parent ~= game.Players then error("Cannot view inventory on non-player.") end end)
			for pos,i in pairs(v.Backpack:GetChildren()) do
				output[#output+1] = "Slot ".. tostring(pos)..": ".. tostring(i)
			end
			output[#output+1] = "\n" --blank line to split targets more clearly
		end
		return table.concat(output,"\n")
	end,
	[[Views the selected targets inventory.]],
	[[viewinventory [target] ]]}
	module.mods["vinv"] = module.mods["viewinventory"]
	module.mods["veiwbackpack"] = module.mods["viewinventory"] 
	
	module.mods["addgold"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		local amount = 1
		local para = vim.argsplit(params)
		if para[#para] ~= nil then amount = para[#para] end
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot add gold to a non-player!") end
			local skydata = v:FindFirstChild("skyData")
			if not skydata then error("SkyData not found!") end
			skydata.gold.Value = skydata.gold.Value + amount
			output[#output+1] = string.char(132).."Added "..amount.." gold to "..v.Name
		end
		return table.concat(output,"\n")
	end,
	[[Adds the amount of gold to the target. Target defaults to speaker;
]]..string.char(133)..[[Amount defaults to 1 if omitted.]],
	[[addgold [target] [amount] ]]}
	module.mods["money"] = module.mods["addgold"]
	module.mods["gold"] = module.mods["addgold"]
	
	module.mods["removegold"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		local amount = 1
		local para = vim.argsplit(params)
		if para[#para] ~= nil then amount = para[#para] end
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot remove gold from a non-player!") end
			local skydata = v:FindFirstChild("skyData")
			if not skydata then error("SkyData not found!") end
			skydata.gold.Value = skydata.gold.Value - amount
			output[#output+1] = string.char(132).."Removed "..amount.." gold from "..v.Name
		end
		return table.concat(output,"\n")
	end,
	[[Removes the amount of gold from the target. Defaults to the targets
]]..string.char(133)..[[gold amount if omitted (thus removing all of it).]],
	[[removegold [target] [amount] ]]}
	module.mods["resetgold"] = module.mods["removegold"]
	module.mods["cleargold"] = module.mods["removegold"]
	
	module.mods["getav"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		local paras = vim.argsplit(params)
		local av = paras[#paras]
		if not tostring(av) then error("Argument 'value' invalid.") end
		av = string.lower(av)
		if av ~= "health" and av ~= "maxhealth" and av ~= "stamina" and av ~= "maxstamina" and av ~= "magicka" and av ~= "maxmagicka" then error("Actor Value \""..av .. "\" does not exist." ) end
		for k,v in pairs(args) do
			output[#output+1] = string.char(132).."Current Target: "..v.Name
			local sh = v:FindFirstChild("skyHealth")
			if not sh then error(v.Name .. " has no skyHealth!") end
			local char = v.Character
			if not char then error(v.Name .. " has no character!") end
			if av == "health" or av == "maxhealth" then
				local hu = char.Humanoid
				if av == "health" then output[#output+1] = string.char(137).."Health: ".. hu.Health else output[#output+1] = string.char(137).."Max Health: "..  hu.MaxHealth end
			end
			
			if av == "stamina" or av == "maxstamina" then
				if av == "stamina" then output[#output+1] = string.char(133).."Stamina: ".. sh.stamina.Value else output[#output+1] = string.char(133).."Max Stamina: ".. sh.stamina.max.Value end
			end
			
			if av == "magicka" or av == "maxmagicka" then
				if av == "magicka" then output[#output+1] = string.char(135).."Magicka: ".. sh.magicka.Value else output[#output+1] = string.char(135).."Max Magicka: ".. sh.magicka.max.Value end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Returns the number of the targets value. Does nothing if no value is given.]],
	[[getav [target] [value] ]]}
	module.mods["getactorvalue"] = module.mods["getav"]
	module.mods["getvalue"] = module.mods["getav"]
	
	module.mods["getpos"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then output[#output+1] = v.Name.."'s current position: ".. tostring(hrp.Position) end
		end
		return table.concat(output,"\n")
	end,
	[[Returns the x/y/z coordinates of the target.]],
	[[getpos [target] ]]}
	module.mods["getposition"] = module.mods["getpos"]
	
	module.mods["setpos"] = {function(player,target,params)
		local output = {}
		--Get coords from args, then remove them from the args list to only leave players/selectors
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		local coords = Vector3.new(para[#para-2],para[#para-1],para[#para])
		for k,v in pairs(args) do
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = CFrame.new(coords)
				hrp:MakeJoints()
				output[#output+1] = "Moved ".. tostring(v)
			else
					error("Cannot teleport a non entity")
			end
			return table.concat(output,"\n")
		end
	end,
	[[Set the position of the target to the given coordinates. Target defaults to speaker if omitted.]],
	[[setpos [target] [x][y][z] ]]}
	module.mods["setposition"] = module.mods["setpos"]
	module.mods["tpc"] = module.mods["setpos"]
	
	module.mods["moveto"] = {function(player,target,params)
		local output = {}
		--Get coords from args, then remove them from the args list to only leave players/selectors
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		local targ = para[#para]
		local offset = Vector3.new(0,0,-2)
		if targ == nil and target == nil then error("Argument 'target' missing!") end
		local char = nil; pcall(function() char = player.Character end)
		if not char then error("Player character not found!") end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		if targ ~= nil then
			local getTargFromPlayer = vim.matchname(player,targ)
			if #getTargFromPlayer == 0 then error("Target not a valid player, or not in game!") end
			for _,p in pairs(getTargFromPlayer) do
				local targHrp = p.Character:FindFirstChild("HumanoidRootPart")
				if hrp and targHrp then
					local cf = offset * 1
					local ncf = CFrame.new(cf,Vector3.new(0,0,0))
					hrp.CFrame = targHrp.CFrame:toWorldSpace(ncf)
					hrp:MakeJoints()
					output[#output+1] = "Moved "..player.Name.." to player "..p.Name
				end
			end
		else
			local targHrp = target:FindFirstChild("HumanoidRootPart")
			--print(hrp.Parent,targHrp.Parent)
			if hrp and targHrp then
				local cf = offset * 1
				local ncf = CFrame.new(cf,Vector3.new(0,0,0))
				hrp.CFrame = targHrp.CFrame:toWorldSpace(ncf)
				hrp:MakeJoints()
				output[#output+1] = "Moved "..player.Name.." to NPC "..target.Name
			end
		end
		return table.concat(output,"\n")
	end,
	[[Teleports the speaker to the target.]],
	[[moveto [target] ]]}
	module.mods["to"] = module.mods["moveto"]
	
	module.mods["placeatme"] = {function(player,target,params)
		local output = {}
		--Get coords from args, then remove them from the args list to only leave players/selectors
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		local targ = para[#para]
		local offset = Vector3.new(0,0,-2)
		if targ == nil and target == nil then error("Argument 'target' missing!") end
		local char = nil; pcall(function() char = player.Character end)
		if not char then error("Player character not found!") end
		local hrp = char:FindFirstChild("HumanoidRootPart")
		for k,v in pairs(args) do
			if targ ~= nil then
				local getTargFromPlayer = vim.matchname(player,targ)
				if #getTargFromPlayer == 0 then error("Target not a valid player, or not in game!") end
				for _,p in pairs(getTargFromPlayer) do
					local targHrp = p.Character:FindFirstChild("HumanoidRootPart")
					if hrp and targHrp then
						local cf = offset * k
						local ncf = CFrame.new(cf,Vector3.new(0,0,0))
						targHrp.CFrame = hrp.CFrame:toWorldSpace(ncf)
						targHrp:MakeJoints()
						output[#output+1] = "Moved player "..p.Name.." to player "..player.Name
					end
				end
			else
				local targHrp = target:FindFirstChild("HumanoidRootPart")
				--print(hrp.Parent,targHrp.Parent)
				if hrp and targHrp then
					local cf = offset * k
					local ncf = CFrame.new(cf,Vector3.new(0,0,0))
					targHrp.CFrame = hrp.CFrame:toWorldSpace(ncf)
					targHrp:MakeJoints()
					output[#output+1] = "Moved NPC "..target.Name.." to player "..player.Name
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Teleports the target to the speaker.]],
	[[placeatme [target] ]]}
	module.mods["bring"] = module.mods["placeatme"]
	
	module.mods["cow"] = {function(player,target,params)
		local name = nil
		local output = {}
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		if para[#para] ~= nil then
			name = tostring(table.concat(para, " "))
		else
			error("Argument 'name' missing!")
		end
		for k,v in pairs(args) do
			local waypoints = workspace:FindFirstChild("CCWaypoints")
			if not waypoints then error("No waypoints to move to!") end
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			local dest = waypoints:FindFirstChild(string.lower(name))
			if dest then
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					char:FindFirstChild("Humanoid").Jump = true --Avoid bringing seats or the like with us...
					hrp.CFrame = dest.CFrame
					hrp:MakeJoints()
					output[#output+1] = "Moved "..v.Name.." to waypoint \"".. dest.Name .. "\", Coords: ".. tostring(dest.Position)
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Teleports the target to a preset waypoint within the map.]],
	[[cow [target] [value] ]]}
	module.mods["centeronworld"] = module.mods["cow"]
	module.mods["tpw"] = module.mods["cow"]
	
	module.mods["tp"] = {function(player,target,params)
		local output = {}
		local args = vim.matchnames(player,vim.argsplit(params))
		local offset = Vector3.new(0,0,-2) --puts players 2 studs in front of destination to avoid wierdness
		local destTarg = args[#args]
		if #args <= 1 then
			destTarg = player
		else
			table.remove(args,#args) --remove destTarg from args
		end
		if target then table.insert(args,target) end
		local destchar = nil; pcall(function() destchar = destTarg.Character end)
		if not destchar then destchar = destTarg end
		if not destchar then error("destination has no character!") end
		local dhrp = destchar.HumanoidRootPart --dest hrp
		for k,v in pairs(args) do
			local cf = offset * k --incremental offset
			local cf = CFrame.new(cf,Vector3.new(0,0,0))
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = dhrp.CFrame:toWorldSpace(cf)
				hrp:MakeJoints()
				output[#output+1] = string.char(136)..char.Name.." teleported to ".. tostring(destTarg)
			else
					error("Cannot teleport a non entity")
			end
		end
		return table.concat(output,"\n")
	end,
	[[Teleports the "a" target(s) to the "b" target. Target B defaults to speaker if
]]..string.char(133)..[[omitted, thus acting like the “placeatme/bring” command.]],
	[[tp [target a] [target b] ]]}

	module.mods["tpr"] = {function(player,target,params)
		local output = {}
		--Get coords from args, then remove them from the args list to only leave players/selectors
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		local coords = Vector3.new(para[#para-2],para[#para-1],para[#para])
		for k,v in pairs(args) do
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			local hrp = char:FindFirstChild("HumanoidRootPart")
			if hrp then
				hrp.CFrame = hrp.CFrame + coords
				hrp:MakeJoints()
				output[#output+1] = string.char(136).."Moved ".. tostring(v)
			else
					error("Cannot teleport a non entity")
			end
			return table.concat(output,"\n")
		end
	end,
	[[Teleports the target relative the x/y/z values relative to the world coordinates.]],
	[[tpr [target] [x][y][z] ]]}
	
	module.mods["pushactoraway"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		local targDist = para[#para]
		if (not string.match(targDist,"%d+")) or targDist==nil then error("Argument 'distance' missing or Not A Number!") end
		for k,v in pairs(args) do
			if v ~= player then --Make sure the player doesnt push themselves
				local char = nil; pcall(function() char = v.Character end)
				if not char then char = v end
				if not char:FindFirstChild("Humanoid") then error("Cannot push a non-humanoid object.") end --catch for non-NPCs & non-Players
				local targHrp = char.HumanoidRootPart
				local speakerHrp = player.Character.HumanoidRootPart
				local cf = speakerHrp.CFrame:ToObjectSpace(targHrp.CFrame)
				cf = cf + Vector3.new(0,0,-targDist)
				targHrp.CFrame = speakerHrp.CFrame:ToWorldSpace(cf)
				targHrp:MakeJoints()
				output[#output+1] = "Pushed ".. v.Name .. " ".. tostring(targDist) .. " studs"
			end
		end
		return table.concat(output,"\n")
	end,
	[[Moves the target in relation to the speaker the given distance.
]]..string.char(133)..[[Negative values will move the target closer.]],
	[[pushactoraway [target] [distance] ]]}
	module.mods["pushactor"] = module.mods["pushactoraway"]
	module.mods["pushaway"] = module.mods["pushactoraway"]
	module.mods["push"] = module.mods["pushactoraway"]
	
	module.mods["setactoralpha"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		local amount = tonumber(para[#para])
		if amount < 0 or amount > 1 then error("Argument 'amount' must be between 0 and 1!") end
		for k,v in pairs(args) do
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			for _,p in pairs(char:GetChildren()) do
				if p:IsA("BasePart") or p:IsA("MeshPart") then
					--game:GetService("PhysicsService"):SetPartCollisionGroup(p, "ghosts")
					p.Transparency = amount
					if p.Name == "Head" then p.face.Transparency = amount end
					if p.Name == "HumanoidRootPart" then p.Transparency = 1 end
				end
				if p:IsA("Accessory") then --collision groups dont work on accessories, so we gotta do something else
					for _,h in pairs(p:GetChildren()) do
						if h:IsA("BasePart") or h:IsA("MeshPart") then
							--game:GetService("PhysicsService"):SetPartCollisionGroup(h, "ghosts")
							h.Transparency = amount
						end
					end
				end
				if p:IsA("Model") then
					for _,pp in pairs(p:GetChildren()) do
						if pp:IsA("BasePart") or pp:IsA("MeshPart") then
							--game:GetService("PhysicsService"):SetPartCollisionGroup(pp, "ghosts")
							pp.Transparency = amount
						end
						if pp:IsA("Accessory") then --there shouldnt be accessories in a model in the player, but just in case
							for _,hh in pairs(pp:GetChildren()) do
								if hh:IsA("BasePart") or hh:IsA("MeshPart") then
									--game:GetService("PhysicsService"):SetPartCollisionGroup(hh, "ghosts")
									hh.Transparency = amount
								end
							end
						end
					end
				end
			end
			output[#output+1] = "Set ".. tostring(v) .."'s transparency to ".. tostring(amount)
		end
		return table.concat(output,"\n")
	end,
	[[Sets the targets transparency to the given value, between 0-1.]],
	[[setactoralpha [target] [amount] ]]}
	module.mods["setalpha"] = module.mods["setactoralpha"]
	module.mods["settransparency"] = module.mods["setactoralpha"]
	module.mods["transparency"] = module.mods["setactoralpha"]
	
	module.mods["setscale"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		local h,d,w,f = nil
		local pattern = "(%a+)#(%d+)"
		for _,v in pairs(para) do
			local targ,val = string.match(v,pattern)
			if targ == "height" or targ == "h" then h = val end
			if targ == "depth" or targ == "d" then d = val end
			if targ == "width" or targ == "w" then w = val end
			if targ == "head" or targ == "f" then f = val end
			if targ == "all" then h,d,w,f = val,val,val,val end
			--Note: since we parse the params first, we cant have an error if targ isnt any of the above values, as the player target is also included as a param
		end
		for k,v in pairs(args) do
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			local humanoid = char:FindFirstChild("Humanoid")
			if not humanoid then error("Cannot set the scale of a non-humanoid object.") end
			if h ~= nil then humanoid.BodyHeightScale.Value = h;output[#output+1] = "Changed ".. v.Name .."'s Height to ".. tostring(h) end
			if d ~= nil then humanoid.BodyDepthScale.Value = d;output[#output+1] = "Changed ".. v.Name .."'s Depth to ".. tostring(d) end
			if w ~= nil then humanoid.BodyWidthScale.Value = w;output[#output+1] = "Changed ".. v.Name .."'s Width to ".. tostring(w) end
			if f ~= nil then humanoid.HeadScale.Value = f;output[#output+1] = "Changed ".. v.Name .."'s Head to ".. tostring(f) end
		end
		return table.concat(output,"\n")
	end,
	[[Sets the scale of the target to the given values. All values are
]]..string.char(133)..[[optional/do not change the target if omitted.]],
	[[setscale [target] [height#value][depth#value][width#value][head#value] ]]}
	module.mods["scale"] = module.mods["setscale"]
	
	module.mods["heal"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			local humanoid = char:FindFirstChild("Humanoid")
			if not humanoid then error("Cannot heal a non-humanoid object.") end
			humanoid.Health = humanoid.MaxHealth
			output[#output+1] = "Healed ".. v.Name
		end
		return table.concat(output,"\n")
	end,
	[[Heals the target back to their maxhealth.]],
	[[heal [target] ]]}
	
	module.mods["restore"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		local paras = vim.argsplit(params)
		local av = paras[#paras]
		if not tostring(av) then error("Argument 'stat' invalid.") end
		av = string.lower(av)
		if av ~= "health" and av ~= "stamina" and av ~= "magicka" then error("Actor Value \""..av .. "\" does not exist." ) end
		for k,v in pairs(args) do
			local sh = v:FindFirstChild("skyHealth")
			if not sh then error("Cannot restore value on a non-player.") end
			if av == "health" then
				local hu = v.Character.Humanoid
				if av == "health" then hu.Health = hu.MaxHealth end
				output[#output+1] = "Restored ".. v.Name .."'s health."
			end
			
			if av == "stamina" then
				if av == "stamina" then sh.stamina.Value = sh.stamina.max.Value end
				output[#output+1] = "Restored ".. v.Name .."'s stamina."
			end
			
			if av == "magicka" then
				if av == "magicka" then sh.magicka.Value = sh.magicka.max.Value end
				output[#output+1] = "Restored ".. v.Name .."'s magicka."
			end
		end
		return table.concat(output,"\n")
	end,
	[[Restores the given stat back to its max on the target.]],
	[[restore [target] [stat] ]]}
	
	module.mods["speed"] = {function(player,target,params)
		local output = {}
		local paras = vim.argsplit(params)
		local speed = paras[#paras]
		if not tonumber(speed) then error("Argument 'value' Not a Number.") end
		local args = vim.selectargs(player,target,params)--"t"
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Target is not a player.") end
			local sh = v.PlayerGui:FindFirstChild("SkyHealth")
			if not sh then error("SkyHealth does not exist!") end
			local mult = sh:FindFirstChild("speedmult")
			if mult then 
				mult:Invoke(tonumber(speed))
				output[#output+1] = "Changed ".. v.Name .."'s Speed Multiplier to ".. speed
			end
		end
		return table.concat(output,"\n")
	end,
	[[Changes the targets walking speed to the value.]],
	[[speed [target] [value] ]]}
	module.mods["walkspeed"] = module.mods["speed"]
	module.mods["ws"] = module.mods["speed"]
	module.mods["speedmult"] = module.mods["speed"]
	module.mods["speedmultiplier"] = module.mods["speed"]
	module.mods["spd"] = module.mods["speed"]
	
	module.mods["jumppower"] = {function(player,target,params)
		local output = {}
		local paras = vim.argsplit(params)
		local speed = paras[#paras]
		if not tonumber(speed) then error("Argument 'value' Not a Number.") end
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			local humanoid = char:FindFirstChild("Humanoid")
			if not humanoid then error("Cannot change Jump Power a non-humanoid object.") end
			humanoid.JumpPower = tonumber(speed)
			output[#output+1] = "Changed ".. v.Name .."'s JumpPower to ".. speed
		end
		return table.concat(output,"\n")
	end,
	[[Changes the targets jump power to the value.]],
	[[jumppower [target] [value] ]]}
	module.mods["jp"] = module.mods["jumppower"]
	
	module.mods["refresh"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall( function() char = v.Character end )
			if not char then char = v end
			if not char:FindFirstChild("HumanoidRootPart") then error("No HumanoidRootPart in target.") end
			pcall(function()
				--print("HRP found, refreshing")
				local playerPos = char.HumanoidRootPart.CFrame
				v.CharacterAppearanceId = 0 --Appearance change catch
				v:LoadCharacter()
				--char = v.Character
				spawn(function()
					wait()
					repeat wait(); pcall( function() char = v.Character end ) until char and char:FindFirstChild("HumanoidRootPart")
					char.HumanoidRootPart.CFrame = playerPos
					char.HumanoidRootPart:MakeJoints()
					--print("sent player back")
				end)
			end)
			output[#output+1] = "Refreshed ".. tostring(v)
		end
		return table.concat(output,"\n")
	end,
	[[Refreshes the targets character.]],
	[[refresh [target] ]]}
	
	module.mods["tpf"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall( function() char = v.Character end )
			if not char then char = v end
			local playerVals = v:FindFirstChild("CCACPlayerVals")
			if not playerVals then error("Target is not a player.") end
			if playerVals then
				if not playerVals.HasFly.Value and (not char:FindFirstChild("CCFly")) then
					playerVals.HasFly.Value = true
					local fly = bin.LocalScripts.CCFly:Clone()
					fly.Parent = char
				elseif playerVals.HasFly.Value then
					playerVals.HasFly.Value = false
					local fly = char:FindFirstChild("CCFly")
					fly:Destroy()
				else
					error("Cannot give fly to a non-player.")
				end
			end
			output[#output+1] = "Toggled flight on ".. tostring(v) .." => ".. tostring(playerVals.HasFly.Value)
		end
		return table.concat(output,"\n")
	end,
	[[Enables or disables flight on the target.]],
	[[tpf [target] ]]}
	module.mods["toggleplayerflight"] = module.mods["tpf"]
	module.mods["fly"] = module.mods["tpf"]
	
	module.mods["clean"] = {function(player,target,params)
		local output = {}
		local numCleaned,numAcc,numTool,numSummon,numClone = 0,0,0,0,0 --Makes everything a bit longer but gives more info in the output!
		for _,child in pairs(workspace:GetChildren()) do
			if child:IsA("Accessory") then
				child:Destroy()
				numCleaned = numCleaned+1
				numAcc = numAcc+1
			end
			if child:IsA("Tool") then
				child:Destroy()
				numCleaned = numCleaned+1
				numTool = numTool+1
			end
			if workspace:FindFirstChild("CCACSummons") then
				for _,v in pairs(workspace:FindFirstChild("CCACSummons"):GetChildren()) do
					v:Destroy()
					numCleaned = numCleaned+1
					numSummon = numSummon+1
				end
			end
			if workspace:FindFirstChild("CCACClones") then
				for _,v in pairs(workspace:FindFirstChild("CCACClones"):GetChildren()) do
					v:Destroy()
					numCleaned = numCleaned+1
					numClone = numClone+1
				end
			end
		end
		output[#output+1] = "Cleaned ".. tostring(numCleaned) .. " objects:"
		if numAcc>0 then output[#output+1] = tostring(numAcc).. " accessories" end
		if numTool>0 then output[#output+1] = tostring(numTool).. " tools" end
		if numSummon>0 then output[#output+1] = tostring(numSummon).. " summons" end
		if numClone>0 then output[#output+1] = tostring(numClone).. " clones" end
		return table.concat(output,"\n")
	end,
	[[Cleans the workspace of all dropped hats, tools, summons, and clones.]],
	[[clean ]]}
	
	module.mods["kick"] = {function(player,target,params)
		local reason = [[You have been kicked from this game.
Reason: Inappropriate behavior.]]
		local output = {}
		local args = vim.selectargs(player,target,params)
		local para = vim.argsplit(params)
		if para[#para] ~= nil then
			reason = [[You have been kicked from this game.
Reason: ]].. tostring(table.concat(para, " "))
		end
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot kick a non-player!") end
			v:Kick(reason)
			if para[#para] ~= nil then
				output[#output+1] = "Kicked ".. v.Name .. ", Reason: ".. tostring(table.concat(para, " "))
			else
				output[#output+1] = "Kicked ".. v.Name .. ", Reason: Inappropriate behavior"
			end
		end
		return table.concat(output,"\n")
	end,
	[[Kicks the target from the game with the optional reason message.
]]..string.char(133)..[[Message defaults if not given.]],
	[[kick [target] [reason] ]]}
	module.mods["boot"] = module.mods["kick"]
	
	module.mods["togglemute"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall( function() char = v.Character end )
			if not char then char = v end
			local playerVals = v:FindFirstChild("CCACPlayerVals")
			if not playerVals then error("Cannot mute a non-player.") end
			if playerVals then
				if not playerVals.IsMuted.Value and (not char:FindFirstChild("CCMute")) then
					playerVals.IsMuted.Value = true
					local mute = bin.LocalScripts.CCMute:Clone()
					mute.Parent = char
					local gag = game:GetService("InsertService"):LoadAsset(4684632159)
					for _,child in pairs(gag:GetChildren()) do
						v:LoadCharacterAppearance(child)
						child.Name = "CCACGag"
					end
				elseif playerVals.IsMuted.Value then
					playerVals.IsMuted.Value = false
					local mute = char:FindFirstChild("CCMute")
					mute:Destroy()
					local gag = char:FindFirstChild("CCACGag")
					gag:Destroy()
				else
					error("Cannot mute a non-player.")
				end
			end
			output[#output+1] = "Toggled mute on ".. tostring(v) .." => ".. tostring(playerVals.IsMuted.Value)
		end
		return table.concat(output,"\n")
	end,
	[[Toggles whether or not the target is muted.]],
	[[togglemute [target] ]]}
	module.mods["tmute"] = module.mods["togglemute"]
	module.mods["mute"] = module.mods["togglemute"]
	module.mods["gag"] = module.mods["togglemute"]
	
	module.mods["srp"] = {function(player,target,params)
		local output = {}
		local para = vim.argsplit(params)
		local amount = 1
		local team = nil
		local playersInTeam = {}
		local tempList = {}
		local selectedPlayers = {}
		if para[#para] ~= nil then --if arguments are given
			if not tonumber(para[#para]) then --if the argument isnt a number, its a team
				team = para[#para]
			else --if the argument is a number, no team argument was given
				amount = tonumber(para[#para])

			end
		end
		if para[#para-1] ~= nil and (not tonumber(para[#para])) then --if there are 2 args, and the last one is a team
			if tonumber(para[#para-1]) then amount = tonumber(para[#para-1]) end
		end
		if amount < 1 then output[#output+1] = string.char(131).."Argument 'amount' cannot be less than 1; Setting to 1"; amount = 1 end
		local teams = game.Teams:GetChildren()
		if #teams ~= 0 then --first pass to select players
			local function isInList(a,list) --if a is in list, returns key (list[key]==a)
				for k,v in pairs(list) do
					if string.lower(a) == string.lower(v.Name) then return v end --doubles as a true
				end
				return false
			end
			local targTeam = isInList(team,teams)
			if not targTeam then
				error("Given argument 'team' does not exist.")
			else
				for _,v in pairs(game.Players:GetPlayers()) do
					if v.Team == targTeam then table.insert(playersInTeam,v) end
				end
			end
		else
			if team ~= nil then output[#output+1] = string.char(131).."No teams found in game; Ignoring argument 'team'." end
		end
		if #teams ~= 0 then --second pass if the team exists, and there are selected players
			if #playersInTeam == 0 then error("No players exist in given team.") end
			if amount > #playersInTeam then output[#output+1] = string.char(131).."Argument 'amount' cannot exceed number of players in team;\n".. string.char(131).."Setting to max."; amount = #playersInTeam end
			tempList = playersInTeam
		else
			if amount > #game.Players:GetPlayers() then output[#output+1] = string.char(131).."Argument 'amount' cannot exceed number of players in server;\n".. string.char(131).."Setting to max."; amount = #game.Players:GetPlayers() end
			tempList = game.Players:GetPlayers()
		end
		for i=1,amount do
			local rand = math.random(1,#tempList)
			table.insert(selectedPlayers,tempList[rand])
			table.remove(tempList,rand)
		end
		if #selectedPlayers == 0 then output[#output+1] = string.char(130).."No players were selected." end
		for _,p in pairs(selectedPlayers) do
			output[#output+1] = "Selected "..p.Name
			coroutine.wrap(function()
				local captain = Instance.new("Sparkles",p.Character.HumanoidRootPart)
				local obiwan = Instance.new("ForceField",p.Character)
				wait(5)
				captain:Destroy()
				obiwan:Destroy()  --you were the chosen one
			end)()
		end
		return table.concat(output,"\n")
	end,
	[[Selects a random player in the game. If the optional amount argument is given, will select
]]..string.char(133)..[[that many random players. If the optional team argument is given, will
]]..string.char(133)..[[instead only select a random person on that team.]],
	[[srp [amount] [team] ]]}
	module.mods["selectrandomplayer"] = module.mods["srp"]
	module.mods["selrand"] = module.mods["srp"]
	
	module.mods["acc"] = {function(player,target,params)
		local output = {}
		local para = vim.argsplit(params)
		local targAcc = tonumber(para[#para])
		if not targAcc then error("Argument 'ID' missing or not a number!") end
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Target cannot be a non-player.") end
			local acc = game:GetService("InsertService"):LoadAsset(targAcc)
			for _,c in pairs(acc:GetChildren()) do
				v:LoadCharacterAppearance(c)
			end
			output[#output+1] = "Loaded accessory/face ".. tostring(targAcc) .." onto ".. v.Name
		end
		return table.concat(output,"\n")
	end,
	[[Gives the target the accessory matching the given ID.]],
	[[acc [target] [ID] ]]}
	module.mods["accessory"] = module.mods["acc"]
	module.mods["hat"] = module.mods["acc"]
	module.mods["face"] = module.mods["acc"]
	
	module.mods["gear"] = {function(player,target,params)
		local output = {}
		local para = vim.argsplit(params)
		local targAcc = tonumber(para[#para])
		if not targAcc then error("Argument 'ID' missing or not a number!") end
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Target cannot be a non-player.") end
			local acc = game:GetService("InsertService"):LoadAsset(targAcc)
			for _,c in pairs(acc:GetChildren()) do
				c.Parent = v.Backpack
			end
			output[#output+1] = "Gave gear ".. tostring(targAcc) .." to ".. v.Name
		end
		return table.concat(output,"\n")
	end,
	[[Gives the target the gear item matching the given ID.]],
	[[gear [target] [ID] ]]}
	
	module.mods["drophats"] = {function(player,target,params)
		--modified isInList from aaadddlib to perform lots of string pattern matches
		local function matchStringList(a,list) --if a is in list, returns key (list[key]==a)
			for k,v in pairs(list) do
				if string.gmatch(a,v) then return k end --doubles as a true
			end
			return false
		end
		local output = {}
		--whitelist mostly used for select animal parts for Khajiit/Argonian players, and other special acc's
		local whitelist = {}
		--Generic "catch-all" hair names to keep head/facial hairs. Some of these prob arent even used in acc names but better to be safe
		local patterns = {"(%a+%s?Beard)","(%a+%s?Hair)","(%a+%s?Moustache)","(%a+%s?Locks)","(%a+%s?Goatee)","(%a+%s?Stubble)","(%a+%s?Dreads)"}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			local humanoid = char:FindFirstChild("Humanoid")
			if not humanoid then error("Cannot drop hats from a non-humanoid object.") end
			local hasDropped = false
			for _,a in pairs(char:GetChildren()) do
				if a:IsA("Accessory") then
					if (not matchStringList(a.Name,patterns)) and (not lib.isInList(a.Name,whitelist)) then
						hasDropped = true	
						a.Parent = game.Workspace
						output[#output+1] = "Dropped ".. a.Name .." from ".. v.Name
					end	
				end
			end
			if not hasDropped then output[#output+1] = "No accessories dropped from ".. v.Name end	
		end
		return table.concat(output,"\n")
	end,
	[[Drops non-hair and non-animal hats/accessories on the target.]],
	[[drophats [player] ]]}
	
	module.mods["dropallhats"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			local humanoid = char:FindFirstChild("Humanoid")
			if not humanoid then error("Cannot drop hats from a non-humanoid object.") end
			for _,a in pairs(char:GetChildren()) do
				if a:IsA("Accessory") then
					a.Parent = game.Workspace
					output[#output+1] = "Dropped ".. a.Name .." from ".. v.Name
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Drops all hats/accessories on the target.]],
	[[dropallhats [player] ]]}
	
	module.mods["morph"] = {function(player,target,params)
		local output = {}
		local morphs = bin.Morphs
		local morphsList = {}
		for k,v in pairs(morphs:GetChildren()) do table.insert(morphsList,v.Name) end 
		local names,para = vim.splitNamesAndArgs(player,params)
		local targMorph = table.concat(para," ")
		if targMorph == "" then error("Argument 'morph' missing!") end
		for k,v in pairs(names) do
			if v.Parent ~= game.Players then error("Cannot morph a non-player!") end
			local char = nil; pcall(function() char = v.Character end)
			if not char then char = v end
			local playerPos = char.HumanoidRootPart.CFrame
			for _,m in pairs(morphsList) do --if the morph matches a CCAC morph
				if string.lower(targMorph) == string.lower(m) then
					local mo = morphs:FindFirstChild(m)
					local s = char:FindFirstChild("Shirt")
					local p = char:FindFirstChild("Pants")
					local t = char:FindFirstChild("ShirtGraphic")
					local f = char.Head:FindFirstChild("face")
					local h = mo.Height.Value
					local d = mo.Depth.Value
					local w = mo.Width.Value
					local he = mo.Head.Value
					
					s.ShirtTemplate = mo.Shirt.Value
					p.PantsTemplate = mo.Pants.Value
					f.Texture = mo.Face.Value
					for _,a in pairs(char:GetChildren()) do
						if a:IsA("Accessory") or a.ClassName == "BodyColors" or a.ClassName == "ShirtGraphic" then
							a:Destroy()
							wait()
						end
					end
					if t==nil then t = Instance.new("ShirtGraphic",char) end
					t.Graphic = mo.TShirt.Value
					for _,a in pairs(mo:GetChildren()) do
						if a:IsA("Accessory") or a.ClassName == "BodyColors" then
							local clone = a:Clone()
							clone.Parent = char
						end
					end
					local humanoid = char:FindFirstChild("Humanoid")
					humanoid.BodyHeightScale.Value = h
					humanoid.BodyDepthScale.Value = d
					humanoid.BodyWidthScale.Value = w
					humanoid.HeadScale.Value = he
					output[#output+1] = "Morphed ".. v.Name .." into Morph: ".. mo.Name
				end
			end
			for _,m in pairs(game.Players:GetPlayers()) do --if the morph matches a player in game
				if string.lower(targMorph) == string.lower(m.Name) then
					v.CharacterAppearanceId = m.CharacterAppearanceId
					v:LoadCharacter()
					output[#output+1] = "Morphed ".. v.Name .." to look like ".. m.Name
				end
			end
			if tonumber(targMorph) then --if target morph is a player ID
				v.CharacterAppearanceId = targMorph
				v:LoadCharacter()
				output[#output+1] = "Morphed ".. v.Name .." to look like UserId: ".. targMorph
			end
			spawn(function()
				wait()
				repeat wait(); pcall( function() char = v.Character end ) until char and char:FindFirstChild("HumanoidRootPart")
				char.HumanoidRootPart.CFrame = playerPos
				char.HumanoidRootPart:MakeJoints()
			end)
		end
		return table.concat(output,"\n")
	end,
	[[Morphs the target player into the target morph.]],
	[[morph [target] [morph] ]]}
	
	module.mods["morphs"] = {function(player,target,params)
		local output = {}
		local morphs = bin.Morphs
		if #morphs:GetChildren() == 0 then error("No morphs avialable!") end
		for k,v in pairs(morphs:GetChildren()) do
			output[#output+1] = "Morph ".. tostring(k)..": ".. v.Name
		end
		return table.concat(output,"\n")
	end,
	[[Outputs a list of all available morphs into the output console.]],
	[[morphs ]]}
	module.mods["morphlist"] = module.mods["morphs"]
	
	module.mods["time"] = {function(player,target,params)
		local output = {}
		local para = vim.argsplit(params)
		local command = para[#para]
		command = string.lower(command)
		local commandList = {"next","back","pause","resume","dawn","noon","dusk","midnight"}
		if not lib.isInList(command,commandList) then error("Argument 'command' is invalid.") end  
		local daynight = game.ServerScriptService:FindFirstChild("DayNight")
		if not daynight then error("DayNight script is not in this place.") end
		local tw = daynight:FindFirstChild("timewarp")
		if tw then
			tw:Invoke(command)
			if command == "next" then output[#output+1] = "Sent time to the next quarter." end
			if command == "back" then output[#output+1] = "Sent time to the previous quarter." end
			if command == "pause" then output[#output+1] = "Paused the passage of time." end
			if command == "resume" then output[#output+1] = "Resumed the passage of time." end
			if command == "dawn" then output[#output+1] = "Set time to dawn." end
			if command == "noon" then output[#output+1] = "Set time to noon." end
			if command == "dusk" then output[#output+1] = "Set time to dusk." end
			if command == "midnight" then output[#output+1] = "Set time to midnight." end
		end
		return table.concat(output,"\n")
	end,
	[[Either changes the game time to the next step, or pauses/resumes the passing of time.]],
	[[time [next/prev/pause/resume/dawn/noon/dusk/midnight] ]]}
	
	module.mods["timemultiplier"] = {function(player,target,params)
		local output = {}
		local para = vim.argsplit(params)
		local mult = para[#para]
		local cycle = para[#para-1]
		local argList = {"day","night","d","n"}
		if not tonumber(para[#para]) then error("Argument 'value' not a number!") end
		if para[#para-1] == nil then error("Argument 'day/night' missing!") end
		if not lib.isInList(cycle,argList) then error("Argument 'day/night' is invalid.") end
		local daynight = game.ServerScriptService:FindFirstChild("DayNight")
		if not daynight then error("DayNight script is not in this place.") end
		local dayMult,nightMult = daynight:FindFirstChild("timemultday"),daynight:FindFirstChild("timemultnight")
		local tw = daynight:FindFirstChild("timewarp")
		local function getQuarter()
			local ct = game.Lighting.ClockTime
			if ct >= 6 and ct < 12 then return "Dawn" end
			if ct >= 12 and ct < 18 then return "Noon" end
			if ct >= 18 and ct < 24 then return "Dusk" end
			if ct >= 0 and ct < 6 then return "Midnight" end
		end
		local function getNextQuarter()
			local ct = game.Lighting.ClockTime
			if ct >= 6 and ct < 12 then return "Noon" end
			if ct >= 12 and ct < 18 then return "Dusk" end
			if ct >= 18 and ct < 24 then return "Midnight" end
			if ct >= 0 and ct < 6 then return "Dawn" end
		end
		if dayMult and nightMult and tw then
			if cycle == "day" or cycle == "d" then
				dayMult.Value = mult
				tw:Invoke("updateDay")
				output[#output+1] = "Day will now pass ".. tostring(mult) .."x as fast starting on the next quarter."
				output[#output+1] = "Current Quarter: ".. getQuarter()
				output[#output+1] = "Next Quarter: ".. getNextQuarter()
			elseif cycle == "night" or cycle == "n" then
				nightMult.Value = mult
				tw:Invoke("updateNight")
				output[#output+1] = "Night will now pass ".. tostring(mult) .."x as fast starting on the next quarter."
				output[#output+1] = "Current Quarter: ".. getQuarter()
				output[#output+1] = "Next Quarter: ".. getNextQuarter()
			end
		end
		return table.concat(output,"\n")
	end,
	[[Changes the game time to the target number.]],
	[[timemultiplier [day/night] [value] ]]}
	module.mods["timemult"] = module.mods["timemultiplier"]
	
	module.mods["stat"] = {function(player,target,params)
		return "TODO"
	end,
	[[If the game has leaderstats, changes the targeted stat to the given value on the target player.]],
	[[stat [target] [stat] [number] ]]}
	
	module.mods["rstats"] = {function(player,target,params)
		return "TODO"
	end,
	[[If the game has leaderstats, resets all stats to 0 on the target player.]],
	[[rstats [target] ]]}
	module.mods["resetstats"] = module.mods["rstats"]
	
	module.mods["m"] = {function(player,target,params)
		local output = {}
		if params == nil then error("Argument 'message' missing!") end
		local players = game.Players:GetPlayers()
		
		for k,v in pairs(players) do
			coroutine.wrap(function()
				if v.PlayerGui:FindFirstChild("MessageTemplate") then repeat wait() until v.PlayerGui:FindFirstChild("MessageTemplate") == nil end --force message queue
				local message = bin.MessageTemplate:Clone()
				message.Parent = v.PlayerGui
				message.Frame.Title.Text = "Message from ".. player.Name
				local mo = vim.getTextObject(params, player.UserId)
				local filtered = ""
				filtered = vim.getFilteredMessage(mo)
				message.Frame.Message.Text = filtered
				wait(10)
				for i=message.Frame.BackgroundTransparency,1,.1 do
					message.Frame.BackgroundTransparency = i
					for _,b in pairs(message.Frame.border:GetChildren()) do
						b.ImageTransparency = i
					end
					wait(.1)
				end
				message:Destroy()
			end)()
		end
		output[#output+1] = "Sent message to all players."	
		return table.concat(output,"\n")
	end,
	[[Sends a serverwide message to all players for 10 seconds.]],
	[[m [message] ]]}
	module.mods["message"] = module.mods["m"]
	module.mods["shout"] = module.mods["m"]
	
	module.mods["tm"] = {function(player,target,params)
		local output = {}
		local para = vim.argsplit(params)
		local aliveTime = tonumber(para[1])
		if not aliveTime then error("Argument 'time' missing or not a number!") end
		if aliveTime > 60 then output[#output+1] = string.char(131).."Time cannot be greater than 60; Setting to 60."; aliveTime = 60 end	
		if aliveTime < 3 then output[#output+1] = string.char(131).."Time cannot be less than 3; Setting to 3."; aliveTime = 3 end
		table.remove(para,1)
		params = table.concat(para," ")
		local players = game.Players:GetPlayers()
		
		for k,v in pairs(players) do
			coroutine.wrap(function()
				if v.PlayerGui:FindFirstChild("MessageTemplate") then repeat wait() until v.PlayerGui:FindFirstChild("MessageTemplate") == nil end --force message queue
				local message = bin.MessageTemplate:Clone()
				message.Parent = v.PlayerGui
				local mo = vim.getTextObject(params, player.UserId)
				local filtered = ""
				filtered = vim.getFilteredMessage(mo)
				message.Frame.Message.Text = filtered
				for i=1,aliveTime+1 do
					message.Frame.Title.Text = "Timed Message from ".. player.Name .." (".. tostring(aliveTime) .."s)"
					aliveTime = aliveTime-1
					wait(1)
				end
				for i=message.Frame.BackgroundTransparency,1,.1 do
					message.Frame.BackgroundTransparency = i
					for _,b in pairs(message.Frame.border:GetChildren()) do
						b.ImageTransparency = i
					end
					wait(.1)
				end
				message:Destroy()
			end)()
			end
			output[#output+1] = "Sent timed message to all players, with time ".. tostring(aliveTime)
		return table.concat(output,"\n")
	end,
	[[Sends a serverwide message that stays for the given time.]],
	[[tm [time] [message] ]]}
	module.mods["timemessage"] = module.mods["tm"]
	
	module.mods["cd"] = {function(player,target,params)
		local output = {}
		local aliveTime = tonumber(params)
		if not aliveTime then error("Argument 'time' missing or not a number!") end
		if aliveTime > 60 then output[#output+1] = string.char(131).."Time cannot be greater than 60; Setting to 120."; aliveTime = 120 end	
		if aliveTime < 3 then output[#output+1] = string.char(131).."Time cannot be less than 3; Setting to 3."; aliveTime = 3 end
		local players = game.Players:GetPlayers()
		
		for k,v in pairs(players) do
			coroutine.wrap(function()
				if v.PlayerGui:FindFirstChild("MessageTemplate") then repeat wait() until v.PlayerGui:FindFirstChild("MessageTemplate") == nil end --force message queue
				local message = bin.MessageTemplate:Clone()
				message.Parent = v.PlayerGui
				message.Frame.Title.Text = "Countdown from ".. player.Name
				for i=1,aliveTime+1 do
					if aliveTime == 0 then
						message.Frame.Message.Text = "Begin!"
					else
						message.Frame.Message.Text = tostring(aliveTime)
					end
					aliveTime = aliveTime-1
					wait(1)
				end
				for i=message.Frame.BackgroundTransparency,1,.1 do
					message.Frame.BackgroundTransparency = i
					for _,b in pairs(message.Frame.border:GetChildren()) do
						b.ImageTransparency = i
					end
					wait(.1)
				end
				message:Destroy()
			end)()
			end
			output[#output+1] = "Started a countdown with time ".. tostring(aliveTime+1)
		return table.concat(output,"\n")
	end,
	[[Starts a countdown from the given time until 0.]],
	[[cd [time] ]]}
	module.mods["countdown"] = module.mods["cd"]
	
	module.mods["bans"] = {function(player,target,params)
		local output = {}
		output[#output+1] = string.char(131).."Currently Banned Players:"
		local lists = trello:GetLists(tBoardId)
		for q,e in next,lists do	
			if lists[q] ~= nil then
				if lists[q]["name"] == "Ban List" then
					local cards = trello:GetCardsInList(lists[q]["id"])
					local pattern = "(%w+):?(%d+)"
					for _,c in next,cards do
						local n,i = c["name"]:match(pattern)
						output[#output+1] = n.." (ID: ".. i ..")"
					end
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Outputs a list of all currently banned players into the output console.]],
	[[bans ]]}
	module.mods["showbans"] = module.mods["bans"]
	
	module.mods["info"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			output[#output+1] = string.char(135).."Current Player: ".. v.Name .." (".. v.UserId ..")"
			output[#output+1] = "Age: ".. v.AccountAge .." days"
			output[#output+1] = "Membership: ".. tostring(v.MembershipType)
			if v.Team ~= nil then
				output[#output+1] = "Team: ".. v.Team.Name
			else
				output[#output+1] = "Team: None/Neutral"
			end
			if v.FollowUserId ~= 0 then 
				local followedUser = game.Players:GetPlayerByUserId(v.FollowUserId)
				if not followedUser then followedUser = "Player no longer in game" end
				output[#output+1] = "Followed User: ".. followedUser.." (".. v.FollowUserId ..")"
			end
			if v:FindFirstChild("CCACPlayerVals") then
				output[#output+1] = string.char(137).."CCAC Values for ".. v.Name
				for _,cv in pairs(v:FindFirstChild("CCACPlayerVals"):GetChildren()) do
					output[#output+1] = cv.Name ..": ".. tostring(cv.Value)
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Displays information on the target player.]],
	[[info [target] ]]}
	
	module.mods["toolpack"] = {function(player,target,params)
		local output = {}
		local names,para = vim.splitNamesAndArgs(player,params)
		local pack = table.concat(para," ")
		for k,v in pairs(names) do
			--print(v)
			if v.Parent ~= game.Players then error("Cannot give tool pack to a non-player.") end
			for _,t in pairs(bin.Toolpacks:GetChildren()) do
				if string.lower(pack) == string.lower(t.Name) then
					for _,c in pairs(t:GetChildren()) do
						local clone = c:Clone()
						clone.Parent = v.Backpack
					end
					output[#output+1] = "Gave ".. v.Name .." tool pack: ".. t.Name
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Gives the target player the target pack of tools.]],
	[[toolpack [target] [pack] ]]}
	
	module.mods["pm"] = {function(player,target,params)
		local output = {}
		local names,para = vim.splitNamesAndArgs(player,params)
		local msg = table.concat(para," ")
		for k,v in pairs(names) do
			local pm = bin.PMWindow:Clone()
			pm.Parent = v.PlayerGui
			local event = pm:WaitForChild("UpdateText")
			local sender = pm:FindFirstChild("Sender")
			sender.Value = player
			local mo = vim.getTextObject(params, player.UserId)
			local filtered = ""
			filtered = vim.getFilteredMessage(mo)
			event:FireClient(v,filtered)
			output[#output+1] = "Sent PM to ".. v.Name
		end
		return table.concat(output,"\n")
	end,
	[[Sends a GUI to the target player with the given message. GUI will have a built-in
]]..string.char(133)..[[reply system to send a GUI back to the intial sender.]],
	[[pm [target] [message] ]]}
	module.mods["privatemessage"] = module.mods["pm"]
	
	module.mods["vote"] = {function(player,target,params)
		return "TODO"
	end,
	[[Sends all users, except the sender, a GUI that contains a question, and two choices
]]..string.char(133)..[[of the given values. GUI will close on user vote, or after given time has elapsed.
]]..string.char(133)..[[At the end of the given time, a GUI will be sent back to the command speaker with the results.]],
	[[vote [question] [time] [option1] | [option2] ... ]]}
	
--	module.mods["promote"] = {function(player,target,params)
--		return "TODO"
--	end,
--	[[If the target player is in the given group, changes their rank to the given rank.
--]]..string.char(133)..[[Requires the given bot account to be in the group, and have permissions to change other members ranks.
--]]..string.char(133)..[[For best usability, the bot should also be set at the max rank you wish to allow to rank people up to.]],
--	[[promote [target] [groupID] [rank] ]]}
	
	module.mods["playercount"] = {function(player,target,params)
		local output = {}
		output[#output+1] = "There are ".. tostring(#game.Players:GetPlayers()).. " currently in this server."
		return table.concat(output,"\n")
	end,
	[[Outputs the number of players currently on the server to the output console.]],
	[[playercount ]]}
	module.mods["plrcount"] = module.mods["playercount"]
	
	module.mods["team"] = {function(player,target,params)
		local output = {}
		local names,para = vim.splitNamesAndArgs(player,params)
		local targTeam = table.concat(para," ")
		for k,v in pairs(names) do
			if v.Parent ~= game.Players then error("Cannot place non-player onto a team.") end
			for _,t in pairs(game.Teams:GetTeams()) do
				if string.lower(targTeam) == string.lower(t.Name) then
					if v.Team ~= t then 
						v.Team = t 
						module.mods["refresh"][1](player,nil,v.Name)
						output[#output+1] = "Placed ".. v.Name .." on team ".. t.Name
					else 
						output[#output+1] = string.char(130).. v.Name .." is already on team ".. t.Name
					end
				end
			end
		end
		return table.concat(output,"\n")
	end,
	[[Places the target player(s) into the target team.]],
	[[team [target] [team] ]]}
	
	module.mods["createteam"] = {function(player,target,params)
		local output = {}
		local para = vim.argsplit(params)
		local color = BrickColor.new(para[#para]) --BUG: Defaults to Medium Stone Gray if invalid is given?
		if not color then error("Argument 'color' must be a valid BrickColor.") end 
		table.remove(para,#para)
		local name = table.concat(para," ")
		for _,t in pairs(game.Teams:GetTeams()) do
			--first pass to check color
			if color == t.TeamColor then error("TeamColor ".. tostring(color) .." already in use by ".. t.Name) end
		end
		for _,t in pairs(game.Teams:GetTeams()) do
			--second pass to check name
			if string.lower(name) == string.lower(t.Name) then error("Team ".. t.Name .." already exists.") end
		end
		local team = Instance.new("Team",game.Teams)
		team.AutoAssignable = false
		team.Name = name
		team.TeamColor = color
		output[#output+1] = "Created team ".. name .." (".. tostring(color) ..")"
		return table.concat(output,"\n")
	end,
	[[Creates a new team with the target name and color.]],
	[[createteam [name] [color] ]]}
	module.mods["maketeam"] = module.mods["createteam"]
	
	module.mods["randomteams"] = {function(player,target,params)
		local output = {}
		local names,para = vim.splitNamesAndArgs(player,params)
		para = table.concat(para," ")
		local maxPerTeam = math.ceil(#names/2)
		local t1c,t2c = 0,0
		local pattern = "([%w%s]+)%s?,%s?([%w%s]+)"
		local t1,t2 = string.match(para,pattern)
		if t1 == nil then error("Argument 'team a' missing!") end
		if t2 == nil then error("Argument 'team b' missing!") end
		local teams = {}
		for _,t in pairs(game.Teams:GetTeams()) do table.insert(teams,string.lower(t.Name)) end
		if not lib.isInList(string.lower(t1),teams) then error("Team ".. t1 .." does not exist!") end
		if not lib.isInList(string.lower(t2),teams) then error("Team ".. t2 .." does not exist!") end
		local function placeInTeam(player,team)
			for _,t in pairs(game.Teams:GetTeams()) do
				if string.lower(team) == string.lower(t.Name) then
					player.Team = t 
				end
			end
		end
		for k,v in pairs(names) do
			if v.Parent ~= game.Players then error("Cannot place non-player onto a team.") end
			local pick = math.random(1,2)
			if pick == 1 and t1c ~= maxPerTeam then
				placeInTeam(v,t1)
				t1c = t1c+1
				module.mods["refresh"][1](player,nil,v.Name)
				output[#output+1] = "Placed ".. v.Name .." on team ".. t1
			elseif pick == 1 and t1c == maxPerTeam then
				placeInTeam(v,t2)
				t2c = t2c+1
				module.mods["refresh"][1](player,nil,v.Name)
				output[#output+1] = "Placed ".. v.Name .." on team ".. t2
			end
			if pick == 2 and t2c ~= maxPerTeam then
				placeInTeam(v,t2)
				t2c = t2c+1
				module.mods["refresh"][1](player,nil,v.Name)
				output[#output+1] = "Placed ".. v.Name .." on team ".. t2
			elseif pick == 2 and t2c == maxPerTeam then
				placeInTeam(v,t1)
				t1c = t1c+1
				module.mods["refresh"][1](player,nil,v.Name)
				output[#output+1] = "Placed ".. v.Name .." on team ".. t1
			end
		end
		return table.concat(output,"\n")
	end,
	[[Randomizes the target(s) between two given teams.]],
	[[randomteams [target] [team a], [team b] ]]}
	module.mods["randomizeteams"] = module.mods["randomteams"]
	module.mods["rteams"] = module.mods["randomteams"]
	
	module.mods["tbl"] = {function(player,target,params)
		local output = {}
		local args = vim.selectargs(player,target,params)
		for k,v in pairs(args) do
			if v.Parent ~= game.Players then error("Cannot blind a non-player.") end
			local playerVals = v:FindFirstChild("CCACPlayerVals")
			if not playerVals then error("Cannot blind a non-player.") end
			if playerVals then
				if not playerVals.IsMuted.Value then
					playerVals.IsMuted.Value = true
					local blinds = bin.CCACBlind:Clone()
					blinds.Parent = v.PlayerGui
					local gag = game:GetService("InsertService"):LoadAsset(4606984474)
					for _,child in pairs(gag:GetChildren()) do
						v:LoadCharacterAppearance(child)
						child.Name = "CCACBlind"
						child.Handle.Color = Color3.fromRGB(231,231,236) --Pearl White
						child.Handle.SpecialMesh.TextureId = ""
					end
				elseif playerVals.IsMuted.Value then
					playerVals.IsMuted.Value = false
					local blinds = v.PlayerGui:FindFirstChild("CCACBlind")
					blinds:Destroy()
					local gag = v.Character:FindFirstChild("CCACBlind")
					gag:Destroy()
				else
					error("Cannot blind a non-player.")
				end
			end
			output[#output+1] = "Toggled blindness on ".. tostring(v) .." => ".. tostring(playerVals.IsBlind.Value)
		end
		return table.concat(output,"\n")	
	end,
	[[Toggles blindness on the target.]],
	[[tbl [target] ]]}
	module.mods["toggleblindness"] = module.mods["tbl"]
	module.mods["blindness"] = module.mods["tbl"]
	module.mods["blind"] = module.mods["tbl"]
end

do		--All / Free
	module.all["cls"] = {function(player,target,params)
		--Does nothing; Is handled internally by the client
	end,
	[[Clears the output console.]],
	[[cls ]]}
	module.all["clearscreen"] = module.all["cls"]

	module.all["error"] = {function(player,target,params)
		error("This is a test error.") --thanks i hate this
		return "If you see this message, contact Jallar or aaaddd ASAP. Something went wrong."
	end,
	[[Produces a test error.]],
	[[error ]]}
	
	module.all["tui"] = {function(player,target,params)
		for _,v in pairs(player.PlayerGui:GetChildren()) do
			if v:IsA("ScreenGui") or v:IsA("GuiMain") then
				v.Enabled = not v.Enabled
			end
		end
	end,
	[[Toggles all GUIs visibility on/off for the speaker only.]],
	[[tui ]]}
	module.all["togglemenus"] = module.all["tui"]
	module.all["toggleui"] = module.all["tui"]
	module.all["tm"] = module.all["tui"]
	
	module.all["fov"] = {function(player,target,params)
		local output = {}
		local names,para = vim.splitNamesAndArgs(player,params)
		local fov = tonumber(para[#para])
		if not fov then error("Argument 'value' missing or not a number!") end
		if fov > 120 then output[#output+1] = string.char(131).."FOV cannot be higher than 120; Setting to 120."; fov = 120 end
		if fov < 1 then output[#output+1] = string.char(131).."FOV cannot be lower than 1; Setting to 1."; fov = 1 end
		for k,v in pairs(names) do
			if v.Parent ~= game.Players then error("Cannot change FOV of a non-player.") end
			local ccfov = v.Character:FindFirstChild("CCFov")
			if not ccfov then
				ccfov = bin.LocalScripts.CCFov:Clone()
				ccfov.Parent = v.Character
			end
			ccfov.FovEvent:FireClient(v,fov)
			output[#output+1] = "Changed Field of View for ".. v.Name .." to ".. tostring(fov)
		end
		return table.concat(output,"\n")
	end,
	[[Sets the speakers FOV to the value.]],
	[[fov [value] ]]}
	
	module.all["help"] = {function(player,target,params)
		return "TODO"
	end,
	[[Displays all help info. If an arg is provided, limits the help output to that item.
]]..string.char(133)..[[Output can be further limited by an optional filter value ranging from 0-4.]],
	[[help [arg][filter] ]]}
	
	module.all["commands"] = {function(player,target,params)
		local cmdList = {}
		cmdList.owner = {}
		cmdList.admin = {}
		cmdList.mods= {}
		cmdList.all = {}
		
		for k,v in pairs(script.Parent:GetChildren()) do --get raw commands lists
			local pak = require(v)
			for rank,list in pairs(pak) do
				for kay,vee in pairs(list) do
					--print(type(rank),type(kay))
					cmdList[rank][kay] = vee --add command
				end
			end
		end
		local cmdlist2 = {}
		for k,v in pairs(cmdList) do --reformat commands lists
			cmdlist2[k] = {}
			for funcname,command in pairs(v) do
				table.insert(cmdlist2[k],{funcname,command[1],command[2],command[3]})
			end
			table.sort(cmdlist2[k], function(a,b) return a[1]:lower() < b[1]:lower() end)
		end
		
		for k,v in pairs(cmdlist2) do --filter out search terms
			cmdlist2[k] = (params ~= "") and lib.allMatching(v,function(a)return string.find(string.lower(a[1]),string.lower(params),1,true)end) or v
		end
		
		--insert section dividers
		table.insert(cmdlist2.owner,1, {"Owner Commands:",nil,"Commands for owner ranks",""})
		table.insert(cmdlist2.owner, {"",nil,"",""})
		table.insert(cmdlist2.admin,1, {"Admin Commands:",nil,"Commands for admin ranks",""})
		table.insert(cmdlist2.admin, {"",nil,"",""})
		table.insert(cmdlist2.mods,1, {"Mod Commands:",nil,"Commands for mod ranks",""})
		table.insert(cmdlist2.mods, {"",nil,"",""})
		table.insert(cmdlist2.all,1, {"Free Commands:",nil,"Commands for everyone",""})
		
		local priv = vim.checkPrivilege(player)
		
		--reformat to flat list, fliter out by privilege
		local cmds = {}
		for k,v in pairs(cmdlist2.all) do
			table.insert(cmds,k,v)
		end
		if priv >= 2 then
		for k,v in pairs(cmdlist2.mods) do
			table.insert(cmds,k,v)
		end
		end
		if priv >= 3 then
		for k,v in pairs(cmdlist2.admin) do
			table.insert(cmds,k,v)
		end
		end
		if priv >= 4 then
		for k,v in pairs(cmdlist2.owner) do
			table.insert(cmds,k,v)
		end
		end
		
		
		--my final form?!?!
		local output = {}
		local showUsage = params ~= ""
		for k,v in pairs(cmds) do
			output[#output+1] = v[1]
			output[#output+1] = string.char(133)..v[3]
			if showUsage and v[4] ~= "" then output[#output+1] = string.char(131).."USAGE: "..v[4] end
		end
		return table.concat(output,"\n")
	end,
	[[Outputs a list of all the commands into the output console.]],
	[[commands ]]}
	module.all["cmds"] = module.all["commands"]
	
	module.all["rank"] = {function(player,target,params)
		local output = {}
		local names,para = vim.splitNamesAndArgs(player,params)
		local group = tonumber(para[#para])
		if not group then error("Argument 'groupId' missing or not a number!") end
		local groupInfo = game:GetService("GroupService"):GetGroupInfoAsync(group)
		if not groupInfo then error("Group with Id ".. tostring(group).. " does not exist!") end
		for k,v in pairs(names) do
			if v.Parent ~= game.Players then error("Cannot check group of a non-player.") end
			if v:IsInGroup(group) then
				output[#output+1] = v.Name .." is in group \"".. groupInfo.Name	.. "\" (".. tostring(group) ..")"
				output[#output+1] = v.Name .."'s Role is \"".. v:GetRoleInGroup(group) .. "\" (".. v:GetRankInGroup(group) ..")"
			else
				output[#output+1] = v.Name .." is not in group \"".. groupInfo.Name	.. "\" (".. tostring(group) ..")"
			end
		end
		return table.concat(output,"\n")
	end,
	[[Outputs the rank of the target player in the target group.]],
	[[rank [target] [groupID] ]]}
	
	module.all["admins"] = {function(player,target,params)
		local output = {}
		local infoList = {}
		for k,v in pairs(game.Players:GetPlayers()) do
			if lib.isInList(v.UserId,adminList.owners) then table.insert(infoList,string.char(130)..v.Name.." - Owner")
			elseif lib.isInList(v.UserId,adminList.admins) then table.insert(infoList,string.char(131)..v.Name.." - Admin")
			elseif lib.isInList(v.UserId,adminList.mods) then table.insert(infoList,string.char(132)..v.Name.." - Mod")
			end
		end
		if #infoList == 0 then error("No admins are currently online!") end
		for _,v in pairs(infoList) do output[#output+1] = v end
		return table.concat(output,"\n")
	end,
	[[Outputs a list of all admins currently in the server and their rank into the output console.]],
	[[admins ]]}
	module.all["listadmins"] = module.all["admins"]
	
	module.all["requesthelp"] = {function(player,target,params)
		local output = {}
		local numSentTo = 0
		for k,v in pairs(game.Players:GetPlayers()) do
			coroutine.wrap(function()
				if lib.isInList(v.UserId,adminList.owners) or lib.isInList(v.UserId,adminList.admins) or lib.isInList(v.UserId,adminList.mods) then
					numSentTo = numSentTo+1
					if v.PlayerGui:FindFirstChild("ReqHelp") then repeat wait() until v.PlayerGui:FindFirstChild("ReqHelp") == nil end --force message queue
					local menu = bin.ReqHelp:Clone()
					menu.Parent = v.PlayerGui
					menu:WaitForChild("Requester").Value = player
					menu.Frame.Title.Text = player.Name.." is requesting help!"
					menu.Frame.PlayerPic.Image = game:GetService("Players"):GetUserThumbnailAsync(player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
					menu.Frame:TweenPosition(UDim2.new(1,-100,0.85,0),"Out","Quad",.5)
					coroutine.wrap(function()
						wait(5)
						menu.Frame:TweenPosition(UDim2.new(1,125,0.85,0),"Out","Quad",.5)
						wait(.5)
						menu:Destroy()
					end)()
				end
			end)()
		end
		if numSentTo > 0 then
			output[#output+1] = "Request sent to all online admins!"
		else
			output[#output+1] = "No online admins to request help from."
			output[#output+1] = string.char(131).. "If you're stuck, try the command 'respawn'."
		end
		return table.concat(output,"\n")
	end,
	[[Send a GUI to all currently online admins requesting help.]],
	[[requesthelp ]]}
	module.all["reqhelp"] = module.all["requesthelp"]
	module.all["rhelp"] = module.all["requesthelp"]
	
	module.all["uptime"] = {function(player,target,params)
		local output = {}
		local hours,mins,secs = 0,0,0
		local DGT = workspace.DistributedGameTime
		secs = math.floor(DGT%60)
		mins = math.floor((DGT/60)%60)
		hours = math.floor(DGT/3600)
		local time_ = hours..":"..string.format("%02d:%02d",mins,secs)
		output[#output+1] = string.char(133).."Uptime: "..time_
		return table.concat(output,"\n")
	end,
	[[Outputs how old the server is into the output console.]],
	[[uptime ]]}
	
	module.all["version"] = {function(player,target,params)
		local output = {}
		local version = bin._version.Value
		output[#output+1] = string.char(129).."VERSION: "..version
		return table.concat(output,"\n")
	end,
	[[Outputs the current version of Console Commands into the output console.]],
	[[version ]]}
	
	module.all["respawn"] = {function(player,target,params)
		local output = {}
		local char = nil; pcall(function() char = player.Character end)
		if not char:FindFirstChild("HumanoidRootPart") then error("No HumanoidRootPart found!") end
		pcall(function()
			player.CharacterAppearanceId = 0 --Appearance Change Catch
			player:LoadCharacter()
		end)
	end,
	[[Respawns the speaker.]],
	[[respawn ]]}
	
	module.all["about"] = {function(player,target,params)
		local output = {}
		output[#output+1] = [[Console Commands Admin Commands (CCAC) by aaaddd & Jallar
is an admin command system designed for 'The Aurbis' TES genre on Roblox.
It features a mix of commands based from the Bethesda games
'Skyrim', 'Oblivion' and 'Morrowind' and many well-known
commands based off of other Roblox admin command systems.]]
		return table.concat(output,"\n")
	end,
	[[Outputs a description of CCAC into the output console.]],
	[[about ]]}
	
	module.all["donate"] = {function(player,target,params)
		local output = {}
		local donate = player.PlayerGui:FindFirstChild("Donate")
		if donate then output[#output+1] = "Donate window already open, thank you for supporting the genre!" 
		else
			donate = bin.Donate:Clone()
			donate.Parent = player.PlayerGui
			output[#output+1] = "Opened donate window, thank you for supporting the genre!"
		end
		return table.concat(output,"\n")
	end,
	[[Brings up a GUI that asks the player if they would like to donate.]],
	[[donate ]]}
	
	module.all["rejoin"] = {function(player,target,params)
		local output = {}
		local targPlace = game.PlaceId
		local targName = game:GetService("MarketplaceService"):GetProductInfo(targPlace).Name
		game:GetService("TeleportService"):Teleport(targPlace,player)
		output[#output+1] = "Rejoining "..targName.." (".. tostring(targPlace) ..")"
		return table.concat(output,"\n")
	end,
	[[Rejoins the game.]],
		[[rejoin ]]}
	
	module.all["qqq"] = {function(player,target,params)
		player:Kick("You have quit the game.")
	end,
	[[Instantly kicks the player from the game.]],
	[[qqq ]]}
	module.all["quitgame"] = module.all["qqq"]
end

return module
