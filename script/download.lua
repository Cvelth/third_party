local download = {}

function download.download(name, url, filename)
    local download_dir = _MAIN_SCRIPT_DIR .. "/third_party/tmp/"
        .. os.target() .. "/"
    local status_dir = _MAIN_SCRIPT_DIR .. "/third_party/status/"
    local status_filename = "download_" .. name .. "_"
        .. os.target() .. "_" .. filename .. " ("
        .. url .. ").status"
    status_filename = status_filename:gsub("[/<>:\"\\|%?%*]", "@")
                                     :gsub("[\n\r]", " ")
                                     :gsub("%s%s+", " ")
                                     :gsub("%s%)", ")")
                                     :gsub("%(%s", "(")
    local status_file = status_dir .. status_filename

    os.mkdir(download_dir)
    os.mkdir(status_dir)

    if not os.isfile(status_file) then
        print("Download '" .. url .. "'.")
        local downloaded_file = download_dir .. filename
        local result_str, response_code = http.download(url, downloaded_file, {})
        if not (response_code == 200) then
            print ("Error: Download failed: " .. result_str .. " (" .. response_code .. ").")
            return nil
        else
            local file = io.open(status_file, "w")
            file:write(download_dir)
            file:close()
            return download_dir
        end
    else
        local file = io.open(status_file, "r")
        local output = file:read()
        file:close()
        return output
    end
end

return download