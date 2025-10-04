local shipyard = load_global_module("cachify")
shipyard.hit_cache({
    sources = {"cachify.lua"},
    cmd = "lua hit_cache.lua",
    mode = "content",
    cache_dir = "./.cachify/",
    cache_name = "hit_cache_test",
    expiration = -1,
    hash_cmds = {}
})