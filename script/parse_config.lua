config_parser = {}

local github = require(path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/third_party/script/github")
local cmake = require(path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/third_party/script/cmake")
local dependency = require(path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/third_party/script/dependency")
local installer = require(path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/third_party/script/install")
local download = require(path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/third_party/script/download")

local function yml_to_table(file_content)
	local tinyyaml_location = github.fetch_release("peposso", "lua-tinyyaml", "1.0", nil, "lua-tinyyaml")
	if not os.isfile(tinyyaml_location .. "/tinyyaml.lua") then
		print("Error: Fail to load yaml parser.")
		return nil
    else
		local tinyyaml = require(tinyyaml_location .. "/tinyyaml")
        return tinyyaml.parse(file_content)
	end
end

local user_config = {}
local function default_user_config()
	user_config.verbose = false
	user_config.cmake = nil
	user_config.git = nil
	return true
end
local function value_or_default(value, default)
	if not value or value == "default" then
		return default
	else
		return value
	end
end

local function parse_user_config(table)
	if table then
		for parameter, value in pairs(table) do
			if parameter == "verbose" or parameter == "debug" then
				user_config.verbose = value_or_default(value, false)
			elseif parameter == "cmake" then
				user_config.cmake = value_or_default(value, nil)
				cmake.custom_location(user_config.cmake)
			elseif parameter == "git" then
				user_config.git = value_or_default(value, nil)
				github.custom_location(user_config.git)
			else
				print("Warning: Ignore unknown user config parameter: '"
					.. parameter .. "'.")
			end
		end
		return true
	else
		print("Error: Fail to parse user config file.")
		return false
	end
end

local function want_about_an_ignored_parameter(parameter, supported_parameters,
											   action_type, dependency_name)
	for _, supported_parameter in pairs(supported_parameters) do
		if parameter == supported_parameter then
			return true
		end
	end
	print("Warning: Ignore unknown parameter '" .. parameter
		.. "', action: '" .. action_type .. "' in '" .. dependency_name .. "'.")
end
local function warn_about_ignored_parameters(table, supported_parameters,
											 action_type, dependency_name)
	for parameter, _ in pairs(table) do
		want_about_an_ignored_parameter(parameter, supported_parameters,
										action_type, dependency_name)
	end
end
local function warn_about_required_parameter(table, required_parameter,
											 action_type, dependency_name)
	for parameter, _ in pairs(table) do
		if required_parameter == parameter then
			return true
		end
	end
	print("Error: Parameter '" .. required_parameter .. "' is required by '"
		.. action_type .. "' action in '" .. dependency_name .. "'.")
	return false
end
local function warn_about_required_parameters(table, required_parameters,
											  action_type, dependency_name)
	local status = true										
	for _, required_parameter in pairs(required_parameters) do
		status = warn_about_required_parameter(table, required_parameter,
											   action_type, dependency_name)
				and status
	end
	return status
end
local function check_parameters(table, required_parameters, supported_parameters,
								action_type, dependency_name)
	warn_about_ignored_parameters(table, supported_parameters,
								  action_type, dependency_name)
	return warn_about_required_parameters(table, required_parameters,
										  action_type, dependency_name)
end

local function log_an_event(event_type, event_name, prefix, event_message)
	if user_config.verbose then
		if event_message then
			print(prefix .. "- " .. event_type .. " '" .. event_name .. "': "
				.. event_message .. ".")
		else
			print(prefix .. "- " .. event_type .. " '" .. event_name .. "'.")
		end
	end
end
local function log_a_result(event_type, event_name, prefix, condition)
	if condition then
		log_an_event(event_type, event_name, prefix, "success")
	else
		log_an_event(event_type, event_name, prefix, "fail")
	end
	return condition
end

local function check_fetch_action(name, parser_state)
	if parser_state.source_location then
		print("Warning: Ignore a '" .. name .. "' action "
			.. "because sources have already been acquired.")
		return false
	end
	return true
end
local function check_build_action(name, parser_state)
	local release_state = true
	local debug_state = true
	if parser_state.config == "release" or parser_state.config == "default" then
		if parser_state.release_output_location then release_state = false end
	end
	if parser_state.config == "debug" or parser_state.config == "default" then
		if parser_state.debug_output_location then debug_state = false end
	end
	if not release_state then
		if not debug_state then
			print("Warning: Ignore a '" .. name .. "' action "
				.. "because the target was already installed.")
				return false
		else
			print("Warning: Change '" .. name .. "' action configuration to 'debug' "
				.. "because the 'release' target was already installed.")
			parser_state.config = "debug"
		end
	elseif not debug_state then
		print("Warning: Change '" .. name .. "' action configuration to 'release' "
			.. "because the 'debug' target was already installed.")
		parser_state.config = "release"
	end

	if not parser_state.source_location then
		print("Warning: Ignore a '" .. name .. "' action "
			.. "because no sources were acquired.")
		return false
	end
	return true
end
local function check_depend_action(name, parser_state)
	local release_state = true
	local debug_state = true
	if parser_state.config == "release" or parser_state.config == "default" then
		if parser_state.release_complete then release_state = false end
	end
	if parser_state.config == "debug" or parser_state.config == "default" then
		if parser_state.release_complete then debug_state = false end
	end
	if not release_state then
		if not debug_state then
			print("Warning: Ignore a '" .. name .. "' action "
				.. "because the target is already in use.")
				return false
		else
			print("Warning: Change '" .. name .. "' action configuration to 'debug' "
				.. "because the 'release' target is already in use.")
			parser_state.config = "debug"
		end
	elseif not debug_state then
		print("Warning: Change '" .. name .. "' action configuration to 'release' "
			.. "because the 'debug' target is already in use.")
		parser_state.config = "release"
	end

	release_state = false
	debug_state = false
	if parser_state.config == "release" or parser_state.config == "default" then
		if parser_state.release_output_location then release_state = true end
	end
	if parser_state.config == "debug" or parser_state.config == "default" then
		if parser_state.release_output_location then debug_state = true end
	end
	if not release_state then
		if not debug_state then
			print("Warning: Ignore a 'depend' action "
				.. "because there are no targets installed.")
				return false
		else
			print("Warning: Change '" .. name .. "' action configuration to 'debug' "
				.. "because there are no 'release' targets installed.")
			parser_state.config = "debug"
		end
	elseif not debug_state then
		print("Warning: Change '" .. name .. "' action configuration to 'release' "
			.. "because there are no 'debug' targets installed.")
		parser_state.config = "release"
	end

	return true
end

local function is_present(value, table)
	for id, item in pairs(table) do
		if value == item then
			return true
		end
	end
	return false
end
local function parse_cmake_option_name(name, accepted_options)
	local output = {}
	local leftover_string = ""
	for string in string.gmatch(name, "([^_]+)") do
		if is_present(string, accepted_options.os) then
			if output["os"] then
				return nil
			else
				output["os"] = string
			end
		elseif is_present(string, accepted_options.config) then
			if output["config"] then
				return nil
			else
				output["config"] = string
			end
		else
			leftover_string = leftover_string .. string .. "_"
		end
	end

	leftover_string = leftover_string:sub(1, #leftover_string - 1)
	local name = accepted_options.name[leftover_string]
	if name then
		if output["name"] then
			return nil
		else
			output["name"] = name
		end
		output["os"] = output["os"] or "every"
		output["config"] = output["config"] or "every"
		return output
	else
		return nil
	end
end

function has_environment_variables(value)
	if value then
		if type(value) == "table" then
			for first, second in pairs(value) do
				if has_environment_variables(first) then return true end
				if has_environment_variables(second) then return true end
			end
			return false
		else
			return value:match("%$([a-zA-Z_]+)")
				or value:match("%%[a-zA-Z_]%%")
		end
	end
end
function fix_environment_variables(value, target_os)
	if value then
		if type(value) == "table" then
			local output = {}
			for first, second in pairs(value) do
				output[fix_environment_variables(first, target_os)]
					= fix_environment_variables(second, target_os)
			end
			return output
		else
			if target_os == "windows" then
				if value then value = value:gsub("%$([a-zA-Z_]+)", "%%%1%%") end
			else
				if value then value = value:gsub("%%([a-zA-Z_]+)%%", "$%1") end
			end
			return value
		end
	end
end

local function github_release_action(dependency_name, table, parser_state)
	log_an_event("Action", "github_release", "    ")
	if not check_fetch_action("github_release", parser_state) then return true end
	if not check_parameters(table,
		{ "owner", "tag" },
		{ "owner", "name", "tag", "file" },
		"github_release", dependency_name
	) then return false end
	
	local ret = github.fetch_release(
		table["owner"], (table["name"] or dependency_name),
		table["tag"], table["file"], dependency_name
	)
	if ret then parser_state.source_location = ret end
	return log_a_result("Action", "github_release", "    ", ret)
end
local function github_clone_action(dependency_name, table, parser_state)
	log_an_event("Action", "github_clone", "    ")
	if not check_fetch_action("github_release", parser_state) then return true end
	if not check_parameters(table,
		{ "owner" },
		{ "owner", "name", "branch", "tag", "options" },
		"github_clone", dependency_name
	) then return false end

	if not (table["tag"] or table["branch"]) then
		print("Error: Parameter 'tag' or 'branch' is required by"
			.. " 'github_clone' action in '" .. dependency_name .. "'.")
		return false
	end
	if table["tag"] and table["branch"] then
		print("Warning 'github_clone' action received both 'tag' and 'branch' paramenters."
			.. " 'branch' is ignored.")
	end

	local ret = github.clone(
		table["owner"], table["name"] or dependency_name,
		table["tag"] or table["branch"], table["options"],
		nil, dependency_name
	)
	if ret then parser_state.source_location = ret end
	return log_a_result("Action", "github_clone", "    ", ret)
end
local function cmake_action(dependency_name, table, parser_state)
	log_an_event("Action", "cmake", "    ")
	if not table or table == "default" then table = {} end
	parser_state.config = table["config"] or "default"
	if not check_build_action("cmake", parser_state) then return true end

	local accepted_options = {}
	accepted_options.name = {
		["options"] = "cmake",
		["build_options"] = "build",
		["native_build_options"] = "native_build",
		["install_options"] = "install"
	}
	accepted_options.os = {
		"windows", "linux", "macosx",
		"aix", "bsd", "haiku",
		"solaris", "wii", "xbox360"
	}
	accepted_options.config = { "release", "debug" }

	local release_options = {}
	if parser_state.config == "release" or parser_state.config == "default" then
		release_options["cmake"] = ""
		release_options["build"] = ""
		release_options["native_build"] = ""
		release_options["install"] = ""
	end

	local debug_options = {}
	if parser_state.config == "debug" or parser_state.config == "default" then
		debug_options["cmake"] = ""
		debug_options["build"] = ""
		debug_options["native_build"] = ""
		debug_options["install"] = ""
	end
	for option_name, option_value in pairs(table) do
		if not (option_name == "log_location" or option_name == "config") then
			local parsed_option = parse_cmake_option_name(option_name, accepted_options)
			if parsed_option and option_value then
				if parsed_option.name then
					if parsed_option.os == os.target() or parsed_option.os == "every" then
						if parser_state.config == "release" or parser_state.config == "default" then
							if parsed_option.config == "release" or parsed_option.config == "every" then
								release_options[parsed_option.name] = release_options[parsed_option.name]
									.. " " .. option_value
							end
						end
						if parser_state.config == "debug" or parser_state.config == "default" then
							if parsed_option.config == "debug" or parsed_option.config == "every" then
								debug_options[parsed_option.name] = debug_options[parsed_option.name]
									.. " " .. option_value
							end
						end
					end
				else
					print("Warning: Ignore unknown parameter '" .. option_name
						.. "', action: 'cmake' in '" .. dependency_name .. "'.")
				end
			else
				print("Warning: Ignore unknown parameter '" .. option_name
					.. "', action: 'cmake' in '" .. dependency_name .. "'.")
			end
		end
	end

	local release = {}
	local debug = {}
	if parser_state.config == "release" or parser_state.config == "default" then
		release = cmake.build(
			dependency_name, parser_state.source_location,
			release_options, table["log_location"], "release"
		)
		if release then parser_state.release_output_location = release end
	end
	if parser_state.config == "debug" or parser_state.config == "default" then
		debug = cmake.build(
			dependency_name, parser_state.source_location,
			release_options, table["log_location"], "debug"
		)
		if debug then parser_state.debug_output_location = debug end
	end
	
	return log_a_result("Action", "cmake", "    ", release and debug)
end

local function install_action(dependency_name, table, parser_state)
	log_an_event("Action", "install", "    ")
	if not table or table == "default" then
		print("Error: Ignore 'install' action."
			.. " It cannot be defaulted, you need to specify"
			.. " at least one valid pattern.")
		return false
	end
	parser_state.config = table["config"] or "default"
	if not check_build_action("install", parser_state) then return true end

	warn_about_ignored_parameters(table,
		{ "include", "source", "lib", "log_location", "debug" },
		"install", dependency_name
	)

	local release = {}
	local debug = {}
	if parser_state.config == "release" or parser_state.config == "default" then
		parser_state.release_output_location = _MAIN_SCRIPT_DIR .. "/third_party/output/"
		local release = installer.files(dependency_name, table,
										parser_state.source_location,
										parser_state.release_output_location,
										"release")
		if release then parser_state.release_output_location = release end
	end
	if parser_state.config == "debug" or parser_state.config == "default" then
		parser_state.debug_output_location = _MAIN_SCRIPT_DIR .. "/third_party/output/"
		local debug = installer.files(dependency_name, table,
									  parser_state.source_location,
									  parser_state.debug_output_location,
									  "debug")
		if debug then parser_state.debug_output_location = debug end
	end
	
	return log_a_result("Action", "install", "    ", release and debug)
end

local function download_action(dependency_name, table, parser_state)
	log_an_event("Action", "download", "    ")
	if not check_fetch_action("download", parser_state) then return true end
	if not table or table == "default" then
		print("Error: Ignore 'download' action."
			.. " It cannot be defaulted, you need to specify an url.")
		return false
	end
	warn_about_ignored_parameters(table, { "url", "filename" }, "download", dependency_name)
	if not check_parameters(table,
		{ "url" },
		{ "url", "filename" },
		"download", dependency_name
	) then return false end

	local ret = download.download(dependency_name, table["url"], table["filename"])
	if ret then parser_state.source_location = ret end
	return log_a_result("Action", "download", "    ", ret)
end

local function depend_action(dependency_name, table, parser_state)
	log_an_event("Action", "depend", "    ")
	if not check_depend_action("depend", parser_state) then return true end
	if not table then
		table = {}
		table["include"] = "default"
		table["lib"] = "default"
		table["files"] = "default"
		table["vpaths"] = "default"
	end
	warn_about_ignored_parameters(table,
		{ "include", "lib", "files", "vpaths" },
		"depend", dependency_name
	)
	local ret = dependency.setup(dependency_name, table, parser_state)
	return log_a_result("Action", "depend", "    ", ret)
end
local function global_action(dependency_name, table, parser_state)
	log_an_event("Action", "global", "    ")
	if not table then
		table = {}
		table["include"] = "default"
		table["lib"] = "default"
		table["files"] = "default"
		table["vpaths"] = "default"
	else
		if os.istarget("windows") or os.istarget("linux") or os.istarget("macosx") then
			table["include"] = fix_environment_variables(table["include"], os.target())
			table["lib"] = fix_environment_variables(table["lib"], os.target())
			table["files"] = fix_environment_variables(table["files"], os.target())
			table["vpaths"] = fix_environment_variables(table["vpaths"], os.target())
		elseif has_environment_variables(table["include"])
			or has_environment_variables(table["lib"])
			or has_environment_variables(table["files"])
			or has_environment_variables(table["vpaths"])
		then
			print("Warning: target OS does not support environment variable correction. "
				.. "'global' action could behave incorrectly.")
		end
	end
	warn_about_ignored_parameters(table,
		{ "include", "lib", "files", "vpaths" },
		"depend", dependency_name
	)
	local ret = dependency.setup_global(dependency_name, table, parser_state)
	return log_a_result("Action", "global", "    ", ret)
end

local function parse_action(dependency_name, action_type, table, parser_state)
	if table == "yaml_null" or table == "default" then table = nil end
	if action_type == "github_release" then
		return github_release_action(dependency_name, table, parser_state)
	elseif action_type == "github_clone" then
		return github_clone_action(dependency_name, table, parser_state)
	elseif action_type == "cmake" then
		return cmake_action(dependency_name, table, parser_state)
	elseif action_type == "install" then
		return install_action(dependency_name, table, parser_state)
	elseif action_type == "download" then
		return download_action(dependency_name, table, parser_state)
	elseif action_type == "depend" then
		return depend_action(dependency_name, table, parser_state)
	elseif action_type == "global" then
		return global_action(dependency_name, table, parser_state)
	else
		print("Error: Unknown action: '" .. action_type .. "'.")
		return false
	end
end
local function parse_dependency(dependency_name, table)
	log_an_event("Dependency", dependency_name, "  ")
	local parser_state = {}
	for id, subtable in pairs(table) do
		for action_type, value in pairs(subtable) do
			if not parse_action(dependency_name, action_type, value, parser_state) then
				return log_a_result("Dependency", dependency_name, "  ", false)
			end
		end
	end
	return log_a_result("Dependency", dependency_name, "  ", true)
end
local function parse_config(table)
	if table then
		local success_flag = true
		for dependency_name, value in pairs(table) do
			success_flag = parse_dependency(dependency_name, value) and success_flag
		end
		return success_flag
	end
	return false
end

function config_parser.parse(config_file, user_config_file)
	if not os.isfile(config_file) then
		print("Error: Config file does not exist.")
		return false
	end

	if os.isfile(user_config_file) then
    	local f = assert(io.open(user_config_file, "rb"))
    	local user_config_content = f:read("*all")
		f:close()

		local user_config_table = yml_to_table(user_config_content)
		if not user_config_table then return false end
		if not parse_user_config(user_config_table) then return false end
	else
		if not default_user_config() then return false end
	end

    local f = assert(io.open(config_file, "rb"))
    local config_content = f:read("*all")
	f:close()

	if not(#config_content:match "[^%s]*" == 0) then
		local config_table = yml_to_table(config_content)
		if not config_table then return false end
		return parse_config(config_table)
	end
end

return config_parser