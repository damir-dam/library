--[[

	Rayfield Interface Suite
	by Sirius

	shlex  | Designing + Programming
	iRay   | Programming
	Max    | Programming
	Damian | Programming

]]

if debugX then
	warn('Initialising Rayfield')
end

local function getService(name)
	local service = game:GetService(name)
	return if cloneref then cloneref(service) else service
end

-- Loads and executes a function hosted on a remote URL. Cancels the request if the requested URL takes too long to respond.
-- Errors with the function are caught and logged to the output
local function loadWithTimeout(url: string, timeout: number?): ...any
	assert(type(url) == "string", "Expected string, got " .. type(url))
	timeout = timeout or 5
	local requestCompleted = false
	local success, result = false, nil

	local requestThread = task.spawn(function()
		local fetchSuccess, fetchResult = pcall(game.HttpGet, game, url) -- game:HttpGet(url)
		-- If the request fails the content can be empty, even if fetchSuccess is true
		if not fetchSuccess or #fetchResult == 0 then
			if #fetchResult == 0 then
				fetchResult = "Empty response" -- Set the error message
			end
			success, result = false, fetchResult
			requestCompleted = true
			return
		end
		local content = fetchResult -- Fetched content
		local execSuccess, execResult = pcall(function()
			return loadstring(content)()
		end)
		success, result = execSuccess, execResult
		requestCompleted = true
	end)

	local timeoutThread = task.delay(timeout, function()
		if not requestCompleted then
			warn(`Request for {url} timed out after {timeout} seconds`)
			task.cancel(requestThread)
			result = "Request timed out"
			requestCompleted = true
		end
	end)

	-- Wait for completion or timeout
	while not requestCompleted do
		task.wait()
	end
	-- Cancel timeout thread if still running when request completes
	if coroutine.status(timeoutThread) ~= "dead" then
		task.cancel(timeoutThread)
	end
	if not success then
		warn(`Failed to process {url}: {result}`)
	end
	return if success then result else nil
end

local requestsDisabled = true --getgenv and getgenv().DISABLE_RAYFIELD_REQUESTS
local InterfaceBuild = '3K3W'
local Release = "Build 1.68"
local RayfieldFolder = "Rayfield"
local ConfigurationFolder = RayfieldFolder.."/Configurations"
local ConfigurationExtension = ".rfld"
local settingsTable = {
	General = {
		-- if needs be in order just make getSetting(name)
		rayfieldOpen = {Type = 'bind', Value = 'K', Name = 'Rayfield Keybind'},
		-- buildwarnings
		-- rayfieldprompts

	},
	System = {
		usageAnalytics = {Type = 'toggle', Value = true, Name = 'Anonymised Analytics'},
	}
}

-- Settings that have been overridden by the developer. These will not be saved to the user's configuration file
-- Overridden settings always take precedence over settings in the configuration file, and are cleared if the user changes the setting in the UI
local overriddenSettings: { [string]: any } = {} -- For example, overriddenSettings["System.rayfieldOpen"] = "J"
local function overrideSetting(category: string, name: string, value: any)
	overriddenSettings[`{category}.{name}`] = value
end

local function getSetting(category: string, name: string): any
	if overriddenSettings[`{category}.{name}`] ~= nil then
		return overriddenSettings[`{category}.{name}`]
	elseif settingsTable[category][name] ~= nil then
		return settingsTable[category][name].Value
	end
end

-- If requests/analytics have been disabled by developer, set the user-facing setting to false as well
if requestsDisabled then
	overrideSetting("System", "usageAnalytics", false)
end

local HttpService = getService('HttpService')
local RunService = getService('RunService')

-- Environment Check
local useStudio = RunService:IsStudio() or false

local settingsCreated = false
local settingsInitialized = false -- Whether the UI elements in the settings page have been set to the proper values
local cachedSettings
local prompt = useStudio and require(script.Parent.prompt) or loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Sirius/refs/heads/request/prompt.lua')
local requestFunc = (syn and syn.request) or (fluxus and fluxus.request) or (http and http.request) or http_request or request

-- Validate prompt loaded correctly
if not prompt and not useStudio then
	warn("Failed to load prompt library, using fallback")
	prompt = {
		create = function() end -- No-op fallback
	}
end



local function loadSettings()
	local file = nil

	local success, result =	pcall(function()
		task.spawn(function()
			if isfolder and isfolder(RayfieldFolder) then
				if isfile and isfile(RayfieldFolder..'/settings'..ConfigurationExtension) then
					file = readfile(RayfieldFolder..'/settings'..ConfigurationExtension)
				end
			end

			-- for debug in studio
			if useStudio then
				file = [[
		{"General":{"rayfieldOpen":{"Value":"K","Type":"bind","Name":"Rayfield Keybind","Element":{"HoldToInteract":false,"Ext":true,"Name":"Rayfield Keybind","Set":null,"CallOnChange":true,"Callback":null,"CurrentKeybind":"K"}}},"System":{"usageAnalytics":{"Value":false,"Type":"toggle","Name":"Anonymised Analytics","Element":{"Ext":true,"Name":"Anonymised Analytics","Set":null,"CurrentValue":false,"Callback":null}}}}
	]]
			end


			if file then
				local success, decodedFile = pcall(function() return HttpService:JSONDecode(file) end)
				if success then
					file = decodedFile
				else
					file = {}
				end
			else
				file = {}
			end


			if not settingsCreated then 
				cachedSettings = file
				return
			end

			if file ~= {} then
				for categoryName, settingCategory in pairs(settingsTable) do
					if file[categoryName] then
						for settingName, setting in pairs(settingCategory) do
							if file[categoryName][settingName] then
								setting.Value = file[categoryName][settingName].Value
								setting.Element:Set(getSetting(categoryName, settingName))
							end
						end
					end
				end
			end
			settingsInitialized = true
		end)
	end)

	if not success then 
		if writefile then
			warn('Rayfield had an issue accessing configuration saving capability.')
		end
	end
end

if debugX then
	warn('Now Loading Settings Configuration')
end

loadSettings()

if debugX then
	warn('Settings Loaded')
end

