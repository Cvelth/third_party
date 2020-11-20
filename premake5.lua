workspace "third_party"
	configurations { "debug", "release" }
	architecture "x86_64"

	newoption {
		trigger = "output_directory",
		description = "A directory path for output binaries to be moved to.",
		value = "path"
	}
	newoption {
		trigger = "build_directory",
		description = "A directory path for temporary files to be generated in.",
		value = "path"
	}

	targetdir (_OPTIONS["output_directory"] or "output/%{cfg.system}_%{cfg.buildcfg}")
	location (_OPTIONS["build_directory"] or "build")

	cppdialect "C++latest"
	flags "FatalWarnings"
	warnings "Extra"
		
	vpaths {
		["include"] = "include/**.h*",
		["source"] = "source/**.c*",
		["source/include"] = "source/**.h*",

		["include/detail"] = "include/detail/**.h*",
		["source/detail"] = "source/detail/**.c*",
		["source/include/detail"] = "source/detail/**.h*",
	}
	
	filter "configurations:debug"
		defines { "_DEBUG" }
		symbols "On"
		optimize "Debug"
	filter "configurations:release"
		defines { "NDEBUG" }
		optimize "Full"
		flags { "NoBufferSecurityCheck", "NoRuntimeChecks" }
	filter "action:vs*"
		flags { "MultiProcessorCompile", "NoMinimalRebuild" }
		linkoptions { "/ignore:4099" }
		defines { "_CRT_SECURE_NO_DEPRECATE", "_CRT_SECURE_NO_WARNINGS", "_CRT_NONSTDC_NO_WARNINGS" }
	filter { "system:windows", "configurations:release" }
		flags { "NoIncrementalLink" }
	filter { "system:windows", "configurations:release", "toolset:not mingw" }
		flags { "LinkTimeOptimization" }

	-- temporary fix
	filter "action:xcode*"
		xcodebuildsettings {           
			["CLANG_CXX_LANGUAGE_STANDARD"] = "c++2a";
		}
	filter "action:gmake*"
		buildoptions "-std=c++2a"

	filter {}

include (path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/script/project/glfw.lua")