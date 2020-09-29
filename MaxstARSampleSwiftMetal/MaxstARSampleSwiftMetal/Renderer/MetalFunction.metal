//
//  MetalFunction.metal
//  MetalTest
//
//  Created by Kimseunglee on 2017. 9. 21..
//  Copyright © 2017년 Maxst. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    packed_float3 position;
    packed_float4 color;
    packed_float2 texCoord;
};

typedef struct {
    float3x3 matrix;
    float3 offset;
} ColorConversion;


struct VertexOut {
    float4 position [[position]];
    float4 color;
    float2 texCoord;
};

struct Uniforms {
    float4x4 modelViewProjectionMatrix;
};

vertex VertexOut texture_vertex_func(constant VertexIn *vertices [[buffer(0)]], constant Uniforms &uniforms [[buffer(1)]], uint vid [[vertex_id]]) {
    float4x4 matrix = uniforms.modelViewProjectionMatrix;
    VertexIn in = vertices[vid];
    VertexOut out;
    out.position = matrix * float4(in.position, 1);
    out.texCoord = in.texCoord;
    return out;
}

fragment float4 texture_fragment_func(VertexOut vert [[stage_in]], texture2d<float> tex2D [[ texture(0) ]], sampler sampler2D [[ sampler(0) ]]) {
    float4 color = tex2D.sample(sampler2D, vert.texCoord);
    return color;
}

vertex VertexOut chromakey_vertex_func(constant VertexIn *vertices [[buffer(0)]], constant Uniforms &uniforms [[buffer(1)]], uint vid [[vertex_id]]) {
    float4x4 matrix = uniforms.modelViewProjectionMatrix;
    VertexIn in = vertices[vid];
    VertexOut out;
    out.position = matrix * float4(in.position, 1);
    out.texCoord = in.texCoord;
    return out;
}

fragment float4 chromakey_fragment_func(VertexOut vert [[stage_in]], texture2d<float> tex2D [[ texture(0) ]], sampler sampler2D [[ sampler(0) ]]) {
    float4 color = tex2D.sample(sampler2D, vert.texCoord);
    if((color.g > color.r * 1.1) && (color.g > color.b * 1.1) && (color.g > 0.2)) {
        color.a = 0.0;
    }
    return color;
}

vertex VertexOut camerabackground_vertex_func(constant VertexIn *vertices [[buffer(0)]], constant Uniforms &uniforms [[buffer(1)]], uint vid [[vertex_id]]) {
    float4x4 matrix = uniforms.modelViewProjectionMatrix;
    VertexIn in = vertices[vid];
    VertexOut out;
    out.position = matrix * float4(in.position, 1);
    out.texCoord = in.texCoord;
    return out;
}

fragment half4 camerabackground_fragment_func(VertexOut in [[stage_in]],
                                           texture2d<float, access::sample> textureY [[ texture(0) ]],
                                           texture2d<float, access::sample> textureCbCr [[ texture(1) ]],
                                           constant ColorConversion &colorConversion [[ buffer(0) ]]) {
    
    constexpr sampler s(address::clamp_to_edge, filter::linear);
    float3 ycbcr = float3(textureY.sample(s, in.texCoord).r, textureCbCr.sample(s, in.texCoord).rg);
    
    float3 rgb = colorConversion.matrix * (ycbcr + colorConversion.offset);
    
    return half4(half3(rgb), 1.0);
}

vertex VertexOut color_vertex_func(constant VertexIn *vertices [[buffer(0)]], constant Uniforms &uniforms [[buffer(1)]], uint vid [[vertex_id]]) {
    float4x4 matrix = uniforms.modelViewProjectionMatrix;
    VertexIn in = vertices[vid];
    VertexOut out;
    out.position = matrix * float4(in.position, 1);
    out.color = in.color;
    return out;
}

fragment float4 color_fragment_func(VertexOut vert [[stage_in]]) {
    float4 color = vert.color;
    return color;
}

struct FeatureVertexIn {
    packed_float3 position;
    packed_float2 texCoord;
};

struct FeatureVertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex FeatureVertexOut vertex_feature_point_func(constant FeatureVertexIn *vertices [[buffer(0)]], constant Uniforms &uniforms [[buffer(1)]], uint vid [[vertex_id]]) {
    float4x4 matrix = uniforms.modelViewProjectionMatrix;
    FeatureVertexIn in = vertices[vid];
    FeatureVertexOut out;
    out.position = matrix * float4(in.position, 1);
    out.texCoord = in.texCoord;
    return out;
}

fragment float4 fragment_feature_point_func(FeatureVertexOut vert [[stage_in]], texture2d<float> tex2D [[ texture(0) ]], sampler sampler2D [[ sampler(0) ]]) {
    float4 color = tex2D.sample(sampler2D, vert.texCoord);
    return color;
}

vertex VertexOut bounding_box_vertex_func(constant packed_float3* positions [[buffer(0)]], constant packed_float4* colors [[buffer(1)]], constant Uniforms &uniforms [[buffer(2)]], uint vid [[vertex_id]]) {
    float4x4 matrix = uniforms.modelViewProjectionMatrix;
    float4 position = float4(positions[vid],1);
    float4 color = colors[vid];
    VertexOut out;
    out.position = matrix * position;
    out.color = color;
    return out;
}

fragment float4 bounding_box_fragment_func(VertexOut vert [[stage_in]]) {
    float4 color = vert.color;
    return color;
}

vertex VertexOut color_raw_vertex_func(constant packed_float3* positions [[buffer(0)]], constant packed_float4* colors [[buffer(1)]], constant Uniforms &uniforms [[buffer(2)]], uint vid [[vertex_id]]) {
    float4x4 matrix = uniforms.modelViewProjectionMatrix;
    float4 position = float4(positions[vid],1);
    float4 color = colors[vid];
    VertexOut out;
    out.position = matrix * position;
    out.color = color;
    return out;
}

fragment float4 color_raw_fragment_func(VertexOut vert [[stage_in]]) {
    float4 color = vert.color;
    return color;
}

vertex VertexOut new_textured_vertex_func(constant packed_float3* positions [[buffer(0)]], constant packed_float2* texture_coord [[buffer(1)]], constant Uniforms &uniforms [[buffer(2)]], uint vid [[vertex_id]]) {
    float4x4 matrix = uniforms.modelViewProjectionMatrix;
    float4 position = float4(positions[vid],1);
    float2 texture = texture_coord[vid];
    VertexOut out;
    out.position = matrix * position;
    out.texCoord = texture;
    return out;
}

fragment float4 new_textured_fragment_func(VertexOut vert [[stage_in]], texture2d<float> tex2D [[ texture(0) ]], sampler sampler2D [[ sampler(0) ]]) {
    float4 color = tex2D.sample(sampler2D, vert.texCoord);
    return color;
}



