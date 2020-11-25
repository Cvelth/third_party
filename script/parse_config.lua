config_parser = {}

local github = require(path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/third_party/script/github")
local cmake = require(path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/third_party/script/cmake")
local dependency = require(path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/third_party/script/dependency")
local installer = require(path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/third_party/script/install")

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
	if parser_state.output_location then
		print("Warning: Ignore a '" .. name .. "' action "
			.. "because the target was already installed.")
		return false
	end
	if not parser_state.source_location then
		print("Warning: Ignore a '" .. name .. "' action "
			.. "because no sources were acquired before it.")
		return false
	end
	return true
end
local function check_depend_action(name, parser_state)
	if parser_state.is_complete then
		print("Warning: Ignore a '" .. name .. "' action "
			.. "because the target is already in use.")
		return false
	end
	if not parser_state.output_location then
		print("Warning: Ignore a 'depend' action "
			.. "because there are no targets installed.")
		return false
	end
	return true
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
	if not check_build_action("cmake", parser_state) then return true end
	if not table or table == "default" then table = {} end
	warn_about_ignored_parameters(table, {
		"options", "windows_options", "linux_options", 
		"macosx_options", "build_options", "native_build_options",
		"windows_build_options", "windows_native_build_options",
		"linux_build_options", "linux_native_build_options",
		"macosx_build_options", "macosx_native_build_options",
		"install_options", "log_location", "debug"
	}, "cmake", dependency_name)

	local options = {}
	options["cmake"] = table["options"] or ""
	options["build"] = table["build_options"] or ""
	options["native_build"] = table["native_build_options"] or ""
	options["install"] = table["install_options"] or ""
	
	if os.target() == "windows" then
		options["cmake"] = options["cmake"] .. " "
			.. (table["windows_options"] or "")
		options["build"] = options["build"] .. " "
			.. (table["windows_build_options"] or "")
		options["native_build"] = options["native_build"] .. " "
			.. (table["windows_native_build_options"] or "")
	elseif os.target() == "linux" then
		options["cmake"] = options["cmake"] .. " "
			.. (table["linux_options"] or "")
		options["build"] = options["build"] .. " "
			.. (table["linux_build_options"] or "")
		options["native_build"] = options["native_build"] .. " "
			.. (table["linux_native_build_options"] or "")
	elseif os.target() == "macosx" then
		options["cmake"] = options["cmake"] .. " "
			.. (table["macosx_options"] or "")
		options["build"] = options["build"] .. " "
			.. (table["macosx_build_options"] or "")
		options["native_build"] = options["native_build"] .. " "
			.. (table["macosx_native_build_options"] or "")
	else
		print("Warning: system-specific options are not supported on '" .. os.target() .. "'.")
	end

	local ret = cmake.build(
		dependency_name, parser_state.source_location,
		options, table["log_location"], table["debug"]
	)
	if ret then parser_state.output_location = ret end
	return log_a_result("Action", "cmake", "    ", ret)
end

local function install_action(dependency_name, table, parser_state)
	log_an_event("Action", "install", "    ")
	if not check_build_action("install", parser_state) then return true end
	if not table or table == "default" then
		print("Error: Ignore 'install' action."
			.. " It cannot be defaulted, you need to specify"
			.. " at least one valid pattern.")
		return false
	end
	warn_about_ignored_parameters(table,
		{ "include", "source", "lib", "log_location", "debug" },
		"install", dependency_name
	)

	parser_state.output_location = _MAIN_SCRIPT_DIR .. "/third_party/output/"
	local ret = installer.files(dependency_name, table, parser_state)
	if ret then parser_state.output_location = ret end
	return log_a_result("Action", "install", "    ", ret)
end

local function depend_action(dependency_name, table, parser_state)
	log_an_event("Action", "depend", "    ")
	if not check_depend_action("depend", parser_state) then return true end
	if not table or table == "default" then table = {} end
	warn_about_ignored_parameters(table,
		{ "include", "lib", "files", "vpaths" },
		"github_clone", dependency_name
	)
	local ret = dependency.setup(dependency_name, table, parser_state.output_location)
	if ret then parser_state.is_complete = true end
	return log_a_result("Action", "depend", "    ", ret)
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
	elseif action_type == "depend" then
		return depend_action(dependency_name, table, parser_state)
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
	
	local config_table = yml_to_table(config_content)
	if not config_table then return false end
	return parse_config(config_table)
end

return config_parser