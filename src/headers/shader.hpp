#ifndef SHADER_HPP
#define SHADER_HPP

#include <glm/glm.hpp>

class Shader {
public:
    static Shader FromFiles(const char* vFile, const char* fFile);
    Shader(const char* vCode, const char* fCode);
    ~Shader();
    void use() const;
    void setFloat(const char* name, float value) const;
    void setInt(const char* name, int value) const;
    void setVec3(const char* name, glm::vec3 value) const;
    void setMat4(const char* name, glm::mat4x4 value) const;
private:
    unsigned int ID;
    unsigned int getLocation(const char* name) const;
};

#endif
