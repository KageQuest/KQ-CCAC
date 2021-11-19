local module = {}

local _version = script.bin._version.Value
local lib = require(script.lib.aaadddLib)
local vim = require(script.lib.VIM2)
local logger = require(script.lib.Log)
local trello_ = script.lib.TrelloAPI; trello_.Parent = game.ServerScriptService; local trello =  require(trello_)
local tBoardId = trello_.BoardID.Value
local HttpService = game:GetService("HttpService")
local httpEnabled = false
local booted = false --flag to track if ccac booted successfully

--Set up collision groups for commands such as 'setghost' or 'tcl'
local PhysicsService = game:GetService("PhysicsService")
PhysicsService:CreateCollisionGroup("players")
PhysicsService:CreateCollisionGroup("ghosts")
PhysicsService:CreateCollisionGroup("noclip")
PhysicsService:CollisionGroupSetCollidable("Default", "players", true)
PhysicsService:CollisionGroupSetCollidable("Default", "ghosts", true)
PhysicsService:CollisionGroupSetCollidable("players", "ghosts", false)
PhysicsService:CollisionGroupSetCollidable("Default", "noclip", false)
PhysicsService:CollisionGroupSetCollidable("players", "noclip", false)
PhysicsService:CollisionGroupSetCollidable("ghosts", "noclip", false)

print("Console Commands Admin Commands Loaded")

local cc = game.ServerScriptService:FindFirstChild("ConsoleCommands") or game.ServerScriptService:WaitForChild("ConsoleCommands")
local cfg = cc.Configuration
local _settings = require(cfg.Settings) --settings are packed to contain both the settings and the admin list
local Settings,adminList = _settings[1],_settings[2]

_G.isServerLocked = false --Preset the serverlock

local commands = {}
commands.owner = {}
commands.admin = {}
commands.mods = {}
commands.all = {}

local _command = game.ReplicatedStorage:FindFirstChild("CCACcommand") or Instance.new("RemoteEvent",game.ReplicatedStorage)
_command.Name = "CCACcommand"; _command.Parent = game.ReplicatedStorage
local guiHandler = game.ReplicatedStorage:FindFirstChild("CCACGuiEvent") or Instance.new("RemoteEvent",game.ReplicatedStorage)
guiHandler.Name = "CCACGuiEvent"; guiHandler.Parent = game.ReplicatedStorage
local pmHandler = game.ReplicatedStorage:FindFirstChild("CCACPMEvent") or Instance.new("RemoteEvent",game.ReplicatedStorage)
pmHandler.Name = "CCACPMEvent"; pmHandler.Parent = game.ReplicatedStorage
local reqHelpHandler = game.ReplicatedStorage:FindFirstChild("reqHelpEvent") or Instance.new("RemoteEvent",game.ReplicatedStorage)
reqHelpHandler.Name = "reqHelpEvent"; reqHelpHandler.Parent = game.ReplicatedStorage

function rank2num(str)
	if str == "Owner" then return 4 end
	if str == "Admin" then return 3 end
	if str == "Mods" then return 2 end
	if str == "All" then return 1 end
end

function num2rank(str)
	if str == 4 then return "Owner" end
	if str == 3 then return "Admin" end
	if str == 2 then return "Mods" end
	if str == 1 then return "All" end
end

local function boot(v)--module insertion
	local pak = require(v)
	for rank,list in pairs(pak) do
		for kay,vee in pairs(list) do
			--check for collision
			if commands[rank][kay] then error("Command Error: Name Collision! colliding name: "..kay.."at rank: "..rank) end
			commands[rank][kay] = vee --add command
		end
	end
end

function loadcmds()
	for k,v in pairs(script.pak:GetChildren()) do 
		if v.Name == "Fun" then
			if Settings.funCommands then boot(v) end
		else
			boot(v)
		end
	end
	boot(cfg.CustomCommands)
end
loadcmds()


function playSound(source,id,vol)
	if not vol then vol = 0.5 end
	local plyr = source
	if plyr then--overwrite player with player's character
		pcall(function()--catch error condition where player's body is nil/destroyed
			local sound = Instance.new("Sound") --Create local sound
			sound.SoundId = id
			sound.MaxDistance = 15
			sound.Parent = plyr.PlayerGui
			sound.Volume = vol
			sound.Playing = true
			while sound.Playing == true do wait() end --Wait until the sound is done playing
			sound:Destroy()
		end)
	end
