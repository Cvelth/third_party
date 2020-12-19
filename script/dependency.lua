local dependency = {}

global_dependency_table = {}

local function setup_impl(name, table, parser_state)
    local include = table["include"]
    if tostring(include) == 'yaml.null' or include == "default" then
        include = "include";
    end
    global_dependency_table[name].include_location = include

    local lib = table["lib"]
    if tostring(lib) == 'yaml.null' or lib == "default" then
        lib = "lib/**";
    end
    global_dependency_table[name].lib_pattern = lib

    local files = table["files"]
    if tostring(files) == 'yaml.null' or files == "default" then
        files = { "source/**", "include/**" }
    end
    global_dependency_table[name].file_list = files

    local vpath_patterns = table["vpaths"]
    if not vpath_patterns or tostring(vpath_patterns) == 'yaml.null' then
        vpath_patterns = "default"
    end
    if not files and not (vpath_patterns == "default") then
        print("Warning: Ignore 'vpaths' parameter."
            .." It doesn't make sense without a valid 'files' pattern.")
    end
    global_dependency_table[name].vpath_patterns = vpath_patterns
end

function dependency.setup(name, table, parser_state)
    if global_dependency_table[name] then
        print("Error: '" .. name .. "' is used more than once. Dependency names must not repeat.")
        return false
    end
    global_dependency_table[name] = {}

    if parser_state.config == "release" or parser_state.config == "default" then
        global_dependency_table[name].config = "release"
        global_dependency_table[name].release_directory = parser_state.release_output_location
    end
    if parser_state.config == "debug" or parser_state.config == "default" then
        if global_dependency_table[name].config == "release" then
            global_dependency_table[name].config = "any"
        else
            global_dependency_table[name].config = "debug"
        end
        global_dependency_table[name].debug_directory = parser_state.debug_output_location
    end

    setup_impl(name, table, parser_state)

    if parser_state.config == "release" or parser_state.config == "default" then
        parser_state.release_complete = true
    end
    if parser_state.config == "debug" or parser_state.config == "default" then
        parser_state.debug_complete = true
    end

    return true
end

function dependency.setup_global(name, table, parser_state)
    if global_dependency_table[name] then
        print("Error: '" .. name .. "' is used more than once. Dependency names must not repeat.")
        return false
    end
    global_dependency_table[name] = {}

    if parser_state.config or parser_state.release_output_location or parser_state.debug_output_location then
        print("Warning: '" .. name .. "' has a 'global' action after the 'config' was already defined. "
            .. "This could break other 'depend' (or 'global') actions of the dependency.")
    end
    parser_state.config = "global"
    global_dependency_table[name].config = "global"
    
    setup_impl(name, table, parser_state)

    parser_state.release_complete = true
    parser_state.debug_complete = true

    return true
end

function depend_impl(name, table_entry, config)
    if not (name and table_entry) then
        print("Error: Unable to depend on an unknown dependency '" .. name .. "'."
            .."\nMake sure it's included in the config file"
            .. " and is successfully installed.")
        return false
    end

    local directory = ""
    if table_entry.config == "global" then
        directory = ""
    elseif config == "release" then
        if (table_entry.config == "release" or table_entry.config == "any") 
                and table_entry.release_directory then
            directory = table_entry.release_directory
        else
            print("Error: Unable to depend on a dependency '" .. name 
                .. "' in release mode it was not build in.")
            return nil
        end
    elseif config == "debug" then
        if (table_entry.config == "debug" or table_entry.config == "any") 
                and table_entry.debug_directory then
            directory = table_entry.debug_directory
        else
            print("Error: Unable to depend on a dependency '" .. name 
                .. "' in debug mode it was not build in.")
            return nil
        end
    elseif config == "any" then
        if table_entry.release_directory then
            directory = table_entry.release_directory
        elseif table_entry.debug_directory then
            directory = table_entry.debug_directory
        else
            print("Error: Unable to depend on a dependency '" .. name 
                .. "': it was not built in a supported configuration.")
            return nil
        end
    else
        print("Error: Unable to depend on a dependency '" .. name
            .. "': unsupported configuration requested '" .. config .. "'.")
        return nil
    end

    local include_location = table_entry.include_location
    if include_location then
        if type(include_location) == "table" then
            for id, pattern in pairs(include_location) do
                includedirs { directory .. pattern }
            end
        else
            includedirs { directory .. include_location }
        end
    end
    local lib_pattern = table_entry.lib_pattern
    if lib_pattern then
        if type(lib_pattern) == "table" then
            for id, pattern in pairs(lib_pattern) do
                links { directory .. pattern }
            end
        else
            links { directory .. lib_pattern }
        end
    end
    local file_list = table_entry.file_list
    if file_list then
        if type(file_list) == "table" then
            for id, pattern in pairs(file_list) do
                files { directory .. pattern }
            end
        else
            files { directory .. file_list }
        end
    end
    local vpath_patterns = table_entry.vpath_patterns
        if vpath_patterns then
        if type(vpath_patterns) == "table" then
            for left, right in pairs(vpath_patterns) do
                vpaths {
                    [left] = directory .. right
                }
            end
        elseif vpath_patterns and not (vpath_patterns == "default") then
            print("Warning: 'vpath_patterns' parameter must either be"
                .. " a 'default', an empty value or a dictionary"
                .. " containing pairs of 'vpath_dir': 'path_pattern'.")
        end
        vpaths {
            [name .. "/include"] = directory .. "include/**",
            [name .. "/source"] = directory .. "source/**"
        }
    end
    return true
end

function dependency.depend_on(name, config)
    return depend_impl(name, global_dependency_table[name], config or "any")
end
function dependency.depend_on_everything(config)
    local ret = true
    for name, table_entry in pairs(global_dependency_table) do
        ret = depend_impl(name, table_entry, config or "any") and ret
    end
    return ret
end

return dependency