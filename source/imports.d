module imports;

public import imgui;
public import initialization : ImguiImpl, g_Window;
public import std.range;
public import std.algorithm;
public import std.experimental.logger;
public import std.conv;
public import std.string;
public import bindbc.glfw;
public import bindbc.opengl;

const (char*) textz(Args...)(Args a)
{
    return text(a).toStringz;
} 