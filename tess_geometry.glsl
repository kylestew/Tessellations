#include "tess_functions"

#define MAX_VERTICES 448

layout(triangles) in;
layout(triangle_strip, max_vertices=MAX_VERTICES) out;

uniform sampler2D texMap;

uniform vec4 instructions;
uniform bool alwaysDivide;
uniform float threshold;

in Vertex {
    vec3 worldSpacePos;
    vec2 texCoords;
} iVert[];

out Vertex {
    vec4 color;
} oVert;

struct TriangleDivision {
    int gen;
    vec4 a, b, c;
    vec2 aUV, bUV, cUV;
};

#define TESS_STACK_SIZE 64
TriangleDivision stack[TESS_STACK_SIZE];
int stackPointer = 0;
int maxDepth = 0;
int vertices = 0;

bool shouldDivide(int depth, float lumi) {
    if (depth > maxDepth)
        return false;
    if (vertices > MAX_VERTICES * 0.9)
        return false; // stop subdividing
    if (alwaysDivide)
        return true;

    // nomalize depth value
    float normDepth = map(depth, 0.0, maxDepth, 0.0, threshold * 3);

    /* if ((lumi * lumi * lumi * threshold) > normDepth) */
    if (lumi > normDepth)
        return true;
    return false;
}

/*
 * TESSELLATIONS
 * https://www.scratchapixel.com/lessons/3d-basic-rendering/ray-tracing-rendering-a-triangle/barycentric-coordinates
 */
void tessFromNodes(TriangleDivision tri) {
    vec4 center = triangleCentroid(tri.a, tri.b, tri.c);
    vec2 centerUV = uvMidpoint(tri.aUV, tri.bUV, tri.cUV);

    // ABP
    stack[++stackPointer].gen = tri.gen + 1;
    stack[stackPointer].a = tri.a;
    stack[stackPointer].b = tri.b;
    stack[stackPointer].c = center;
    stack[stackPointer].aUV = tri.aUV;
    stack[stackPointer].bUV = tri.bUV;
    stack[stackPointer].cUV = centerUV;

    // BCP
    stack[++stackPointer].gen = tri.gen + 1;
    stack[stackPointer].a = tri.b;
    stack[stackPointer].b = tri.c;
    stack[stackPointer].c = center;
    stack[stackPointer].aUV = tri.bUV;
    stack[stackPointer].bUV = tri.cUV;
    stack[stackPointer].cUV = centerUV;

    // CAP
    stack[++stackPointer].gen = tri.gen + 1;
    stack[stackPointer].a = tri.c;
    stack[stackPointer].b = tri.a;
    stack[stackPointer].c = center;
    stack[stackPointer].aUV = tri.cUV;
    stack[stackPointer].bUV = tri.aUV;
    stack[stackPointer].cUV = centerUV;
}

void tessFromEdges(TriangleDivision tri) {
    // find edge midpoints
    vec4 ab = tri.a + (tri.b - tri.a) * 0.5;
    vec4 bc = tri.b + (tri.c - tri.b) * 0.5;
    vec4 ca = tri.c + (tri.a - tri.c) * 0.5;

    // find new UVs
    vec2 abUV = tri.aUV + (tri.bUV - tri.aUV) * 0.5;
    vec2 bcUV = tri.bUV + (tri.cUV - tri.bUV) * 0.5;
    vec2 caUV = tri.cUV + (tri.aUV - tri.cUV) * 0.5;

    // left bottom
    stack[++stackPointer].gen = tri.gen + 1;
    stack[stackPointer].a = tri.a;
    stack[stackPointer].b = ab;
    stack[stackPointer].c = ca;
    stack[stackPointer].aUV = tri.aUV;
    stack[stackPointer].bUV = abUV;
    stack[stackPointer].cUV = caUV;

    // right bottom
    stack[++stackPointer].gen = tri.gen + 1;
    stack[stackPointer].a = ab;
    stack[stackPointer].b = tri.b;
    stack[stackPointer].c = bc;
    stack[stackPointer].aUV = abUV;
    stack[stackPointer].bUV = tri.bUV;
    stack[stackPointer].cUV = bcUV;

    // top center
    stack[++stackPointer].gen = tri.gen + 1;
    stack[stackPointer].a = ca;
    stack[stackPointer].b = bc;
    stack[stackPointer].c = tri.c;
    stack[stackPointer].aUV = caUV;
    stack[stackPointer].bUV = bcUV;
    stack[stackPointer].cUV = tri.cUV;

    // center
    stack[++stackPointer].gen = tri.gen + 1;
    stack[stackPointer].a = bc;
    stack[stackPointer].b = ca;
    stack[stackPointer].c = ab;
    stack[stackPointer].aUV = bcUV;
    stack[stackPointer].bUV = caUV;
    stack[stackPointer].cUV = abUV;
}

