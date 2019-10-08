#version 430 core


layout (location = 0) in vec2 aPos;

out vec3 wDir;
out vec2 uv;

void main() {
    gl_Position = vec4(aPos.x, aPos.y, 0.0, 1.0);

    wDir = vec3(aPos, 1.0);
    uv = (1 + aPos) / 2;
}
