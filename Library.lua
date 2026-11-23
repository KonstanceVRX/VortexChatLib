-- Chat library for Vortex
-- Currently only Astra is supported since they're the only ones with easily available documentation, although I put implementation for my own network exploit too (vrxnetpwner)
-- Some of the functions here were adapted from my own chat implementation at https://github.com/luarsky/iyve/blob/master/source , which themselves were adapted for the Infinite Yield Vortex Edition project

local G = getgenv

local Info = {
  ["LibName"] = "ChatLibrary",
  ["ReleaseVersion"] = 1,
  ["LibraryVersion"] = 1
}

local NetworkLib = network or Network -- hmu if your executor uses a different networking library
setclipboard = setclipboard or SetClipBoard or toclipboard or (Clipboard and Clipboard.Set) or (clipboard and clipboard.set) or function(...) --[[ Do nothing! ]] end

local function ConstructDebug(DebugID: string, DebugContent: table)
    if DebugID and DebugContent and typeof(DebugID) == "string" and typeof(DebugContent) == "table" then
        local Debug = {
            ["DebugID"] = DebugID,
            ["DebugContent"] = DebugContent
        }

        return Debug
    end

    -- cant i just make a "raw" function that will take input without checking anything and returning finished construct while i turn these functions into wrappers? meh, too many functions
    local Debug = {
        ["DebugID"] = "ConstructDebug",
        ["DebugContent"] = {
            ["ProvidedContent"] = DebugContent
        }
    }

    return Debug
end

local function ConstructResponse(Status: string, Response) -- is it even correct to call it a status?
    if Status and typeof(Status) == "string" then
        local ResponseTable = {
            ["Success"] = true,
            ["Status"] = Status,
            ["Response"] = Response
        }

        return ResponseTable
    end

    local DebugID = "ConstructResponse"
    local DebugInfo = {
        ["Status"] = Status,
        ["Response"] = Response
    }

    return ConstructDebug(DebugID, DebugInfo) 
end

local function ConstructError(ErrorReason: string, ErrorMessage: string, Debug: table)
    if ErrorReason and ErrorMessage and Debug and typeof(ErrorReason) == "string" and typeof(ErrorMessage) == "string" and typeof(Debug) == "table" then
        return {
            ["Success"] = false,
            ["ErrorReason"] = ErrorReason,
            ["ErrorMessage"] = ErrorMessage,
            ["Debug"] = Debug
        }
    end

	local DebugID = "ConstructError"
    local DebugInfo = {
		["WARNING_FOR_DEVS"] = "You're examining the arguments passed to ConstructError function, not anything else!",
        ["ErrorReason"] = ErrorReason,
        ["ErrorMessage"] = ErrorMessage,
		["Debug"] = Debug
    }

    return ConstructDebug(DebugID, DebugInfo) 
end

-- Internal functions, im pretty sure GetCharMap can be replaced with a simple string.byte but whatever, this works

local function GetCharMap()
	local CharMap = {
		["0"] = 0x30,
		["1"] = 0x31,
		["2"] = 0x32,
		["3"] = 0x33,
		["4"] = 0x34,
		["5"] = 0x35,
		["6"] = 0x36,
		["7"] = 0x37,
		["8"] = 0x38,
		["9"] = 0x39,

		["-"] = 0x2D,
		["="] = 0x3D,

		["Q"] = 0x51,
		["W"] = 0x57,
		["E"] = 0x45,
		["R"] = 0x52,
		["T"] = 0x54,
		["Y"] = 0x59,
		["U"] = 0x55,
		["I"] = 0x49,
		["O"] = 0x4F,
		["P"] = 0x50,
		["["] = 0x5B,
		["]"] = 0x5D,

		["A"] = 0x41,
		["S"] = 0x53,
		["D"] = 0x44,
		["F"] = 0x46,
		["G"] = 0x47,
		["H"] = 0x48,
		["J"] = 0x4A,
		["K"] = 0x4B,
		["L"] = 0x4C,
		[";"] = 0x3B,
		["'"] = 0x27,

		["Z"] = 0x5A,
		["X"] = 0x58,
		["C"] = 0x43,
		["V"] = 0x56,
		["B"] = 0x42,
		["N"] = 0x4E,
		["M"] = 0x4D,
		[","] = 0x2C,
		["."] = 0x2E,
		["/"] = 0x2F,

		["`"] = 0x60,
		[" "] = 0x20,
		["\\"] = 0x5C,

		["*"] = 0x2A,
		["<"] = 0x3C,
		[">"] = 0x3E,
		["?"] = 0x3F,
		["!"] = 0x21,
		["@"] = 0x40,
		["#"] = 0x23,
		["$"] = 0x24,
		["%"] = 0x25,
		["^"] = 0x5E,
		["&"] = 0x26,
		["("] = 0x28,
		[")"] = 0x29,

		["q"] = 0x71,
		["w"] = 0x77,
		["e"] = 0x65,
		["r"] = 0x72,
		["t"] = 0x74,
		["y"] = 0x79,
		["u"] = 0x75,
		["i"] = 0x69,
		["o"] = 0x6F,
		["p"] = 0x70,
		["a"] = 0x61,
		["s"] = 0x73,
		["d"] = 0x64,
		["f"] = 0x66,
		["g"] = 0x67,
		["h"] = 0x68,
		["j"] = 0x6A,
		["k"] = 0x6B,
		["l"] = 0x6C,
		["z"] = 0x7A,
		["x"] = 0x78,
		["c"] = 0x63,
		["v"] = 0x76,
		["b"] = 0x62,
		["n"] = 0x6E,
		["m"] = 0x6D,
	}

	return table.freeze(CharMap)

