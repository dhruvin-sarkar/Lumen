#version 330 compatibility
/* No volumetric sun shafts in the Nether. */
/* RENDERTARGETS: 6 */
layout(location = 0) out vec4 outVol;
void main() { outVol = vec4(0.0); }
