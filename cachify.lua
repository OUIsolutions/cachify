print("mensagem de teste")

local total_sources = argv.get_flag_size({ "src", "sources" })
if total_sources == 0 then
    print("No sources provided. Use --src <source1> <source2> ...")
    return
end

local cmd = argv.get_flag_arg_by_index({ "cmd" }, 1)
if not cmd then
    print("No command provided. Use --cmd <command>")
    return
end

local mode = argv.get_flag_arg_by_index({ "mode" }, 1) or "last_modification"
if mode ~= "last_modification" and mode ~= "content" then
    print("Invalid --mode. Use 'last_modification' or 'content'.")
    return
end

local cache_dir = argv.get_flag_arg_by_index({ "cache_dir" }, 1) or "./.cachify/"
local cache_name = argv.get_flag_arg_by_index({ "cache_name" }, 1) or "default_cache"
local expiration_str = tonumber(argv.get_flag_arg_by_index({ "expiration" }, 1)) or "-1"
local expiration = tonumber(expiration_str)

if not expiration then
    print("Invalid --expiration. Use a positive integer or -1 for no expiration.")
    return
end

local hasher = dtw.newHasher()

-- Processa sources
for i=1,total_sources do
    local current = argv.get_flag_arg_by_index({ "src", "sources" }, i)

    if dtw.isfile(current) then
        hasher.digest_file(current)
    end

    if dtw.isdir(current) then
        if mode == "last_modification" then
            hasher.digest_folder_by_last_modification(current)
        end
        if mode == "content" then
            hasher.digest_folder_by_content(current)
        end
    end
end

-- Processa hash_cmd (agora como array)
local total_hash_cmds = argv.get_flag_size({ "hash_cmd" })
for i=1,total_hash_cmds do
    local hash_cmd = argv.get_flag_arg_by_index({ "hash_cmd" }, i)
    local handle = io.popen(hash_cmd)
    if handle then
        local output = handle:read("*a")
        handle:close()
        hasher.digest(output)

        print("hash_cmd output included in hash: " .. hash_cmd)
    else
        print("Warning: Failed to execute hash_cmd: " .. hash_cmd)
    end
end

local executed = false

dtw.execute_cache({
    expiration = expiration,
    cache_name = cache_name,
    cache_dir = cache_dir,
    input = hasher.get_value(),
    callback = function()
        os.execute(cmd)
        executed = true
    end
})

if executed then
    print("Cache miss. Command executed.")
end

if not executed then
    print("Cache hit. Command not executed.")
end