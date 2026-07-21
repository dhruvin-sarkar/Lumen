#version 330 compatibility
/*
 * Fullscreen-pass vertex stage for final. Iris draws a screen quad;
 * we forward the screen UV.
 */
out vec2 texcoord;

void main() {
    gl_Position = ftransform();
    texcoord    = gl_MultiTexCoord0.xy;
}
