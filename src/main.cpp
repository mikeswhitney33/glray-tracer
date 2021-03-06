#include <glad/glad.h>
#include <GLFW/glfw3.h>

#include <glm/glm.hpp>

#include <cmath>
#include <iostream>

#include "headers/shader.hpp"
#include "headers/camera.hpp"

#define deg2rad(deg) deg * M_PI / 180.0f

int screen_width = 800;
int screen_height = 600;
float deltaTime = 0;
int sample_i = 0;

float lastX, lastY;

Camera camera;

void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void key_callback(GLFWwindow* window,  int key, int scancode, int action, int mods);
void cursorpos_callback(GLFWwindow* window, double xpos, double ypos);
void cursorenter_callback(GLFWwindow* window, int entered);
void scroll_callback(GLFWwindow* window, double dx, double dy);

int main(int argc, char** argv) {
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

    GLFWwindow* window = glfwCreateWindow(screen_width, screen_height, "GLRay Tracer", NULL, NULL);
    if(window == NULL) {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    glfwMakeContextCurrent(window);

    if(!gladLoadGL()) {
        std::cout << "Failed to initialize GLAD" << std::endl;
        glfwTerminate();
        exit(EXIT_FAILURE);
    }
    glViewport(0, 0, screen_width, screen_height);
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    glfwSetKeyCallback(window, key_callback);
    glfwSetCursorPosCallback(window, cursorpos_callback);
    glfwSetCursorEnterCallback(window, cursorenter_callback);
    glfwSetScrollCallback(window, scroll_callback);

    // Buffers
    float vertices[] = {
        -1.0f, -1.0f, -1.0f, 1.0f, 1.0f, 1.0f, 1.0f, -1.0f
    };

    unsigned int VBO, VAO;
    glGenVertexArrays(1, &VAO);
    glBindVertexArray(VAO);

    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*) 0);
    glEnableVertexAttribArray(0);

    Shader rtShader = Shader::FromFiles("src/shaders/rtvert.glsl", "src/shaders/rtfrag.glsl");
    Shader scShader = Shader::FromFiles("src/shaders/texvert.glsl", "src/shaders/texfrag.glsl");
    rtShader.use();
    rtShader.setFloat("scale", tanf(deg2rad(60.0f) * 0.5f));
    rtShader.setInt("tex", 0);

    scShader.setInt("tex", 0);

    unsigned int FBO;
    glGenFramebuffers(1, &FBO);
    glBindFramebuffer(GL_FRAMEBUFFER, FBO);

    unsigned int textureBuffer;
    glGenTextures(1, &textureBuffer);
    glBindTexture(GL_TEXTURE_2D, textureBuffer);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, screen_width, screen_height, 0, GL_RGB, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, textureBuffer, 0);

    if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        std::cout << "ERROR::FRAMEBUFFER:: Framebuffer is not complete!" << std::endl;
        exit(EXIT_FAILURE);
    }
    glBindFramebuffer(GL_FRAMEBUFFER, 0);

    sample_i = 0;

    glBindFramebuffer(GL_FRAMEBUFFER, FBO);
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    float lastFrame = 0;

    while(!glfwWindowShouldClose(window)) {
        float time= glfwGetTime();
        deltaTime = time - lastFrame;
        lastFrame = time;

        // Render Code Here:
        glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        glBindFramebuffer(GL_FRAMEBUFFER, FBO);
        rtShader.use();
        rtShader.setFloat("aspect", screen_width / (float) screen_height);
        rtShader.setFloat("pixel_width", 1 / (float)screen_width);
        rtShader.setFloat("pixel_height", 1 / (float)screen_height);
        rtShader.setInt("sample_i", sample_i);
        rtShader.setMat4("cam", camera.getViewMatrix());

        sample_i++;
        glBindVertexArray(VAO);
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);

        glBindFramebuffer(GL_FRAMEBUFFER, 0);
        scShader.use();
        glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
        // glDrawElements(GL_TRIANGLE_FAN, 6, GL_UNSIGNED_INT, 0);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glDeleteFramebuffers(1, &FBO);
    glDeleteVertexArrays(1, &VAO);
    glDeleteBuffers(1, &VBO);

    glfwDestroyWindow(window);
    glfwTerminate();
    exit(EXIT_SUCCESS);
}

void framebuffer_size_callback(GLFWwindow* window, int width, int height) {
    screen_width = width;
    screen_height = height;
    glViewport(0, 0, screen_width, screen_height);
}

void key_callback(GLFWwindow* window,  int key, int scancode, int action, int mods) {
    if(action == GLFW_PRESS || action == GLFW_REPEAT) {
        sample_i = 0;
        if(key == GLFW_KEY_Q || key == GLFW_KEY_ESCAPE) {
            glfwSetWindowShouldClose(window, true);
        }
        if(key == GLFW_KEY_W) {
            camera.move(Camera::CameraDirection::UP, deltaTime);
        }
        if(key == GLFW_KEY_S) {
            camera.move(Camera::CameraDirection::DOWN, deltaTime);
        }
        if(key == GLFW_KEY_A) {
            camera.move(Camera::CameraDirection::LEFT, deltaTime);
        }
        if(key == GLFW_KEY_D) {
            camera.move(Camera::CameraDirection::RIGHT, deltaTime);
        }
    }
}

void cursorpos_callback(GLFWwindow* window, double xpos, double ypos) {
    // std::cout << xpos << "," << ypos << std::endl;
    if(glfwGetMouseButton(window, GLFW_MOUSE_BUTTON_1)) {
        float dx = lastX - xpos;
        float dy = lastY - ypos;

        camera.rotate(dx, dy);
        sample_i = 0;
    }
    lastX = xpos;
    lastY = ypos;

}

void cursorenter_callback(GLFWwindow* window, int entered) {
    // std::cout << "Entered" << std::endl;
    double xpos, ypos;
    glfwGetCursorPos(window, &xpos, &ypos);
    lastX = xpos;
    lastY = ypos;
}

void scroll_callback(GLFWwindow* window, double dx, double dy) {
    camera.move(dy > 0 ? Camera::CameraDirection::FORWARD : Camera::CameraDirection::BACKWARD, deltaTime);
    sample_i = 0;
}
