#version 430 core

#define NUM_SPHERES 1
#define NUM_TRIANGLES 10
#define NUM_MATERIALS 2
#define NUM_POINT_LIGHTS 2
#define HIT_NONE 0
#define HIT_SPHERE 1
#define HIT_TRIANGLE 2


out vec4 FragColor;

in vec3 wDir;
in vec2 uv;

uniform float aspect;
uniform float scale;
uniform int sample_i;
uniform sampler2D tex;
uniform float pixel_width;
uniform float pixel_height;
// uniform vec3 orig;
uniform mat4 cam;

struct Sphere {
    int matID;
    vec3 center;
    float rad;
    float rad2;
};
Sphere makeSphere(int matID, vec3 center, float rad) {
    return Sphere(matID, center, rad, rad*rad);
}

struct Triangle {
    int matID;
    vec3 A, B, C;
};

struct Material {
    float ka, kd, ks;
    vec3 ia;
    float phong;
};

struct PointLight {
    vec3 id, is;
    vec3 pos;
};

Triangle triangles[NUM_TRIANGLES];
Sphere spheres[NUM_SPHERES];
Material materials[NUM_MATERIALS];
PointLight pointLights[NUM_POINT_LIGHTS];

void initMaterials() {
    materials[0] = Material(0.2, 0.2, 0.2, vec3(0.25, 0.25, 0.75), 32);
    materials[1] = Material(0.2, 0.2, 0.2, vec3(0.75, 0.75, 0.75), 1);
}
void initSpheres() {
    spheres[0] = makeSphere(0, vec3(0, -0.35, 0), 0.15);
}
void initTriangles() {
    triangles[0] = Triangle(0, vec3(-0.5, -0.5, -0.5), vec3(-0.5, -0.5, 0.5), vec3(0.5, -0.5, 0.5));
    triangles[1] = Triangle(0, vec3(-0.5, -0.5, -0.5), vec3(0.5, -0.5, -0.5), vec3(0.5, -0.5, 0.5));
    triangles[2] = Triangle(1, vec3(-0.5, -0.5, 0.5), vec3(-0.5, 0.5, 0.5), vec3(0.5, 0.5, 0.5));
    triangles[3] = Triangle(1, vec3(-0.5, -0.5, 0.5), vec3(0.5, -0.5, 0.5), vec3(0.5, 0.5, 0.5));
    triangles[4] = Triangle(1, vec3(-0.5, -0.5, -0.5), vec3(-0.5, 0.5, -0.5), vec3(-0.5, 0.5, 0.5));
    triangles[5] = Triangle(1, vec3(-0.5, -0.5, -0.5), vec3(-0.5, -0.5, 0.5), vec3(-0.5, 0.5, 0.5));
    triangles[6] = Triangle(1, vec3(0.5, -0.5, -0.5), vec3(0.5, 0.5, -0.5), vec3(0.5, 0.5, 0.5));
    triangles[7] = Triangle(1, vec3(0.5, -0.5, -0.5), vec3(0.5, -0.5, 0.5), vec3(0.5, 0.5, 0.5));
    triangles[8] = Triangle(1, vec3(-0.5, 0.5, -0.5), vec3(0.5, 0.5, -0.5), vec3(0.5, 0.5, 0.5));
    triangles[9] = Triangle(1, vec3(-0.5, 0.5, -0.5), vec3(-0.5, 0.5, 0.5), vec3(0.5, 0.5, 0.5));
}

void initPointLights() {
    pointLights[0] = PointLight(vec3(1, 1, 1), vec3(1, 1, 1), vec3(0.4, 0.4, 0.0));
    pointLights[1] = PointLight(vec3(1, 1, 1), vec3(1, 1, 1), vec3(-0.4, 0.4, 0.0));
}

void initLights() {
    initPointLights();
}

void initScene() {
    initSpheres();
    initTriangles();
    initMaterials();
    initLights();
}

float noise(vec2 co){
    return 2 * fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453) - 1;
}

bool ray_sphere(vec3 orig, vec3 dir, vec3 center, float rad2, inout float t) {
    // return false;
    vec3 L = center - orig;
    float tca = dot(L, dir);
    if(tca < 0) return false;
    float d2 = dot(L, L) - tca * tca;
    if(d2 > rad2) return false;
    float thc = sqrt(rad2 - d2);
    float t0 = tca - thc;
    float t1 = tca + thc;

    if(t0 > t1) {
        float tmp = t0;
        t0 = t1;
        t1 = tmp;
    }

    if(t0 < 0) {
        t0 = t1;
        if(t0 < 0) return false;
    }

    if(t0 > t) return false;
    t = t0;
    return true;
}