end


local function popSublist(lists,stringname,targlist)
	for q,e in next,lists do --Pre-check to see if player is in the admin-deletion queue
		if lists[q] ~= nil then
			if lists[q]["name"] == stringname then
				local cards = trello:GetCardsInList(lists[q]["id"]) --Get all cards in list
				local pattern = "(%w+):?(%d+)" --String capture pattern
				for _,c in next,cards do
					local n,i = c["name"]:match(pattern)
					if not lib.isInList(i,targlist) then --If theyre in the queue, add them to a table to check against
						table.insert(targlist,tonumber(i))
					end
				end
			end
		end
	end
end

function popAdmins()
	local lists = trello:GetLists(tBoardId) --Get the board
	popSublist(lists,"Delete Queue",adminList.delQ)
	popSublist(lists,"Owner List",adminList.owners)
	popSublist(lists,"Admin List",adminList.admins)
	popSublist(lists,"Mod List",adminList.mods)
	popSublist(lists,"Ban List",adminList.banned)
end

local function testHttp()
	local test,data
	
	pcall(function()
		test = HttpService:GetAsync("https://httpbin.org/get") --Send a simple Get request to a testing website
		data = HttpService:JSONDecode(test)
	end)
	
	if not data then return false end
	
	if data then return true end --If the request succeeds, continue with CCAC setup
end

local function cmdLook(cmdName)
	if commands.owner[cmdName] then
		return commands.owner[cmdName][1],4,commands.owner[cmdName][2],commands.owner[cmdName][3]
	elseif commands.admin[cmdName] then
		return commands.admin[cmdName][1],3,commands.admin[cmdName][2],commands.admin[cmdName][3]
	elseif commands.mods[cmdName] then
		return commands.mods[cmdName][1],2,commands.mods[cmdName][2],commands.mods[cmdName][3]
	elseif commands.all[cmdName] then
		return commands.all[cmdName][1],1,commands.all[cmdName][2],commands.all[cmdName][3]
	end
end

local function joinMsg(player)
	local players = game.Players:GetChildren()
	for i=1,#players do
		if players[i] then
			spawn(function()
				if players[i].PlayerGui:FindFirstChild("NewPlayer") then repeat wait() until players[i].PlayerGui:FindFirstChild("NewPlayer") == nil end --force message queue
				local screenGui = Instance.new("ScreenGui",players[i].PlayerGui)
				screenGui.Name = "NewPlayer"
				local msg = Instance.new("TextLabel",screenGui)
				msg.BackgroundColor3 = Color3.new(0,0,0)
				msg.BackgroundTransparency = 0.5
				msg.BorderSizePixel = 0
				msg.Size = UDim2.new(1,0,0.05,0)
				msg.Font = "SourceSansBold"
				msg.TextColor3 = Color3.new(255,255,255)
				msg.TextSize = 16
				msg.TextStrokeTransparency = 0.3
				msg.Text = player.Name.." joined, Admin Level: ".. num2rank(vim.checkPrivilege(player))..", Age: "..player.AccountAge
				wait(5)
				for i=msg.BackgroundTransparency,1,.1 do msg.BackgroundTransparency = i wait(.1) end 
				screenGui:Destroy()
			end)
		end
	end
end

local function announceAdmin(player)
	local priv = vim.checkPrivilege(player)
	if priv > 1 then
		local announce = script.bin.AnnounceAdmin:Clone()
		if priv == 2 then announce.Frame.Rank.Text = "You're a mod!" end
		if priv == 3 then announce.Frame.Rank.Text = "You're an admin!" end
		if priv == 4 then announce.Frame.Rank.Text = "You're an owner!" end
		if Settings.chatCommands then 
			announce.Frame.ChatEnabled.Text = "Command usage in chat is enabled on this server! Use '" .. Settings.prefix .. "' in the chat to use commands."
			announce.Frame.ChatEnabled.Visible = true
		end
		announce.Parent = player.PlayerGui
		spawn(function()
			wait(5)
			for i = announce.Frame.BackgroundTransparency,1,.1 do announce.Frame.BackgroundTransparency = i wait(.1) end
			announce:Destroy()
		end)
	end
