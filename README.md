# WATER SHADER #
Implements both static and Fractional Brownian Motion generation with different sine-based functions to generate a water-like material. 

# Parameters #
 - Reflection Sharpness : Power for Blinn-Phong shading's (N · H) product.
 - Normal Contrast : Also called Normal Strength, multiplies the FBM derivatives before normalization, increasing the horizontal variation. 
 - Wave Size : Scales the horizontal width of the computation. A higher number will produce lower frequency waves.
 - Displacement Scale : Scales the vertical displacement of the mesh.
 - Wave Generation method : Either FBM or statically chosen from an array of 3 values.
 - Starting Amplitude : Maximum range of the wave amplitude. The final vertex displacement will be always in the range` [h * Displacement Scale, -h * Displacement Scale]` where `h = 1/(1-Starting Amplitude)`
 - Lacunarity : Determines how smaller in amplitude( and higher in frequency) the next generated value is compared to the previous one.
 - Wave Number : Either `Compile or Runtime`, will allow to choose the number of waves via the Editor if runtime, otherwise it will need manual Shader code adjustment.
 - Debug : If activated the waves will not follow `_Time` progression from unity and will instead follow the `Wave Progression` parameter from the Editor.

## Nota Bene ##
 - For storage purposes the repository is missing the `Assets/SkyboxCubemap.cubemap` asset which can be generated via any of the `Waves.cs` components attached to each plane in the scene.
 - No Cubemap is provided to the `TextureSkybox.mat` material used for the sky, the one used in the sample is `CoriolisNight4k` from the [Asset Store](https://assetstore.unity.com/packages/2d/textures-materials/sky/skybox-series-free-103633#content) with some manual adjustments. 
