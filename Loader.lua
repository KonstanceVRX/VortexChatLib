-- Loader for ChatLibrary
-- Requires filesystem, HTTP and loadstring functions
-- This isn't meant to be executed as an editor script or a regular script!
-- Loader version 1 release (total) 1
-- =!1=!

local G = getgenv

local Info = {
    ["LoaderVersion"] = 1,
    ["ReleaseTotal"] = 1
}

local BaseURL = "https://raw.githubusercontent.com/KonstanceVRX/VortexChatLib/main/"
local FolderExists = isfolder("ChatLibrary")

-- Return structuring

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

local function Output(String: string, Table: table)
    print(String)
    print("Table attached below:")
    for k, v in pairs(Table) do
        print(k, v)
    end
end

-- functinosss

local function HTTPGet(URL: string)
    local Response;
    local Success, Failure = pcall(function()
        Response = game:HttpGet(URL)
    end)
    if Success then
        return Response
    else
        local ErrorReason = "PCALL_FAILED"
        local ErrorMessage = "game:Httpget pcall failed due to " .. Failure
        local DebugID = "HTTPGET_PCALL"
        local DebugContent = {
            ["FailReason"] = Failure,
            ["URL"] = URL
        }

        return ConstructError(ErrorReason, ErrorMessage, ConstructDebug(DebugID, DebugContent))
    end
end

local function MissingFile(Path: string, FunctionToExecute)
    if isfile(Path) then
        return true
    else
        writefile(Path, "Autocreated by ChatLibrary")
        return false
    end
    return false
end

local function MakeTheFile(Name: string) -- i couldnt come up with a better name
    if Name and typeof(Name) == "string" then
        local TargetURL = BaseURL .. Name
        local TargetFile = HTTPGet(TargetURL)

        if typeof(TargetFile) == "table" and TargetFile.Success == false then
            return TargetFile
        end

        if TargetFile == nil then
            local ErrorReason = "TARGET_FILE_NIL"
            local ErrorMessage = `Attempted to request file {Name}, nil returned`
            local DebugID = "MakeTheFile_TargetFile"
            local DebugInfo = {
                ["TargetURL"] = TargetURL,
                ["TargetFile"] = TargetFile -- why put if nil anyway
            }

            return ConstructError(ErrorReason, ErrorMessage, ConstructDebug(DebugID, DebugInfo))
        else
            local Success, Failure = pcall(function() writefile("ChatLibrary/"..Name, TargetFile) end)
            
            if Success then
                local UpdateMessage = `Successfully wrote file {Name}!`
                return ConstructResponse(UpdateMessage, TargetFile)
            else
                local ErrorReason = "PCALL_FAILED"
                local ErrorMessage = "writefile pcall failed due to " .. Failure
                local DebugID = "MakeTheFile_PCALL"
                local DebugContent = {
                    ["FailReason"] = Failure,
                    ["Name"] = Name,
                    ["NameWithPath"] = "ChatLibrary/"..Name,
                    ["TargetFile"] = TargetFile
                }

                return ConstructError(ErrorReason, ErrorMessage, ConstructDebug(DebugID, DebugContent))
            end
        end
    else
        local ErrorReason = "INVALID_ARGUMENTS"
        local ErrorMessage = "Name argument wasn't provided or Name's type is invalid!"
        local DebugID = "MakeTheFile"
        local DebugInfo = {
            ["NameArgument"] = Name,
            ["NameType"] = typeof(Name)
        }

        return ConstructError(ErrorReason, ErrorMessage, ConstructDebug(DebugID, DebugInfo))
    end
end

if G().ChatLibrary ~= nil and typeof(G().ChatLibrary) == "table" then
    local ErrorReason = "CHAT_LIBRARY_ALREADY_LOADED"
    local ErrorMessage = "Chat library is already loaded! If it's not the intended chat library, you can remove the table pointer (make it nil) at getgenv().ChatLibrary and re-execute."
    local DebugID = "ChatLibraryAlreadyLoaded"
    local DebugInfo = {
        ["IdentifiedLibrary"] = G().ChatLibrary
    }
    local Debug = ConstructDebug(DebugID, DebugInfo)
    return ConstructError(ErrorReason, ErrorMessage, Debug)
end

