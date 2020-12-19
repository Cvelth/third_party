local third_party = {}

local config = require(path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/third_party/script/parse_config")
function third_party.acquire(filename)
    config_file = filename or "third_party"
    user_config_file = config_file .. ".user"

    print("- third_party: acquire dependencies (config: '" .. config_file .. ".yml').")
    local parsing_result = config.parse(config_file .. '.yml',
                                        user_config_file .. '.yml')
    if parsing_result then
        print("- third_party: success")
    else
        print("- third_party: fail")
    end
end

local dependency = require(path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/third_party/script/dependency")
local function depend_impl(input, config)
    if input then
        if type(input) == "table" then
            for id, value in pairs(input) do
                dependency.depend_on(value, config)
            end
        else
            dependency.depend_on(input, config)
        end
    else
        print("Warning: Ignore empty 'depends_on' function call. "
            .. "At least one argument is required")
    end
end

function third_party.depends(table, config)
    if config then
        depend_impl(table, config)
    else
        filter "configurations:release"
            depend_impl(table, "release")
        filter "configurations:debug"
            depend_impl(table, "debug")
        filter {}
    end
end
function third_party.depends_on_everything(config)
    if config then
        dependency.depend_on_everything(config)
    else
        filter "configurations:release"
            dependency.depend_on_everything("release")
        filter "configurations:debug"
            dependency.depend_on_everything("debug")
        filter {}
    end
end

return third_party