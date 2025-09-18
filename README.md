# WATER SHADER #
Implements both static and Fractional Brownian Motion generation with different sine-based functions to generate a water-like material. 
Currently only implements displacement by computing sum of sines, but supports multiple height functions (beyond the simple sine) and it can be extended by modifying the `WaveGeneration.cginc`.
It works generally well for a stylized look, as the mathematical model is not detailed enough to give off proper semblance of tide motions as well as no sophisticated way of computing more turbulent effects (e.g. foam and breaking waves).

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
 ## Debugging ##
 - `Debug` : If activated the waves will not follow `_Time` progression from unity and will instead follow the `Wave Progression` parameter from the Editor.

## Nota Bene ##
 - Since it's dynamically generated, the repository is missing the `Assets/SkyboxCubemap.cubemap` asset which can be generated via any of the `Waves.cs` components attached to each plane in the scene.
 - No Cubemap is provided to the `TextureSkybox.mat` material used for the sky, the one used in the sample is `CoriolisNight4k` from the [Asset Store](https://assetstore.unity.com/packages/2d/textures-materials/sky/skybox-series-free-103633#content) with some manual adjustments. 
