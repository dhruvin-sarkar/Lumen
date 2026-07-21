#version 330 compatibility
/* Fullscreen vertex stage for the deferred lighting resolve. */
out vec2 texcoord;
void main() {
    gl_Position = ftransform();
    texcoord    = gl_MultiTexCoord0.xy;
}
