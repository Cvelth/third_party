local cmake = {}

custom_cmake_location = nil
function cmake.custom_location(new_location)
    custom_cmake_location = new_location
end

function cmake.build(name, directory_path, options, log_location, configuration_string)
    local status_dir = _MAIN_SCRIPT_DIR .. "/third_party/status/"
    local status_filename = "cmake_build_" .. name .. "_"
        .. os.target() .. "_" .. configuration_string .. " ("
        .. options["cmake"] .. " " .. options["build"] .. " "
        .. options["native_build"] .. " "  .. options["install"]
        .. ").status"
    status_filename = status_filename:gsub("[/<>:\"\\|%?%*]", "@")
                                     :gsub("[\n\r]", " ")
                                     :gsub("%s%s+", " ")
                                     :gsub("%s%)", ")")
                                     :gsub("%(%s", "(")
    local status_file = status_dir .. status_filename
    log_location = log_location or (_MAIN_SCRIPT_DIR .. "/third_party/log")
    local build_dir = _MAIN_SCRIPT_DIR .. "/third_party/build/" .. os.target() .. "_"
        .. configuration_string .. "/" .. name .. "/"
    local output_dir = _MAIN_SCRIPT_DIR .. "/third_party/output/" .. os.target() .. "_"
        .. configuration_string .. "/" .. name .. "/"
    os.mkdir(log_location)
    os.mkdir(build_dir)
    os.mkdir(output_dir)
    if not os.isfile(status_file) then
        print("Getting '" .. name .. "' (" .. configuration_string .. ") ready.")
        local cmake_path = custom_cmake_location or ""
        local cmake_configuration = "Release"
        if not (configuration_string == "release") then cmake_configuration = "Debug" end
        local platform = ""
        if os.target() == "windows" then platform = "-A x64" end

        print("  Running '" .. cmake_path .. "cmake'.")
        local cmake_command = cmake_path .. "cmake"
            .. " -B" .. build_dir .. " " .. platform
            .. " -DCMAKE_BUILD_TYPE=" .. cmake_configuration
            .. " -S " .. directory_path .. " "
            .. options["cmake"]
            .. " --no-warn-unused-cli"
            .. " > " .. log_location .. "/"
            .. name .. "_cmake_" .. configuration_string .. ".log"
        cmake_command = cmake_command:gsub("[\n\r]", " ")
        if not os.execute(cmake_command) then
            print("Error: 'cmake' ("
                .. configuration_string .. ") failed.")
            return false
        end

        print("  Building '" .. name .. "'.")
        local cmake_build_command = cmake_path .. "cmake"
            .. " --build " .. build_dir
            .. " --config " .. cmake_configuration
            .. " --parallel "
            .. options["build"] .. " "
            .. " -- "
            .. options["native_build"] .. " "
            .. " > " .. log_location .. "/"
            .. name .. "_cmake_build_" .. configuration_string .. ".log"
        cmake_build_command = cmake_build_command:gsub("[\n\r]", " ")
        if not os.execute(cmake_build_command) then
            print("Error: 'cmake --build' ("
                .. configuration_string .. ") failed.")
            return false
        end

        print("  Installing '" .. name .. "'.")
        local cmake_install_command = cmake_path .. "cmake"
            .. " --install " .. build_dir
            .. " --config " .. cmake_configuration
            .. " --prefix " .. output_dir
            .. options["install"]
            .. " > " .. log_location .. "/"
            .. name .. "_install_" .. configuration_string .. ".log"
        cmake_install_command = cmake_install_command:gsub("[\n\r]", " ")
        if not os.execute(cmake_install_command) then
            print("Error: 'cmake --install' ("
                .. configuration_string .. ") failed.")
            return false
        end

        local file = io.open(status_file, "w")
        file:write(output_dir)
        file:close()
        return output_dir
    else
        local file = io.open(status_file, "r")
        local output = file:read()
        file:close()
        return output
    end
end

return cmake