end

local function ToHex(Number: number)
	return string.format("%X", Number)
end

local function ToDec(Hex: string)
	return tonumber(Hex, 16)
end

local function TextLength(Message: string)
	local Length = string.len(Message)
	if Length < 16 then
		return "0"..ToHex(Length)
	else
		return ToHex(Length) 
	end
end

local function StringToBytes(String: string)
	local SplitString = string.split(String, "")
	local Temp = {}
	local CharMap = GetCharMap()

	for _, Char in pairs(SplitString) do
		if Char ~= nil then
			table.insert(Temp, ToHex(CharMap[Char] or CharMap["?"]))
		end
	end

	return table.concat(Temp, "")
end

local function ConstructRawPacket(Username: string, Text: string)
	local Packet = "0200000002C6010000000000" 
	.. TextLength(Username) 
	.. "00000000000000" 
	.. StringToBytes(Username) 
	.. TextLength(Text) 
	.. "00000000000000"
	.. StringToBytes(Text) .. "00"
	return Packet
end

-- The real deal

local function LSendChatPacket(Message: string)
	Message = tostring(Message)
	if NetworkLib then
		-- Astra
		if typeof(NetworkLib.create) == "function" and typeof(NetworkLib.send) == "function" then
			local ChatPacket;
			local ChatSuccess, ChatFail = pcall(function() 
				ChatPacket = NetworkLib.create("Chat", {
				username = game.Players.LocalPlayer.Name,
				text = Message,
			}) 
			end)
			
			local NetSuccess, NetFail = pcall(function()
				NetworkLib.send(ChatPacket)
			end)
			
			if ChatSuccess and NetSuccess then
				return ConstructResponse("ChatMessageSent", "Chat message successfully passed to NetworkLib.send! Expect a chat message to appear.")
			else
				local ErrorReason = "PCALL_FAILED"
				local ErrorMessage = `pcall failed: ChatPacket: {(ChatFail or "nil")} | SendFunction: {(NetFail or "nil")}`
				local DebugID = "SendChatPacket"
				local DebugInfo = {
					["ChatSuccess"] = ChatSuccess,
					["NetSuccess"] = NetSuccess,
					["ChatFailMessage"] = (ChatFail or "nil"),
					["NetFailMessage"] = (NetFail or "nil")
				}
				local Debug = ConstructDebug(DebugID, DebugInfo)

				return ConstructError(ErrorReason, ErrorMessage, Debug)
			end
		else
			local ErrorReason = "INSUFFICIENT_NET_LIBRARY"
        	local ErrorMessage = "Library doesn't have either send or create, both are essential for ChatLibrary's function."
        	local DebugID = "SendChatPacket"
        	local DebugInfo = {
            	["NetworkLib"] = NetworkLib,
            	["Message"] = Message
            	-- tbh not able to add much because there's no debug library like in roblox
        	}
        	local Debug = ConstructDebug(DebugID, DebugInfo)

        	return ConstructError(ErrorReason, ErrorMessage, Debug)
		end
	else
		setclipboard(ConstructRawPacket(game.Players.LocalPlayer.Name, Message))
		local ErrorReason = "NO_NET_LIB"
        local ErrorMessage = "Networking library not found! You can manually set the networking library using SetNetLibrary. Attempted to copy raw packet to clipboard."
        local DebugID = "SendChatPacket"
        local DebugInfo = {
            ["NetworkLib"] = NetworkLib,
            ["Message"] = Message
            -- tbh not able to add much because there's no debug library like in roblox
        }
        local Debug = ConstructDebug(DebugID, DebugInfo)

        return ConstructError(ErrorReason, ErrorMessage, Debug)
		--print(ConstructRawPacket(owner.Name, Message))
	end
end

local function LSetNetLibrary(Library: table)
	if typeof(Library) == "table" then
		if rawget(Library, "send") and rawget(Library, "create") then
			NetworkLib = Library
			return ConstructResponse("NetLibrarySet", "Library successfully linked and send/create functions located!")
		else
			local ErrorReason = "INSUFFICIENT_NET_LIBRARY"
			local ErrorMessage = "Library doesn't have either send or create, both are essential for ChatLibrary's function."
			local DebugID = "SetNetLibrary"
			local DebugContent = {
				["ProvidedLibrary"] = Library,
				["CurrentLibrary"] = NetworkLib
			}
			local Debug = ConstructDebug(DebugID, DebugContent)

			return ConstructError(ErrorReason, ErrorMessage, Debug)
		end
	else
		local ErrorReason = "INVALID_TYPE"
		local ErrorMessage = "Library provided isn't a table!"
		local DebugID = "SetNetLibrary"
		local DebugContent = {
			["ProvidedLibrary"] = Library,
			["CurrentLibrary"] = NetworkLib
		}
		local Debug = ConstructDebug(DebugID, DebugContent)

		return ConstructError(ErrorReason, ErrorMessage, Debug)
	end
end

-- Returning library

local Lib = {
	["Info"] = Info,

	["SetNetLibrary"] = function(Library: table)
		return LSetNetLibrary(Library)
	end,

	["SendChatPacket"] = function(Message: string)
		return LSendChatPacket(Message)
	end
}

table.freeze(Lib)

return Lib -- All of that just for 11 lines of code... even less than before
