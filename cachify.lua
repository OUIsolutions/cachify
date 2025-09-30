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