if G().ChatLibraryReady == true then
    local Lib = loadstring(readfile("ChatLibrary/Library.lua"))()
    G().ChatLibrary = Lib
    return Lib
end

if FolderExists then
    if isfile("ChatLibrary/Loader.lua") and isfile("ChatLibrary/Library.lua") and isfile("ChatLibrary/LibVersion") then
        local Version = string.split(readfile("ChatLibrary/LibVersion"), " ")[1]
        local NumVersion = tonumber(Version)
        local Proper = NumVersion ~= nil and NumVersion == NumVersion and NumVersion ~= math.huge and NumVersion ~= -math.huge and NumVersion > 0
        if not Proper or NumVersion < Info["ReleaseTotal"] then
            print(`ChatLibrary loader version is outdated! {Version} < {Info["ReleaseTotal"]}, current version {Info["LoaderVersion"]} and release total {Info["ReleaseTotal"]}`)
            print("Initiating loader upgrade...")
    
            local LoaderResult = MakeTheFile("Loader.lua")
            local LibraryResult = MakeTheFile("Library.lua")
            local LibVersionResult = MakeTheFile("LibVersion")

            if LoaderResult.Success == true and LibraryResult.Success == true and LibVersionResult.Success == true then
                G().ChatLibraryReady = true
                return loadstring(readfile("ChatLibrary/Loader.lua"))()
            else
                local ErrorReason = "INSTALL_FAILED"
                local ErrorMessage = "Failed to update ChatLibrary files"
                local DebugID = "ResultSuccessChecks"
                local DebugContent = {
                    ["LoaderResult"] = LoaderResult.Success,
                    ["LibraryResult"] = LibraryResult.Success,
                    ["LibVersionResult"] = LibVersionResult.Success
                }
                local Debug = ConstructDebug(DebugID, DebugContent)

                return ConstructError(ErrorReason, ErrorMessage, Debug)
            end
        else
            G().ChatLibraryReady = true
            return loadstring(readfile("ChatLibrary/Loader.lua"))()
        end
    else
        local LoaderResult = MakeTheFile("Loader.lua")
        local LibraryResult = MakeTheFile("Library.lua")
        local LibVersionResult = MakeTheFile("LibVersion")
        if LoaderResult.Success == true and LibraryResult.Success == true and LibVersionResult.Success == true then
            G().ChatLibraryReady = true
            return loadstring(readfile("ChatLibrary/Loader.lua"))()
        else
            local ErrorReason = "INSTALL_FAILED"
            local ErrorMessage = "Failed to complete a full install"
            local DebugID = "FolderExistsIfStatement"
            local DebugContent = {
                ["LoaderResult"] = LoaderResult.Success,
                ["LibraryResult"] = LibraryResult.Success,
                ["LibVersionResult"] = LibVersionResult.Success
            }
            local Debug = ConstructDebug(DebugID, DebugContent)

            return ConstructError(ErrorReason, ErrorMessage, Debug)
        end
    end
else
    print("Folder doesn't exist, will create all necessary files") -- Because if the main folder doesn't exist, nothing exists in it
    local Success, Failure = pcall(function() makefolder("ChatLibrary") end)
    if Success then
        print("Folder created successfully, proceeding")
        local LoaderResult = MakeTheFile("Loader.lua")
        local LibraryResult = MakeTheFile("Library.lua")
        local LibVersionResult = MakeTheFile("LibVersion")

        if LoaderResult.Success == true and LibraryResult.Success == true and LibVersionResult.Success == true then
            G().ChatLibraryReady = true
            return loadstring(readfile("ChatLibrary/Loader.lua"))()
        else
            local ErrorReason = "INSTALL_FAILED"
            local ErrorMessage = "Failed to update ChatLibrary files"
            local DebugID = "ResultSuccessChecks"
            local DebugContent = {
                ["LoaderResult"] = LoaderResult.Success,
                ["LibraryResult"] = LibraryResult.Success,
                ["LibVersionResult"] = LibVersionResult.Success
            }
            local Debug = ConstructDebug(DebugID, DebugContent)

            return ConstructError(ErrorReason, ErrorMessage, Debug)
        end
    else
        print("Unable to create folder due to " .. Failure)
        return "Unable to create folder due to " .. Failure
    end
end
