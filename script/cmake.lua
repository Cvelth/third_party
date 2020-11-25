local cmake = {}

custom_cmake_location = nil
function cmake.custom_location(new_location)
    custom_cmake_location = new_location
end

function cmake.build(name, directory_path, options, log_location, debug)
    local configuration_string = "release"
    if debug then configuration_string = "debug" end
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
        print("Getting '" .. name .. "' ready.")
        local cmake_path = custom_cmake_location or ""
        local configuration_option = "Release"
        if debug then configuration_option = "Debug" end
        print("  Running '" .. cmake_path .. "cmake'.")
        if not os.execute(cmake_path .. "cmake"
            .. " -B" .. build_dir
            .. " -A x64 -DCMAKE_BUILD_TYPE=" .. configuration_option
            .. " -S " .. directory_path .. " "
            .. options["cmake"]
            .. " --no-warn-unused-cli"
            .. " > " .. log_location .. "/"
            .. name .. "_cmake_release.log"
        ) then
            print("Error: 'cmake' ("
                .. configuration_string .. ") failed.")
            return false
        end
        print("  Building '" .. name .. "'.")
        if not os.execute(cmake_path .. "cmake"
            .. " --build " .. build_dir
            .. " --config " .. configuration_option
            .. " --parallel "
            .. options["build"] .. " "
            .. " -- "
            .. options["native_build"] .. " "
            .. " > " .. log_location .. "/"
            .. name .. "_cmake_build_release.log"
        ) then
            print("Error: 'cmake --build' ("
                .. configuration_string .. ") failed.")
            return false
        end
        print("  Installing '" .. name .. "'.")
        if not os.execute(cmake_path .. "cmake"
            .. " --install " .. build_dir
            .. " --config " .. configuration_option
            .. " --prefix " .. output_dir
            .. options["install"]
            .. " > " .. log_location .. "/"
            .. name .. "_install_release.log"
        ) then
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