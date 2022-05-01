--[[

Kool, a cool game framework

Author: xFly_Flame1014
Date: 23/3/2022

Github: https://github.com/Chillable/Kool

]]

local RunService = game:GetService("RunService")

local Controllers = {}
local Services = {}

local Kool = script.Parent.Parent

local Assets = Kool.Assets
local Modules = Kool.Modules
local Settings = Kool.Settings

local Signal = require(Modules.Signal)

local EndpointsFolder = Settings.EndpointsFolder

local serverStarted = Assets.Server
local clientStarted = Assets.Client

local OutputFormat = "[Kool]: %s"

export type Service = {

	Name: string,
	[any]: any

}

export type Controller = {

	Name: string,
	[any]: any,
	Init: () -> nil,
	Start: () -> nil

}

export type Module = {

	Name: string,
	[any]: any

}

local RemoteSignal do

	RemoteSignal = {}
	RemoteSignal.__index = RemoteSignal

	function RemoteSignal:Fire(...)

		self.__signal:FireServer(...)

	end

	function RemoteSignal:Connect(handler)

		assert(typeof(handler) == "function", OutputFormat:format("Argument #1 must be a function"))

		self.__signal.OnClientEvent:Connect(handler)

	end

end

local KoolClient do

	KoolClient = {}

	KoolClient.Player = game:GetService("Players").LocalPlayer
	KoolClient.RunService = game:GetService("RunService")
	KoolClient.ReplicatedStorage = game:GetService("ReplicatedStorage")

	KoolClient.Utilities = {}

	KoolClient.Utilities.Globals = script.Parent.Globals

	KoolClient.Heartbeat = RunService.Heartbeat

	function KoolClient:Start()

		if clientStarted.Value then

			warn(OutputFormat:format("Kool has already started"))

			return

		end
		
		clientStarted.Value = true
		
		--Setup Controllers
		for i, controller in pairs(Controllers) do

			if typeof(controller.Init) == "function" then

				task.spawn(function()

					controller:Init()

				end)

			end

			for i, controller in pairs(Controllers) do

				if typeof(controller.Start) == "function" then

					task.spawn(function()

						debug.setmemorycategory(controller.Name)

						controller:Start()

					end)

				end

			end

		end

	end

	function KoolClient:RequireFolder(directory: Instance)

		assert(typeof(directory) == "Instance", OutputFormat:format("Argument #1 must be an Instance"))

		for i, module in pairs(directory:GetChildren()) do

			if module:IsA("ModuleScript") then

				require(module)

			end

		end

	end

	function KoolClient:CreateEvent()

		return Signal.new()

	end

	function KoolClient:CreateController(controllerData: Controller): Controller

		assert(typeof(controllerData) == "table", OutputFormat:format("Argument #1 must be a table"))
		assert(typeof(controllerData.Name) == "string", OutputFormat:format("Controller's Name must be a string"))
		assert(Controllers[controllerData.Name] == nil, OutputFormat:format(controllerData.Name.." already existed"))

		if Controllers[controllerData.Name] then

			return warn(OutputFormat:format(controllerData.Name.." already exists"))

		end

		Controllers[controllerData.Name] = controllerData

		RunService.Heartbeat:Wait()

		return controllerData

	end

	function KoolClient:GetController(name: string): Controller

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		local controller = Controllers[name]

		RunService.Heartbeat:Wait()

		if clientStarted.Value then

			if controller then 

				return controller

			else

				warn(name.." does not exist")

			end

		else

			warn(OutputFormat:format("All Controllers aren't available until Kool has started"))

		end

	end

	function KoolClient:GetAllControllers(): {string}

		if clientStarted.Value then

			warn(OutputFormat:format("All Controllers aren't available until Kool has started"))

		else

			local controllers = {}

			for i, controller in pairs(Controllers) do

				table.insert(controllers, controller.Name)

			end

			return controllers

		end

	end

	function KoolClient:RemoveController(name:  string)

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		local controller = Controllers[name]

		if controller then

			Controllers[name] = nil

		else

			warn(name.." does not exist")

		end

	end

	function KoolClient:GetService(name: string): Service

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		if serverStarted.Value then

			if Services[name] then

				return Services[name]				

			end

			if EndpointsFolder.Value:FindFirstChild(name) then
				
				local folder = EndpointsFolder.Value:FindFirstChild(name)
				
				local service = {}
				
				service.Name = folder.Name
				
				for i, v in pairs(folder:GetChildren()) do
					
					if v:IsA("RemoteEvent") then
						
						service[v.Name] = setmetatable({__signal = v}, RemoteSignal)
						
					elseif v:IsA("RemoteFunction") then
						
						service[v.Name] = function(...)
							
							return v:InvokeServer(...)
							
						end	
						
					end
					
				end
				
				Services[service.Name] = service
				
				return service
				
			else

				warn(OutputFormat:format(name.." does not exist or isn't available for Client"))

			end

		else

			wait(OutputFormat:format("All Services aren't available until Kool has started"))

		end

	end	

	function KoolClient:WaitForServer()

		repeat RunService.Heartbeat:Wait() until serverStarted.Value == true

	end

end

return KoolClient