local analyticsLib
local sendReport = function(ev_n, sc_n) warn("Failed to load report function") end
if not requestsDisabled then
	if debugX then
		warn('Querying Settings for Reporter Information')
	end	
	analyticsLib = loadWithTimeout("https://analytics.sirius.menu/script")
	if not analyticsLib then
		warn("Failed to load analytics reporter")
		analyticsLib = nil
	elseif analyticsLib and type(analyticsLib.load) == "function" then
		analyticsLib:load()
	else
		warn("Analytics library loaded but missing load function")
		analyticsLib = nil
	end
	sendReport = function(ev_n, sc_n)
		if not (type(analyticsLib) == "table" and type(analyticsLib.isLoaded) == "function" and analyticsLib:isLoaded()) then
			warn("Analytics library not loaded")
			return
		end
		if useStudio then
			print('Sending Analytics')
		else
			if debugX then warn('Reporting Analytics') end
			analyticsLib:report(
				{
					["name"] = ev_n,
					["script"] = {["name"] = sc_n, ["version"] = Release}
				},
				{
					["version"] = InterfaceBuild
				}
			)
			if debugX then warn('Finished Report') end
		end
	end
	if cachedSettings and (#cachedSettings == 0 or (cachedSettings.System and cachedSettings.System.usageAnalytics and cachedSettings.System.usageAnalytics.Value)) then
		sendReport("execution", "Rayfield")
	elseif not cachedSettings then
		sendReport("execution", "Rayfield")
	end
end

local promptUser = 2

if promptUser == 1 and prompt and type(prompt.create) == "function" then
	prompt.create(
		'Be cautious when running scripts',
	    [[Please be careful when running scripts from unknown developers. This script has already been ran.

<font transparency='0.3'>Some scripts may steal your items or in-game goods.</font>]],
		'Okay',
		'',
		function()

		end
	)
end

if debugX then
	warn('Moving on to continue initialisation')
end

local RayfieldLibrary = {
	Flags = {},
	Theme = {
		Default = {
			TextColor = Color3.fromRGB(255, 255, 255),

			Background = Color3.fromRGB(0, 100, 0),
			Topbar = Color3.fromRGB(0, 150, 0),
			Shadow = Color3.fromRGB(0, 50, 0),

			NotificationBackground = Color3.fromRGB(0, 120, 0),
			NotificationActionsBackground = Color3.fromRGB(255, 215, 0),

			TabBackground = Color3.fromRGB(139, 69, 19),
			TabStroke = Color3.fromRGB(160, 82, 45),
			TabBackgroundSelected = Color3.fromRGB(255, 0, 0),
			TabTextColor = Color3.fromRGB(255, 255, 255),
			SelectedTabTextColor = Color3.fromRGB(255, 255, 0),

			ElementBackground = Color3.fromRGB(0, 128, 0),
			ElementBackgroundHover = Color3.fromRGB(0, 160, 0),
			SecondaryElementBackground = Color3.fromRGB(0, 100, 0),
			ElementStroke = Color3.fromRGB(255, 215, 0),
			SecondaryElementStroke = Color3.fromRGB(255, 255, 255),

			SliderBackground = Color3.fromRGB(255, 0, 0),
			SliderProgress = Color3.fromRGB(0, 255, 0),
			SliderStroke = Color3.fromRGB(255, 255, 0),

			ToggleBackground = Color3.fromRGB(0, 100, 0),
			ToggleEnabled = Color3.fromRGB(255, 0, 0),
			ToggleDisabled = Color3.fromRGB(128, 128, 128),
			ToggleEnabledStroke = Color3.fromRGB(255, 255, 0),
			ToggleDisabledStroke = Color3.fromRGB(192, 192, 192),
			ToggleEnabledOuterStroke = Color3.fromRGB(255, 215, 0),
			ToggleDisabledOuterStroke = Color3.fromRGB(128, 128, 128),

			DropdownSelected = Color3.fromRGB(0, 160, 0),
			DropdownUnselected = Color3.fromRGB(0, 120, 0),

			InputBackground = Color3.fromRGB(0, 100, 0),
			InputStroke = Color3.fromRGB(255, 215, 0),
			PlaceholderColor = Color3.fromRGB(255, 255, 255)
		},

		Ocean = {
			TextColor = Color3.fromRGB(230, 240, 240),

			Background = Color3.fromRGB(20, 30, 30),
			Topbar = Color3.fromRGB(25, 40, 40),
			Shadow = Color3.fromRGB(15, 20, 20),

			NotificationBackground = Color3.fromRGB(25, 35, 35),
			NotificationActionsBackground = Color3.fromRGB(230, 240, 240),

			TabBackground = Color3.fromRGB(40, 60, 60),
			TabStroke = Color3.fromRGB(50, 70, 70),
			TabBackgroundSelected = Color3.fromRGB(100, 180, 180),
			TabTextColor = Color3.fromRGB(210, 230, 230),
			SelectedTabTextColor = Color3.fromRGB(20, 50, 50),

			ElementBackground = Color3.fromRGB(30, 50, 50),
			ElementBackgroundHover = Color3.fromRGB(40, 60, 60),
			SecondaryElementBackground = Color3.fromRGB(30, 45, 45),
			ElementStroke = Color3.fromRGB(45, 70, 70),
			SecondaryElementStroke = Color3.fromRGB(40, 65, 65),

			SliderBackground = Color3.fromRGB(0, 110, 110),
			SliderProgress = Color3.fromRGB(0, 140, 140),
			SliderStroke = Color3.fromRGB(0, 160, 160),

			ToggleBackground = Color3.fromRGB(30, 50, 50),
			ToggleEnabled = Color3.fromRGB(0, 130, 130),
			ToggleDisabled = Color3.fromRGB(70, 90, 90),
			ToggleEnabledStroke = Color3.fromRGB(0, 160, 160),
			ToggleDisabledStroke = Color3.fromRGB(85, 105, 105),
			ToggleEnabledOuterStroke = Color3.fromRGB(50, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(45, 65, 65),

			DropdownSelected = Color3.fromRGB(30, 60, 60),
			DropdownUnselected = Color3.fromRGB(25, 40, 40),

			InputBackground = Color3.fromRGB(30, 50, 50),
			InputStroke = Color3.fromRGB(50, 70, 70),
			PlaceholderColor = Color3.fromRGB(140, 160, 160)
		},

		AmberGlow = {
			TextColor = Color3.fromRGB(255, 245, 230),

			Background = Color3.fromRGB(45, 30, 20),
			Topbar = Color3.fromRGB(55, 40, 25),
			Shadow = Color3.fromRGB(35, 25, 15),

			NotificationBackground = Color3.fromRGB(50, 35, 25),
			NotificationActionsBackground = Color3.fromRGB(245, 230, 215),

			TabBackground = Color3.fromRGB(75, 50, 35),
			TabStroke = Color3.fromRGB(90, 60, 45),
			TabBackgroundSelected = Color3.fromRGB(230, 180, 100),
			TabTextColor = Color3.fromRGB(250, 220, 200),
			SelectedTabTextColor = Color3.fromRGB(50, 30, 10),

			ElementBackground = Color3.fromRGB(60, 45, 35),
			ElementBackgroundHover = Color3.fromRGB(70, 50, 40),
			SecondaryElementBackground = Color3.fromRGB(55, 40, 30),
			ElementStroke = Color3.fromRGB(85, 60, 45),
			SecondaryElementStroke = Color3.fromRGB(75, 50, 35),

			SliderBackground = Color3.fromRGB(220, 130, 60),
			SliderProgress = Color3.fromRGB(250, 150, 75),
			SliderStroke = Color3.fromRGB(255, 170, 85),

			ToggleBackground = Color3.fromRGB(55, 40, 30),
			ToggleEnabled = Color3.fromRGB(240, 130, 30),
			ToggleDisabled = Color3.fromRGB(90, 70, 60),
			ToggleEnabledStroke = Color3.fromRGB(255, 160, 50),
			ToggleDisabledStroke = Color3.fromRGB(110, 85, 75),
			ToggleEnabledOuterStroke = Color3.fromRGB(200, 100, 50),
			ToggleDisabledOuterStroke = Color3.fromRGB(75, 60, 55),

			DropdownSelected = Color3.fromRGB(70, 50, 40),
			DropdownUnselected = Color3.fromRGB(55, 40, 30),

			InputBackground = Color3.fromRGB(60, 45, 35),
			InputStroke = Color3.fromRGB(90, 65, 50),
			PlaceholderColor = Color3.fromRGB(190, 150, 130)
		},

		Light = {
			TextColor = Color3.fromRGB(40, 40, 40),

			Background = Color3.fromRGB(245, 245, 245),
			Topbar = Color3.fromRGB(230, 230, 230),
			Shadow = Color3.fromRGB(200, 200, 200),

			NotificationBackground = Color3.fromRGB(250, 250, 250),
			NotificationActionsBackground = Color3.fromRGB(240, 240, 240),

			TabBackground = Color3.fromRGB(235, 235, 235),
			TabStroke = Color3.fromRGB(215, 215, 215),
			TabBackgroundSelected = Color3.fromRGB(255, 255, 255),
			TabTextColor = Color3.fromRGB(80, 80, 80),
			SelectedTabTextColor = Color3.fromRGB(0, 0, 0),

			ElementBackground = Color3.fromRGB(240, 240, 240),
			ElementBackgroundHover = Color3.fromRGB(225, 225, 225),
			SecondaryElementBackground = Color3.fromRGB(235, 235, 235),
			ElementStroke = Color3.fromRGB(210, 210, 210),
			SecondaryElementStroke = Color3.fromRGB(210, 210, 210),

			SliderBackground = Color3.fromRGB(150, 180, 220),
			SliderProgress = Color3.fromRGB(100, 150, 200), 
			SliderStroke = Color3.fromRGB(120, 170, 220),

			ToggleBackground = Color3.fromRGB(220, 220, 220),
			ToggleEnabled = Color3.fromRGB(0, 146, 214),
			ToggleDisabled = Color3.fromRGB(150, 150, 150),
			ToggleEnabledStroke = Color3.fromRGB(0, 170, 255),
			ToggleDisabledStroke = Color3.fromRGB(170, 170, 170),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 100, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(180, 180, 180),

			DropdownSelected = Color3.fromRGB(230, 230, 230),
			DropdownUnselected = Color3.fromRGB(220, 220, 220),

			InputBackground = Color3.fromRGB(240, 240, 240),
			InputStroke = Color3.fromRGB(180, 180, 180),
			PlaceholderColor = Color3.fromRGB(140, 140, 140)
		},

		Amethyst = {
			TextColor = Color3.fromRGB(240, 240, 240),

			Background = Color3.fromRGB(30, 20, 40),
			Topbar = Color3.fromRGB(40, 25, 50),
			Shadow = Color3.fromRGB(20, 15, 30),

			NotificationBackground = Color3.fromRGB(35, 20, 40),
			NotificationActionsBackground = Color3.fromRGB(240, 240, 250),

			TabBackground = Color3.fromRGB(60, 40, 80),
			TabStroke = Color3.fromRGB(70, 45, 90),
			TabBackgroundSelected = Color3.fromRGB(180, 140, 200),
			TabTextColor = Color3.fromRGB(230, 230, 240),
			SelectedTabTextColor = Color3.fromRGB(50, 20, 50),

			ElementBackground = Color3.fromRGB(45, 30, 60),
			ElementBackgroundHover = Color3.fromRGB(50, 35, 70),
			SecondaryElementBackground = Color3.fromRGB(40, 30, 55),
			ElementStroke = Color3.fromRGB(70, 50, 85),
			SecondaryElementStroke = Color3.fromRGB(65, 45, 80),

			SliderBackground = Color3.fromRGB(100, 60, 150),
			SliderProgress = Color3.fromRGB(130, 80, 180),
			SliderStroke = Color3.fromRGB(150, 100, 200),

			ToggleBackground = Color3.fromRGB(45, 30, 55),
			ToggleEnabled = Color3.fromRGB(120, 60, 150),
			ToggleDisabled = Color3.fromRGB(94, 47, 117),
			ToggleEnabledStroke = Color3.fromRGB(140, 80, 170),
			ToggleDisabledStroke = Color3.fromRGB(124, 71, 150),
			ToggleEnabledOuterStroke = Color3.fromRGB(90, 40, 120),
			ToggleDisabledOuterStroke = Color3.fromRGB(80, 50, 110),

			DropdownSelected = Color3.fromRGB(50, 35, 70),
			DropdownUnselected = Color3.fromRGB(35, 25, 50),

			InputBackground = Color3.fromRGB(45, 30, 60),
			InputStroke = Color3.fromRGB(80, 50, 110),
			PlaceholderColor = Color3.fromRGB(178, 150, 200)
		},

		Green = {
			TextColor = Color3.fromRGB(30, 60, 30),

			Background = Color3.fromRGB(235, 245, 235),
			Topbar = Color3.fromRGB(210, 230, 210),
			Shadow = Color3.fromRGB(200, 220, 200),

			NotificationBackground = Color3.fromRGB(240, 250, 240),
			NotificationActionsBackground = Color3.fromRGB(220, 235, 220),

			TabBackground = Color3.fromRGB(215, 235, 215),
			TabStroke = Color3.fromRGB(190, 210, 190),
			TabBackgroundSelected = Color3.fromRGB(245, 255, 245),
			TabTextColor = Color3.fromRGB(50, 80, 50),
			SelectedTabTextColor = Color3.fromRGB(20, 60, 20),

			ElementBackground = Color3.fromRGB(225, 240, 225),
			ElementBackgroundHover = Color3.fromRGB(210, 225, 210),
			SecondaryElementBackground = Color3.fromRGB(235, 245, 235), 
			ElementStroke = Color3.fromRGB(180, 200, 180),
			SecondaryElementStroke = Color3.fromRGB(180, 200, 180),

			SliderBackground = Color3.fromRGB(90, 160, 90),
			SliderProgress = Color3.fromRGB(70, 130, 70),
			SliderStroke = Color3.fromRGB(100, 180, 100),

			ToggleBackground = Color3.fromRGB(215, 235, 215),
			ToggleEnabled = Color3.fromRGB(60, 130, 60),
			ToggleDisabled = Color3.fromRGB(150, 175, 150),
			ToggleEnabledStroke = Color3.fromRGB(80, 150, 80),
			ToggleDisabledStroke = Color3.fromRGB(130, 150, 130),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 160, 100),
			ToggleDisabledOuterStroke = Color3.fromRGB(160, 180, 160),

			DropdownSelected = Color3.fromRGB(225, 240, 225),
			DropdownUnselected = Color3.fromRGB(210, 225, 210),

			InputBackground = Color3.fromRGB(235, 245, 235),
			InputStroke = Color3.fromRGB(180, 200, 180),
			PlaceholderColor = Color3.fromRGB(120, 140, 120)
		},

		Bloom = {
			TextColor = Color3.fromRGB(60, 40, 50),

			Background = Color3.fromRGB(255, 240, 245),
			Topbar = Color3.fromRGB(250, 220, 225),
			Shadow = Color3.fromRGB(230, 190, 195),

			NotificationBackground = Color3.fromRGB(255, 235, 240),
			NotificationActionsBackground = Color3.fromRGB(245, 215, 225),

			TabBackground = Color3.fromRGB(240, 210, 220),
			TabStroke = Color3.fromRGB(230, 200, 210),
			TabBackgroundSelected = Color3.fromRGB(255, 225, 235),
			TabTextColor = Color3.fromRGB(80, 40, 60),
			SelectedTabTextColor = Color3.fromRGB(50, 30, 50),

			ElementBackground = Color3.fromRGB(255, 235, 240),
			ElementBackgroundHover = Color3.fromRGB(245, 220, 230),
			SecondaryElementBackground = Color3.fromRGB(255, 235, 240), 
			ElementStroke = Color3.fromRGB(230, 200, 210),
			SecondaryElementStroke = Color3.fromRGB(230, 200, 210),

			SliderBackground = Color3.fromRGB(240, 130, 160),
			SliderProgress = Color3.fromRGB(250, 160, 180),
			SliderStroke = Color3.fromRGB(255, 180, 200),

			ToggleBackground = Color3.fromRGB(240, 210, 220),
			ToggleEnabled = Color3.fromRGB(255, 140, 170),
			ToggleDisabled = Color3.fromRGB(200, 180, 185),
			ToggleEnabledStroke = Color3.fromRGB(250, 160, 190),
			ToggleDisabledStroke = Color3.fromRGB(210, 180, 190),
			ToggleEnabledOuterStroke = Color3.fromRGB(220, 160, 180),
			ToggleDisabledOuterStroke = Color3.fromRGB(190, 170, 180),

			DropdownSelected = Color3.fromRGB(250, 220, 225),
			DropdownUnselected = Color3.fromRGB(240, 210, 220),

			InputBackground = Color3.fromRGB(255, 235, 240),
			InputStroke = Color3.fromRGB(220, 190, 200),
			PlaceholderColor = Color3.fromRGB(170, 130, 140)
		},

		DarkBlue = {
			TextColor = Color3.fromRGB(230, 230, 230),

			Background = Color3.fromRGB(20, 25, 30),
			Topbar = Color3.fromRGB(30, 35, 40),
			Shadow = Color3.fromRGB(15, 20, 25),

			NotificationBackground = Color3.fromRGB(25, 30, 35),
			NotificationActionsBackground = Color3.fromRGB(45, 50, 55),

			TabBackground = Color3.fromRGB(35, 40, 45),
			TabStroke = Color3.fromRGB(45, 50, 60),
			TabBackgroundSelected = Color3.fromRGB(40, 70, 100),
			TabTextColor = Color3.fromRGB(200, 200, 200),
			SelectedTabTextColor = Color3.fromRGB(255, 255, 255),

			ElementBackground = Color3.fromRGB(30, 35, 40),
			ElementBackgroundHover = Color3.fromRGB(40, 45, 50),
			SecondaryElementBackground = Color3.fromRGB(35, 40, 45), 
			ElementStroke = Color3.fromRGB(45, 50, 60),
			SecondaryElementStroke = Color3.fromRGB(40, 45, 55),

			SliderBackground = Color3.fromRGB(0, 90, 180),
			SliderProgress = Color3.fromRGB(0, 120, 210),
			SliderStroke = Color3.fromRGB(0, 150, 240),

			ToggleBackground = Color3.fromRGB(35, 40, 45),
			ToggleEnabled = Color3.fromRGB(0, 120, 210),
			ToggleDisabled = Color3.fromRGB(70, 70, 80),
			ToggleEnabledStroke = Color3.fromRGB(0, 150, 240),
			ToggleDisabledStroke = Color3.fromRGB(75, 75, 85),
			ToggleEnabledOuterStroke = Color3.fromRGB(20, 100, 180), 
			ToggleDisabledOuterStroke = Color3.fromRGB(55, 55, 65),

			DropdownSelected = Color3.fromRGB(30, 70, 90),
			DropdownUnselected = Color3.fromRGB(25, 30, 35),

			InputBackground = Color3.fromRGB(25, 30, 35),
			InputStroke = Color3.fromRGB(45, 50, 60), 
			PlaceholderColor = Color3.fromRGB(150, 150, 160)
		},

		Serenity = {
			TextColor = Color3.fromRGB(50, 55, 60),
			Background = Color3.fromRGB(240, 245, 250),
			Topbar = Color3.fromRGB(215, 225, 235),
			Shadow = Color3.fromRGB(200, 210, 220),

			NotificationBackground = Color3.fromRGB(210, 220, 230),
			NotificationActionsBackground = Color3.fromRGB(225, 230, 240),

			TabBackground = Color3.fromRGB(200, 210, 220),
			TabStroke = Color3.fromRGB(180, 190, 200),
			TabBackgroundSelected = Color3.fromRGB(175, 185, 200),
			TabTextColor = Color3.fromRGB(50, 55, 60),
			SelectedTabTextColor = Color3.fromRGB(30, 35, 40),

			ElementBackground = Color3.fromRGB(210, 220, 230),
			ElementBackgroundHover = Color3.fromRGB(220, 230, 240),
			SecondaryElementBackground = Color3.fromRGB(200, 210, 220),
			ElementStroke = Color3.fromRGB(190, 200, 210),
			SecondaryElementStroke = Color3.fromRGB(180, 190, 200),

			SliderBackground = Color3.fromRGB(200, 220, 235),  -- Lighter shade
			SliderProgress = Color3.fromRGB(70, 130, 180),
			SliderStroke = Color3.fromRGB(150, 180, 220),

			ToggleBackground = Color3.fromRGB(210, 220, 230),
			ToggleEnabled = Color3.fromRGB(70, 160, 210),
			ToggleDisabled = Color3.fromRGB(180, 180, 180),
			ToggleEnabledStroke = Color3.fromRGB(60, 150, 200),
			ToggleDisabledStroke = Color3.fromRGB(140, 140, 140),
			ToggleEnabledOuterStroke = Color3.fromRGB(100, 120, 140),
			ToggleDisabledOuterStroke = Color3.fromRGB(120, 120, 130),

			DropdownSelected = Color3.fromRGB(220, 230, 240),
			DropdownUnselected = Color3.fromRGB(200, 210, 220),

			InputBackground = Color3.fromRGB(220, 230, 240),
			InputStroke = Color3.fromRGB(180, 190, 200),
			PlaceholderColor = Color3.fromRGB(150, 150, 150)
		},
	}
}


-- Services
local UserInputService = getService("UserInputService")
local TweenService = getService("TweenService")
local Players = getService("Players")
local CoreGui = getService("CoreGui")

-- Interface Management

local Rayfield = useStudio and script.Parent:FindFirstChild('Rayfield') or game:GetObjects("rbxassetid://10804731440")[1]
local buildAttempts = 0
local correctBuild = false
local warned
local globalLoaded
local rayfieldDestroyed = false -- True when RayfieldLibrary:Destroy() is called

repeat
	if Rayfield:FindFirstChild('Build') and Rayfield.Build.Value == InterfaceBuild then
		correctBuild = true
		break
	end

	correctBuild = false

	if not warned then
		warn('Rayfield | Build Mismatch')
		print('Rayfield may encounter issues as you are running an incompatible interface version ('.. ((Rayfield:FindFirstChild('Build') and Rayfield.Build.Value) or 'No Build') ..').\n\nThis version of Rayfield is intended for interface build '..InterfaceBuild..'.')
		warned = true
	end

	toDestroy, Rayfield = Rayfield, useStudio and script.Parent:FindFirstChild('Rayfield') or game:GetObjects("rbxassetid://10804731440")[1]
	if toDestroy and not useStudio then toDestroy:Destroy() end

	buildAttempts = buildAttempts + 1
until buildAttempts >= 2

Rayfield.Enabled = false

if gethui then
	Rayfield.Parent = gethui()
elseif syn and syn.protect_gui then 
	syn.protect_gui(Rayfield)
	Rayfield.Parent = CoreGui
elseif not useStudio and CoreGui:FindFirstChild("RobloxGui") then
	Rayfield.Parent = CoreGui:FindFirstChild("RobloxGui")
elseif not useStudio then
	Rayfield.Parent = CoreGui
end

if gethui then
	for _, Interface in ipairs(gethui():GetChildren()) do
		if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
			Interface.Enabled = false
			Interface.Name = "Rayfield-Old"
		end
	end
elseif not useStudio then
	for _, Interface in ipairs(CoreGui:GetChildren()) do
		if Interface.Name == Rayfield.Name and Interface ~= Rayfield then
			Interface.Enabled = false
			Interface.Name = "Rayfield-Old"
		end
	end
end


local minSize = Vector2.new(1024, 768)
local useMobileSizing

if Rayfield.AbsoluteSize.X < minSize.X and Rayfield.AbsoluteSize.Y < minSize.Y then
	useMobileSizing = true
end

if UserInputService.TouchEnabled then
	useMobilePrompt = true
end


-- Object Variables

local Main = Rayfield.Main
local MPrompt = Rayfield:FindFirstChild('Prompt')
local Topbar = Main.Topbar
local Elements = Main.Elements
local LoadingFrame = Main.LoadingFrame
local TabList = Main.TabList
local dragBar = Rayfield:FindFirstChild('Drag')
local dragInteract = dragBar and dragBar.Interact or nil
local dragBarCosmetic = dragBar and dragBar.Drag or nil

local dragOffset = 255
local dragOffsetMobile = 150

Rayfield.DisplayOrder = 100
LoadingFrame.Version.Text = Release

-- Thanks to Latte Softworks for the Lucide integration for Roblox
local Icons = useStudio and require(script.Parent.icons) or loadWithTimeout('https://raw.githubusercontent.com/SiriusSoftwareLtd/Rayfield/refs/heads/main/icons.lua')
-- Variables

local CFileName = nil
local CEnabled = false
local Minimised = false
local Hidden = false
local Debounce = false
local searchOpen = false
local Notifications = Rayfield.Notifications

local SelectedTheme = RayfieldLibrary.Theme.Default

local function ChangeTheme(Theme)
	if typeof(Theme) == 'string' then
		SelectedTheme = RayfieldLibrary.Theme[Theme]
	elseif typeof(Theme) == 'table' then
		SelectedTheme = Theme
	end

	Rayfield.Main.BackgroundColor3 = SelectedTheme.Background
	Rayfield.Main.Topbar.BackgroundColor3 = SelectedTheme.Topbar
	Rayfield.Main.Topbar.CornerRepair.BackgroundColor3 = SelectedTheme.Topbar
	Rayfield.Main.Shadow.Image.ImageColor3 = SelectedTheme.Shadow

	Rayfield.Main.Topbar.ChangeSize.ImageColor3 = SelectedTheme.TextColor
	Rayfield.Main.Topbar.Hide.ImageColor3 = SelectedTheme.TextColor
	Rayfield.Main.Topbar.Search.ImageColor3 = SelectedTheme.TextColor
	if Topbar:FindFirstChild('Settings') then
		Rayfield.Main.Topbar.Settings.ImageColor3 = SelectedTheme.TextColor
		Rayfield.Main.Topbar.Divider.BackgroundColor3 = SelectedTheme.ElementStroke
	end

	Main.Search.BackgroundColor3 = SelectedTheme.TextColor
	Main.Search.Shadow.ImageColor3 = SelectedTheme.TextColor
	Main.Search.Search.ImageColor3 = SelectedTheme.TextColor
	Main.Search.Input.PlaceholderColor3 = SelectedTheme.TextColor
	Main.Search.UIStroke.Color = SelectedTheme.SecondaryElementStroke

	if Main:FindFirstChild('Notice') then
		Main.Notice.BackgroundColor3 = SelectedTheme.Background
	end

	for _, text in ipairs(Rayfield:GetDescendants()) do
		if text.Parent.Parent ~= Notifications then
			if text:IsA('TextLabel') or text:IsA('TextBox') then text.TextColor3 = SelectedTheme.TextColor end
		end
	end

	for _, TabPage in ipairs(Elements:GetChildren()) do
		for _, Element in ipairs(TabPage:GetChildren()) do
			if Element.ClassName == "Frame" and Element.Name ~= "Placeholder" and Element.Name ~= "SectionSpacing" and Element.Name ~= "Divider" and Element.Name ~= "SectionTitle" and Element.Name ~= "SearchTitle-fsefsefesfsefesfesfThanks" then
				Element.BackgroundColor3 = SelectedTheme.ElementBackground
				Element.UIStroke.Color = SelectedTheme.ElementStroke
			end
		end
	end
end

local function getIcon(name : string): {id: number, imageRectSize: Vector2, imageRectOffset: Vector2}
	if not Icons then
		warn("Lucide Icons: Cannot use icons as icons library is not loaded")
		return
	end
	name = string.match(string.lower(name), "^%s*(.*)%s*$") :: string
	local sizedicons = Icons['48px']
	local r = sizedicons[name]
	if not r then
		error(`Lucide Icons: Failed to find icon by the name of "{name}"`, 2)
	end

	local rirs = r[2]
	local riro = r[3]

	if type(r[1]) ~= "number" or type(rirs) ~= "table" or type(riro) ~= "table" then
		error("Lucide Icons: Internal error: Invalid auto-generated asset entry")
	end

	local irs = Vector2.new(rirs[1], rirs[2])
	local iro = Vector2.new(riro[1], riro[2])

	local asset = {
		id = r[1],
		imageRectSize = irs,
		imageRectOffset = iro,
	}

	return asset
end
-- Converts ID to asset URI. Returns rbxassetid://0 if ID is not a number
local function getAssetUri(id: any): string
	local assetUri = "rbxassetid://0" -- Default to empty image
	if type(id) == "number" then
		assetUri = "rbxassetid://" .. id
	elseif type(id) == "string" and not Icons then
		warn("Rayfield | Cannot use Lucide icons as icons library is not loaded")
	else
		warn("Rayfield | The icon argument must either be an icon ID (number) or a Lucide icon name (string)")
	end
	return assetUri
end

local function makeDraggable(object, dragObject, enableTaptic, tapticOffset)
	local dragging = false
	local relative = nil

	local offset = Vector2.zero
	local screenGui = object:FindFirstAncestorWhichIsA("ScreenGui")
	if screenGui and screenGui.IgnoreGuiInset then
		offset += getService('GuiService'):GetGuiInset()
	end

	local function connectFunctions()
		if dragBar and enableTaptic then
			dragBar.MouseEnter:Connect(function()
				if not dragging and not Hidden then
					TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.5, Size = UDim2.new(0, 120, 0, 4)}):Play()
				end
			end)

			dragBar.MouseLeave:Connect(function()
				if not dragging and not Hidden then
					TweenService:Create(dragBarCosmetic, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {BackgroundTransparency = 0.7, Size = UDim2.new(0, 100, 0, 4)}):Play()
				end
			end)
		end
	end

	connectFunctions()

	dragObject.InputBegan:Connect(function(input, processed)
		if processed then return end

		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			dragging = true

			relative = object.AbsolutePosition + object.AbsoluteSize * object.AnchorPoint - UserInputService:GetMouseLocation()
			if enableTaptic and not Hidden then
				TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 110, 0, 4), BackgroundTransparency = 0}):Play()
			end
		end
	end)

	local inputEnded = UserInputService.InputEnded:Connect(function(input)
		if not dragging then return end

		local inputType = input.UserInputType.Name
		if inputType == "MouseButton1" or inputType == "Touch" then
			dragging = false

			connectFunctions()

			if enableTaptic and not Hidden then
				TweenService:Create(dragBarCosmetic, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.new(0, 100, 0, 4), BackgroundTransparency = 0.7}):Play()
			end
		end
	end)

	local renderStepped = RunService.RenderStepped:Connect(function()
		if dragging and not Hidden then
			local position = UserInputService:GetMouseLocation() + relative + offset
			if enableTaptic and tapticOffset then
				TweenService:Create(object, TweenInfo.new(0.4, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(position.X, position.Y)}):Play()
				TweenService:Create(dragObject.Parent, TweenInfo.new(0.05, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out), {Position = UDim2.fromOffset(position.X, position.Y + ((useMobileSizing and tapticOffset[2]) or tapticOffset[1]))}):Play()
			else
				if dragBar and tapticOffset then
					dragBar.Position = UDim2.fromOffset(position.X, position.Y + ((useMobileSizing and tapticOffset[2]) or tapticOffset[1]))
				end
				object.Position = UDim2.fromOffset(position.X, position.Y)
			end
		end
	end)

	object.Destroying:Connect(function()
		if inputEnded then inputEnded:Disconnect() end
		if renderStepped then renderStepped:Disconnect() end
	end)