void tessFold(TriangleDivision tri, int type) {
    if (type == 0) {
        vec4 ab = tri.a + (tri.b - tri.a) * 0.5;

        // find new UVs
        vec2 abUV = tri.aUV + (tri.bUV - tri.aUV) * 0.5;

        // left
        stack[++stackPointer].gen = tri.gen + 1;
        stack[stackPointer].a = tri.a;
        stack[stackPointer].b = ab;
        stack[stackPointer].c = tri.c;
        stack[stackPointer].aUV = tri.aUV;
        stack[stackPointer].bUV = abUV;
        stack[stackPointer].cUV = tri.cUV;

        // right
        stack[++stackPointer].gen = tri.gen + 1;
        stack[stackPointer].a = tri.b;
        stack[stackPointer].b = ab;
        stack[stackPointer].c = tri.c;
        stack[stackPointer].aUV = tri.bUV;
        stack[stackPointer].bUV = abUV;
        stack[stackPointer].cUV = tri.cUV;
    } else if (type == 1) {
        vec4 bc = tri.b + (tri.c - tri.b) * 0.5;

        // find new UVs
        vec2 bcUV = tri.bUV + (tri.cUV - tri.bUV) * 0.5;

        // left
        stack[++stackPointer].gen = tri.gen + 1;
        stack[stackPointer].a = tri.b;
        stack[stackPointer].b = bc;
        stack[stackPointer].c = tri.a;
        stack[stackPointer].aUV = tri.bUV;
        stack[stackPointer].bUV = bcUV;
        stack[stackPointer].cUV = tri.aUV;

        // right
        stack[++stackPointer].gen = tri.gen + 1;
        stack[stackPointer].a = tri.c;
        stack[stackPointer].b = bc;
        stack[stackPointer].c = tri.a;
        stack[stackPointer].aUV = tri.cUV;
        stack[stackPointer].bUV = bcUV;
        stack[stackPointer].cUV = tri.aUV;
    } else if (type == 2) {
        vec4 ca = tri.c + (tri.a - tri.c) * 0.5;

        // find new UVs
        vec2 caUV = tri.cUV + (tri.aUV - tri.cUV) * 0.5;

        // left
        stack[++stackPointer].gen = tri.gen + 1;
        stack[stackPointer].a = tri.c;
        stack[stackPointer].b = ca;
        stack[stackPointer].c = tri.b;
        stack[stackPointer].aUV = tri.cUV;
        stack[stackPointer].bUV = caUV;
        stack[stackPointer].cUV = tri.bUV;

        // right
        stack[++stackPointer].gen = tri.gen + 1;
        stack[stackPointer].a = tri.a;
        stack[stackPointer].b = ca;
        stack[stackPointer].c = tri.b;
        stack[stackPointer].aUV = tri.aUV;
        stack[stackPointer].bUV = caUV;
        stack[stackPointer].cUV = tri.bUV;
    }
}

/*
 * MAIN
 */
