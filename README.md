# Cryptanalysis

This repository contains assignments, implemented as part of the course **Cryptanalysis**.

It features a GUI app built with GLFW + OpenGL + ImGui. See explanatory markdown documents for each of the assignments in the `doc` folder. Assignments are all in *Romanian*.

> The markdown files use [tex math formulas, which won't show on github](https://stackoverflow.com/questions/11256433/how-to-show-math-equations-in-general-githubs-markdownnot-githubs-blog). To see formulas, you will either have to convert markdown to html or pdf, with [`MathJax`](https://www.mathjax.org/) enabled, or find the compiled pdf's [on my google drive](https://drive.google.com/drive/folders/1Rs0-qy6ivSDuHh5JadrP4Ta4YDhuVRiC).

PR's with grammar corrections, bug fixes, improvement suggestions or translations are very welcome.

Leave a star as a way to say "Thank you". Enjoy!


## Build instructions

> Warning! This will "just work" only on Windows. On Linux, you will have to build GLFW and ImGui manually. I'm not providing concrete instructions on how to do that.

1. `git clone --recursive https://github.com/AntonC9018/uni_cryptanalysis`
2. Install DMD from [here](https://dlang.org/download.html). Be sure to add D binaries in path (you'll be asked on installation).
3. `dub run` in the project root folder will start the app.


**If there are linker errors**:

1. It probably means the precompiled ImGui is not compatible with your system. Read [this](https://github.com/Superbelko/imgui-d) for instructions on how to use their script that builds both ImGui and GLFW for you.
2. Move the compiled `imgui.lib` and `glfw3.dll` into `lib` and `bin` respectively.
3. Now it should work.


### Linux

If you're a Linux geek, you should be able to build ImGui and GLFW youself (you're probably smarter than I am at this).


## Debugging

You can build and run in VSCode by hitting F5. 
- For this though you will need to install the [C/C++ extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode.cpptools). 
- To be able to set breakpoints, enable the setting "Allow breakpoints everywhere".