newoption {
	trigger = "glfw",
	description = "A multi-platform library for OpenGL, OpenGL ES, Vulkan, window and input"
}

if _OPTIONS["glfw"] then
	newoption {
		trigger = "glfw-use-wayland",
		description = "Force GLFW to use a Wayland backend API."
	}
	newoption {
		trigger = "glfw-use-osmesa",
		description = "Force GLFW to use a OSMesa backend API."
	}
	
	if _OPTIONS["glfw-use-wayland"] then
		glfw_backend_api = "wayland"
	elseif _OPTIONS["glfw-use-osmesa"] then
		glfw_backend_api = "osmesa"
	elseif os.target() == "windows" then 
		glfw_backend_api = "win32"
	elseif os.target() == "macosx" then 
		glfw_backend_api = "cocoa"
	elseif os.target() == "linux" then 
		glfw_backend_api = "x11"
	else
		print ("No supported backend API available to GLFW on given os.")
		return
	end
end

newoption {
	trigger = "all",
	description = "Fetch and build all available dependencies"
}

require (path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/script/fetch")
require (path.getrelative(_SCRIPT_DIR, _MAIN_SCRIPT_DIR) .. "/script/project")
if _OPTIONS["glfw"] then
	fetch_a_github_release("glfw", "glfw", "3.3.2", "glfw-3.3.2.zip", "include/GLFW", "src")
	add_project("glfw")
	removeflags "FatalWarnings"

	if os.target() == "linux" then 
		add_library("rt")
		add_library("m")
	else
		removefiles { "**/posix_*", "**/xkb_*", "**/linux_*" }
	end

	if not os.target() == "windows" then
		removefiles { "**/wgl_*" }
	end

	if glfw_backend_api == "wayland" then 
		defines "_GLFW_WAYLAND"
		add_dependency("wayland")
		print ("Warning: wayland support is not properly implemented!")
	else
		removefiles { "**/wl_*" }
	end
	
	if glfw_backend_api == "osmesa" then
		defines "_GLFW_OSMESA"
		add_dependency("osmesa")
	else
		removefiles { "**/null_*" }
	end

	if glfw_backend_api == "win32" then
		defines "_GLFW_WIN32"
		links { "gdi32" }
	else
		removefiles { "**/win32_*" }
	end

	if glfw_backend_api == "cocoa" then
		defines "_GLFW_COCOA"
		add_files { "source/**.m" }
		links { "Cocoa.framework", "IOKit.framework", "CoreFoundation.framework" }
		print ("Warning: cocoa support is not properly implemented!")
	else
		removefiles { "**/cocoa_*" }
	end

	if glfw_backend_api == "x11" then 
		defines "_GLFW_X11"
		add_dependency("x11")
	else
		removefiles { "**/x11_*", "**/glx_*" }
	end
end
	