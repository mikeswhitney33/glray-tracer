#include "headers/shader.hpp"

#include <glad/glad.h>
#include <GLFW/glfw3.h>

#include <fstream>
#include <iostream>
#include <string>

unsigned int makeShader(const char* code, GLuint shaderType, const char* shaderTypeName);
std::string get_file_contents(const char* filename);

Shader Shader::FromFiles(const char* vFile, const char* fFile) {
    std::string vCodeStr = get_file_contents(vFile);
    std::string fCodeStr = get_file_contents(fFile);

    const char* vCode = vCodeStr.c_str();
    const char* fCode = fCodeStr.c_str();
    return Shader(vCode, fCode);
}

Shader::Shader(const char* vCode, const char* fCode) {
    unsigned int shaderProgram;
    shaderProgram = glCreateProgram();

    unsigned int vertexShader = makeShader(vCode, GL_VERTEX_SHADER, "VERTEX");
    unsigned int fragShader = makeShader(fCode, GL_FRAGMENT_SHADER, "FRAGMENT");

    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragShader);
    glLinkProgram(shaderProgram);
    {
        int success;
        char infoLog[512];
        glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
        if(!success) {
            glGetProgramInfoLog(shaderProgram, 512, NULL, infoLog);
            std::cout << "ERROR::SHADER::PROGRAM::LINKING_FAILED\n" << infoLog << std::endl;
            exit(EXIT_FAILURE);
        }
    }

    ID = shaderProgram;
    glDeleteShader(vertexShader);
    glDeleteShader(fragShader);
}

Shader::~Shader() {}

void Shader::use() const {
    glUseProgram(ID);
}

unsigned int Shader::getLocation(const char* name) const {
    return glGetUniformLocation(ID, name);
}

void Shader::setFloat(const char* name, float value) const {
    glUniform1f(getLocation(name), value);
}

void Shader::setInt(const char* name, int value) const {
    glUniform1i(getLocation(name), value);
}

void Shader::setVec3(const char* name, glm::vec3 value) const {
    glUniform3f(getLocation(name), value.x, value.y, value.z);
}

void Shader::setMat4(const char* name, glm::mat4x4 value) const {
    glUniformMatrix4fv(getLocation(name), 1, false, &value[0][0]);
}

unsigned int makeShader(const char* code, GLuint shaderType, const char* shaderTypeName) {
    unsigned int shader;
    shader = glCreateShader(shaderType);
    glShaderSource(shader, 1, &code, NULL);
    glCompileShader(shader);
    {
        int success;
        char infoLog[512];
        glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
        if(!success) {
            glGetShaderInfoLog(shader, 512, NULL, infoLog);
            std::cout << "ERROR::SHADER::" << shaderTypeName << "::COMPILATION_FAILED\n" << infoLog << std::endl;
            exit(EXIT_FAILURE);
        }
    }
    return shader;
}

std::string get_file_contents(const char* filename) {
    std::ifstream in(filename, std::ios::in | std::ios::binary);
    if(in) {
        std::string contents;
        in.seekg(0, std::ios::end);
        contents.resize(in.tellg());
        in.seekg(0, std::ios::beg);
        in.read(&contents[0], contents.size());
        in.close();
        return (contents);
    }
    throw(errno);
}

