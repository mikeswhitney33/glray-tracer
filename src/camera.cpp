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

glm::vec3 Camera::getFront() const {
    return wFront;
}
glm::vec3 Camera::getPos() const {
    return wPos;
}
glm::vec3 Camera::getUp() const {
    return wUp;
}
glm::vec3 Camera::getRight() const {
    return wRight;
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
        wPos -= wRight * velocity;
        break;
    case LEFT:
        wPos += wRight * velocity;
        break;
    case UP:
        wPos -= wUp * velocity;
        break;
    case DOWN:
        wPos += wUp * velocity;
        break;
    }
}

void Camera::rotate(float dx, float dy) {
    dx *= sensitivity;
    dy *= sensitivity;
    yaw += dx;
    pitch += dy;

    if(pitch > 89.0f) pitch = 89.0f;
    if(pitch < -89.0f) pitch = -89.0f;
    updateCameraVectors();
}
