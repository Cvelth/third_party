local github = {}

-- local helper = require(path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/third_party/script/helper")

custom_git_location = nil
function github.custom_location(new_location)
    custom_git_location = new_location
end

function github.fetch_release(owner, name, tag, filename)
    local download_dir = _MAIN_SCRIPT_DIR .. "/third_party/tmp/"
        .. os.target() .. "/"
    local status_dir = _MAIN_SCRIPT_DIR .. "/third_party/status/"
    local status_file = status_dir .. "github_fetch_release_" .. owner
        .. "_" .. name .. "_" .. tag 
    if (filename) then
        status_file = status_file .. "_(" .. filename .. ")"
    end
    status_file = status_file .. "_" .. os.target() .. ".status"

    os.mkdir(download_dir)
    os.mkdir(status_dir)

    if not os.isfile(status_file) then
        --print("- third_party: '" .. name .."' not found.")
        local url = "https://github.com/" .. owner .. "/" .. name
        if filename then
            url = url .. "/releases/download/" .. tag .. "/" .. filename
        else
            url = url .. "/archive/" .. tag .. ".zip"
        end
        print("Download '" .. url .. "'.")

        local filename = filename or (name .. '_' .. tag .. ".zip")
        local target_dir = path.replaceextension(download_dir .. filename, "")
        local downloaded_file = download_dir .. filename
        local result_str, response_code = http.download(url, downloaded_file, {})
        if not (response_code == 200) then
            print ("Error: Download failed: " .. result_str .. " (" .. response_code .. ").")
            return nil
        else
            if not (path.getextension(downloaded_file) == ".zip") then
                print ("Error: Unable to extract unsupported file: '" .. os.realpath(downloaded_file))
            else
                print ("Extract '" .. os.realpath(downloaded_file) .. "'.")
                zip.extract(downloaded_file, target_dir)

                local matches = os.matchdirs(target_dir .. "/*")
                if not (#matches == 1) then
                    print ("Error: The extraction has failed"
                        .." or file structure inside the archive is not supported.")
                else
                    target_dir = matches[1]
                    local file = io.open(status_file, "w")
                    file:write(target_dir)
                    file:close()
                    return target_dir
                end
            end
        end
    else
        local file = io.open(status_file, "r")
        local output = file:read()
        file:close()
        return output
    end
end
function github.clone(owner, name, tag, options, log_location)
    local download_dir = _MAIN_SCRIPT_DIR .. "/third_party/tmp/"
        .. os.target() .. "/"
    local status_dir = _MAIN_SCRIPT_DIR .. "/third_party/status/"

    options = options or ""
    log_location = log_location or (_MAIN_SCRIPT_DIR .. "/third_party/log/")
    local target_dir = download_dir .. name .. "_" .. tag
    local status_file = status_dir .. "github_clone_" .. owner
        .. "_" .. name .. "_" .. tag .. " (" .. options .. ")_" 
        .. os.target() .. ".status"

    os.mkdir(target_dir)
    os.mkdir(status_dir)
    os.mkdir(log_location)

    if not os.isfile(status_file) then
        --print("'" .. name .."' is not present.")
        local git_path = custom_git_location or ""
        local url = "https://github.com/" .. owner .. "/" .. name .. ".git"

        print("Clone '" .. url .. "'.")
        local command = git_path .. "git clone --depth 1 -q "
        .. "-c advice.detachedHead=false "
        .. options .. " --branch " .. tag
        .. " " .. url .. " " .. target_dir
        .. " > " .. log_location .. "/" .. name .. "_git_clone.log"
        command = command:gsub("[\n\r]", " ")
        local ret = os.execute(command)
        if not ret then
            print("Error: 'git clone' failed.")
            return false
        end

        if os.isdir(target_dir) then
            file = io.open(status_file, "w")
            file:write(target_dir)
            file:close()
            return target_dir
        else
            return nil
        end
    else
        file = io.open(status_file, "r")
        local output = file:read()
        file:close()
        return output
    end
end

return github