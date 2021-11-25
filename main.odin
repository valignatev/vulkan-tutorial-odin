package main

import "core:fmt"

import "vendor:glfw"
import vk "vendor:vulkan"
import win32 "core:sys/windows"

WIDTH: u32 = 800
HEIGHT: u32 = 600

W :: win32.utf8_to_wstring
vk_loader: win32.HMODULE

instance: vk.Instance
vk_get_instance_proc_addr: #type proc "system" (
    instance: vk.Instance, 
    pName: cstring,
) -> rawptr


set_proc_address :: proc(p: rawptr, name: cstring) {
    // Only load vkGetInstanceProcAddr the platform-specific way and then
    // load everything else with vkGetInstanceProcAddr or vkGetDeviceProcAddr
    if name == "vkGetInstanceProcAddr" {
        fptr := win32.GetProcAddress(vk_loader, name)
        (cast(^rawptr)p)^ = fptr
    } else {
        fptr := vk_get_instance_proc_addr(instance, name)
        (cast(^rawptr)p)^ = fptr
    }

    // An alternative way, less wordy - load everything the platform-specific way
    // fptr := win32.GetProcAddress(vk_loader, name)
    // (cast(^rawptr)p)^ = fptr
}

create_window :: proc(width: u32, height :u32) -> glfw.WindowHandle {
    // This means "pls don't create opengl context uwu"
    glfw.WindowHint(glfw.CLIENT_API, glfw.NO_API)
    glfw.WindowHint(glfw.RESIZABLE, 0)
    window := glfw.CreateWindow(cast(i32)width, cast(i32)height, "Vulkan window", nil, nil)
    return window
}

destroy_window :: proc(window: glfw.WindowHandle) {
    glfw.DestroyWindow(window)
}

main :: proc() {
    glfw.Init();
    defer glfw.Terminate()

    vk_loader = win32.LoadLibraryW(W("vulkan-1.dll"))
    defer win32.FreeLibrary(vk_loader)

    assert(vk_loader != nil, "Couldn't find Vulkan loader")

    set_proc_address(&vk_get_instance_proc_addr, "vkGetInstanceProcAddr")
    vk.load_proc_addresses(set_proc_address)

    window := create_window(WIDTH, HEIGHT)
    defer destroy_window(window)

    extension_count: u32 = ---
    vk.EnumerateInstanceExtensionProperties(nil, &extension_count, nil)
    fmt.printf("{} extensions supported\n", extension_count)

    for glfw.WindowShouldClose(window) == false {
        glfw.PollEvents()
    }
}
