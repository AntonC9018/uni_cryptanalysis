module main;
import std.stdio;
import initialization;

void main()
{
	initialize();
	run();
    shutdown();
}

void run()
{
	import imports;
    import std.exception : enforce;
	import app : App;
    IApp app = new App(); 
    app.setup();

    double time = glfwGetTime();

    while (!glfwWindowShouldClose(g_Window))
    {
        glfwPollEvents();

		double dt = glfwGetTime() - time;
        time = glfwGetTime();
		app.update(dt);

		glfwMakeContextCurrent(g_Window);
        glClear(GL_COLOR_BUFFER_BIT);

		ImguiImpl.RenderDrawData(ImGui.GetDrawData());

		glfwMakeContextCurrent(g_Window);
		glfwSwapBuffers(g_Window);
    }
}