-- Example.lua
-- This is a script that utilizes most of what you need to use ChatLibrary. 
-- You can use and I advise you use the methods that are in this script, especially LoadChatLibrary!

local function LoadChatLibrary()
    local LibraryPresent = isfolder("ChatLibrary")
    local LoaderURL = "https://raw.githubusercontent.com/KonstanceVRX/VortexChatLib/main/Loader.lua"
    if LibraryPresent == false then
        local Loader = loadstring(game:HttpGet(LoaderURL))()
        return Loader
    else
        if isfile("ChatLibrary/Loader.lua") then
            local Loader = loadstring(readfile("ChatLibrary/Loader.lua"))()
            return Loader
        else
            local Loader = loadstring(game:HttpGet(LoaderURL))()
            return Loader
        end
    end
    return nil
end

local ChatLibrary = LoadChatLibrary() -- You can also just use getgenv().ChatLibrary and execute the necessary functions from there (useful for multiple scripts, no need to load library more than once),
-- loading it into a variable like here would give you the result of the loader, helping you with diagnosing any potential issues like errors

local NetResponse = ChatLibrary.SetNetLibrary(network) -- Example library
local ChatResponse = ChatLibrary.SendChatPacket("Hello, world!")

if ChatResponse.Success == true then
    print("Successfully sent a message! Status from ChatResponse: ", ChatResponse.Status .. " Message from ChatResponse: " .. ChatResponse.Response) -- ChatResponse has .Success, .Status and
    -- optionally a third argument (SendChatPacket returns a third argument as a string in this case)
else    
    warn("Failed to send a message. Error message: " .. ChatResponse.ErrorMessage) -- Errors always have .ErrorMessage, .ErrorReason and .Debug (we're gonna get onto that later)
    warn("Full response:", table.unpack(ChatResponse))
end

if NetResponse.Success == true then
    print("Net library successfully set!")
    -- You get it, the response is the same as chat's, every response no matter error or not has same success boolean
end

local ChatResponse2 = ChatLibrary.SendChatPacket("Lol 123") -- Here we're gonna analyze debug information!
if ChatResponse2.Success == false then
    warn("Failed to send chat packet because of " .. ChatResponse2.ErrorReason .. " | Error message: " .. ChatResponse2.ErrorMessage)
    warn("Checking debug information...") -- Each error also includes a debug table, which helps you identify what caused the error
    local Debug = ChatResponse2.Debug
    local DebugID = Debug.DebugID -- Each debug table has a DebugID and a DebugContent table, DebugID helps you identify which function / code had the error and
    -- DebugContent provides local code-specific variables that could've caused the error
    if ChatResponse2.ErrorReason == "NO_NET_LIB" then -- Real ErrorReason that we're gonna use
        local NetLib = Debug.DebugContent.NetworkLib -- NO_NET_LIB ErrorReason provides enough information for us to know that DebugContent.NetworkLib key is present
        local Message = Debug.DebugContent.Message
        warn("Message inside DebugContent: " .. tostring(Message)) -- DebugContent.Message is a string that contains your message, Lol 123 in this example
        warn("DebugID: " .. DebugID) -- DebugID is SendChatPacket in this example as its the function that experienced an error
        if NetLib == nil then
            warn("Network library is nil!") -- NetworkLib is nil when literally no table was provided as a networking library
        else
            warn("Network library is present, checking for send+create functions") -- send and create functions are essential for Library's work
            if NetLib.send == nil or NetLib.create == nil then
                warn("Either send or create is absent!")
            end
        end
    end
end

-- Now, we're gonna create a compatibility networking library for ChatLibrary.
-- ChatLibrary's networking library requirements are essentially a table with two functions (send and create), and now we're gonna port another executor's networking library
-- into Astra's naming convention (default for ChatLibrary) and if the original networking library works, our custom "library" should work too.
getgenv().AstraNetLib = {
    ["send"] = function(Packet)
        return SpecificExecLib.send(Packet) -- Imagine an executor that uses this library name.
    end,
    ["create"] = function(PacketType: string, Info: table)
        return SpecificExecLib.create(PacketType, Info)
    end
}

table.freeze(getgenv().AstraNetLib)

local NetResponse = ChatLibrary.SetNetLibrary(getgenv().AstraNetLib)

if NetResponse.Success == true then
    print("Networking library successfully set!")
else
    warn("Failed to set new networking library. Error message: " .. NetResponse.ErrorMessage)
    -- Now I could write another deep dive with proper debug analysis and error analysis, but I prefer if you took lessons from ChatResponse2
end
