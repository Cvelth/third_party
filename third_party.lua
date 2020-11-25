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
function third_party.link(name_table)
    for id, name in pairs(name_table) do
        dependency.link(name)
    end
end
function third_party.link_everything()
    dependency.link_everything()
end

return third_party