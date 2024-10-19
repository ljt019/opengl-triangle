package main

import "core:fmt"
import "core:os"
import "vendor:glfw"
import "vendor:OpenGL"

load_shader :: proc(file_path: string) -> (string, bool) {
    data, ok := os.read_entire_file(file_path)
    if !ok {
        fmt.eprintln("Failed to read shader file:", file_path)
        return "", false
    }
    return string(data), true
}

// Create a shader object from the provided source code
create_shader :: proc(shader_type: u32, source: string) -> (u32, bool) {

    // Create a shader object
    shader := OpenGL.CreateShader(shader_type)

    // Load the shader source code
    source_cstring := cstring(raw_data(source))

    // Compile the shader
    OpenGL.ShaderSource(shader, 1, &source_cstring, nil)
    OpenGL.CompileShader(shader)

    // Check if the shader compilation was successful
    success: i32
    OpenGL.GetShaderiv(shader, OpenGL.COMPILE_STATUS, &success)

    // If the compilation failed, print the error message and return
    if success == 0 {
        info_log: [512]u8
        OpenGL.GetShaderInfoLog(shader, 512, nil, &info_log[0])
        fmt.eprintln("Shader compilation failed:", string(info_log[:]))
        return 0, false
    }

    return shader, true
}

main :: proc() {
    // Initialize GLFW
    glfw.Init()

    defer glfw.Terminate()

    // Set the OpenGL version to 3.3
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, 3)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, 3)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    // Create a window
    window := glfw.CreateWindow(800, 600, "OpenGL Triangle", nil, nil)

    defer glfw.DestroyWindow(window)

    // Make the window's OpenGL context the current one for rendering
    glfw.MakeContextCurrent(window)

    // Load OpenGL functions up to version 3.3
    OpenGL.load_up_to(3, 3, glfw.gl_set_proc_address)

    // Define the vertices of the triangle
    vertices := [?]f32{
        -0.5, -0.5, 0.0,
         0.5, -0.5, 0.0,
         0.0,  0.5, 0.0,
    }

    // Create a Vertex Array Object
    vao: u32
    OpenGL.GenVertexArrays(1, &vao)
    OpenGL.BindVertexArray(vao)

    // Create a Vertex Buffer Object
    vbo: u32
    OpenGL.GenBuffers(1, &vbo)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, vbo)
    OpenGL.BufferData(OpenGL.ARRAY_BUFFER, size_of(vertices), &vertices, OpenGL.STATIC_DRAW)

    // Load the vertex and fragment shaders
    vertex_shader_source, vs_ok := load_shader("shaders/vertex.glsl")
    fragment_shader_source, fs_ok := load_shader("shaders/frag.glsl")

    // If the shaders failed to load, return
    if !vs_ok || !fs_ok {
        return
    }

    // Create the shaders
    vertex_shader, vs_created := create_shader(OpenGL.VERTEX_SHADER, vertex_shader_source)
    fragment_shader, fs_created := create_shader(OpenGL.FRAGMENT_SHADER, fragment_shader_source)

    // If the shaders failed to compile, return
    if !vs_created || !fs_created {
        return
    }

    // Create a shader program object to contain compiled and linked shaders
    shader_program := OpenGL.CreateProgram()


    // prepares the shaders to be linked together
    OpenGL.AttachShader(shader_program, vertex_shader)
    OpenGL.AttachShader(shader_program, fragment_shader)

    // combines the attached shaders into a single program that can be used for rendering
    OpenGL.LinkProgram(shader_program)

    OpenGL.DeleteShader(vertex_shader)
    OpenGL.DeleteShader(fragment_shader)

    // Set up the vertex attributes for our shader
    // This tells OpenGL how to interpret the vertex data 
    OpenGL.VertexAttribPointer(0, 3, OpenGL.FLOAT, OpenGL.FALSE, 3 * size_of(f32), 0)
    OpenGL.EnableVertexAttribArray(0)

    // Main rendering loop
    // This loop continues until the window should close (e.g., user clicks the close button)
    for !glfw.WindowShouldClose(window) {
        // Clear the color buffer
        OpenGL.ClearColor(0.2, 0.3, 0.3, 1.0)
        OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT)

        // Use the shader program we created earlier
        OpenGL.UseProgram(shader_program)

        // Bind the vertex array object
        OpenGL.BindVertexArray(vao)

        // Draw the triangle
        OpenGL.DrawArrays(OpenGL.TRIANGLES, 0, 3)

        // Swap the front and back buffers
        glfw.SwapBuffers(window)

        // Poll for events (e.g., window resize, keyboard input)
        glfw.PollEvents()
    }
}