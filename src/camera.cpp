#include "headers/camera.hpp"

#include <glm/gtc/matrix_transform.hpp>


Camera::Camera(glm::vec3 pos, glm::vec3 up):
    yaw(YAW), pitch(PITCH), speed(SPEED), sensitivity(SENSITIVITY), zoom(ZOOM),
    wPos(pos), wFront(glm::vec3(0, 0, -1)), wUp(up){
        updateCameraVectors();
    }

glm::mat4 Camera::getViewMatrix() {
    return glm::lookAt(wPos, wPos + wFront, wUp);
}

void Camera::updateCameraVectors() {
    glm::vec3 front;
    front.x = cos(glm::radians(yaw)) * cos(glm::radians(pitch));
    front.y = sin(glm::radians(pitch));
    front.z = sin(glm::radians(yaw)) * cos(glm::radians(pitch));
    wFront = glm::normalize(front);
    wRight = glm::normalize(glm::cross(wFront, wUp));
    wUp = glm::normalize(glm::cross(wRight, wFront));
}

void Camera::move(Camera::CameraDirection dir, float deltaTime) {
    float velocity = speed * deltaTime;
    switch(dir) {
    case FORWARD:
        wPos += wFront * velocity;
        break;
    case BACKWARD:
        wPos -= wFront * velocity;
        break;
    case RIGHT:
        wPos += wRight * velocity;
        break;
    case LEFT:
        wPos -= wRight * velocity;
        break;
    }
}
// class Camera {
// public:
//     static const float YAW = -90.0f;
//     static const float PITCH = 0.0f;
//     static const float SPEED = 2.5f;
//     static const float SENSITIVITY = 0.1f;
//     static const float ZOOM = 45.0f;

//     Camera(glm::vec3 pos, glm::vec3 up);
//     glm::mat4 getViewMatrix();
// private:
//     float yaw, pitch, speed, sensitivity, zoom;
//     void updateCameraVectors();
// };