end


local function PackColor(Color)
	return {R = Color.R * 255, G = Color.G * 255, B = Color.B * 255}
end    

local function UnpackColor(Color)
	return Color3.fromRGB(Color.R, Color.G, Color.B)
end

local function LoadConfiguration(Configuration)
	local success, Data = pcall(function() return HttpService:JSONDecode(Configuration) end)
	local changed

	if not success then warn('Rayfield had an issue decoding the configuration file, please try delete the file and reopen Rayfield.') return end

	-- Iterate through current UI elements' flags
	for FlagName, Flag in pairs(RayfieldLibrary.Flags) do
		local FlagValue = Data[FlagName]

		if (typeof(FlagValue) == 'boolean' and FlagValue == false) or FlagValue then
			task.spawn(function()
				if Flag.Type == "ColorPicker" then
					changed = true
					Flag:Set(UnpackColor(FlagValue))
				else
					if (Flag.CurrentValue or Flag.CurrentKeybind or Flag.CurrentOption or Flag.Color) ~= FlagValue then 
						changed = true
						Flag:Set(FlagValue) 	
					end
				end
			end)
		else
			warn("Rayfield | Unable to find '"..FlagName.. "' in the save file.")
			print("The error above may not be an issue if new elements have been added to Rayfield since the last save.")
		end
	end

	if changed then
		sendReport("configuration_loaded", "Rayfield")
	end