bool ray_triangle(vec3 orig, vec3 dir, vec3 A, vec3 B, vec3 C, inout float t) {
    vec3 AB = B - A;
    vec3 AC = C - A;
    vec3 pvec = cross(dir, AC);
    float det = dot(AB, pvec);
    if(abs(det) < 0.0000001) return false;
    float invDet = 1 / det;
    vec3 tvec = orig - A;
    float u = dot(tvec, pvec) * invDet;
    if(u < 0 || u > 1) return false;
    vec3 qvec = cross(tvec, AB);
    float v = dot(dir, qvec) * invDet;
    if(v < 0 || u + v > 1) return false;
    float tmpt = dot(AC, qvec) * invDet;
    if(tmpt > t || tmpt < 0) return false;
    t = tmpt;


    return true;
}

int intersectSpheres(vec3 orig, vec3 dir, inout float t, inout int hit) {
    int ID = -1;
    for(int i = 0;i < NUM_SPHERES;i++) {
        Sphere s = spheres[i];
        if(ray_sphere(orig, dir, s.center, s.rad2, t)) {
            ID = i;
        }
    }
    if(ID > -1) {
        hit = HIT_SPHERE;
    }
    return ID;
}

int intersectTriangles(vec3 orig, vec3 dir, inout float t, inout int hit) {
    int ID = -1;
    for(int i = 0;i < NUM_TRIANGLES;i++) {
        Triangle tri = triangles[i];
        if(ray_triangle(orig, dir, tri.A, tri.B, tri.C, t)) {
            ID = i;
        }
    }
    if(ID > -1) {
        hit = HIT_TRIANGLE;
    }
    return ID;
}

int intersectShapes(vec3 orig, vec3 dir, inout float t, inout int ID) {
    int hit = HIT_NONE;
    int tmpID = -1;
    tmpID = intersectSpheres(orig, dir, t, hit);
    if(hit == HIT_SPHERE) ID = tmpID;
    tmpID = intersectTriangles(orig, dir, t, hit);
    if(hit == HIT_TRIANGLE) ID = tmpID;
    return hit;
}

vec3 getNormal(vec3 orig, vec3 dir, vec3 pt, int hit, int ID) {
    if(hit == HIT_SPHERE) {
        return normalize(pt - spheres[ID].center);
    }
    else if(hit == HIT_TRIANGLE) {
        Triangle tri = triangles[ID];
        vec3 AB = tri.B - tri.A;
        vec3 AC = tri.C - tri.A;
        vec3 n = normalize(cross(AB, AC));
        if(dot(dir, n) > 0) {
            n = -n;
        }
        return n;
    }
    return vec3(0, 0, 0);
}

Material getMaterial(int hit, int ID) {
    if(hit == HIT_SPHERE) {
        return materials[spheres[ID].matID];
    }
    else if(hit == HIT_TRIANGLE) {
        return materials[triangles[ID].matID];
    }
    return materials[0];
}

vec3 castRay(vec3 orig, vec3 dir) {
    float t = 10000000;
    int ID = -1;
    int hit = intersectShapes(orig, dir, t, ID);
    if(hit == HIT_NONE) {
        return vec3(0, 0, 0);
    }
    vec3 pt = orig + t * dir;
    vec3 normal = getNormal(orig, dir, pt, hit, ID);
    Material mat = getMaterial(hit, ID);
    vec3 color = mat.ka * mat.ia;
    vec3 V = normalize(orig - pt);
    for(int i = 0;i < NUM_POINT_LIGHTS;i++) {
        PointLight light = pointLights[i];
        vec3 shadow_orig = pt;
        vec3 shadow_dir = normalize(light.pos - shadow_orig);
        float shadowt = 10000000.0;
        int shadow_ID = -1;
        int shadow_hit = intersectShapes(shadow_orig + normal * 0.0001, shadow_dir, shadowt, shadow_ID);
        vec3 shadowpt = shadow_orig + shadowt * shadow_dir;
        if(shadow_hit == HIT_NONE || distance(shadow_orig, light.pos) < distance(shadow_orig, shadowpt)) {
            vec3 Lm = normalize(light.pos - pt);
            vec3 Rm = normalize(reflect(-Lm, normal));

            color += mat.kd * max(dot(Lm, normal), 0) * light.id + mat.ks * pow(max(dot(Rm, V), 0), mat.phong) * light.is;
        }
    }
    return color;
}

vec3 rolling_avg(vec3 avg, vec3 new_sample, int N) {
    return (new_sample + (N * avg)) / (N+1);
}

void main() {
    initScene();

    vec3 orig = (cam * vec4(vec3(0, 0, 0), 1)).xyz;
    // vec3 orig = cam * vec4(vec3(0, 0, 0), 1).xyz;
    vec3 dir = normalize(vec3(
        (wDir.x + pixel_width * noise(wDir.xy*sample_i)) * scale * aspect,
        (wDir.y + pixel_height * noise(wDir.yx*sample_i)) * scale, 1));
    vec3 color = castRay(orig, dir);
    vec3 avg = texture(tex, uv).xyz;

    FragColor = vec4(rolling_avg(avg, color, sample_i), 1.0f);
}
