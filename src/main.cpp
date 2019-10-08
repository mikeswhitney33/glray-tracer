#include <glad/glad.h>
#include <GLFW/glfw3.h>
#include <iostream>

int screen_width = 800;
int screen_height = 600;

void framebuffer_size_callback(GLFWwindow* window, int width, int height);
void key_callback(GLFWwindow* window,  int key, int scancode, int action, int mods);

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

    // Buffers
    float vertices[] = {
        -0.5f, -0.5f,
        0.5f, -0.5f,
        0.0f, 0.5f,
    };

    unsigned int VBO, VAO;
    glGenVertexArrays(1, &VAO);
    glBindVertexArray(VAO);

    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glVertexAttribPointer(0, 2, GL_FLOAT, GL_FALSE, 2 * sizeof(float), (void*) 0);
    glEnableVertexAttribArray(0);

    // Shader
    const char* vertexCode = "#version 330 core\n\
    layout (location = 0) in vec2 aPos;\n\
    void main() {\n\
    gl_Position = vec4(aPos.x, aPos.y, 0.0, 1.0);\n\
    }";
    unsigned int vertexShader;
    vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertexShader, 1, &vertexCode, NULL);
    glCompileShader(vertexShader);
    {
        int success;
        char infoLog[512];
        glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &success);
        if(!success) {
            glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
            std::cout << "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n" << infoLog << std::endl;
            exit(EXIT_FAILURE);
        }
    }

    const char* fragCode = "#version 330 core\n\
    out vec4 FragColor;\n\
    void main() {\n\
    FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);\n\
    }";
    unsigned int fragShader;
    fragShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragShader, 1, &fragCode, NULL);
    glCompileShader(fragShader);
    {
        int success;
        char infoLog[512];
        glGetShaderiv(fragShader, GL_COMPILE_STATUS, &success);
        if(!success) {
            glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
            std::cout << "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n" << infoLog << std::endl;
            exit(EXIT_FAILURE);
        }
    }

    unsigned int shaderProgram;
    shaderProgram = glCreateProgram();

    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragShader);
    glLinkProgram(shaderProgram);
    {
        int success;
        char infoLog[512];
        glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
        if(!success) {
            glGetShaderInfoLog(shaderProgram, 512, NULL, infoLog);
            std::cout << "ERROR::SHADER::PROGRAM::LINKING_FAILED\n" << infoLog << std::endl;
            exit(EXIT_FAILURE);
        }
    }

    glDeleteShader(vertexShader);
    glDeleteShader(fragShader);



    while(!glfwWindowShouldClose(window)) {
        glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);

        // Render Code Here:
        glUseProgram(shaderProgram);
        glBindVertexArray(VAO);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    glfwTerminate();
    exit(EXIT_SUCCESS);
}

void framebuffer_size_callback(GLFWwindow* window, int width, int height) {
    screen_width = width;
    screen_height = height;
    glViewport(0, 0, screen_width, screen_height);
}

void key_callback(GLFWwindow* window,  int key, int scancode, int action, int mods) {
    if(action == GLFW_PRESS) {
        if(key == GLFW_KEY_Q || key == GLFW_KEY_ESCAPE) {
            glfwSetWindowShouldClose(window, true);
        }
    }
}
