#version 430 core

#define NUM_MATERIALS 7
#define NUM_POINT_LIGHTS 2
#define NUM_SHAPES 13

#define SHAPE_TRIANGLE 0
#define SHAPE_SPHERE 1

#define M_PI 3.141592654
#define RAND_MAX pow(2, 31)

//mt19937
#define RK_STATE_LEN 624
#define mt_N 624
#define mt_M 397
#define mt_MATRIX_A  0x9908b0dfU
#define mt_UPPER_MASK 0x80000000U
#define mt_LOWER_MASK 0x7fffffffU

#extension GL_NV_gpu_shader5 : enable



struct s_mt19937_state {
    uint32_t key[RK_STATE_LEN];
    int pos;
};

void mt19937_seed(inout s_mt19937_state state, uint32_t seed) {
    int pos;
    seed &= 0xffffffffU;
    for(pos = 0;pos < RK_STATE_LEN;pos++) {
        state.key[pos] = seed;
        seed = (1812433253U * (seed ^ (seed >> 30)) + pos + 1) & 0xffffffffU;
    }
    state.pos = RK_STATE_LEN;
}

void init_genrand(inout s_mt19937_state state, uint32_t s) {
    int mti;
    // uint32_t state.key[RK_STATE_LEN] = state.key;
    for(mti = 1; mti < RK_STATE_LEN;mti++) {
        state.key[mti] = 1812433253U * (state.key[mti-1] ^ (state.key[mti-1] >> 30)) + mti;
        state.key[mti] &= 0xffffffffUL;
    }
    state.pos = mti;
}



void mt19937_gen(inout s_mt19937_state state) {
    uint32_t y;
    int i;
    for(i = 0;i < mt_N - mt_M;i++) {
        y = (state.key[i] & mt_UPPER_MASK) | (state.key[i+1] & mt_LOWER_MASK);
        state.key[i] = state.key[i+mt_M] ^ (y >> 1) ^ (-(y & 1) & mt_MATRIX_A);
    }
    for(; i < mt_N - 1;i++) {
        y = (state.key[i] & mt_UPPER_MASK) | (state.key[i+1] & mt_LOWER_MASK);
        state.key[i] = state.key[i + (mt_M - mt_N)] ^ (y >> 1) ^ (-(y&1)&mt_MATRIX_A);
    }
    y = (state.key[mt_N-1] & mt_UPPER_MASK) | (state.key[0] & mt_LOWER_MASK);
    state.key[mt_N - 1] = state.key[mt_M - 1] ^ (y >> 1) ^ (-(y&1) & mt_MATRIX_A);

    state.pos = 0;
}

uint32_t mt19937_next(inout s_mt19937_state state) {
    uint32_t y;
    if(state.pos == RK_STATE_LEN) {
        mt19937_gen(state);
    }
    y = state.key[state.pos++];
    y ^= (y>>11);
    y ^= (y << 7) & 0x9d2c5680U;
    y ^= (y << 15) & 0xefc60000U;
    y ^= (y >> 18);
    return y;
}

uint64_t mt19937_next64(inout s_mt19937_state state) {
    return mt19937_next(state) << 32 | mt19937_next(state);
}

uint32_t mt_19937_next32(inout s_mt19937_state state) {
    return uint32_t(mt19937_next(state));
}

double mt19937_next_double(inout s_mt19937_state state) {
    uint64_t a = mt19937_next(state) >> 5, b = mt19937_next(state) >> 6;
    return (double(a) * 67108864.0 + b) / 9007199254740992.0;
}

float mt19937_next_float(inout s_mt19937_state state) {
    return float(mt19937_next_double(state));
}

s_mt19937_state state;







// unsigned long next = mt_MATRIX_A;

// unsigned long rand() {
//     // next = (630360016 * next) % (long(pow(2, 31)) - 1);
//     // return next;
//     // next = next * 1103515245 + 12345;
//     // return int(next / 65536) % 32768;
// }
void srand(uint32_t seed) {
    mt19937_seed(state, seed);
    // next = seed;
}

float randf() {
    return mt19937_next_float(state);
    // return sin(cos(rand())) / M_PI;
    // return float(rand()) / float(RAND_MAX);
    // return fract(sin(dot(normalize(vec2(rand(), rand())), vec2(12.9898,78.233))) * 43758.5453);

}

float randf(float max) {
    return randf() * max;
}



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
    vec3 center;
    float rad;
    float rad2;
};
Sphere makeSphere(vec3 center, float rad) {
    return Sphere(center, rad, rad*rad);
}

struct Triangle {
    vec3 A, B, C;
};

