-- ============================================
-- PRIVATE API - Internal Functions
-- ============================================
local PRIVATE_CACHIFY_API = {}

PRIVATE_CACHIFY_API.validate_mode = function(mode)
    return mode == "last_modification" or mode == "content"
end

PRIVATE_CACHIFY_API.execute_hash_command = function(hash_cmd)
    local handle = io.popen(hash_cmd)
    if not handle then
        return nil, "Failed to execute command"
    end
    
    local output = handle:read("*a")
    handle:close()
    return output, nil
end

PRIVATE_CACHIFY_API.process_source = function(hasher, source, mode)
    if dtw.isfile(source) then
        hasher.digest_file(source)
        return true
    end
    
    if dtw.isdir(source) then
        if mode == "last_modification" then
            hasher.digest_folder_by_last_modification(source)
        elseif mode == "content" then
            hasher.digest_folder_by_content(source)
        end
        return true
    end
    
    return false
end

-- ============================================
-- PUBLIC API - Exposed Functions
-- ============================================
local CACHIFY_API = {}

CACHIFY_API.parse_arguments = function()
    local config = {}
    
    config.total_sources = argv.get_flag_size({ "src", "sources" })
    config.cmd = argv.get_flag_arg_by_index({ "cmd" }, 1)
    config.mode = argv.get_flag_arg_by_index({ "mode" }, 1) or "last_modification"
    config.cache_dir = argv.get_flag_arg_by_index({ "cache_dir" }, 1) or "./.cachify/"
    config.cache_name = argv.get_flag_arg_by_index({ "cache_name" }, 1) or "default_cache"
    
    local expiration_str = argv.get_flag_arg_by_index({ "expiration" }, 1) or "-1"
    config.expiration = tonumber(expiration_str)
    
    config.total_hash_cmds = argv.get_flag_size({ "hash_cmd" })
    
    return config
end

CACHIFY_API.validate_config = function(config)
    if config.total_sources == 0 then
        return false, "No sources provided. Use --src <source1> <source2> ..."
    end
    
    if not config.cmd then
        return false, "No command provided. Use --cmd <command>"
    end
    
    if not PRIVATE_CACHIFY_API.validate_mode(config.mode) then
        return false, "Invalid --mode. Use 'last_modification' or 'content'."
    end
    
    if not config.expiration then
        return false, "Invalid --expiration. Use a positive integer or -1 for no expiration."
    end
    
    return true, nil
end

CACHIFY_API.create_hasher = function()
    return dtw.newHasher()
end

CACHIFY_API.process_sources = function(hasher, config)
    for i = 1, config.total_sources do
        local current = argv.get_flag_arg_by_index({ "src", "sources" }, i)
        PRIVATE_CACHIFY_API.process_source(hasher, current, config.mode)
    end
end

CACHIFY_API.process_hash_commands = function(hasher, config)
    for i = 1, config.total_hash_cmds do
        local hash_cmd = argv.get_flag_arg_by_index({ "hash_cmd" }, i)
        local output, err = PRIVATE_CACHIFY_API.execute_hash_command(hash_cmd)
        
        if output then
            hasher.digest(output)
            CACHIFY_CLI.print_info("hash_cmd output included in hash: " .. hash_cmd)
        else
            CACHIFY_CLI.print_warning("Failed to execute hash_cmd: " .. hash_cmd)
        end
    end
end

CACHIFY_API.execute_with_cache = function(config, hash_value)
    local executed = false
    
    dtw.execute_cache({
        expiration = config.expiration,
        cache_name = config.cache_name,
        cache_dir = config.cache_dir,
        input = hash_value,
        callback = function()
            os.execute(config.cmd)
            executed = true
        end
    })
    
    return executed
end

    -- Main Function
CACHIFY_API.hit_cache = function(options)
    -- Default configuration
    local config = {
        sources = options.sources or {},
        cmd = options.cmd,
        mode = options.mode or "last_modification",
        cache_dir = options.cache_dir or "./.cachify/",
        cache_name = options.cache_name or "default_cache",
        expiration = options.expiration or -1,
        hash_cmds = options.hash_cmds or {}
    }
    
    if #config.sources == 0 then
        error("No sources provided")
    end
    
    if not config.cmd then
        error("No command provided")
    end
    
    if not PRIVATE_CACHIFY_API.validate_mode(config.mode) then
        error("Invalid mode. Use 'last_modification' or 'content'")
    end
    
    local hasher = dtw.newHasher()
    
    for _, source in ipairs(config.sources) do
        PRIVATE_CACHIFY_API.process_source(hasher, source, config.mode)
    end
    
    for _, hash_cmd in ipairs(config.hash_cmds) do
        local output, err = PRIVATE_CACHIFY_API.execute_hash_command(hash_cmd)
        if output then
            hasher.digest(output)
        end
    end
    
    local executed = false
    dtw.execute_cache({
        expiration = config.expiration,
        cache_name = config.cache_name,
        cache_dir = config.cache_dir,
        input = hasher.get_value(),
        callback = function()
            os.execute(config.cmd)
            executed = true
        end
    })
    
    return {
        executed = executed,
        cache_hit = not executed,
        hash = hasher.get_value(),
        config = config
    }
end

-- ============================================
-- CLI Layer - User Interface Functions
-- ============================================
local CACHIFY_CLI = {}

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
    local config = CACHIFY_API.parse_arguments()
    
    local valid, error_msg = CACHIFY_API.validate_config(config)
    if not valid then
        CACHIFY_CLI.print_error(error_msg)
        return
    end
    
    local hasher = CACHIFY_API.create_hasher()
    
    CACHIFY_API.process_sources(hasher, config)
    
    CACHIFY_API.process_hash_commands(hasher, config)
    
    local executed = CACHIFY_API.execute_with_cache(config, hasher.get_value())
    
    if executed then
        CACHIFY_CLI.print_info("Cache miss. Command executed.")
    else
        CACHIFY_CLI.print_success("Cache hit. Command not executed.")
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