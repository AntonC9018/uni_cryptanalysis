module app;

import imports;

int[] ints;

// Initialize data
void setup()
{
    ints = 3.iota.array;
}

// The game loop, called each frame
void update(double dt)
{
    ImguiImpl.NewFrame();
    if (ImGui.Begin("Main Window"))
    {
        ImGui.Text("User-defined uniforms");
        if (ImGui.Button("Click to add integer"))
        {
            ints.length += 1;
        }
        foreach (i; 0..ints.length)
        {
            ImGui.InputInt(textz("Integer number ", i), &ints[i]);
        }
        ImGui.Separator();
    }
    ImGui.End();
    ImGui.Render();
}