struct Material {
    float ka, kd, ks;
    vec3 ia;
    float phong;
    float reflectance;
    float transparency;
    float diffusness;
};

struct PointLight {
    vec3 id, is;
    vec3 pos;
};

struct Shape {
    int matID;
    int shapeType;
    Triangle triangle;
    Sphere sphere;
};

Shape shapes[NUM_SHAPES];

Material materials[NUM_MATERIALS];
PointLight pointLights[NUM_POINT_LIGHTS];

Triangle nullTriangle() {
    return Triangle(vec3(0, 0, 0), vec3(0, 0, 0), vec3(0, 0, 0));
}

Sphere nullSphere() {
    return Sphere(vec3(0, 0, 0), 0, 0);
}

Shape makeShape(int matID, Triangle tri) {
    return Shape(matID, SHAPE_TRIANGLE, tri, nullSphere());
}

Shape makeShape(int matID, Sphere s) {
    return Shape(matID, SHAPE_SPHERE, nullTriangle(), s);
}

void initShapes() {
    // floor
    shapes[0] = makeShape(4, Triangle(vec3(-0.5, -0.5, -0.5), vec3(-0.5, -0.5, 0.5), vec3(0.5, -0.5, 0.5)));
    shapes[1] = makeShape(4, Triangle(vec3(-0.5, -0.5, -0.5), vec3(0.5, -0.5, -0.5), vec3(0.5, -0.5, 0.5)));
    // back
    shapes[2] = makeShape(1, Triangle(vec3(-0.5, -0.5, 0.5), vec3(-0.5, 0.5, 0.5), vec3(0.5, 0.5, 0.5)));
    shapes[3] = makeShape(1, Triangle(vec3(-0.5, -0.5, 0.5), vec3(0.5, -0.5, 0.5), vec3(0.5, 0.5, 0.5)));
    // left
    shapes[4] = makeShape(5, Triangle(vec3(-0.5, -0.5, -0.5), vec3(-0.5, 0.5, -0.5), vec3(-0.5, 0.5, 0.5)));
    shapes[5] = makeShape(5, Triangle(vec3(-0.5, -0.5, -0.5), vec3(-0.5, -0.5, 0.5), vec3(-0.5, 0.5, 0.5)));
    // right
    shapes[6] = makeShape(6, Triangle(vec3(0.5, -0.5, -0.5), vec3(0.5, 0.5, -0.5), vec3(0.5, 0.5, 0.5)));
    shapes[7] = makeShape(6, Triangle(vec3(0.5, -0.5, -0.5), vec3(0.5, -0.5, 0.5), vec3(0.5, 0.5, 0.5)));
    // ceiling
    shapes[8] = makeShape(1, Triangle(vec3(-0.5, 0.5, -0.5), vec3(0.5, 0.5, -0.5), vec3(0.5, 0.5, 0.5)));
    shapes[9] = makeShape(1, Triangle(vec3(-0.5, 0.5, -0.5), vec3(-0.5, 0.5, 0.5), vec3(0.5, 0.5, 0.5)));

    shapes[10] = makeShape(0, makeSphere(vec3(0, -0.35, 0), 0.15));
    shapes[11] = makeShape(2, makeSphere(vec3(0.35, -0.35, 0.0), 0.15));
    shapes[12] = makeShape(3, makeSphere(vec3(-0.35, -0.35, -0.1), 0.15));
}

void initMaterials() {
    materials[0] = Material(0.2, 0.4, 0.2, vec3(0.25, 0.25, 0.75), 32, 0, 0, 1);
    materials[1] = Material(0.2, 0.4, 0.2, vec3(0.75, 0.75, 0.25), 1, 0, 0, 1);
    materials[2] = Material(0.2, 0.4, 0.2, vec3(1, 1, 1), 32, 1, 0, 1);
    materials[3] = Material(0.2, 0.4, 0.2, vec3(.7, .7, .7), 32, 0, 1, 0);
    materials[4] = Material(0.2, 0.4, 0.2, vec3(.2, .7, .2), 32, .1, 0, 0);
    materials[5] = Material(0.2, 0.4, 0.2, vec3(0.75, 0.25, 0.25), 1, .1, 0, 0);
    materials[6] = Material(0.2, 0.4, 0.2, vec3(0.25, 0.25, 0.75), 1, .1, 0, 0);
}

void initPointLights() {
    pointLights[0] = PointLight(vec3(1, 1, 1), vec3(1, 1, 1), vec3(0.4, 0.4, 0.0));
    pointLights[1] = PointLight(vec3(1, 1, 1), vec3(1, 1, 1), vec3(-0.4, 0.4, 0.0));
}

void initLights() {
    initPointLights();
}

