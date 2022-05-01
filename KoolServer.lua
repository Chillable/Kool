--[[

Kool, a cool game framework

Author: xFly_Flame1014
Date: 23/3/2022

Github: https://github.com/Chillable/Kool

]]

local RunService = game:GetService("RunService")

local Services = {}

local Kool = script.Parent.Parent

local Assets = Kool.Assets
local Modules = Kool.Modules
local Settings = Kool.Settings

local Signal = require(Modules.Signal)

local EndpointsFolder = Settings.EndpointsFolder

local serverStarted = Assets.Server

local OutputFormat = "[Kool]: %s"

export type Service = {

	Name: string,
	Client: {[any]: any},
	[any]: any,
	Init: () -> nil,
	Start: () -> nil

}

export type Controller = {

	Name: string,
	[any]: any
}

export type Module = {

	Name: string,
	[any]: any

}

export type RemoteSignal = {

	FireClient: (client: Player, any?) -> nil,
	FireAllClients: (any?) -> nil,
	Connect: (handler: (player: Player, any?) -> nil) -> RBXScriptConnection,
	Destroy: () -> nil

}

local SignalRemote do

	RemoteSignal = {}
	RemoteSignal.__index = RemoteSignal

	function RemoteSignal:FireClient(client: Player, ...)

		assert(typeof(client) == "Instance" and client:IsA("Player"), OutputFormat:format("Argument #1 must be a Player"))

		self.__signal:FireClient(client, ...)

	end

	function RemoteSignal:FireAllClients(...)

		self.__signal:FireAllClients(...)

	end

	function RemoteSignal:Connect(handler)

		assert(typeof(handler) == "function", OutputFormat:format("Argument #1 must be a function"))

		return self.__signal.OnServerEvent:Connect(handler)

	end

	function RemoteSignal:Destroy()

		self.__signal:Destroy()

	end

end

local KoolServer do 

	KoolServer = {}

	KoolServer.ReplicatedStorage = game:GetService("ReplicatedStorage")
	KoolServer.ServerStorage = game:GetService("ServerStorage")
	KoolServer.RunService = RunService

	KoolServer.Heartbeat = RunService.Heartbeat

	KoolServer.Utilities = {}

	KoolServer.Utilities.Globals = Modules.Globals

	function KoolServer:Start()

		if serverStarted.Value then

			return warn(OutputFormat:format("Kool has already started"))

		end

		serverStarted.Value = true

		do --Remotes Creation

			if not EndpointsFolder.Value then

				local folder = Instance.new("Folder")

				folder.Parent = game:GetService("ReplicatedStorage")
				folder.Name = "EndpointsFolder"

				EndpointsFolder.Value = folder

			end

			for i, service in pairs(Services) do

				local serviceClient = service.Client

				if serviceClient then

					local ServiceFolder = Instance.new("Folder")

					ServiceFolder.Parent = EndpointsFolder.Value
					ServiceFolder.Name = service.Name

					for i, v in pairs(serviceClient) do

						if typeof(v) == "function" then

							local remoteFunction = Instance.new("RemoteFunction")

							remoteFunction.Parent = ServiceFolder
							remoteFunction.Name = i

							remoteFunction.OnServerInvoke = function(player, ...)

								return v(serviceClient, player, ...)

							end

						elseif v == "REMOTE_SIGNAL" then

							local remoteEvent = Instance.new("RemoteEvent")

							remoteEvent.Parent = ServiceFolder
							remoteEvent.Name = i

							serviceClient[i] = setmetatable({__signal = remoteEvent}, RemoteSignal)

						end

					end

				end

			end

		end

		do --Setup Services

			--Initialize Services
			for i, service in pairs(Services) do

				if typeof(service.Init) == "function" then

					service:Init()

				end

			end

			--Start Services
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

	function KoolServer:CreateRemoteSignal(): RemoteSignal

		return "REMOTE_SIGNAL"

	end

	function KoolServer:CreateEvent()

		return Signal.new()

	end

	function KoolServer:RequireFolder(directory: Instance)

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

		return serviceData

	end

	function KoolServer:GetService(name: string): Service

		assert(typeof(name) == "string", OutputFormat:format("Argument #1 must be a string"))

		local service = Services[name]

		RunService.Heartbeat:Wait()

		if serverStarted.Value then

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

			local serviceEndpoints = EndpointsFolder.Value:FindFirstChild(name)

			if serviceEndpoints then

				serviceEndpoints:Destroy()

			end

		else

			warn(name.." does not exist")

		end

	end

	function KoolServer:GetAllServices(): {string}

		if serverStarted.Value then

			warn(OutputFormat:format("All Services aren't available until Kool has started"))

		else

			local services = {}

			for i, service in pairs(Services) do

				table.insert(services, service.Name)

			end

			return services

		end

	end

	function KoolServer:WaitForServer()

		repeat RunService.Heartbeat:Wait() until serverStarted.Value == true

	end

end	

if RunService:IsServer() then

	return KoolServer

elseif RunService:IsClient() then

	return nil

end
