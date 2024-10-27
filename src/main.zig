const std = @import("std");
const win32 = @cImport({
    @cInclude("Windows.h");
    @cInclude("GL/gl.h");
    @cInclude("GL/glext.h");
});

var glCreateShader: win32.PFNGLCREATESHADERPROC = undefined;
var glShaderSource: win32.PFNGLSHADERSOURCEPROC = undefined;
var glCompileShader: win32.PFNGLCOMPILESHADERPROC = undefined;
var glCreateProgram: win32.PFNGLCREATEPROGRAMPROC = undefined;
var glAttachShader: win32.PFNGLATTACHSHADERPROC = undefined;
var glLinkProgram: win32.PFNGLLINKPROGRAMPROC = undefined;
var glUseProgram: win32.PFNGLUSEPROGRAMPROC = undefined;
var glGenVertexArrays: win32.PFNGLGENVERTEXARRAYSPROC = undefined;
var glGenBuffers: win32.PFNGLGENBUFFERSPROC = undefined;
var glBindBuffer: win32.PFNGLBINDBUFFERPROC = undefined;
var glBufferData: win32.PFNGLBUFFERDATAPROC = undefined;
var glBindVertexArray: win32.PFNGLBINDVERTEXARRAYPROC = undefined;
var glEnableVertexAttribArray: win32.PFNGLENABLEVERTEXATTRIBARRAYPROC = undefined;
var glVertexAttribPointer: win32.PFNGLVERTEXATTRIBPOINTERPROC = undefined;

var ghdc: win32.HDC = undefined;
var ghrc: win32.HGLRC = undefined;

var shaderProgram: win32.GLuint = 0;
var vao: win32.GLuint = 0;
var vbo: win32.GLuint = 0;

pub export fn wndproc(hwnd: win32.HWND, msg: win32.UINT, wParam: win32.WPARAM, lParam: win32.LPARAM) callconv(std.os.windows.WINAPI) win32.LRESULT {
    switch (msg) {
        win32.WM_CREATE => {
            ghdc = win32.GetDC(hwnd);
            createContext();
            loadOpenGLFunctions();
            setupShaders();
            setupTriangle();
        },
        win32.WM_DESTROY => {
            _ = win32.wglMakeCurrent(null, null);
            _ = win32.wglDeleteContext(ghrc);
            _ = win32.ReleaseDC(hwnd, ghdc);
            win32.PostQuitMessage(0);
        },
        else => {
            return win32.DefWindowProcA(hwnd, msg, wParam, lParam);
        },
    }
    return 0;
}

pub export fn loadOpenGLFunctions() void {
    glCreateShader = @ptrCast(win32.wglGetProcAddress("glCreateShader"));
    glShaderSource = @ptrCast(win32.wglGetProcAddress("glShaderSource"));
    glCompileShader = @ptrCast(win32.wglGetProcAddress("glCompileShader"));
    glCreateProgram = @ptrCast(win32.wglGetProcAddress("glCreateProgram"));
    glAttachShader = @ptrCast(win32.wglGetProcAddress("glAttachShader"));
    glLinkProgram = @ptrCast(win32.wglGetProcAddress("glLinkProgram"));
    glUseProgram = @ptrCast(win32.wglGetProcAddress("glUseProgram"));
    glGenVertexArrays = @ptrCast(win32.wglGetProcAddress("glGenVertexArrays"));
    glGenBuffers = @ptrCast(win32.wglGetProcAddress("glGenBuffers"));
    glBindBuffer = @ptrCast(win32.wglGetProcAddress("glBindBuffer"));
    glBufferData = @ptrCast(win32.wglGetProcAddress("glBufferData"));
    glBindVertexArray = @ptrCast(win32.wglGetProcAddress("glBindVertexArray"));
    glEnableVertexAttribArray = @ptrCast(win32.wglGetProcAddress("glEnableVertexAttribArray"));
    glVertexAttribPointer = @ptrCast(win32.wglGetProcAddress("glVertexAttribPointer"));
}

pub export fn createContext() void {
    var pfd: win32.PIXELFORMATDESCRIPTOR = std.mem.zeroes(win32.PIXELFORMATDESCRIPTOR);
    pfd.nSize = @sizeOf(win32.PIXELFORMATDESCRIPTOR);
    pfd.nVersion = 1;
    pfd.dwFlags = win32.PFD_DRAW_TO_WINDOW | win32.PFD_SUPPORT_OPENGL | win32.PFD_DOUBLEBUFFER;
    pfd.iPixelType = win32.PFD_TYPE_RGBA;
    pfd.cColorBits = 32;
    pfd.cDepthBits = 24;
    pfd.cStencilBits = 8;
    pfd.iLayerType = win32.PFD_MAIN_PLANE;

    const pixelFormat = win32.ChoosePixelFormat(ghdc, &pfd);
    _ = win32.SetPixelFormat(ghdc, pixelFormat, &pfd);

    const tempContext = win32.wglCreateContext(ghdc);
    _ = win32.wglMakeCurrent(ghdc, tempContext);

    const context = win32.wglCreateContext(ghdc);
    _ = win32.wglMakeCurrent(null, null);
    _ = win32.wglDeleteContext(tempContext);
    _ = win32.wglMakeCurrent(ghdc, context);
    ghrc = context;
}

