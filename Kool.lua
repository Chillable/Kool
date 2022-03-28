--[[

Kool, a cool game framework

Author: xFly_Flame1014
Date: 23/3/2022

Version 1.5

Github: https://github.com/Chillable/Kool

]]

--//Services
local RunService = game:GetService("RunService")

--//Containers
local Services = {}
local Controllers = {}

local Modules = {}

--//Modules
local KoolStorage = require(script.Modules.KoolStorage)

--//Variables
local OutputFormat = "[Kool]: %s"

local serverStarted = false
local clientStarted = false

--//Types
export type Service = {

	Name: string,
	Client: {[any]: any},
	[any]: any

}

export type Controller = {

	Name: string,
	[any]: any
}

export type Storage = {

	Name: string,
	Protected: boolean,
	AddItem: (key: string | number, item: any) -> nil,
	GetItem: (key: string | number) -> any,
	RemoveItem: (key: string | number)

}

export type Module = {

	Name: string,
	[any]: any

}

--//Main

--//Server
local KoolServer do 

	KoolServer = {}

	local folder = Instance.new("Folder")

	folder.Name = "Remotes"

	KoolServer.RunService = game:GetService("RunService")

	KoolServer.RemotesFolder = folder

	function KoolServer:Start()

		if serverStarted then

			warn(OutputFormat:format("Kool has already started"))

			return

		else

			serverStarted = true

			--Setup Services
			for i, service in pairs(Services) do

				if typeof(service.Init) == "function" then

					task.spawn(function()

						service:Init()

					end)

				end

				for i, service in pairs(Services) do

					if typeof(service.Start) == "function" then

						task.spawn(function()

							debug.setmemorycategory(service.Name)

							service:Start()

						end)

					end

				end

			end

		end

	end

	function KoolServer:AddServices(directory: Instance)

		assert(typeof(directory) == "Instance", OutputFormat:format("Argument #1 must be an Instance"))

		for i, module in pairs(directory:GetChildren()) do

			if module:IsA("ModuleScript") then

				require(module)

			end

		end

	end

	function KoolServer:CreateService(serviceData: Service): Service

		assert(typeof(serviceData) == "table", OutputFormat:format("Argument #1 must be a table"))
		assert(typeof(serviceData.Name) == "string", OutputFormat:format("Service's Name must be a string"))
		assert(Services[serviceData.Name] == nil, OutputFormat:format(serviceData.Name.." already existed"))

		if Services[serviceData.Name] then

			return OutputFormat:format(serviceData.Name.." already exists")

		end

		Services[serviceData.Name] = serviceData

		RunService.Heartbeat:Wait()

		return serviceData

	end

	function KoolServer:GetService(name: string)

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		local service = Services[name]

		RunService.Heartbeat:Wait()

		if serverStarted then

			if not service then 

				warn(name.." does not exist")

			else

				return service

			end

		else

			warn(OutputFormat:format("All Services aren't available until Kool has started"))

		end

	end

	function KoolServer:RemoveService(name:  string)

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		local service = Services[name]

		if service then

			Services[name] = nil

		else

			warn(name.." does not exist")

		end

	end

	function KoolServer:GetAllServices()

		if serverStarted then

			warn(OutputFormat:format("All Services aren't available until Kool has started"))

		else

			local services = {}

			for i, service in pairs(Services) do

				table.insert(services, service.Name)

			end

			return services

		end

	end

	function KoolServer:CreateModule(module: Module)

		assert(typeof(module) == "table" , OutputFormat:format("Argument #1 must be a table"))
		assert(typeof(module.Name), OutputFormat:format("Module's Name must be a string"))

		if Modules[module.Name] then

			return warn(OutputFormat:format(module.Name.." already exists"))

		else 

			Modules[module.Name] = module

			return module

		end

	end

	function KoolServer:GetModule(name: string)

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		if Modules[name] then

			return Modules[name]

		else

			warn(OutputFormat:format(name.." does not exist"))

		end

	end

	function KoolServer:RemoveModule(name: string)

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		if Modules[name] then

			Modules[name] = nil

		else

			warn(OutputFormat:format(name.." does not exist"))

		end

	end

	function KoolServer:AddModules(directory: Instance)

		assert(typeof(directory) == "Instance", OutputFormat:format("Argument #1 must be an Instance"))

		for i, module in pairs(directory:GetChildren()) do

			if module:IsA("ModuleScript") then

				require(module)

				self:AddModules(module)

			end

		end

	end

end

--//Client
local KoolClient do

	KoolClient = {}

	KoolClient.Player = game:GetService("Players").LocalPlayer
	KoolClient.RunService = game:GetService("RunService")

	function KoolClient:Start()

		if clientStarted then

			warn(OutputFormat:format("Kool has already started"))

			return

		end

		clientStarted = true

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

	function KoolClient:AddControllers(directory: Instance)

		assert(typeof(directory) == "Instance", OutputFormat:format("Argument #1 must be an Instance"))

		for i, module in pairs(directory:GetChildren()) do

			if module:IsA("ModuleScript") then

				require(module)

				self:AddControllers(module)

			end

		end

	end

	function KoolClient:CreateController(controllerData: Controller):Controller

		assert(typeof(controllerData) == "table", OutputFormat:format("Argument #1 must be a table"))
		assert(typeof(controllerData.Name) == "string", OutputFormat:format("Controller's Name must be a string"))
		assert(Services[controllerData.Name] == false, OutputFormat:format(controllerData.Name.." already existed"))

		if Controllers[controllerData.Name] then

			return warn(OutputFormat:format(controllerData.Name.." already exists"))

		end

		Controllers[controllerData.Name] = controllerData

		RunService.Heartbeat:Wait()

		return controllerData

	end

	function KoolClient:GetController(name: string)

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		local controller = Controllers[name]

		RunService.Heartbeat:Wait()

		if clientStarted then

			if controller then 

				return controller

			else

				warn(name.." does not exist")

			end

		else

			warn(OutputFormat:format("All Controllers aren't available until Kool has started"))

		end

	end
	
	function KoolClient:GetAllControllers()
		
		if clientStarted then

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

	function KoolClient:GetModule(name: string)

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		if Modules[name] then

			return Modules[name]

		else

			warn(OutputFormat:format(name.." does not exist"))

		end

	end

	function KoolClient:GetService(name: string)

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		local service = Services[name]

		if serverStarted then

			if service then

				if service.Client then

					return service.Client

				else

					warn(OutputFormat:format(name.." is not available to Client"))

				end

			else

				warn(OutputFormat:format(name.." does not exist"))

			end

		else

			warn(OutputFormat:format("All Services aren't available until Kool has started"))

		end

	end

end

if RunService:IsServer() then

	return KoolServer

end

if RunService:IsClient() then

	return KoolClient

end
