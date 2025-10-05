-- ============================================
-- PRIVATE API - Internal Functions
-- ============================================
local PRIVATE_CACHIFY_API = {}


PRIVATE_CACHIFY_API.execute_hash_command = function(hash_cmd)
    local handle = io.popen(hash_cmd)
    if not handle then
        return nil
    end
    
    local output = handle:read("*a")
    handle:close()
    return output
end

PRIVATE_CACHIFY_API.process_source = function(hasher, source, mode)
    if dtw.isfile(source) then
        hasher.digest_file(source)
    end

    if dtw.isdir(source) then
        if mode == "last_modification" then
            hasher.digest_folder_by_last_modification(source)
        elseif mode == "content" then
            hasher.digest_folder_by_content(source)
        end
    end
end

-- ============================================
-- PUBLIC API - Exposed Functions
-- ============================================
local CACHIFY_API = {}


CACHIFY_API.execute_config = function(config)
    local hasher = dtw.newHasher()

    for _, source in ipairs(config.sources) do
        PRIVATE_CACHIFY_API.process_source(hasher, source, config.mode)
        
    end
    if config.hash_cmd then 
        for _, hash_cmd in ipairs(config.hash_cmd) do
            PRIVATE_CACHIFY_API.execute_hash_command(hash_cmd)
        end
    end
    local final_hash = hasher.get_value()   
    local cache_path = config.cache_dir .. "/" .. config.cache_name .. "/" .. final_hash 
    local exist = dtw.isfile(cache_path)
    print("cache_path", cache_path)
    if not exist then
        dtw.write_file(cache_path, "")

        if config.ignore_first then
            local itens = dtw.list_files(config.cache_dir .. "/" .. config.cache_name .. "/")
            if #itens == 1 then 
                return false, true  -- not executed, first_execution
            end
        end
        pcall(config.callback)
        return true, true
    end

    return false, false  -- not executed, not first_execution

end 



CACHIFY_API.register_first = function(config)
    local hasher = dtw.newHasher()

    for _, source in ipairs(config.sources) do
        PRIVATE_CACHIFY_API.process_source(hasher, source, config.mode)
        
    end
    if config.hash_cmd then 
        for _, hash_cmd in ipairs(config.hash_cmd) do
            PRIVATE_CACHIFY_API.execute_hash_command(hash_cmd)
        end
    end
    local final_hash = hasher.get_value()   
    local cache_path = config.cache_dir .. "/" .. config.cache_name .. "/" .. final_hash 
    local exist = dtw.isfile(cache_path)
    if not exist then
        dtw.write_file(cache_path, "")
        return true
    end

    return false

end 

-- ============================================
-- CLI Layer - User Interface Functions
-- ============================================
local CACHIFY_CLI = {}



CACHIFY_CLI.parse_arguments = function()
    local config = {}
    
    config.sources = {}
    local total_sources = argv.get_flag_size({ "src", "sources" })
    if total_sources == 0 then
        error("At least one source (--src or --sources) must be provided")
    end

    for i = 1, total_sources do
        local source = argv.get_flag_arg_by_index({ "src", "sources" }, i)
        table.insert(config.sources, source)
    end

    local cmd = argv.get_flag_arg_by_index({ "cmd" }, 1)
    if not cmd then 
        error("cmd flag not provided")
    end 
    config.callback = function()
        os.execute(cmd)
    end 

    config.mode = argv.get_flag_arg_by_index({ "mode" }, 1) or "last_modification"
    if not (config.mode == "last_modification" or config.mode == "content") then
        error("Invalid mode. Use 'last_modification' or 'content'")
    end

    config.cache_dir = argv.get_flag_arg_by_index({ "cache_dir" }, 1) or "./.cachify/"
    config.cache_name = argv.get_flag_arg_by_index({ "cache_name" }, 1) or "default_cache"
    
    local expiration_str = argv.get_flag_arg_by_index({ "expiration" }, 1) or "-1"

    config.expiration = tonumber(expiration_str)
    if not config.expiration then
        error("Invalid expiration value. Must be a number.")
    end    
    config.hash_cmd ={}
    config.ignore_first = argv.flags_exist({ "ignore_first" })

    local total_hash_cmds = argv.get_flag_size({ "hash_cmd" })
    for i = 1, total_hash_cmds do
        local hash_cmd = argv.get_flag_arg_by_index({ "hash_cmd" }, i)
        table.insert(config.hash_cmd, hash_cmd)
    end


    return config
end


CACHIFY_CLI.print_error = function(message)
    print("❌ ERROR: " .. message)
end

CACHIFY_CLI.print_success = function(message)
    print("✅ " .. message)
end

CACHIFY_CLI.print_info = function(message)
    print("ℹ️  " .. message)
end

CACHIFY_CLI.print_warning = function(message)
    print("⚠️  WARNING: " .. message)
end

CACHIFY_CLI.main = function()
    local ok, config_or_error = pcall(CACHIFY_CLI.parse_arguments)
    
    if not ok then
        CACHIFY_CLI.print_error(config_or_error)
        return
    end

    local config = config_or_error

    local executed, is_first = CACHIFY_API.execute_config(config)

    

    if executed then
        if is_first then
            CACHIFY_CLI.print_success("First execution detected. Command executed.")
        else
            CACHIFY_CLI.print_success("Cache miss. Command executed.")
        end
    end 
    if not executed then
        if is_first then
            CACHIFY_CLI.print_info("First execution detected. Not Command executed.")
        else
            CACHIFY_CLI.print_info("Cache Hit. Command Not executed.")
        end
    end
end

-- ============================================
-- Entry Point
-- ============================================
if is_main_script then 
CACHIFY_CLI.main()
end
if not is_main_script then
    return CACHIFY_API
end