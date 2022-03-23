--//Services
local RunService = game:GetService("RunService")

--//Containers
local Storages = {}
local StorageData = {}

local Services = {}
local Controllers = {}

--//Variables
local OutputFormat = "[Kool]: %s"

local started = false
local clientStarted = false

--//Types
export type Service = {

	Name: string,
	Client: {},
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

--//Main
local StorageClass do

	StorageClass = {}

	StorageClass.__index = StorageClass

	function StorageClass:AddItem(key: string | number, item: any)

		assert(typeof(key) == "string" or typeof(key) == "number", OutputFormat:format("Argument #1 must be a string or number"))
		assert(item, OutputFormat:format("Argument #2 must be a value"))

		local Storage = Storages[self.Name]

		RunService.Heartbeat:Wait()

		if self.Protected and RunService:IsServer() then

			Storage[key] = item

		elseif RunService:IsClient() and not self.Protected then

			Storage[key] = item

		elseif self.Protected and RunService:IsClient() then

			warn(OutputFormat:format(self.Name.." is protected, Client cannot edit or view it"))

		end

	end

	function StorageClass:GetItem(key: string | number)

		assert(typeof(key) == "string" or typeof(key) == "number", OutputFormat:format("Argument #1 must be a string or number"))

		local Storage = Storages[self.Name]
		local Item = Storage[key]

		RunService.Heartbeat:Wait()

		if self.Protected and RunService:IsServer() then

			return Item

		elseif RunService:IsClient() and not self.Protected then

			return Item

		elseif self.Protected and RunService:IsClient() then

			warn(OutputFormat:format(self.Name.." is protected, Client cannot edit or view it"))

		end

	end

	function StorageClass:RemoveItem(key: string | number)

		assert(typeof(key) == "string" or typeof(key) == "number", OutputFormat:format("Argument #1 must be a string or number"))

		local Storage = Storages[self.Name]
		local Item = Storage[key]

		RunService.Heartbeat:Wait()

		if key then

			if self.Protected and RunService:IsServer() then

				Storage[key] = nil

			elseif RunService:IsClient() and not self.Protected then

				Storage[key] = nil

			elseif self.Protected and RunService:IsClient() then

				warn(OutputFormat:format(self.Name.." is protected, Client cannot edit or view it"))

			end

		else

			warn(OutputFormat:format(key.." does not exist"))

		end	

	end

end

--//Server
local KoolServer do 

	KoolServer = {}

	function KoolServer:Start()

		if started then

			warn(OutputFormat:format("Kool has already started"))

			return

		else

			started = true

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

				self:AddServices(module)

			end

		end

	end

	function KoolServer:CreateService(serviceData: Service): Service

		assert(typeof(serviceData) == "table", OutputFormat:format("Argument #1 must be a table"))
		assert(typeof(serviceData.Name) == "string", OutputFormat:format("Service's Name must be a string"))
		assert(Services[serviceData.Name] == nil, OutputFormat:format(serviceData.Name.." already existed"))

		Services[serviceData.Name] = serviceData

		RunService.Heartbeat:Wait()

		return serviceData

	end

	function KoolServer:GetService(name: string)

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		local service = Services[name]

		RunService.Heartbeat:Wait()

		if started then

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

	function KoolServer:CreateStorage(storageData: Storage): Storage

		assert(typeof(storageData) == "table", OutputFormat:format("Argument #1 must be a table"))
		assert(typeof(storageData.Name) == "string", OutputFormat:format("Storage's Name must be a string"))
		assert(Storages[storageData.Name], OutputFormat:format(storageData.Name.." already existed"))

		Storages[storageData.Name] = {}
		StorageData[storageData.Name] = storageData

		RunService.Heartbeat:Wait()

		return setmetatable(storageData, StorageClass)

	end

	function KoolServer:RemoveStorage(name: string)

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		local Storage = Storages[name]

		if StorageData[name] then

			StorageData[name] = nil
			Storages[name] = nil

		else

			warn(OutputFormat:format(name.." does not exist"))

		end

	end

	function KoolServer:GetStorage(name: string)

		assert(typeof(name) == "string" or typeof(name) == "number", OutputFormat:format("Argument #1 must be a string or number"))

		local Storage = StorageData[name]

		if Storage then

			return setmetatable(Storage, StorageClass)

		else

			warn(OutputFormat:format(name.." does not exist"))

		end

	end

end

--//Client
local KoolClient do

	KoolClient = {}

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

		Controllers[controllerData.Name] = controllerData

		RunService.Heartbeat:Wait()

		return controllerData

	end

	function KoolClient:GetController(name: string)

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		local controller = Controllers[name]

		RunService.Heartbeat:Wait()

		if started then

			if controller then 

				return controller

			else

				warn(name.." does not exist")

			end

		else

			warn(OutputFormat:format("All Controllers aren't available until Kool has started"))

		end

	end

	function KoolClient:RemoveService(name:  string)

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		local controller = Controllers[name]

		if controller then

			Controllers[name] = nil

		else

			warn(name.." does not exist")

		end

	end

	function KoolClient:GetStorage(name: string)

		assert(typeof(name) == "string" or typeof(name) == "number", OutputFormat:format("Argument #1 must be a string or number"))

		local Storage = StorageData[name]

		if Storage then

			if Storage.Protected then

				warn(OutputFormat:format(name.." is protected, Client cannot edit or view it"))

			else

				return setmetatable(Storage, StorageClass)

			end

		else

			warn(OutputFormat:format(name.." does not exist"))

		end

	end

end


if RunService:IsServer() then

	return KoolServer

end

if RunService:IsClient() then

	return KoolClient

end