void initScene() {
    initShapes();
    initMaterials();
    initLights();
}


float noise(vec2 co){
    return randf();
    // return noise1(cos(sample_i));
    // return 2 * fract(sin(dot(co.xy, vec2(12.9898,78.233))) * 43758.5453) - 1;
}

vec3 rolling_avg(vec3 avg, vec3 new_sample, int N) {
    return (new_sample + (N * avg)) / (N+1);
}

bool intersect(vec3 orig, vec3 dir, Sphere s, inout float t) {
    vec3 L = s.center - orig;
    float tca = dot(L, dir);
    if(tca < 0) return false;
    float d2 = dot(L, L) - tca * tca;
    if(d2 > s.rad2) return false;
    float thc = sqrt(s.rad2 - d2);
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

bool intersect(vec3 orig, vec3 dir, Triangle tri, inout float t) {
    vec3 AB = tri.B - tri.A;
    vec3 AC = tri.C - tri.A;
    vec3 pvec = cross(dir, AC);
    float det = dot(AB, pvec);
    if(abs(det) < 0.0000001) return false;
    float invDet = 1 / det;
    vec3 tvec = orig - tri.A;
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

bool intersect(vec3 orig, vec3 dir, Shape shape, inout float t) {
    if(shape.shapeType == SHAPE_SPHERE) {
        return intersect(orig, dir, shape.sphere, t);
    }
    else {
        return intersect(orig, dir, shape.triangle, t);
    }
}

bool intersect(vec3 orig, vec3 dir, inout float t, inout int ID) {
    for(int i = 0;i < NUM_SHAPES;i++) {
        if(intersect(orig, dir, shapes[i], t)) {
            ID = i;
        }
    }
    return ID > -1;
}


vec3 getNormal(vec3 pt, Sphere s) {
    return normalize(pt - s.center);
}

vec3 getNormal(vec3 dir, Triangle tri) {
    vec3 AB = tri.B - tri.A;
    vec3 AC = tri.C - tri.A;
    vec3 n = normalize(cross(AB, AC));
    if(dot(dir, n) > 0) {
        n = -n;
    }
    return n;
}

vec3 getNormal(vec3 dir, vec3 pt, Shape s) {
    if(s.shapeType == SHAPE_SPHERE) {
        return getNormal(pt, s.sphere);
    }
    else {
        return getNormal(dir, s.triangle);
    }
}


vec3 getColor(vec3 pt, vec3 normal, vec3 V, Material mat) {
    // vec3 color_i = mat.ka * mat.ia;
    vec3 color_i = vec3(0, 0, 0);
    for(int i = 0;i < NUM_POINT_LIGHTS;i++) {
        PointLight light = pointLights[i];
        vec3 shadow_orig = pt;
        vec3 shadow_dir = normalize(light.pos - shadow_orig);
        float shadowt = 10000000.0;
        int shadow_ID = -1;
        bool shadow_hit = intersect(shadow_orig + normal * 0.0001, shadow_dir, shadowt, shadow_ID);
        vec3 shadowpt = shadow_orig + shadowt * shadow_dir;
        if(!shadow_hit || distance(shadow_orig, light.pos) < distance(shadow_orig, shadowpt)) {
            vec3 Lm = normalize(light.pos - pt);
            vec3 Rm = normalize(reflect(-Lm, normal));

            color_i += mat.kd * max(dot(Lm, normal), 0) * mat.ia + mat.ks * pow(max(dot(Rm, V), 0), mat.phong) * light.is;
        }
    }
    return color_i;
}

void getReflectionRay(vec3 pt, vec3 normal, inout vec3 orig, inout vec3 dir) {
    dir = reflect(dir, normal);
    dir += vec3(pixel_width*2 * randf(), pixel_height*2 * randf(), pixel_width*2 * randf());

    dir = normalize(dir);
    orig = pt + dir * .000001;
}

void getRefractionRay(vec3 pt, vec3 normal, inout vec3 orig, inout vec3 dir) {
    float eta1 = 1;
    float eta2 = 1.003;

    float n = dot(dir, normal) > 0 ? eta2 / eta1 : eta1 / eta2;
    float cosI = -dot(normal, dir);
    float sinT2 = n * n * (1.0 - cosI * cosI);
    if(sinT2 > 1.0) {
        dir = reflect(dir, normal);
    }
    else {
        float cosT = sqrt(1.0 - sinT2);
        dir = n * dir + (n * cosI - cosT) * -normal;
    }
    dir = normalize(dir);
    orig = pt + dir * 0.000001;
}

void makeCoordinateSystem(vec3 N, inout vec3 Nt, inout vec3 Nb) {
    if(abs(N.x) > abs(N.y)) {
        Nt = vec3(N.z, 0, -N.x) / sqrt(N.x * N.x + N.z * N.z);
    }
    else {
        Nt = vec3(0, -N.z, N.y) / sqrt(N.y * N.y + N.z * N.z);
    }
    Nb = cross(N, Nt);
}

vec3 uniformSampleHemisphere(float r1, float r2) {
    float sinT = sqrt(1 - r1 * r1);
    float phi = 2 * M_PI * r2;
    float x = sinT * cos(phi);
    float z = sinT * sin(phi);
    return vec3(x, r1, z);
}

void getDiffuseRay(vec3 pt, vec3 normal, inout vec3 orig, inout vec3 dir) {
    vec3 smp = uniformSampleHemisphere(randf(), randf());
    vec3 Nb, Nt;
    makeCoordinateSystem(normal, Nt, Nb);
    dir = vec3(
        smp.x * Nb.x + smp.y * normal.x + smp.z * Nt.x,
        smp.x * Nb.y + smp.y * normal.y + smp.z * Nt.y,
        smp.x * Nb.z + smp.y * normal.z + smp.z * Nt.z
    );
    orig = pt + dir * 0.000001;
}

vec3 castRay(vec3 orig, vec3 dir, int depth) {
    vec3 finalColor = vec3(0, 0, 0);
    bool noHit = true;
    float r = 1.0;
    for(int i = 0;i < depth;i++) {
        float t = 1000000.0;
        int ID = -1;
        if(intersect(orig, dir, t, ID)) {
            noHit = false;
            vec3 pt = orig + dir * t;
            vec3 normal = getNormal(dir, pt, shapes[ID]);
            vec3 nl = dot(normal, dir) < 0 ? normal : -normal;
            Material mat = materials[shapes[ID].matID];
            vec3 color = getColor(pt, normal, -dir, mat);
            finalColor += r * color;

            float p = randf() * (mat.transparency + mat.reflectance + mat.diffusness);
            if(p < mat.transparency) {
                bool into = dot(normal, nl) > 0;
                float nc = 1, nt = 1.5, nnt = into ? nc / nt : nt / nc, ddn = dot(dir, nl);

                float cos2t = 1 - nnt * nnt * (1 - ddn * ddn);
                if(cos2t < 0) {
                    getReflectionRay(pt, normal, orig, dir);
                    r *= mat.transparency;
                    continue;
                }
                vec3 tdir = normalize(dir * nnt - normal * ((into? 1 : -1) * (ddn * nnt + sqrt(cos2t))));
                dir = tdir;
                orig = pt + dir * 0.00001;
                // float a = nt - nc;
                // float b = nt + nc;
                // float R0 = a * a / (b*b);
                // float c = 1 - (into? -ddn : dot(tdir,normal));
                // float Re = R0 + (1 - R0) * c * c * c * c * c;
                // float Tr = 1 - Re;
                // float P = .25 + .5 * Re;

                // // if(noise(tdir.xy * sample_i * depth) < P) {
                // //     getReflectionRay(pt, normal, orig, dir);
                // //     r *= mat.transparency;
                // // }
                // // else {
                //     dir = tdir;
                //     orig = pt;
                //     orig + dir * 0.0001;
                //     // finalColor *= c;
                //     r *= mat.transparency;
                // }
                // getRefractionRay(pt, normal, orig, dir);
                // Ray reflRay(x, r.d-n*2*n.dot(r.d));     // Ideal dielectric REFRACTION

                // r *= mat.transparency;
                // vec3 rdir = -dir;
                // getRefractionRay(pt, normal, orig, dir);
                // dir = rdir;
                r *= mat.transparency;
            }
            // else if(mat.reflectance == 1) {
            else if(p < mat.transparency + mat.reflectance) {
                getReflectionRay(pt, normal, orig, dir);
                r *= mat.reflectance;
            }
            else {
                getDiffuseRay(pt, normal, orig, dir);
                r *= mat.diffusness;
            }
        }
    }
    return noHit ? vec3(0, 0, 0) : finalColor;
}

void main() {
    srand(sample_i);
    initScene();

    vec4 orig4 = cam * vec4(0, 0, 0, 1);
    vec3 orig = orig4.xyz / orig4.w;
    vec3 dir = vec3(
        wDir.x * scale * aspect + pixel_width * randf(),
        wDir.y * scale + pixel_height * randf(),
        -1
    );
    dir = (cam * vec4(dir, 0)).xyz;

    vec3 color = castRay(orig, normalize(dir), 5);
    vec3 avg = texture(tex, uv).xyz;

    FragColor = vec4(rolling_avg(avg, color, sample_i), 1.0f);
}
