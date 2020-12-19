# `third_party`
A bunch of dependency management scripts for `premake5`.

## Usage
- Add this repository as a submodule:  
```$ git submodule add https://github.com/Cvelth/third_party third_party```
- Add `third_party.yml` config file to the root of the project directory
- (optional) Add `third_party.user.yml` to set platform-specific settings (don't forget to add it to `.gitignore`)
- Use the module inside your `premake5.lua` file:
    - Add `acquire()` call at the top of the file:
        ```lua
        local third_party = require "third_party/third_party"
        third_party.acquire()
        ```
  
        `acquire()` accepts a path to a file (without extension) as an argument, similar to `require()` in case you prefer for your `config.yml` file to be named differently, or placed somewhere other than the roon of your project. Default value is `third_party`, e.g. `third_party.yml` in the same directory as `premake5.lua` is used as a config file.
    - Add `third_party.depends(...)` or `third_party.depends_on_everything()` call inside project definition.  
    Note: one could add an alias to any function, for example:  
        ```lua
        depends = third_party.depends
        depends_on_everything = third_party.depends_on_everything
        ```  
- Enjoy!


## `third_party.yml` file structure
The file is a dictionary with the structure of:
```yml
dependency_name:
- list
- of
- actions
second_dependency:
- second
- list
# ...
```

### Supported actions:
- `github_release`  
    Downloads an asset from a tagged github release.  
    Accepts parameters:  
    - username of the repository `owner`
    - `tag` of the release
    - (optional) repository `name`, if not present `dependency_name` is used instead
    - (optional) custom `file`name, if not present, `Source code (zip)` is downloaded
- `github_clone`  
    Clones a detached head of the repository at specified tag or branch  
    Accepts parameters:  
    - `owner`, username of the repository `owner`
    - `tag` or `branch` to clone. If both are present, `branch` is ignored.
    - (optional) repository `name`, if not present `dependency_name` is used instead
    - (optional) `options` to pass to `git clone` command, e.g. `--recursive`
- `download`
    Downloads a single file using specified url.
    Acceps parameters:
    - `url` address of the file
    - `filename` to save the file as
- `cmake`  
    Builds the project (using `cmake --build`) and installs it (`cmake 3.15+` is required)  
    Accepts `default` or optional parameters:
    - `config` is one of `release`, `debug` or `default`, where `default` builds both release and debug versions
    - `log_location` - a directory to place the file with `stdout` output of `cmake` calls (default value is `third_party/log`), `stderr` is not affected.

    And a set of `options` parameters:
    - `options` to pass to `cmake .` command, e.g. `-G <generator-name>`
    - `build_options` to pass to `cmake --build`, e.g. `-j [<jobs>]`
    - `native_build_options` to pass to `cmake --build` after `--`
    - `install_options` to pass to `cmake --install` command, e.g. `--component <comp>`
    
    As well as prefixes for them:
    - configuration: `release_` or `debug_` (for example, `release_install_options` or `debug_build_options`)
    - target OS: `windows_`, `linux_`, `macosx_`, `aix_`, `bsd_`, `haiku_`, `solaris_`, `wii_` or `xbox360_` (for example `windows_native_build_options` or `linux_options`)
    
    Any combination of these prefixes are acceptable, for example both `release_linux_options` and `linux_release_options` are equivalent and are concatenated together (both can even be used for the same action)
- `install`  
    Copies files to install location based on specified patterns  
    Accepts parameters, at least one of `{include, source, lib}` must be present:
    - `include` - a pattern or a list of patterns to be copied to `{install_dir}/include/**`, default is `{source_dir}/include/**`
    - `source` - a pattern or a list of patterns to be copied to `{install_dir}/source/**`, default is `{source_dir}/source/**`
    - `lib` - a pattern or a list of patterns to be copied to `{install_dir}/lib/**`, default is `{source_dir}/lib/**`
    - `log_location` - a directory where to place the file with output of `isntall` command calls (default value is `third_party/log`)
    - `config` is one of `release`, `debug` or `default`, where `default` installs into both release and debug directories
  
    Note, that `{source_dir}` is implied and must not be explicitly added to patterns, e.g. `{source_dir}/includes/my_include/single_file.hpp` is to be specified as `includes/my_include/single_file.hpp`
- `depend`  
    Selects files to be used by the project to when `depends(...)` or `depends_on_everything()` is called.  
    Accepts `default` or optional parameters:
    - `include`, a single pattern or a list of patterns to be added to `includedirs` of the project, e.g. `include/add/only/this/subdirectory/**`. Default value is `include`
    - `lib`, a single pattern or a list of patterns to be added as input library dependencies, e.g. `lib/link_only_this_one_file.*`, or `lib/link/everything/from/this/subdirectory/**`. Default value is `lib/**`
    - `files`, a single pattern or a list of patterns to be added as source files to the project, e.g. `source/**` to add everything from the directory. Default value is `{ "source/**", "include/**" }`
    - `vpaths`, a `default` or a dictionary where `lhs` are virtual path pattern and `rhs` - real one, e.g. `resource/text_files: **.txt` would consider all the `*.txt` files as part of `resource/text_files` virtual directory. Default value is `{ dependency_name/include: include/**, dependency_name/source: source/** }`
- `global`
    Selects to be by the project to when `depends(...)` or `depends_on_everything()` is called.  
    The difference from `depend` is that `global` does not require any previous steps. This allows to simply link or add as include directory or even add a source file using its global path. This option is intended primarily to give an ability to use 'third_party' together with another dependency management system.
    Accepts `default` or optional parameters equivalent to a `depend` action.

## `third_party.user.yml` file structure
The file is a dictionary with the structure of:
```yml
option: value
second_option: second_value
# ...
```

### Supported options:
- `verbose` - if `true`, additional output is "thrown" into `stdout`.
- `debug` - same as `verbose`, if both are specified, the value is (`verbose` or `debug`), e.g. it's `false` only if both of them are set to `false` (or not specified)
- `cmake` - path to cmake, only needed if `cmake` is not present in the `PATH` variable. It should not include filename itself. Only the directory.
- `git` - path to cmake, only needed if `git` is not present in the `PATH` variable. It should not include filename itself. Only the directory.

## Examples
### `premake5.lua`
```lua
    local third_party = require "third_party/third_party"
    third_party.acquire "third_party"

    workspace "example_solution"
        -- workspace settings
    project "example_lib"
        kind "StaticLib"
        language "C++"

        -- project settings

        files {
            "include/**"
            "source/lib/**"
        }
        third_party.depends {
            "lib_dependency_1_name",
            "lib_dependency_2_name",
            -- ...
            "lib_dependency_N_name"
        }

    project "example_app"
        kind "ConsoleApp"
        language "C++"

        -- project settings

        files {
            "include/**"
            "source/app/**"
        }
        third_party.depends {
            "app_dependency_1_name",
            "app_dependency_2_name",
            -- ...
            "app_dependency_N_name"
        }
```

### `third_party.yml`
```yml
# cmake example
glfw:
- github_release:
    owner: glfw
    tag: "3.3.2"
    file: glfw-3.3.2.zip
- cmake:
    debug_options: >
        -DUSE_MSVC_RUNTIME_LIBRARY_DLL=ON
    linux_options: >
        -G "Unix Makefiles"
- depend:
    include: include
    lib: lib/*
    
# example of adding source files to the project
lodepng:
- github_clone:
    owner: Cvelth
    branch: master
- install: 
    include: lodepng.h
    source: lodepng.cpp
- depend:
    include: default
    files: 
    - include/lodepng.h
    - source/lodepng.cpp
    vpaths: 
        lodepng: "**"
        
# header only example
vkfw:
- github_clone:
    owner: cvelth
    tag: main
- install:
    include: default
- depend:
    include: default

# single header example
doctest:
- download:
    url: https://raw.githubusercontent.com/onqtam/doctest/2.4.1/doctest/doctest.h
    filename: doctest.h
- install:
    include: doctest.h
- depend: default

# global example
vulkan:
- global:
    include: %VULKAN_SDK%/Include
    lib: %VULKAN_SDK%/Lib/vulkan-1
```

### `third_party.user.yml`
```yml
verbose: true # default: false
cmake: /usr/bin/custom/path/to/cmake # default: ""
git: /usr/bin/custom/path/to/git # default: ""
```