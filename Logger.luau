--[[
    LoggerModule - Copyright (c) 2023 Dottik

    - This script is in a finished state.
	- The script aims to provide a simple logging mechanism, which allows developers to trace logs on the console with little to no problem.
]]

local RunService = game:GetService("RunService")
local logger = {}

--- Construct a Logger.
--- @param loggerName string The name of the logger. Used when printing to trace logs.
--- @param studioOnly boolean If true, the logs will only show up on Roblox Studio.
--- @return Logger logger An instance of af a logger, ready to be used.
function logger.new(loggerName: string, studioOnly: boolean): Logger
	--- @class Logger
	local self = {
		--- The name of the logger, used when building it.
		LoggerName = loggerName,
		--- Whether or not the logger should only print when it is on studio
		StudioOnly = studioOnly,
	}

	--- Emits a print into the console. Labeled as an Information level print.
	--- @param message string The message to be printed.
	function self:PrintInformation(message: string)
		if self.StudioOnly and not RunService:IsStudio() then
			return
		end
		print(("[INFO/%s] %s"):format(self.LoggerName, message))
	end

	--- Emits a print into the console. Labeled as an Warning level print.
	--- @param message string The message to be printed.
	function self:PrintWarning(message: string)
		if self.StudioOnly and not RunService:IsStudio() then
			return
		end
		print(("[WARN/%s] %s"):format(self.LoggerName, message))
	end

	--- Emits a warning into the console. Labeled as an Error level print.
	--- @param message string The message to be warned.
	function self:PrintError(message: string)
		if self.StudioOnly and not RunService:IsStudio() then
			return
		end
		warn(("[ERROR/%s] %s"):format(self.LoggerName, message))
	end

	--- Emits an error into the console. Labeled as an Critical level print.
	--- Remarks: This will stop the caller thread.
	--- @param message string The message to be errored with.
	function self:PrintCritical(message: string)
		if self.StudioOnly and not RunService:IsStudio() then
			return
		end
		error(("[CRITICAL/%s] %s"):format(self.LoggerName, message))
	end

	return table.freeze(self) -- Freeze.
end

export type Logger = {
	LoggerName: string,
	StudioOnly: boolean,

	PrintInformation: (self: Logger, message: string) -> (),
	PrintWarning: (self: Logger, message: string) -> (),
	PrintError: (self: Logger, message: string) -> (),
	PrintCritical: (self: Logger, message: string) -> (),
}

return logger
