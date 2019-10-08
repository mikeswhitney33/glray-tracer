#ifndef CAMERA_HPP
#define CAMERA_HPP

#include <glm/glm.hpp>

class Camera {
public:
    enum CameraDirection {
        FORWARD, BACKWARD, LEFT, RIGHT
    };
    const float YAW = -90.0f;
    const float PITCH = 0.0f;
    const float SPEED = 2.5f;
    const float SENSITIVITY = 0.1f;
    const float ZOOM = 45.0f;

    Camera(glm::vec3 pos=glm::vec3(0, 0, 1), glm::vec3 up=glm::vec3(0, 1, 0));
    glm::mat4 getViewMatrix();
    void move(Camera::CameraDirection dir, float deltaTime);

private:
    float yaw, pitch, speed, sensitivity, zoom;
    glm::vec3 wFront, wPos, wUp, wRight;
    void updateCameraVectors();
};

#endif