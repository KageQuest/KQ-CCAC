--Voodo Internal Module 2.0
local lib = require(script.Parent.aaadddLib)
local cc = game.ServerScriptService:FindFirstChild("ConsoleCommands") or game.ServerScriptService:WaitForChild("ConsoleCommands")
local cfg = cc.Configuration
local _settings = require(cfg.Settings) --settings are packed to contain both the settings and the admin list
local Settings,adminList = _settings[1],_settings[2]

local TextService = game:GetService("TextService")

local module = {}

local function groupadmincheck(player)
	local adminlevel = 1
	for k,v in pairs(Settings.GroupAdmin) do
		if player:isInGroup(k) then
			local ranque = player:GetRankInGroup(k)
			for rank, level in pairs(v) do
				if ranque>=rank then adminlevel = math.max(adminlevel,level) end
			end
		end
	end
	return adminlevel
end

local function checkPrivilege(player)
	local adminlevel = 1
	adminlevel = math.max(adminlevel,4*lib.bool2num(lib.isInList(player.UserId,adminList.owners))) --owner level
	adminlevel = math.max(adminlevel,3*lib.bool2num(lib.isInList(player.UserId,adminList.admins ))) --admin level
	adminlevel = math.max(adminlevel,2*lib.bool2num(lib.isInList(player.UserId,adminList.mods  ))) --mod level
	adminlevel = math.max(adminlevel,groupadmincheck(player)) --group rank check
	adminlevel = (not lib.isInList(player.UserId,adminList.delQ)) and adminlevel or 1 --remove admin if in the delete queue
	if Settings.freeAdmin then adminlevel = Settings.adminLevel end
	return adminlevel
end

local function argsplit(str)
	
	local args = {}
	for w in string.gmatch(str, "[^%s]+") do --Split the message
		table.insert(args,w) --Adds the rest of the args to a table
	end
	
	local args2 = {} --used for second pass to allow quotes with spaces
	local tempstr = ""
	local instring = false
	for k,v in pairs(args) do
		local quote = string.find(v,"\"")
		if quote == 1 then
			tempstr = string.sub(v,2,-1)
			instring = true
		elseif quote == #v and instring then
			tempstr = tempstr .. " ".. string.sub(v,1,-2)
			table.insert(args2,tempstr)
			instring = false
		else
			if instring then tempstr = tempstr .. " " .. v;
			else table.insert(args2,v)
			end
		end
	end
	if instring then error("SYNTAX ERROR: MISSING END OF STRING!") end
	return args2
end

function findFirstPlayer(name,players)
	for _,child in pairs(players) do
		if child.Name == name then return child end
	end
	return nil
end

local function matchname(_player,name)
	local players = game.Players:GetPlayers()
	if name == "*" or name == "all" then return players end
	if name == "me" or name == "player" then --[[print("me",type(_player))]] return {_player} end
	if name == "others" then return lib.allMatching(players, function(a) return a.UserId ~= _player.UserId end )	end
	if name == "rand" or name == "random" or name == "?" then return {players[math.random(1,#players)]} end
	
	--if true then --something about checking selectors/asterisk here?
		local function getShort(player)
			local sub = string.sub(name,1,-1) --something about cutting off the last char which is "guaranteed to be an asterisk"?
			local index = string.find(string.lower(player.Name), string.lower(sub),1,true)
			return index == 1 --if index == 1 then its a match
		end
		local result = lib.allMatching(players,getShort)
		return result
end

local function matchnames(player,splitArgs)
	local selectedPlayers = {}
	for k,v in pairs(splitArgs) do
			local matchedNames = matchname(player,v)
			selectedPlayers = lib.listconcat(selectedPlayers,matchedNames)
	end
	return selectedPlayers
end

local function selectargs(player,target,params)
	--local para = 
	local names = matchnames(player,argsplit(params))
	local args = (target and not (#names>0)) and {target} or names --select the target if there is one, otherwise select based on params
	return (not args[1] and not (#names>0)) and {player} or args --select the player only if there are no params
end

local function splitNamesAndArgs(player,str)
	local args = argsplit(str) --split args into sections
	local names = {}
	for k,v in pairs(args) do --get names and remove from args
		local matches = matchname(player,v)
		names = lib.listconcat(names,matches)
		if #matches > 0 then table.remove(args,k) end
	end
	if #names == 0 then table.insert(names,player) end
	return names,args
end

local function getTextObject(message, fromPlayerId)
	local textObject
	local success, errorMessage = pcall(function()
		textObject = TextService:FilterStringAsync(message, fromPlayerId)
	end)
	if success then return textObject
	elseif errorMessage then
		print("Error generating TextFiltering result: ", errorMessage)
	end
	return false
end

local function getFilteredMessage(textObject)
	local filteredMessage
	local success, errorMessage = pcall(function()
		filteredMessage = textObject:GetNonChatStringForBroadcastAsync()
	end)
	if success then
		return filteredMessage
	elseif errorMessage then
		print("Error filtering message:", errorMessage)
	end
	return false
end

module.argsplit = argsplit
module.matchname = matchname
module.matchnames = matchnames
module.selectargs = selectargs
module.groupadmincheck = groupadmincheck
module.checkPrivilege = checkPrivilege
module.splitNamesAndArgs = splitNamesAndArgs
module.getTextObject = getTextObject
module.getFilteredMessage = getFilteredMessage
return module
