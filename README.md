# WATER SHADER #

[Visual Samples](./Assets/Visual%20Samples)

Implements both static and Fractional Brownian Motion generation with different sine-based functions to generate a water-like material. 
Currently only implements displacement by computing sum of sines, but supports multiple height functions (beyond the simple sine) and it can be extended by modifying the `WaveGeneration.cginc`.
It works generally well for a stylized look, as the mathematical model is not detailed enough to give off proper semblance of tide motions as well as no sophisticated way of computing more turbulent effects (e.g. foam and breaking waves).
Two shaders are present, one uses classic vertex and fragments shaders to animate already present vertices of the mesh and compute lighting. The other leverages Tessellation in order to generate new vertices on the fly depending on factors that can be directly manipulated (Check the tessellation section for more).

# Parameters #
 - `Specular Sharpness` : Power for Blinn-Phong shading's (N · H) product. Determines sharpness of specular strength falloff.
 - `Specular Strength` : Specular Multiplier.
 - `Foam Base Color` : The diffuse color for when foam is present. 
 - `Height Based Foam Amount` : The value of H at which the foam can start appearing, when computing foam based on height.
 - `Height Based Foam Sharpness`: Sharpness of the falloff from higher values to lower values of the height based foam.
 - `Angle Based Foam Amount` : The minimum angle from the up vector at which foam starts appearing (influenced by the height based factor, will not appear in shallower values of H). 
 - `Angle Based Foam Sharpness` : Falloff sharpness for the foam amount. 
 - `MinHeightRemap and MaxHeightRemap` : Allows to remap the values of H to a different range, thus being able to choose more precisely where foam gathers. 
 - `Wave Generation method` : Either FBM or statically chosen from an array of 3 values.
 ## Fractional Brownian Motion Specific Parameters ##
 - `Base Values` (Amplitude, Phase and Frequency) : Starting values for FBM Wave generation. 
 - `Ramp Values` (Amplitude, Phase and Frequency) : Multipliers for the next values in the FBM iterations. Given a parameter X, the value for X in the next iteration will be X * RampX.
 - `Normal Contrast` : Also called Normal Strength, multiplies the FBM derivatives before normalization, increasing the horizontal variation. 
 - `Wave Size` : Scales the horizontal width of the computation. A higher number will produce lower frequency waves.
 - `Displacement Scale` : Scales the vertical displacement of the mesh.
 - `Starting Amplitude` : Maximum range of the wave amplitude. The final vertex displacement will be always in the range` [h * Displacement Scale, -h * Displacement Scale]` where `h = 1/(1-Starting Amplitude)`
 - `Lacunarity` : Determines how smaller in amplitude( and higher in frequency) the next generated value is compared to the previous one.
 - `Wave Number` : Either `Compile or Runtime`, will allow to choose the number of waves via the Editor if runtime, otherwise it will need manual Shader code adjustment.
 ## Height Function Specific Parameters ##
 ### Exponential Sine Function ###
 - `Max Exponential Multiplier` : Multiplies the overall result of the exponential sine function.
 - `Exponential Negative Offset` : Will offset the minimum value of the exponent in the exponential sine function. 
 
 ## Tessellation Specific Parameters ##
 - `TessellationMode` : Can take one of 4 values, each one determines the way tessellation factors are chosen.
    - `Fixed` : All tris will be subdivided via the same factor `Tessellation Subdivisions`. 
    - `DistanceBased` : `Tessellation Subdivisions` will slowly decay towards no tessellation based on two extra parameters `Tessellation Maximum Distance` (Beyond which no tessellation is done) and `Tessellation Minimum Distance` (below which all tris will be tessellated by the same factor as `Fixed`).
    - `EdgeBased` : The distance between points of a tri will be measured in world space and that will be measured against `Tessellation Target Edge Length` as a factor to multiply the fixed amount of subdivisions by. The closer points are the less tessellation is requested.
    - `HeightFunctionBased` : Uses the height function information (Frequency of the biggest waves) to compute the Nyquist critical sample rate and uses that as the main factor for determining tessellation. Offers extra parameters to better customize the tessellation, making it stronger when closer to camera or prioritizing detail when the mesh is viewed at an angle. 
 - `Tessellation Subdivisions` : The constant factor by which to subdivide tris or multiply the other subdivision factors.
 - `Tessellation Target Edge Length` : Target edge length in world space for Edge based tessellation.
 - `Tessellation Maximum Distance` : Distance for no tessellation in distance based tessellation and height function based.
 - `Tessellation Minimum Distance` : Distance for maximum tessellation in distance based tessellation and height function based. 
 - `Tessellation at Edge Minimum` : Angle for no tesselation (if 0 view direction must be parallel to normal) in Height function based tessellation.
 - `Tessellation at Edge Maximum` : Angle for maximum tesselation (if 1 view direction must be perpendicular to normal) in Height function based tessellation.
 - `Phong Tesselation Factor` : Factor for Unity's automatic Phong tessellation factor (might not work on some platforms).

 ### Height Function Tessellation ###
 The formula being used is the following:
 $$ T = Nyq(p1,p2) \cdot SchlickFresnel(\vec{V}, \vec{N})^{Max}_{Min} \cdot \frac{|p1-p2| - minDist}{maxDist-minDist} \cdot S$$
 Where:
 $$ \begin{aligned}
& \vec{V} = \text{World Space View Direction} \\ 
& \vec{N} = \text{World Space Normal} \\ 
& S = \text{Tessellation Subdivisions} \\
& Nyq(x,y) = 2 * (f * f_r^4) * |p_1^{world}-p_2^{world}| \\
& SchlickFresnel(x,y) = (1-\vec{X}\cdot\vec{Y})^5 \\
& X^{Max}_{Min} = clamp(X,Min,Max) \\
\end{aligned} $$

The formula is meant to offer a tessellation method rooted in the mathematical model generating the waves, while still offering the freedom to customize the algorithm in view of different use cases (e.g. tessellation needs might change greatly based on the expected view angle, presence of fog etc...)

 ## Debugging ##
 - `Debug` : If activated the waves will not follow `_Time` progression from unity and will instead follow the `Wave Progression` parameter from the Editor.

## Nota Bene ##
 - Since it's dynamically generated, the repository is missing the `Assets/SkyboxCubemap.cubemap` asset which can be generated via any of the `Waves.cs` components attached to each plane in the scene.
 - No Cubemap is provided to the `TextureSkybox.mat` material used for the sky, the one used in the sample is `CoriolisNight4k` from the [Asset Store](https://assetstore.unity.com/packages/2d/textures-materials/sky/skybox-series-free-103633#content) with some manual adjustments. 
