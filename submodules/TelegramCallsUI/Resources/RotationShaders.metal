//
//  RotationShaders.metal
//  TelegramCalls
//

#include <metal_stdlib>

using namespace metal;

struct VertexRotation {
    vector_float3 position;
    vector_float4 color;
};

struct SceneMatrices {
  float4x4 projectionMatrix;
  float4x4 viewModelMatrix;
};

struct RasterizedData {
    float4 position [[position]];
    float4 color;
};

vertex RasterizedData rotation_vertex(const device VertexRotation* vertex_array [[ buffer(0) ]],
                                      const device SceneMatrices& scene_matrices [[ buffer(1) ]],
                                      unsigned int vid [[ vertex_id ]]) {

    float4x4 viewModelMatrix = scene_matrices.viewModelMatrix;
    float4x4 projectionMatrix = scene_matrices.projectionMatrix;

    RasterizedData output;
    VertexRotation vertexData = vertex_array[vid];
    output.position = projectionMatrix * viewModelMatrix * float4(vertexData.position, 1.0);
//    output.position = float4(vertexData.position, 1.0);
    output.color = pow(vertexData.color, 1.6);
    return output;
}

fragment float4 rotation_fragment(RasterizedData input [[stage_in]]) {
    return pow(input.color, 0.666666666667);
}
