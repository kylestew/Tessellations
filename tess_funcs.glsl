
float luma(vec4 color) {
    return dot(color.rgb, vec3(0.299, 0.587, 0.114));
}

float map(float value, float inMin, float inMax, float outMin, float outMax) {
  return outMin + (outMax - outMin) * (value - inMin) / (inMax - inMin);
}

vec4 triangleCentroid(vec4 a, vec4 b, vec4 c) {
    return vec4(
        (a.x + b.x + c.x) / 3.0,
        (a.y + b.y + c.y) / 3.0,
        (a.z + b.z + c.z) / 3.0,
        a.w
    );
}

/* https://codegolf.stackexchange.com/questions/52338/calculate-the-orthocenter-of-a-triangle
    // https://byjus.com/orthocenter-formula */
vec2 invSlope(vec2 a, vec2 b, vec2 c) {
    // swap for some reason
    if (a.y == b.y) {
        vec2 t = a;
        a = b;
        b = t;
    }

    vec2 res;
    // inv slope
    float m = (a.x - b.x) / (b.y - a.y);
    res.x = m;
    res.y = c.y - m * c.x;
    return res;
}

vec4 triangleOrthocenter(vec4 a, vec4 b, vec4 c) {

    // doesn't work if triangle wound wrong!

    vec2 mq = invSlope(a.xy, b.xy, c.xy);
    vec2 kz = invSlope(c.xy, b.xy, a.xy);
    float m = mq.x;
    float q = mq.y;
    float k = kz.x;
    float z = kz.y;
    float x = (q - z) / (k - m);
    return vec4(x, k * x + z, (a.z + b.z + c.z) / 3, 1);
}

vec2 uvMidpoint(vec2 a, vec2 b, vec2 c) {
    return vec2(
        (a.x + b.x + c.x) / 3.0,
        (a.y + b.y + c.y) / 3.0
    );
}