const vertexShaderSource =
    \\    #version 330 core
    \\layout (location = 0) in vec3 aPos;
    \\layout (location = 1) in vec3 aColor;
    \\
    \\out vec3 outColor;
    \\
    \\void main() {
    \\    gl_Position = vec4(aPos, 1.0);
    \\	outColor = aColor;
    \\}
;

const fragmentShaderSource =
    \\#version 330 core
    \\out vec4 FragColor;
    \\in vec3 outColor;
    \\
    \\void main() {
    \\    FragColor = vec4(outColor, 1.0);
    \\}
;

pub export fn setupShaders() void {
    const vertexShader = glCreateShader.?(win32.GL_VERTEX_SHADER);
    const vss = &[_][*c]const u8{vertexShaderSource};
    glShaderSource.?(vertexShader, 1, vss, null);
    glCompileShader.?(vertexShader);

    const fragmentShader = glCreateShader.?(win32.GL_FRAGMENT_SHADER);
    const fss = &[_][*c]const u8{fragmentShaderSource};
    glShaderSource.?(fragmentShader, 1, fss, null);
    glCompileShader.?(fragmentShader);

    shaderProgram = glCreateProgram.?();
    glAttachShader.?(shaderProgram, vertexShader);
    glAttachShader.?(shaderProgram, fragmentShader);
    glLinkProgram.?(shaderProgram);
}

pub export fn setupTriangle() void {
    const vertices = [_]f32{ 0.5, -0.5, 0.0, 1.0, 0.0, 0.0, -0.5, -0.5, 0.0, 0.0, 1.0, 0.0, 0.0, 0.5, 0.0, 0.0, 0.0, 1.0 };

    glGenVertexArrays.?(1, &vao);
    glGenBuffers.?(1, &vbo);

    glBindVertexArray.?(vao);
    glBindBuffer.?(win32.GL_ARRAY_BUFFER, vbo);
    const vert: ?*const anyopaque = @ptrCast(&vertices);
    glBufferData.?(win32.GL_ARRAY_BUFFER, @sizeOf(@TypeOf(vertices)), vert, win32.GL_STATIC_DRAW);

    glVertexAttribPointer.?(0, 3, win32.GL_FLOAT, win32.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(0));
    glEnableVertexAttribArray.?(0);

    glVertexAttribPointer.?(1, 3, win32.GL_FLOAT, win32.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
    glEnableVertexAttribArray.?(1);
}

pub export fn main(instance: ?std.os.windows.HINSTANCE, prevInstance: ?std.os.windows.HINSTANCE, pCmdLine: std.os.windows.LPWSTR, nCmdShow: c_int) c_int {
    _ = instance;
    _ = prevInstance;
    _ = pCmdLine;
    _ = nCmdShow;

    var msg: win32.MSG = std.mem.zeroes(win32.MSG);

    const hInstance = win32.GetModuleHandleA(null);

    var wc: win32.WNDCLASSEXA = std.mem.zeroes(win32.WNDCLASSEXA);
    wc.cbSize = @sizeOf(win32.WNDCLASSEXA);
    wc.style = win32.CS_VREDRAW | win32.CS_HREDRAW;
    wc.lpfnWndProc = wndproc;
    wc.hInstance = hInstance;
    wc.lpszClassName = "OpenGL Window";

    _ = win32.RegisterClassExA(&wc);

    const ghwnd = win32.CreateWindowExA(win32.WS_EX_CLIENTEDGE, "OpenGL Window", "OpenGL Triangle", win32.WS_OVERLAPPEDWINDOW, win32.CW_USEDEFAULT, win32.CW_USEDEFAULT, 800, 600, null, null, hInstance, null);

    _ = win32.ShowWindow(ghwnd, win32.SW_NORMAL);
    _ = win32.UpdateWindow(ghwnd);

    while (true) {
        if (win32.PeekMessageA(&msg, null, 0, 0, win32.PM_REMOVE) == win32.TRUE) {
            if (msg.message == win32.WM_QUIT) {
                break;
            }
            _ = win32.TranslateMessage(&msg);
            _ = win32.DispatchMessageA(&msg);
        }

        win32.glClear(win32.GL_COLOR_BUFFER_BIT);
        glUseProgram.?(shaderProgram);
        glBindVertexArray.?(vao);
        win32.glDrawArrays(win32.GL_TRIANGLES, 0, 3);
        _ = win32.SwapBuffers(ghdc);
    }

    return @intCast(msg.wParam);
}