end

local function SaveConfiguration()
	if not CEnabled then return end

	local Data = {}
	local success, encodedData = pcall(function()
		for i,v in pairs(RayfieldLibrary.Flags) do
			if v.Type == "ColorPicker" then
				Data[i] = PackColor(v.Color)
			else
				Data[i] = v.CurrentValue or v.CurrentKeybind or v.CurrentOption or false
			end
		end

		return HttpService:JSONEncode(Data)
	end)

	if not success then warn('Rayfield had an issue encoding the configuration file, please try delete the file and reopen Rayfield.') return end

	if writefile then
		writefile(ConfigurationFolder .. "/" .. CFileName .. ConfigurationExtension, encodedData)
	else
		setclipboard(encodedData)
		warn("Rayfield | Unable to save configuration, copied to clipboard instead")
	end
end

local function addFolder(name)
	if not isfolder then return end

	if not isfolder(name) then
		makefolder(name)
	end
end

local function loadFile(filePath)
	if not isfile or not readfile then return end

	if isfile(filePath) then
		return readfile(filePath)
	end
end

local function saveFile(filePath, data)
	if not writefile then return end

	writefile(filePath, data)
end

local neon = (function() -- Open sourced neon module by stravant
	local module = {}

	do
		local function IsNotNaN(x)
			return x == x
		end
		local continued = IsNotNaN(Camera:ScreenPointToRay(0,0).Origin.x)
		while not continued do
			RunService.RenderStepped:wait()
			continued = IsNotNaN(Camera:ScreenPointToRay(0,0).Origin.x)
		end
	end
	local RootParent = Camera

	local binds = {}
	local rootDescendants = {}

	local GenUid; do
		local id = 0
		function GenUid()
			return 'neon::'..tostring(id)
		end
	end

	local DrawQuad; do
		local acos, asin, sqrt, type, assert = math.acos, math.asin, math.sqrt, type, assert
		local function DrawTriangle(v1, v2, v3, p0, p1, p2, p3)
			local s1 = (v1 - v2):Dot(p2 - p1)
			local s2 = (v2 - v3):Dot(p3 - p2)
			local s3 = (v3 - v1):Dot(p1 - p3)

			if s1 <= 0 and s2 <= 0 and s3 <= 0 then
				return true
			else
				return false
			end
		end

		function DrawQuad(v1, v2, v3, v4, logimass, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15)
			local t1 = DrawTriangle(v1, v2, v3, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15)
			local t2 = DrawTriangle(v1, v3, v4, p0, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15)
			return t1 or t2
		end
	end

	local function BindRemover(bind)
		return function()
			local loc = table.find(binds, bind)
			if loc then
				table.remove(binds, loc)
			end
		end
	end

	local function CreateBind(holder, object)
		local bind = BindRemover(setmetatable({}, {__mode = 'v'}))
		table.insert(binds, bind)
		return bind
	end

	local Root = Instance.new('Folder', Camera)
	Root.Name = 'neon'

	local GenChildren = {}

	local Children = {}

	local function AddObject(object, holder, parent)
		if parent ~= nil then
			Children[object] = parent
			object.Parent = holder
		else
			Children[object] = holder
			object.Parent = holder
		end
	end

	local function DescendantRemoved(obj)
		for _, bind in next, binds do
			for prop, val in next, bind do
				if val == obj then
					bind[prop] = nil
				end
			end
		end

		if Children[obj] then
			Children[obj] = nil
		end
	end

	local function AncestorRemoved(obj)
		for _, bind in next, binds do
			for prop, val in next, bind do
				if val == obj then
					bind[prop] = nil
				end
			end
		end

		if Children[obj] then
			Children[obj] = nil
		end
	end

	DescendantRemoved = Root.DescendantRemoving:Connect(DescendantRemoved)
	AncestorRemoved = Root.AncestorRemoving:Connect(AncestorRemoved)

	local function DrawQuad(v1, v2, v3, v4, parts, properties, holder, parent)
		local model = Instance.new('Model')
		model.Name = GenUid()
		local part = Instance.new('Part')
		part.Transparency = 1
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Plastic
		part.Size = Vector3.new(0.01, 0.01, 0.01)
		part.Name = 'Main'
		local mesh = Instance.new('SpecialMesh')
		mesh.MeshType = Enum.MeshType.Brick
		mesh.Scale = Vector3.new(0, 0, 0)
		local part = Instance.new('Part')
		part.Transparency = 1
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Plastic
		part.Size = Vector3.new(0.01, 0.01, 0.01)
		part.Name = 'Main'
		local mesh = Instance.new('SpecialMesh')
		mesh.MeshType = Enum.MeshType.Brick
		mesh.Scale = Vector3.new(0, 0, 0)
		local part = Instance.new('Part')
		part.Transparency = 1
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Plastic
		part.Size = Vector3.new(0.01, 0.01, 0.01)
		part.Name = 'Main'
		local mesh = Instance.new('SpecialMesh')
		mesh.MeshType = Enum.MeshType.Brick
		mesh.Scale = Vector3.new(0, 0, 0)
		local part = Instance.new('Part')
		part.Transparency = 1
		part.Anchored = true
		part.CanCollide = false
		part.Material = Enum.Material.Plastic
		part.Size = Vector3.new(0.01, 0.01, 0.01)
		part.Name = 'Main'
		local mesh = Instance.new('SpecialMesh')
		mesh.MeshType = Enum.MeshType.Brick
		mesh.Scale = Vector3.new(0, 0, 0)
		local part4 = Instance.new('Part')
		part4.Transparency = 1
		part4.Anchored = true
		part4.CanCollide = false
		part4.Material = Enum.Material.Plastic
		part4.Size = Vector3.new(0.01, 0.01, 0.01)
		part4.Name = 'Main'
		local mesh4 = Instance.new('SpecialMesh')
		mesh4.MeshType = Enum.MeshType.Brick
		mesh4.Scale = Vector3.new(0, 0, 0)

		part.Parent = model
		part2.Parent = model
		part3.Parent = model
		part4.Parent = model

		mesh.Parent = part
		mesh2.Parent = part2
		mesh3.Parent = part3
		mesh4.Parent = part4

		for _, part in next, {part, part2, part3, part4} do
			part.CFrame = CFrame.new(v1.Position, v2.Position, v3.Position)
			local cframe = part.CFrame
			local v1p, v2p, v3p, v4p = cframe * (v1 - cframe.Position), cframe * (v2 - cframe.Position), cframe * (v3 - cframe.Position), cframe * (v4 - cframe.Position)
			local irs = (v2p - v1p):Cross(v3p - v1p).Unit
			local irs2 = (v3p - v2p):Cross(v4p - v2p).Unit
			part.Size = Vector3.new((v2p - v1p).Magnitude, (v3p - v1p).Magnitude, 0)
			part2.Size = Vector3.new((v3p - v2p).Magnitude, (v4p - v2p).Magnitude, 0)
			part3.Size = Vector3.new((v4p - v3p).Magnitude, (v1p - v3p).Magnitude, 0)
			part4.Size = Vector3.new((v1p - v4p).Magnitude, (v2p - v4p).Magnitude, 0)
			mesh.Scale = Vector3.new(part.Size.X / part.Size.X, part.Size.Y / part.Size.Y, 0.01)
			mesh2.Scale = Vector3.new(part2.Size.X / part2.Size.X, part2.Size.Y / part2.Size.Y, 0.01)
			mesh3.Scale = Vector3.new(part3.Size.X / part3.Size.X, part3.Size.Y / part3.Size.Y, 0.01)
			mesh4.Scale = Vector3.new(part4.Size.X / part4.Size.X, part4.Size.Y / part4.Size.Y, 0.01)
			part.CFrame = cframe * CFrame.new(0, 0, -0.005) * CFrame.fromEulerAnglesXYZ(math.pi / 2, 0, 0)
			part2.CFrame = cframe * CFrame.new(0, 0, -0.005) * CFrame.fromEulerAnglesXYZ(math.pi / 2, 0, 0)
			part3.CFrame = cframe * CFrame.new(0, 0, -0.005) * CFrame.fromEulerAnglesXYZ(math.pi / 2, 0, 0)
			part4.CFrame = cframe * CFrame.new(0, 0, -0.005) * CFrame.fromEulerAnglesXYZ(math.pi / 2, 0, 0)
		end

		for _, prop in next, properties or {} do
			model[prop[1]] = prop[2]
		end

		AddObject(model, holder, parent)
		return model
	end

	function module.Start(...)
		for _, obj in next, RootParent:GetDescendants() do
			if obj:IsA('BasePart') and obj.Name == 'Main' and obj.Parent.Name:sub(1, 6) == 'neon::' then
				table.insert(rootDescendants, obj)
			end
		end

		local function Update()
			for _, part in next, rootDescendants do
				if part.Parent and part.Parent.Parent then
					local holder = Children[part.Parent]
					if holder then
						part.CFrame = holder.CFrame
						part.Transparency = holder.Transparency
						part.Color = holder.Color
						part.Material = holder.Material
					end
				end
			end
		end

		Update()
		RunService.RenderStepped:Connect(Update)
	end

	function module.CreateQuad(v1, v2, v3, v4, properties, holder, parent)
		return DrawQuad(v1, v2, v3, v4, 4, properties, holder, parent)
	end

	function module.CreateTriangle(v1, v2, v3, properties, holder, parent)
		return DrawQuad(v1, v2, v3, v3, 3, properties, holder, parent)
	end

	return module
end)()

