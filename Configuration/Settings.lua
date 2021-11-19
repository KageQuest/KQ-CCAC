-- Entered values may only be UserIds
-- Example: local banned = {161097}	

local banned = {}				-- Banned people from this place in specific

--[[
	Admin Ranks>Levels
	Owner 		= 4
	Admins 		= 3
	Mods 		= 2
	All / Free 	= 1
--]]

local owners = {}				-- People with access to owner-level commands
local admins = {}				-- People with access to admin-level commands
local mods = {}					-- People with access to mod-level commands
local delQ = {}					-- People in the admin deletion queue (Do not get commands)

local Settings = {

topButton = true;				-- Enables the CCAC Logo that appears in the top bar
--chatCommands = false;			-- Enables the use of commands in chat NOTE: Chat Commands currently deprecated
--prefix = "/";					-- The prefix to be used if commands are enabled in chat
funCommands = true;				-- Enables the use of the "fun" commands
freeAdmin = false;				-- Enables free admin for all users who join
adminLevel = 4;					-- The level of admin to give users if freeAdmin is enabled; 2=Mod, 3=Admin, 4=Owner
publicLogs = false;				-- Enables all users to see chat and command logs

--[[
	Give admin automatically to anyone in a group with specific ranks
	
	Example:
	GroupAdmin = {
		[12345] = { [254] = 3, [50] = 2 }
		[GROUPID] = {[RANK]=ADMINLEVEL, [RANK]=ADMINLEVEL}
	}
--]]


GroupAdmin = {
	
};


}
return {Settings,{owners = owners; admins = admins; mods = mods; banned = banned; delQ = delQ}}
