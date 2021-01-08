local installer = {}

local function install_impl(pattern, source_location, directory, file_type, log_file, status)
    local matches = os.matchfiles(source_location ..  "/" .. pattern)
    for id, file in pairs(matches) do
		local destination = directory .. file_type .. "/"
            .. path.getrelative(source_location, file)
        os.mkdir(path.getdirectory(destination))
        ret, err = os.copyfile(file, destination)
        if not ret then print(err) end
		status = ret and status
		log_file:write("copy " .. file .. "\nto   " .. destination .. "\n\n")
	end
end

local function install_table(value, source_location, directory, file_type, log_file, status)
    if value then
        if type(value) == "table" then
            for id, pattern in pairs(value) do
                install_impl(pattern, source_location, directory, file_type, log_file, status)
            end
        else
            install_impl(value, source_location, directory, file_type, log_file, status)
        end
    end
end

local function to_string(input)
    if not input then
        return ""
    elseif not (type(input) == "table") then
        return input
    else
        local ret = ""
        for id, value in pairs(input) do
            ret = ret .. " " .. to_string(value)
        end
        return ret
    end
end

function installer.files(dependency_name, table, source_location, output_location, configuration_string)
    local log_location = table["log_location"] or (_MAIN_SCRIPT_DIR .. "/third_party/log")

    local status_dir = _MAIN_SCRIPT_DIR .. "/third_party/status/"
    local status_filename = "install_" .. dependency_name .. "_"
        .. os.target() .. "_" .. configuration_string .. " ("
        .. to_string(table["include"]) .. " "
        .. to_string(table["source"]) .. " "
        .. to_string(table["lib"])
        .. ").status"
    status_filename = status_filename:gsub("[/<>:\"\\|%?%*]", "@")
                                     :gsub("[\n\r]", " ")
                                     :gsub("%s%s+", " ")
                                     :gsub("%s%)", ")")
                                     :gsub("%(%s", "(")
    local status_file = status_dir .. status_filename

    if not os.isfile(status_file) then
        local output_dir = output_location .. os.target() .. "_"
            .. configuration_string .. "/" .. dependency_name .. "/"

        os.mkdir(log_location)
        local log_file = io.open(log_location .. "/" .. dependency_name .. "_install.log", "w")
        local installation_status = true
        for name, value in pairs(table) do
            if name == "include" then
                if not value or value == "default" then
                    value = "include/**"
                end
                install_table(
                    value, source_location, output_dir,
                    "include", log_file, installation_status
                )
            elseif name == "source" then
                if not value or value == "default" then
                    value = "source/**"
                end
                install_table(
                    value, source_location, output_dir,
                    "source", log_file, installation_status
                )
            elseif name == "lib" then
                if not value or value == "default" then
                    value = "lib/**"
                end
                install_table(
                    value, source_location, output_dir,
                    "lib", log_file, installation_status
                )
            elseif name == "log_location" or name == "debug" then
            else
                print("Warning: Ignore unknown parameter '" .. name
                    .. "', action: 'install' in '" .. dependency_name .. "'.")
            end
        end
        log_file:close()

        if (installation_status) then
            local file = io.open(status_file, "w")
            file:write(output_dir)
            file:close()
            return output_dir
        end
        return installation_status
    else
        local file = io.open(status_file, "r")
        local output = file:read()
        file:close()
        return output
    end
end

return installer