end

local function commandrun(player,cmd)
	local command, target = table.unpack(cmd)
	if command == "" then return end
	_command:FireClient(player,command) --echo back
	local __command = string.match(command,"[^%s]+") --seperate command from parameters
	local param = string.sub(command,#__command+2,-1)
	command = __command --return seperated command
	local source,sourceId = string.lower(player.Name),player.UserId
	_G.speaker = player
	
	local exec,rank,desc,usage = cmdLook(command)
	
	if exec then
		local priv = vim.checkPrivilege(player)
		print("User: "..source..":"..sourceId..", Priv. Level: "..priv..", Command Level: "..rank)
		if priv >= rank then
			local result = ""
			local success, errormsg = pcall(function() result = exec(player,target,param) end) --actually exeucte the command
			--if not success then error(errormsg) end --Add other error stuff here?
			logger.logCmd(player,cmd)
			
			--discord integration
			local placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
			local Data = {["content"]="[".. lib.ACXTimeStamp() .."] ".. tostring(player) ..": ".. cmd[1] .."\n*Place: "..placeName.."*"}
			Data = HttpService:JSONEncode(Data)
			HttpService:PostAsync("WEBHOOK API HERE",Data)
			
			if result then _command:FireClient(player,result) end
			if not success then _command:FireClient(player,string.char(130).."ERROR:\n"..string.char(137)..errormsg); _command:FireClient(player,string.char(131).."USAGE: "..usage); playSound(player,"rbxassetid://1517077364",5) end --Add other error stuff here?
		else
			--failsound or something
			_command:FireClient(player,string.char(130).."ERROR:\n".. string.char(137).. "Insufficient Admin Level to run command.")
			playSound(player,"rbxassetid://138087015")
		end
	else
		--failsound or something
			_command:FireClient(player,string.char(130).."ERROR:\n".. string.char(137).. "No such command found")
			playSound(player,"rbxassetid://138087015")
	end

end
_command.OnServerEvent:connect(commandrun)

local function onRespawn(player)
	local madenew = false
	if not player.PlayerGui:FindFirstChild("ConsoleCommandsWrapper") then local ccw = script.bin.ConsoleCommandsWrapper:Clone();ccw.Parent = player.PlayerGui; madenew = true end
	local ccw = player.PlayerGui:FindFirstChild("ConsoleCommandsWrapper")
	ccw.permLevel.Value = vim.checkPrivilege(player)
	if not player.PlayerGui:FindFirstChild("Topbar") then local t = script.bin.Topbar:Clone();t.Parent = player.PlayerGui end
	if not player:FindFirstChild("CCACPlayerVals") then local f = script.bin.CCACPlayerVals:Clone();f.Parent = player end
	coroutine.wrap(function() --Default console output
		wait(1)
		if not madenew then return end
_command:FireClient(player,
	string.char(130)..
	"__    __________  _   _______ ____  __    ______   __________  __  _____  ______    _   ______  _____\n"..string.char(131)..
	"\\ \\  / ____/ __ \\/ | / / ___// __ \\/ /   / ____/  / ____/ __ \\/  |/  /  |/  /   |  / | / / __ \\/ ___/\n"..string.char(133)..
	" \\ \\/ /   / / / /  |/ /\\__ \\/ / / / /   / __/    / /   / / / / /|_/ / /|_/ / /| | /  |/ / / / /\\__ \\ \n"..string.char(134)..
	" / / /___/ /_/ / /|  /___/ / /_/ / /___/ /___   / /___/ /_/ / /  / / /  / / ___ |/ /|  / /_/ /___/ / \n"..string.char(137)..
	"/_/\\____/\\____/_/ |_//____/\\____/_____/_____/   \\____/\\____/_/  /_/_/  /_/_/  |_/_/ |_/_____//____/")
_command:FireClient(player,[[By aaaddd and Jallar]])
_command:FireClient(player,string.char(129)..[[VERSION: ]].._version)
			local hours,mins,secs = 0
			local DGT = workspace.DistributedGameTime
			secs = math.floor(DGT%60)
			mins = math.floor((DGT/60)%60)
			hours = math.floor(DGT/3600)
			local time_ = hours..":"..string.format("%02d:%02d",mins,secs)
_command:FireClient(player,string.char(133).."Uptime: "..time_)
	end)()
	coroutine.wrap(function() --Set all parts in the player to the players collision group, for use with the setghost command
		local char = player.Character
		for _,p in pairs(char:GetChildren()) do
			if p:IsA("BasePart") or p:IsA("MeshPart") then
				game:GetService("PhysicsService"):SetPartCollisionGroup(p, "players")
			end
			if p:IsA("Model") then --Not sure if roblox adds models to a player by default, but just in case
				for _,pp in pairs(p:GetChildren()) do
					if pp:IsA("BasePart") or pp:IsA("MeshPart") then
						game:GetService("PhysicsService"):SetPartCollisionGroup(pp, "players")
					end
				end
			end
		end
	end)()
end

local function main(player)
	if lib.isInList(player.UserId,adminList.banned) then player:Kick("You are banned from this game. Bans may be appealed in the genre discord.") end
	
	if _G.isServerLocked then
		local priv = vim.checkPrivilege(player)
		if priv ~= 4 then
			player:Kick("This server is currently locked.")
		end
	end
	
	-- Turn off the use of the topbar button if disabled in settings
	if not Settings.topButton then script.bin.Topbar.Frame.ImageButton.Visible = false end
	onRespawn(player)
	
	announceAdmin(player)
	
	if Settings.chatCommands then --Only allow commands in chat if the Setting is enabled
	end
end

local function closeGui(player,args)
	if args.Parent.Name ~= "PlayerGui" then return end
	args:remove()
end

guiHandler.OnServerEvent:Connect(function(player,arg)
	if arg == "Close" then --Close the GUI
		closeGui(player,player.PlayerGui:FindFirstChild("CommandLog") or player.PlayerGui:FindFirstChild("ChatLog") or player.PlayerGui:FindFirstChild("PMWindow") or player.PlayerGui:FindFirstChild("Donate"))
	end
end)

pmHandler.OnServerEvent:Connect(function(player,respondTo,message)
	local pm = script.bin.PMWindow:Clone()
	pm.Parent = respondTo.PlayerGui
	local event = pm:WaitForChild("UpdateText")
	local sender = pm:FindFirstChild("Sender")
	sender.Value = player
	local mo = vim.getTextObject(message, player.UserId)
	local filtered = ""
	filtered = vim.getFilteredMessage(mo)
	event:FireClient(respondTo,filtered)
	--Discord integration
	local placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
	local msgRecip = respondTo.Name
	local Data = {["content"] = "[".. lib.ACXTimeStamp() .."] ".. player.Name .." (via PM): ".. message .. "\nRecipient: ".. msgRecip .. "\n*Place: ".. placeName .."*"}
	Data = HttpService:JSONEncode(Data)
	HttpService:PostAsync("DISCORD API HERE",Data)
end)

reqHelpHandler.OnServerEvent:Connect(function(player,target)
	target = target.Value --get the player
	local offset = Vector3.new(0,0,-2)
	local char = player.Character
	local hrp = char:FindFirstChild("HumanoidRootPart")
	local targChar = target.Character
	local targHrp = targChar:FindFirstChild("HumanoidRootPart")
	if hrp and targHrp then
		local cf = CFrame.new(offset,Vector3.new(0,0,0))
		hrp.CFrame = targHrp.CFrame:toWorldSpace(cf)
		hrp:MakeJoints()
	end
end)

local function httperror(player)
	local err = script.bin.ErrorPrompt:Clone()
	err.Parent = player.PlayerGui
end

local function runcheck(player)
	booted = true
	popAdmins()
	httpEnabled = testHttp()
	if httpEnabled then
		coroutine.wrap(joinMsg)(player) --show ver here
		main(player)
		player.CharacterAdded:Connect(function() wait(); onRespawn(player) end) --add the gui here
		onRespawn(player)
	else
		--err
		httperror(player)
	end
	print(player.Name,", Admin level: ",num2rank(vim.checkPrivilege(player)))
end
game.Players.PlayerAdded:Connect(runcheck)
logger.initChatLogging()

wait(3)
if not booted then warn("CCAC FORCE BOOT") for k,v in pairs(game.Players:GetPlayers()) do runcheck(v) end end --force boot!
return true