local function CreateWindow(Properties)
	local Properties = Properties or {}
	local Title = Properties.Name or Properties.Title or "Rayfield Interface Suite"
	local LoadingTitle = Properties.LoadingTitle or "Rayfield Interface Suite"
	local LoadingSubtitle = Properties.LoadingSubtitle or "by Sirius"
	local ConfigurationSaving = Properties.ConfigurationSaving or Properties.SaveCfg or false
	local KeySystem = Properties.KeySystem or false
	local KeySettings = Properties.KeySettings or {}

	if Title == "Rayfield Interface Suite" then Title = "" end

	local function Destroy()
		rayfieldDestroyed = true
		Rayfield:Destroy()
	end

	local function SetTheme(Theme)
		ChangeTheme(Theme)
	end

	local function Hide(notify)
		if notify then
			sendReport("interface_hidden", "Rayfield")
		end
		Hidden = true
		Rayfield.Enabled = false
		if dragBar then
			dragBar.Visible = false
		end
	end

	local function Show(notify)
		if notify then
			sendReport("interface_shown", "Rayfield")
		end
		Hidden = false
		Rayfield.Enabled = true
		if dragBar then
			dragBar.Visible = true
		end
	end

	local function Toggle(notifications)
		if Hidden then
			Show(notifications)
		else
			Hide(notifications)
		end
	end

	local function Notify(Properties)
		local Properties = Properties or {}
		local Title = Properties.Title or "Notification"
		local Content = Properties.Content or "This is a notification."
		local Duration = Properties.Duration or 5
		local Image = Properties.Image or 0

		local Notification = Notifications.Template:Clone()
		Notification.Name = "Notification"
		Notification.Parent = Notifications
		Notification.Visible = true

		Notification.Title.Text = Title
		Notification.Description.Text = Content
		Notification.Icon.Image = getAssetUri(Image)

		Notification.BackgroundColor3 = SelectedTheme.NotificationBackground
		Notification.Title.TextColor3 = SelectedTheme.TextColor
		Notification.Description.TextColor3 = SelectedTheme.TextColor
		Notification.Icon.ImageColor3 = SelectedTheme.TextColor
		Notification.UIStroke.Color = SelectedTheme.ElementStroke

		local Actions = Notification.Actions
		if Properties.Actions then
			for _, Action in pairs(Properties.Actions) do
				local Button = Actions.Template:Clone()
				Button.Name = "Action"
				Button.Parent = Actions
				Button.BackgroundColor3 = SelectedTheme.NotificationActionsBackground
				Button.Text.TextColor3 = SelectedTheme.TextColor
				Button.Text.Text = Action.Name
				Button.UIStroke.Color = SelectedTheme.ElementStroke

				Button.MouseButton1Click:Connect(function()
					Action.Callback()
					Notification:Destroy()
				end)
			end
		else
			Actions:Destroy()
		end

		local function Remove()
			Notification:Destroy()
		end

		local function Update(Properties)
			Properties = Properties or {}
			Title = Properties.Title or Title
			Content = Properties.Content or Content
			Duration = Properties.Duration or Duration
			Image = Properties.Image or Image

			Notification.Title.Text = Title
			Notification.Description.Text = Content
			Notification.Icon.Image = getAssetUri(Image)
		end

		task.delay(Duration, Remove)

		return {
			Remove = Remove,
			Update = Update
		}
	end

	local function CreateTab(Properties)
		local Properties = Properties or {}
		local Title = Properties.Name or Properties.Title or "Tab"
		local Icon = Properties.Icon or ""

		local TabButton = TabList.Template:Clone()
		TabButton.Name = Title
		TabButton.Title.Text = Title
		TabButton.Parent = TabList
		TabButton.Title.TextColor3 = SelectedTheme.TabTextColor
		TabButton.BackgroundColor3 = SelectedTheme.TabBackground
		TabButton.UIStroke.Color = SelectedTheme.TabStroke

		if Icon ~= "" then
			local asset = getIcon(Icon)
			if asset then
				TabButton.Title.Icon.Image = "rbxassetid://" .. asset.id
				TabButton.Title.Icon.ImageRectOffset = asset.imageRectOffset
				TabButton.Title.Icon.ImageRectSize = asset.imageRectSize
				TabButton.Title.Icon.Visible = true
				TabButton.Title.Text.Position = UDim2.new(0, 30, 0.5, 0)
			end
		end

		local TabPage = Elements.Template:Clone()
		TabPage.Name = Title
		TabPage.Parent = Elements
		TabPage.Visible = false

		local function SelectTab()
			if Debounce then return end
			Debounce = true

			for _, Tab in ipairs(TabList:GetChildren()) do
				if Tab:IsA("Frame") and Tab ~= TabButton then
					Tab.BackgroundColor3 = SelectedTheme.TabBackground
					Tab.Title.TextColor3 = SelectedTheme.TabTextColor
					Tab.UIStroke.Color = SelectedTheme.TabStroke
					Elements:FindFirstChild(Tab.Name).Visible = false
				end
			end

			TabButton.BackgroundColor3 = SelectedTheme.TabBackgroundSelected
			TabButton.Title.TextColor3 = SelectedTheme.SelectedTabTextColor
			TabButton.UIStroke.Color = SelectedTheme.TabStroke
			TabPage.Visible = true

			Debounce = false
		end

		TabButton.Interact.MouseButton1Click:Connect(SelectTab)

		local function CreateSection(Properties)
			local Properties = Properties or {}
			local Title = Properties.Name or Properties.Title or "Section"

			local Section = TabPage.Section:Clone()
			Section.Name = Title
			Section.Parent = TabPage
			Section.Title.Text = Title
			Section.Title.TextColor3 = SelectedTheme.TextColor
			Section.BackgroundColor3 = SelectedTheme.Background

			local SectionContainer = Section.Container
			local SectionContent = SectionContainer.Content

			local function CreateButton(Properties)
				local Properties = Properties or {}
				local Title = Properties.Name or "Button"
				local Callback = Properties.Callback or function() end
				local Icon = Properties.Icon or ""

				local Button = SectionContent.Button:Clone()
				Button.Name = Title
				Button.Parent = SectionContent
				Button.Title.Text = Title
				Button.BackgroundColor3 = SelectedTheme.ElementBackground
				Button.UIStroke.Color = SelectedTheme.ElementStroke
				Button.Title.TextColor3 = SelectedTheme.TextColor

				if Icon ~= "" then
					local asset = getIcon(Icon)
					if asset then
						Button.Title.Icon.Image = "rbxassetid://" .. asset.id
						Button.Title.Icon.ImageRectOffset = asset.imageRectOffset
						Button.Title.Icon.ImageRectSize = asset.imageRectSize
						Button.Title.Icon.Visible = true
						Button.Title.Text.Position = UDim2.new(0, 30, 0.5, 0)
					end
				end

				Button.Interact.MouseButton1Click:Connect(Callback)

				local function Set(Properties)
					Properties = Properties or {}
					Title = Properties.Name or Title
					Callback = Properties.Callback or Callback
					Icon = Properties.Icon or Icon

					Button.Title.Text = Title
					if Icon ~= "" then
						local asset = getIcon(Icon)
						if asset then
							Button.Title.Icon.Image = "rbxassetid://" .. asset.id
							Button.Title.Icon.ImageRectOffset = asset.imageRectOffset
							Button.Title.Icon.ImageRectSize = asset.imageRectSize
							Button.Title.Icon.Visible = true
							Button.Title.Text.Position = UDim2.new(0, 30, 0.5, 0)
						end
					end
				end

				return {
					Set = Set
				}
			end

			local function CreateToggle(Properties)
				local Properties = Properties or {}
				local Title = Properties.Name or "Toggle"
				local CurrentValue = Properties.CurrentValue or false
				local Flag = Properties.Flag or nil
				local Callback = Properties.Callback or function() end
				local Icon = Properties.Icon or ""

				local Toggle = SectionContent.Toggle:Clone()
				Toggle.Name = Title
				Toggle.Parent = SectionContent
				Toggle.Title.Text = Title
				Toggle.BackgroundColor3 = SelectedTheme.ElementBackground
				Toggle.UIStroke.Color = SelectedTheme.ElementStroke
				Toggle.Title.TextColor3 = SelectedTheme.TextColor

				local ToggleFrame = Toggle.Container.ToggleFrame
				ToggleFrame.BackgroundColor3 = SelectedTheme.ToggleBackground
				ToggleFrame.UIStroke.Color = SelectedTheme.ToggleDisabledStroke

				local ToggleCircle = ToggleFrame.Circle
				ToggleCircle.BackgroundColor3 = SelectedTheme.ToggleDisabled

				if Icon ~= "" then
					local asset = getIcon(Icon)
					if asset then
						Toggle.Title.Icon.Image = "rbxassetid://" .. asset.id
						Toggle.Title.Icon.ImageRectOffset = asset.imageRectOffset
						Toggle.Title.Icon.ImageRectSize = asset.imageRectSize
						Toggle.Title.Icon.Visible = true
						Toggle.Title.Text.Position = UDim2.new(0, 30, 0.5, 0)
					end
				end

				local function Set(Value)
					Value = Value or false
					CurrentValue = Value

					if Value then
						ToggleFrame.BackgroundColor3 = SelectedTheme.ToggleEnabled
						ToggleFrame.UIStroke.Color = SelectedTheme.ToggleEnabledStroke
						ToggleCircle.BackgroundColor3 = SelectedTheme.ToggleEnabled
						ToggleCircle.Position = UDim2.new(0.6, 0, 0.5, 0)
					else
						ToggleFrame.BackgroundColor3 = SelectedTheme.ToggleBackground
						ToggleFrame.UIStroke.Color = SelectedTheme.ToggleDisabledStroke
						ToggleCircle.BackgroundColor3 = SelectedTheme.ToggleDisabled
						ToggleCircle.Position = UDim2.new(0.4, 0, 0.5, 0)
					end

					Callback(Value)
				end

				Set(CurrentValue)

				Toggle.Interact.MouseButton1Click:Connect(function()
					Set(not CurrentValue)
				end)

				if Flag then
					RayfieldLibrary.Flags[Flag] = {
						Type = "Toggle",
						CurrentValue = CurrentValue,
						Set = Set
					}
				end

				return {
					Set = Set
				}
			end

			local function CreateSlider(Properties)
				local Properties = Properties or {}
				local Title = Properties.Name or "Slider"
				local Range = Properties.Range or {0, 100}
				local Increment = Properties.Increment or 1
				local CurrentValue = Properties.CurrentValue or 50
				local Flag = Properties.Flag or nil
				local Callback = Properties.Callback or function() end
				local Icon = Properties.Icon or ""

				local Slider = SectionContent.Slider:Clone()
				Slider.Name = Title
				Slider.Parent = SectionContent
				Slider.Title.Text = Title
				Slider.BackgroundColor3 = SelectedTheme.ElementBackground
				Slider.UIStroke.Color = SelectedTheme.ElementStroke
				Slider.Title.TextColor3 = SelectedTheme.TextColor

				local SliderBar = Slider.Container.SliderBar
				SliderBar.BackgroundColor3 = SelectedTheme.SliderBackground
				SliderBar.UIStroke.Color = SelectedTheme.SliderStroke

				local SliderFill = SliderBar.Fill
				SliderFill.BackgroundColor3 = SelectedTheme.SliderProgress

				local SliderCircle = SliderBar.Circle
				SliderCircle.BackgroundColor3 = SelectedTheme.SliderProgress

				local ValueLabel = Slider.Container.ValueLabel
				ValueLabel.TextColor3 = SelectedTheme.TextColor

				if Icon ~= "" then
					local asset = getIcon(Icon)
					if asset then
						Slider.Title.Icon.Image = "rbxassetid://" .. asset.id
						Slider.Title.Icon.ImageRectOffset = asset.imageRectOffset
						Slider.Title.Icon.ImageRectSize = asset.imageRectSize
						Slider.Title.Icon.Visible = true
						Slider.Title.Text.Position = UDim2.new(0, 30, 0.5, 0)
					end
				end

				local function Set(Value)
					Value = math.clamp(Value, Range[1], Range[2])
					Value = math.round(Value / Increment) * Increment
					CurrentValue = Value

					local Percent = (Value - Range[1]) / (Range[2] - Range[1])
					SliderFill.Size = UDim2.new(Percent, 0, 1, 0)
					SliderCircle.Position = UDim2.new(Percent, 0, 0.5, 0)
					ValueLabel.Text = tostring(Value)

					Callback(Value)
				end

				Set(CurrentValue)

				local Dragging = false
				Slider.Interact.MouseButton1Down:Connect(function()
					Dragging = true
				end)

				UserInputService.InputEnded:Connect(function(Input)
					if Input.UserInputType == Enum.UserInputType.MouseButton1 then
						Dragging = false
					end
				end)

				RunService.RenderStepped:Connect(function()
					if Dragging then
						local MousePosition = UserInputService:GetMouseLocation()
						local SliderPosition = SliderBar.AbsolutePosition
						local SliderSize = SliderBar.AbsoluteSize
						local Percent = math.clamp((MousePosition.X - SliderPosition.X) / SliderSize.X, 0, 1)
						local Value = Range[1] + (Range[2] - Range[1]) * Percent
						Set(Value)
					end
				end)

				if Flag then
					RayfieldLibrary.Flags[Flag] = {
						Type = "Slider",
						CurrentValue = CurrentValue,
						Set = Set
					}
				end

				return {
					Set = Set
				}
			end

			local function CreateInput(Properties)
				local Properties = Properties or {}
				local Title = Properties.Name or "Input"
				local Placeholder = Properties.Placeholder or ""
				local CurrentValue = Properties.CurrentValue or ""
				local Flag = Properties.Flag or nil
				local Callback = Properties.Callback or function() end
				local Icon = Properties.Icon or ""

				local Input = SectionContent.Input:Clone()
				Input.Name = Title
				Input.Parent = SectionContent
				Input.Title.Text = Title
				Input.BackgroundColor3 = SelectedTheme.ElementBackground
				Input.UIStroke.Color = SelectedTheme.ElementStroke
				Input.Title.TextColor3 = SelectedTheme.TextColor

				local InputBox = Input.Container.InputBox
				InputBox.BackgroundColor3 = SelectedTheme.InputBackground
				InputBox.UIStroke.Color = SelectedTheme.InputStroke
				InputBox.PlaceholderColor3 = SelectedTheme.PlaceholderColor
				InputBox.TextColor3 = SelectedTheme.TextColor
				InputBox.PlaceholderText = Placeholder
				InputBox.Text = CurrentValue

				if Icon ~= "" then
					local asset = getIcon(Icon)
					if asset then
						Input.Title.Icon.Image = "rbxassetid://" .. asset.id
						Input.Title.Icon.ImageRectOffset = asset.imageRectOffset
						Input.Title.Icon.ImageRectSize = asset.imageRectSize
						Input.Title.Icon.Visible = true
						Input.Title.Text.Position = UDim2.new(0, 30, 0.5, 0)
					end
				end

				local function Set(Value)
					Value = Value or ""
					CurrentValue = Value
					InputBox.Text = Value
					Callback(Value)
				end

				InputBox.FocusLost:Connect(function()
					Set(InputBox.Text)
				end)

				if Flag then
					RayfieldLibrary.Flags[Flag] = {
						Type = "Input",
						CurrentValue = CurrentValue,
						Set = Set
					}
				end

				return {
					Set = Set
				}
			end

			local function CreateDropdown(Properties)
				local Properties = Properties or {}
				local Title = Properties.Name or "Dropdown"
				local Options = Properties.Options or {}
				local CurrentOption = Properties.CurrentOption or ""
				local Flag = Properties.Flag or nil
				local Callback = Properties.Callback or function() end
				local Icon = Properties.Icon or ""

				local Dropdown = SectionContent.Dropdown:Clone()
				Dropdown.Name = Title
				Dropdown.Parent = SectionContent
				Dropdown.Title.Text = Title
				Dropdown.BackgroundColor3 = SelectedTheme.ElementBackground
				Dropdown.UIStroke.Color = SelectedTheme.ElementStroke
				Dropdown.Title.TextColor3 = SelectedTheme.TextColor

				local DropdownContainer = Dropdown.Container
				local DropdownList = DropdownContainer.List

				local SelectedLabel = DropdownContainer.Selected
				SelectedLabel.BackgroundColor3 = SelectedTheme.DropdownSelected
				SelectedLabel.UIStroke.Color = SelectedTheme.ElementStroke
				SelectedLabel.TextColor3 = SelectedTheme.TextColor
				SelectedLabel.Text = CurrentOption

				if Icon ~= "" then
					local asset = getIcon(Icon)
					if asset then
						Dropdown.Title.Icon.Image = "rbxassetid://" .. asset.id
						Dropdown.Title.Icon.ImageRectOffset = asset.imageRectOffset
						Dropdown.Title.Icon.ImageRectSize = asset.imageRectSize
						Dropdown.Title.Icon.Visible = true
						Dropdown.Title.Text.Position = UDim2.new(0, 30, 0.5, 0)
					end
				end

				local function Set(Value)
					Value = Value or ""
					CurrentOption = Value
					SelectedLabel.Text = Value
					Callback(Value)
				end

				local function Refresh(Options)
					Options = Options or {}
					for _, Option in ipairs(DropdownList:GetChildren()) do
						if Option:IsA("TextButton") then
							Option:Destroy()
						end
					end

					for _, Option in ipairs(Options) do
						local OptionButton = DropdownList.Template:Clone()
						OptionButton.Name = Option
						OptionButton.Parent = DropdownList
						OptionButton.Text = Option
						OptionButton.BackgroundColor3 = SelectedTheme.DropdownUnselected
						OptionButton.UIStroke.Color = SelectedTheme.ElementStroke
						OptionButton.TextColor3 = SelectedTheme.TextColor

						OptionButton.MouseButton1Click:Connect(function()
							Set(Option)
							DropdownList.Visible = false
						end)
					end
				end

				Refresh(Options)

				SelectedLabel.MouseButton1Click:Connect(function()
					DropdownList.Visible = not DropdownList.Visible
				end)

				if Flag then
					RayfieldLibrary.Flags[Flag] = {
						Type = "Dropdown",
						CurrentOption = CurrentOption,
						Set = Set,
						Refresh = Refresh
					}
				end

				return {
					Set = Set,
					Refresh = Refresh
				}
			end

			local function CreateKeybind(Properties)
				local Properties = Properties or {}
				local Title = Properties.Name or "Keybind"
				local CurrentKeybind = Properties.CurrentKeybind or "None"
				local Flag = Properties.Flag or nil
				local Callback = Properties.Callback or function() end
				local Icon = Properties.Icon or ""

				local Keybind = SectionContent.Keybind:Clone()
				Keybind.Name = Title
				Keybind.Parent = SectionContent
				Keybind.Title.Text = Title
				Keybind.BackgroundColor3 = SelectedTheme.ElementBackground
				Keybind.UIStroke.Color = SelectedTheme.ElementStroke
				Keybind.Title.TextColor3 = SelectedTheme.TextColor

				local KeybindLabel = Keybind.Container.KeybindLabel
				KeybindLabel.BackgroundColor3 = SelectedTheme.InputBackground
				KeybindLabel.UIStroke.Color = SelectedTheme.InputStroke
				KeybindLabel.TextColor3 = SelectedTheme.TextColor
				KeybindLabel.Text = CurrentKeybind

				if Icon ~= "" then
					local asset = getIcon(Icon)
					if asset then
						Keybind.Title.Icon.Image = "rbxassetid://" .. asset.id
						Keybind.Title.Icon.ImageRectOffset = asset.imageRectOffset
						Keybind.Title.Icon.ImageRectSize = asset.imageRectSize
						Keybind.Title.Icon.Visible = true
						Keybind.Title.Text.Position = UDim2.new(0, 30, 0.5, 0)
					end
				end

				local Listening = false
				local function Set(Value)
					Value = Value or "None"
					CurrentKeybind = Value
					KeybindLabel.Text = Value
					Callback(Value)
				end

				KeybindLabel.MouseButton1Click:Connect(function()
					if Listening then return end
					Listening = true
					KeybindLabel.Text = "..."

					local Connection
					Connection = UserInputService.InputBegan:Connect(function(Input)
						if Input.UserInputType == Enum.UserInputType.Keyboard then
							Set(Input.KeyCode.Name)
							Connection:Disconnect()
							Listening = false
						end
					end)
				end)

				if Flag then
					RayfieldLibrary.Flags[Flag] = {
						Type = "Keybind",
						CurrentKeybind = CurrentKeybind,
						Set = Set
					}
				end

				return {
					Set = Set
				}
			end

			local function CreateColorPicker(Properties)
				local Properties = Properties or {}
				local Title = Properties.Name or "Color Picker"
				local Color = Properties.Color or Color3.fromRGB(255, 255, 255)
				local Flag = Properties.Flag or nil
				local Callback = Properties.Callback or function() end
				local Icon = Properties.Icon or ""

				local ColorPicker = SectionContent.ColorPicker:Clone()
				ColorPicker.Name = Title
				ColorPicker.Parent = SectionContent
				ColorPicker.Title.Text = Title
				ColorPicker.BackgroundColor3 = SelectedTheme.ElementBackground
				ColorPicker.UIStroke.Color = SelectedTheme.ElementStroke
				ColorPicker.Title.TextColor3 = SelectedTheme.TextColor

				local ColorDisplay = ColorPicker.Container.ColorDisplay
				ColorDisplay.BackgroundColor3 = Color

				if Icon ~= "" then
					local asset = getIcon(Icon)
					if asset then
						ColorPicker.Title.Icon.Image = "rbxassetid://" .. asset.id
						ColorPicker.Title.Icon.ImageRectOffset = asset.imageRectOffset
						ColorPicker.Title.Icon.ImageRectSize = asset.imageRectSize
						ColorPicker.Title.Icon.Visible = true
						ColorPicker.Title.Text.Position = UDim2.new(0, 30, 0.5, 0)
					end
				end

				local function Set(Value)
					Value = Value or Color3.fromRGB(255, 255, 255)
					Color = Value
					ColorDisplay.BackgroundColor3 = Value
					Callback(Value)
				end

				ColorDisplay.MouseButton1Click:Connect(function()
					-- Simple color picker logic, in full version it would open a color wheel
					local NewColor = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
					Set(NewColor)
				end)

				if Flag then
					RayfieldLibrary.Flags[Flag] = {
						Type = "ColorPicker",
						Color = Color,
						Set = Set
					}
				end

				return {
					Set = Set
				}
			end

			return {
				CreateButton = CreateButton,
				CreateToggle = CreateToggle,
				CreateSlider = CreateSlider,
				CreateInput = CreateInput,
				CreateDropdown = CreateDropdown,
				CreateKeybind = CreateKeybind,
				CreateColorPicker = CreateColorPicker
			}
		end

		return {
			CreateSection = CreateSection,
			Select = SelectTab
		}
	end

	local function CreateSettingsTab()
		local SettingsTab = CreateTab({
			Name = "Settings",
			Icon = "settings"
		})

		local GeneralSection = SettingsTab.CreateSection("General")

		local KeybindToggle = GeneralSection.CreateToggle({
			Name = "Rayfield Keybind",
			CurrentValue = false,
			Flag = "rayfieldOpen",
			Callback = function(Value)
				if Value then
					UserInputService.InputBegan:Connect(function(Input)
						if Input.KeyCode == Enum.KeyCode.K then
							Toggle()
						end
					end)
				end
			end
		})

		local AnalyticsToggle = GeneralSection.CreateToggle({
			Name = "Anonymised Analytics",
			CurrentValue = getSetting("System", "usageAnalytics"),
			Flag = "usageAnalytics",
			Callback = function(Value)
				overrideSetting("System", "usageAnalytics", Value)
			end
		})

		return SettingsTab
	end

	local function LoadConfiguration(Configuration)
		LoadConfiguration(Configuration)
	end

	local function SaveConfiguration()
		SaveConfiguration()
	end

	local function SetConfigurationSaving(Value)
		CEnabled = Value
		if Value then
			addFolder(RayfieldFolder)
			addFolder(ConfigurationFolder)
		end
	end

	SetConfigurationSaving(ConfigurationSaving)

	local MainTab = CreateTab({
		Name = "Main"
	})

	MainTab.Select()

	if not globalLoaded then
		globalLoaded = true
		sendReport("interface_loaded", "Rayfield")
	end

	LoadingFrame:Destroy()

	return {
		CreateTab = CreateTab,
		CreateSettingsTab = CreateSettingsTab,
		Notify = Notify,
		LoadConfiguration = LoadConfiguration,
		SaveConfiguration = SaveConfiguration,
		SetConfigurationSaving = SetConfigurationSaving,
		SetTheme = SetTheme,
		Hide = Hide,
		Show = Show,
		Toggle = Toggle,
		Destroy = Destroy
	}
end

return RayfieldLibrary
