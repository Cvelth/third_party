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
    - Add `link(...)` or `link_everything()` call inside project definition:
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
    - `options` to pass to `cmake .` command, e.g. `-G <generator-name>`
    - `build_options` to pass to `cmake --build`, e.g. `-j [<jobs>]`
    - `native_build_options` to pass to `cmake --build` after `--`
    - `install_options` to pass to `cmake --install` command, e.g. `--component <comp>`
    - `windows_options` are identical to `options` except they are ignored if `os.target()` is not `"windows"`
    - `windows_build_options` are identical to `build_options` except they are ignored if `os.target()` is not `"windows"`
    - `windows_native_build_options` are identical to `native_build_options` except they are ignored if `os.target()` is not `"windows"`
    - `linux_options` are identical to `options` except they are ignored if `os.target()` is not `"linux"`
    - `linux_build_options` are identical to `build_options` except they are ignored if `os.target()` is not `"linux"`
    - `linux_native_build_options` are identical to `native_build_options` except they are ignored if `os.target()` is not `"linux"`
    - `macosx_options` are identical to `options` except they are ignored if `os.target()` is not `"macosx"`
    - `macosx_build_options` are identical to `build_options` except they are ignored if `os.target()` is not `"macosx"`
    - `macosx_native_build_options` are identical to `native_build_options` except they are ignored if `os.target()` is not `"macosx"`
    - `log_location` - a directory to place the file with `stdout` output of `cmake` calls (default value is `third_party/log`), `stderr` is not affected.
    - `debug` - if `true`, debug configuration is build if applicable. Default value is `false`
- `install`  
    Copies files to install location based on specified patterns  
    Accepts parameters, at least one of `{include, source, lib}` must be present:
    - `include` - a pattern or a list of patterns to be copied to `{install_dir}/include/**`, default is `{source_dir}/include/**`
    - `source` - a pattern or a list of patterns to be copied to `{install_dir}/source/**`, default is `{source_dir}/source/**`
    - `lib` - a pattern or a list of patterns to be copied to `{install_dir}/lib/**`, default is `{source_dir}/lib/**`
    - `log_location` - a directory where to place the file with output of `isntall` command calls (default value is `third_party/log`)
    - `debug` - if `true`, files are installed into a separate, debug version of `{install_dir}`. Can be useful to try out changes without touching already installed targets.
  
    Note, that `{source_dir}` is implied and must not be explicitly added to patterns, e.g. `{source_dir}/includes/my_include/single_file.hpp` is to be specified as `includes/my_include/single_file.hpp`
- `depend`  
    Selects files to be linked to when `link(...)` or `link_everything()` is called.  
    Accepts `default` or optional parameters:
    - `include`, a single pattern or a list of patterns to be added to `includedirs` of the project, e.g. `include/add/only/this/subdirectory/**`. Default value is `include`
    - `lib`, a single pattern or a list of patterns to be added as input library dependencies, e.g. `lib/link_only_this_one_file.*`, or `lib/link/everything/from/this/subdirectory/**`. Default value is `lib/**`
    - `files`, a single pattern or a list of patterns to be added as source files to the project, e.g. `source/**` to add everything from the directory. Default value is `{ "source/**", "include/**" }`
    - `vpaths`, a `default` or a dictionary where `lhs` are virtual path pattern and `rhs` - real one, e.g. `resource/text_files: **.txt` would consider all the `*.txt` files as part of `resource/text_files` virtual directory. Default value is `{ dependency_name/include: include/**, dependency_name/source: source/** }`

## `third_party.user.yml` file structure
The file is a dictionary with the structure of:
```yml
option: value
second_option: second_value
# ...
```

### Known options:
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
        third_party.link {
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
        third_party.link {
            "app_dependency_1_name",
            "app_dependency_2_name",
            -- ...
            "app_dependency_N_name"
        }
```

### `third_party.yml`
```yml
glfw:
- github_release:
    owner: glfw
    tag: "3.3.2"
    file: glfw-3.3.2.zip
- cmake:
    linux_options: >
        -G "Unix Makefiles"
- depend:
    include: include
    lib: lib/*

glfw_debug:
- github_release:
    owner: glfw
    name: glfw
    tag: "3.3.2"
    file: glfw-3.3.2.zip
- cmake:
    debug: true
    options: >
        -DUSE_MSVC_RUNTIME_LIBRARY_DLL=ON
    linux_options: >
        -G "Unix Makefiles"
- depend:
    include: include
    lib: lib/*
    
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

doctest:
- download:
    url: https://raw.githubusercontent.com/onqtam/doctest/2.4.1/doctest/doctest.h
    filename: doctest.h
- install:
    include: doctest.h
- depend: default
```
`third_party.link { "glfw" }` will link a release build, while `third_party.link { "glfw_debug" }` - a debug one.

### `third_party.user.yml`
```yml
verbose: true # default: false
cmake: /usr/bin/custom/path/to/cmake # default: ""
git: /usr/bin/custom/path/to/git # default: ""
```