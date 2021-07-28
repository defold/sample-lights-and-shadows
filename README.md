# Lights and Shadows
Example of how to achieve pixel perfect shadows in a 2D view. The sample is based on the following the following sources:

* 2D Pixel Perfect Shadows LIBGDX example: https://github.com/mattdesl/lwjgl-basics/wiki/2D-Pixel-Perfect-Shadows
* Adapted to Defold with technical discussion by d954mas: https://forum.defold.com/t/problem-with-shader/3808
* Final Defold sample project by Sayuris1: https://github.com/Sayuris1/2d_light_defold


# Installation
You can use this solution in your own project by adding this this project as a Defold library dependency. Open your game.project file and in the dependencies field under project add:

https://github.com/defold/sample-lights-and-shadows/archive/master.zip


# Usage
The main components of this light and shadow casting example are:

* `lights/lightsource.script` - Attach this script to any game object that should act as a lightsource. Modify the exposed script properties to control the light properties:
   * `radius` [number] - Radius of the lightsource in pixels
   * `color` [vector4] - Color of the lightsource (RGBA)
   * `arc_angle` [number] - Arc angle of the lightsource. Can be used to generate a cone of light up to an arc angle of 180 degrees. Anything above 180 degrees will result in a full circle.
   * `static` [boolean] - Use this for static lights that do not move or rotate to skip updates of light position and rotation each frame.
* `lights/render/light_quad.go` - A game object with a basic model quad, used as a render target when drawing lights and shadows.
* `lights/render/lights.render` and `lights/render/lights.render_script` - The render file and render script used when drawing lights and shadows (and also all of the standard Defold components such as sprites, particles, tilemaps etc)
* `lights/materials/light_occluder_*.material` - Materials to use for sprite, tilemaps and other components that should occlude light and cast shadows.


## Step 1 - Render script
Open **game.project** and scroll down to `Bootstrap` and change Render file to `lights/render/lights.render`. This render script works like the default render script with the addition of also drawing lights and shadows.

![](/docs/add_render_file_to_bootstrap.png)


## Step 2 - Add light quad
Add the `lights/render/light_quad.go` to a collection where lights and shadows should be calculated.

![](/docs/add_light_quad.png)


## Step 3 - Add lightsources
Attach the `lights/lightsource.script` to any game object that should act as a lightsource.

![](/docs/add_lightsource.png)

Configure the lightsource properties to your liking.

![](/docs/configure_lightsource.png)


## Step 4 - Add light occluders
Change the material for any component that should cast shadows when lit by a lightsource. Select a material from `lights/materials/` matching the component type casting shadows.

![](/docs/configure_light_occluder.png)
