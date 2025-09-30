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

local hasher = dtw.newHasher()

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