void main() {
    stack[0].gen = 0;
    stack[0].a = gl_in[0].gl_Position;
    stack[0].b = gl_in[1].gl_Position;
    stack[0].c = gl_in[2].gl_Position;
    stack[0].aUV = iVert[0].texCoords;
    stack[0].bUV = iVert[1].texCoords;
    stack[0].cUV = iVert[2].texCoords;

    // determine max level for instruction set
    maxDepth = 0;
    if (instructions.x > 0) {
        maxDepth++;
    }
    if (instructions.y > 0) {
        maxDepth++;
    }
    if (instructions.z > 0) {
        maxDepth++;
    }
    if (instructions.w > 0) {
        maxDepth++;
    }

    int justInCase = 0; // don't put shaders in infinite loop, locks up Mac OS!!!
    while (stackPointer >= 0 && justInCase < 1024) {
        justInCase++;

        int sp = stackPointer;
        TriangleDivision tri = stack[sp]; // copies on assignment, not a reference
        int gen = tri.gen;
        if (gen == -1) {
            // this triangle was previously replaced down the stack
            stackPointer--;
            continue;
        }

        // sample texture at center of current texture sub-rect
        vec2 st;
        st.x = (tri.aUV.x + tri.bUV.x + tri.cUV.x) / 2.0;
        st.y = (tri.aUV.y + tri.bUV.y + tri.cUV.y) / 2.0;
        vec2 texCenter = vec2(st);
        vec4 col = texture(texMap, texCenter);
        float bri = luma(col);

        if (shouldDivide(gen, bri)) {

            // grab instruction
            int instruction = 0;
            if (gen == 0) {
                instruction = int(instructions.x);
            } else if (gen == 1) {
                instruction = int(instructions.y);
            } else if (gen == 2) {
                instruction = int(instructions.z);
            } else if (gen == 3) {
                instruction = int(instructions.w);
            } // else - out of range

            // run instruction
            // apply level
            if (instruction == 0) {

                // NO division

            } else if (instruction == 1) {

                tessFromNodes(tri);
                stack[sp].gen = -1; // we are replacing this bit of geometry
                continue;

            } else if (instruction == 2) {

                tessFromEdges(tri);
                stack[sp].gen = -1; // we are replacing this bit of geometry
                continue;

            } else if (instruction == 3) {

                tessFromNodes(tri);
                stack[sp].gen = -1; // we are replacing this bit of geometry

                // fold the 3 triangles we just put on the stack
                int nsp = stackPointer;
                tri = stack[nsp];
                tri.gen -= 1; // cause the folds to be at the same generation
                tessFold(tri, 0);
                stack[nsp].gen = -1;

                nsp--;
                tri = stack[nsp];
                tri.gen -= 1;
                tessFold(tri, 0);
                stack[nsp].gen = -1;

                nsp--;
                tri = stack[nsp];
                tri.gen -= 1;
                tessFold(tri, 0);
                stack[nsp].gen = -1;

                continue;

            } else if (instruction == 4) {

                tessFold(tri, 0);
                stack[sp].gen = -1; // we are replacing this bit of geometry
                continue;

            } else if (instruction == 5) {

                tessFold(tri, 1);
                stack[sp].gen = -1; // we are replacing this bit of geometry
                continue;

            } else if (instruction == 6) {

                tessFold(tri, 2);
                stack[sp].gen = -1; // we are replacing this bit of geometry
                continue;

            }
        }


        /* col = vec4(bri*bri*threshold, 0, 0, 1); */


        // draw this vertex
        oVert.color = col;
        gl_Position = TDWorldToProj(tri.a, 0);
        EmitVertex();

        oVert.color = col;
        gl_Position = TDWorldToProj(tri.b, 0);
        EmitVertex();

        oVert.color = col;
        gl_Position = TDWorldToProj(tri.c, 0);
        EmitVertex();

        vertices += 3;

        stack[sp].gen = -1; // mark as processed
        stackPointer--;

        EndPrimitive();
    }
}
