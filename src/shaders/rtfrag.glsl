#version 430 core

#define NUM_SPHERES 3
#define NUM_TRIANGLES 10
#define NUM_MATERIALS 4
#define NUM_POINT_LIGHTS 2
#define HIT_NONE 0
#define HIT_SPHERE 1
#define HIT_TRIANGLE 2
#define MAT_DIFF 0
#define MAT_SPEC 1
#define MAT_REFR 2


out vec4 FragColor;

in vec3 wDir;
in vec2 uv;

uniform float aspect;
uniform float scale;
uniform int sample_i;
uniform sampler2D tex;
uniform float pixel_width;
uniform float pixel_height;
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
    int MatType;
    float eta;
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
    materials[0] = Material(0.2, 0.2, 0.2, vec3(0.25, 0.25, 0.75), 32, MAT_DIFF, 1.03);
    materials[1] = Material(0.2, 0.2, 0.2, vec3(0.75, 0.75, 0.75), 1, MAT_DIFF, 1.03);
    materials[2] = Material(0.2, 0.2, 0.2, vec3(1, 1, 1), 32, MAT_SPEC, 1.03);
    materials[3] = Material(0.2, 0.2, 0.2, vec3(1, 1, 1), 32, MAT_REFR, 1.03);
}
void initSpheres() {
    spheres[0] = makeSphere(0, vec3(0, -0.35, 0), 0.15);
    spheres[1] = makeSphere(2, vec3(-0.35, -0.35, 0.2), 0.15);
    spheres[2] = makeSphere(3, vec3(0.35, -0.35, -0.2), 0.15);
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

vec3 rolling_avg(vec3 avg, vec3 new_sample, int N) {
    return (new_sample + (N * avg)) / (N+1);
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

vec3 castRay(vec3 orig, vec3 dir, int depth) {
    int depth_i = 0;
    vec3 color = vec3(0, 0, 0);
    float eta = 1.03;
    while(depth_i < depth) {
        float t = 10000000;
        int ID = -1;
        int hit = intersectShapes(orig, dir, t, ID);
        if(hit == HIT_NONE) {
            return color;
        }
        vec3 pt = orig + t * dir;
        vec3 normal = getNormal(orig, dir, pt, hit, ID);
        Material mat = getMaterial(hit, ID);
        vec3 color_i = mat.ka * mat.ia;
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

                color_i += mat.kd * max(dot(Lm, normal), 0) * light.id + mat.ks * pow(max(dot(Rm, V), 0), mat.phong) * light.is;
            }
        }
        color = rolling_avg(color, color_i, depth_i);
        if(mat.MatType == MAT_SPEC) {
            orig = pt;
            dir = reflect(dir, normal);
            dir = vec3(
                dir.x + pixel_width * noise(normal.xy * sample_i),
                dir.y + pixel_height * noise(normal.yx * sample_i),
                dir.z + pixel_width * noise(normal.xz * sample_i)
            );
            dir = normalize(dir);
        }
        else if(mat.MatType == MAT_REFR) {
            // orig = pt - normal * 0.000001;
            vec3 tdir = (dot(dir, normal) > 0) ? -dir : dir;
            dir = refract(tdir, normal, mat.eta / eta);
            dir = normalize(dir);
            orig = pt + tdir * 0.00001;
            eta = mat.eta;
        }
        else {
            return color;
        }
        depth_i++;
        // color = color + color_i / depth_i;
    }
    
    return color;
}



void main() {
    initScene();

    // vec3 orig = vec3(0, 0, -1);
    vec4 orig4 = cam * vec4(0, 0, 0, 1);
    vec3 orig = orig4.xyz / orig4.w;
    vec3 dir = vec3(
        wDir.x * scale * aspect + pixel_width * noise(wDir.xy * sample_i),
        wDir.y * scale + pixel_height * noise(wDir.yx * sample_i),
        1
    );
    // dir = (inverse(cam) * vec4(dir, 0)).xyz;

    vec3 color = castRay(orig, normalize(dir), 5);
    vec3 avg = texture(tex, uv).xyz;

    FragColor = vec4(rolling_avg(avg, color, sample_i), 1.0f);
}
