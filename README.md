# Cachify
![VibeScript Logo](https://img.shields.io/badge/VibeScript-0.1.0-blue?style=for-the-badge&logo=lua)
[![GitHub Release](https://img.shields.io/badge/GitHub-Release-blue?style=for-the-badge)](https://github.com/OUIsolutions/cachify/releases)
[![License](https://img.shields.io/badge/License-MIT-green.svg?style=for-the-badge)](https://github.com/OUIsolutions/cachify/blob/main/LICENSE)
![Status](https://img.shields.io/badge/Status-Stable-brightgreen?style=for-the-badge)
![Platforms](https://img.shields.io/badge/Platforms-VibeScript-lightgrey?style=for-the-badge)

---

### Overview

Cachify is a smart caching tool for VibeScript that executes commands only when source files change. It provides an intelligent caching layer that avoids re-running commands if the content or modification time of the sources remains the same:

1. **Install VibeScript runtime**
2. **Configure Cachify with your sources and command**
3. **Run commands only when needed**

This tool is designed for developers who want to:
- Speed up build and execution times
- Avoid re-running tasks unnecessarily
- Create efficient CI/CD pipelines
- Optimize development workflows

### Key Features

- **Content-based Caching** - Caches based on the hash of file contents.
- **Modification Time Caching** - Caches based on the last modification time of files.
- **Expiration Control** - Set expiration times for caches.
- **Custom Cache Directory** - Specify a custom directory for storing cache files.
- **Command Execution** - Execute a shell command on a cache miss.
- **Flexible Source Handling** - Works with both files and directories.

## Installation

### Step 1: Install VibeScript

Choose the appropriate installation method for your operating system:

#### Option A: Pre-compiled Binary (Linux only)
```bash
curl -L https://github.com/OUIsolutions/VibeScript/releases/download/0.32.0/vibescript.out -o vibescript.out && chmod +x vibescript.out && sudo mv vibescript.out /usr/local/bin/vibescript
```

#### Option B: Compile from Source (Linux and macOS)
```bash
curl -L https://github.com/OUIsolutions/VibeScript/releases/download/0.35.0/amalgamation.c -o vibescript.c && gcc vibescript.c -o vibescript.out && sudo mv vibescript.out /usr/local/bin/vibescript
```

### Step 2: Install Cachify
```bash
vibescript add_script --file https://github.com/OUIsolutions/cachify/releases/download/0.1.0/cli.lua cachify
```

## Usage

Cachify can be used in two ways: as a command-line tool or as a Lua API within your VibeScript scripts.

### API Usage

You can integrate Cachify directly into your VibeScript Lua scripts:

```lua
local cachify = load_global_module("cachify")

cachify.execute_config({
    sources = {"src/", "config.json"},
    callback = function() 
        print("Building project...")
        os.execute("npm run build")
    end,
    cache_name = "my_build_cache",
    cache_dir = ".cachify",
    mode = "last_modification",  -- or "content"
    hash_cmd = {"git rev-parse HEAD"},  -- optional
    ignore_first = false,  -- optional
})
```

#### API Configuration Options

- `sources` (required): Array of file paths or directories to monitor
- `callback` (required): Function to execute when cache is missed
- `cache_name` (optional): Name of the cache (default: "default_cache")
- `cache_dir` (optional): Directory to store cache files (default: "./.cachify/")
- `mode` (optional): Caching mode - `"last_modification"` or `"content"` (default: "last_modification")
- `hash_cmd` (optional): Array of shell commands whose output will be included in the hash
- `ignore_first` (optional): If true, skips execution on the very first run (default: false)

#### Return Values

The `execute_config` function returns two boolean values:
- `executed`: Whether the callback was executed (true on cache miss)
- `is_first`: Whether this was the first execution

```lua
local executed, is_first = cachify.execute_config({...})
if executed and is_first then
    print("First time running!")
elseif executed then
    print("Cache miss - files changed!")
else
    print("Cache hit - nothing to do!")
end
```

### Command Line Usage

Cachify will execute the specified command only if the hash of the source files has changed since the last execution.

```bash
vibescript cachify --src <source1> <source2> ... --cmd <command>
```



### Command Line Options

- `--src` or `--sources`: One or more source files or directories to monitor.
- `--cmd`: The command to execute if a change is detected.
- `--mode`: Caching mode. Can be `last_modification` (default) or `content`.
- `--cache_dir`: The directory to store cache files (default: `./.cachify/`).
- `--cache_name`: The name of the cache to use (default: `default_cache`).
- `--expiration`: Cache expiration time in seconds. Use -1 for no expiration (default: -1).
- `--hash_cmd`: One or more optional commands whose output will be included in the hash calculation. This allows you to use the output of external commands (for example, a Git repository version) as part of the cache key.
- `--ignore_first`: If present, skips command execution on the very first run.

### Command Line Examples

```bash
# Execute a build script if any file in the 'src' directory has been modified
vibescript cachify --sources src --cmd "npm run build"

# Use content-based caching and a custom cache directory
vibescript cachify --sources src --mode content --cache_dir .my_cache --cmd "echo 'Files have changed!'"

# Include git command output in the hash so the cache is invalidated if HEAD changes
vibescript cachify --sources src --hash_cmd "git rev-parse HEAD" --cmd "npm test"

# Use an external command to generate a dynamic cache key based on the current date
vibescript cachify --sources src --hash_cmd "date +%Y%m%d" --cmd "gerar_relatorio_diario.sh"

# Use multiple hash commands to include several factors in the cache key
vibescript cachify --sources src --hash_cmd "git rev-parse HEAD" --hash_cmd "node --version" --cmd "npm run build"

# Ignore the first execution (useful for initialization)
vibescript cachify --sources src --cmd "npm run build" --ignore_first
```

### API Examples

```lua
-- Basic usage with file monitoring
local cachify = load_global_module("cachify")

cachify.execute_config({
    sources = {"cachify.lua", "README.md"},
    callback = function() 
        print("Files changed! Running tests...")
        os.execute("lua test.lua")
    end,
    cache_name = "test_cache",
    cache_dir = ".cachify",
})

-- Advanced usage with git tracking and custom logic
local cachify = load_global_module("cachify")

local executed, is_first = cachify.execute_config({
    sources = {"src/"},
    mode = "content",
    hash_cmd = {"git rev-parse HEAD", "node --version"},
    callback = function()
        print("Building project...")
        os.execute("npm run build")
        os.execute("npm test")
    end,
    cache_name = "build_cache",
    cache_dir = ".build_cache",
    ignore_first = true,
})

if executed then
    print("Build completed successfully!")
end
```

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
