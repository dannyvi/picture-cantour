//
//  filter.metal
//  PicAnalyze
//
//  Created by DannyV on 16/3/24.
//  Copyright © 2016年 YuDan. All rights reserved.
//

#include <metal_stdlib>
#import "colortransfer.metal"
using namespace metal;

//extern float3 xyz2rgb(float3 xyz);
struct Vertex_in {
    packed_float2 position;
    packed_float3 colorrgb;
    packed_float3 colorjch;
};

struct Vertex_out{
    float4 pos[[position]];
    float3 colorrgb;
    float3 colorjch;
};
//packed_float2
struct IMIndex {
    packed_uint3 index1;
    packed_uint3 index2;
};

//float3 optimizejch(float3 jch);
float3 optimizejch(device Vertex_in* posr, constant uint* size, uint v_id);


kernel void display_on_screen (
                    texture2d<float , access::read>  targ [[texture(0)]],
                    texture2d<float , access::read>  source [[ texture(1) ]],
                    texture2d<float , access::write> dest   [[ texture(2) ]],
                    uint2 gid [[ thread_position_in_grid]])
{
    float4 targ_color = 0;//targ.read(gid);
    float4 source_color = source.read(gid);

    float4 result_color = targ_color + source_color;
    dest.write(result_color,gid);
}

kernel void gen_points(
                       texture2d<float , access::read> texmap [[texture(0)]],
                       device Vertex_in* posr     [[buffer(0)]],
                       //device float3* posg     [[buffer(1)]],
                       //device float3* posb     [[buffer(2)]],
                       device uint *picsize  [[buffer(1)]],
                      
                       uint2    gid [[thread_position_in_grid]])
{
    if (gid.x >= picsize[0] || gid.y >= picsize[1] ) return;
    uint v_id = picsize[0] * gid.y + gid.x;
    //uint size = max(picsize[0],picsize[1]) - 1;
    //float biasx = float(picsize[0] - 1) / float(size * 2);
    //float biasy = float(picsize[1] - 1) / float(size * 2);
    float x = float(gid.x); // float(size) - biasx ;
    float y = float(gid.y); // float(size) - biasy ;
    float4 z4 = float4(texmap.read(gid));
    float3 rgb = float3(z4.rgb);
    float3 jch = rgb2jch(rgb);//test(rgb);//rgb2jch(rgb);
    //float3 jch = jch2rgb(jch2);
    //jch =
    device float* p = (device float*)((device char*)posr + v_id * sizeof(Vertex_in));
    p[0] = x * 1;
    p[1] = y * 1;
    p[2] = z4.r;
    p[3] = z4.g;
    p[4] = z4.b;
    p[5] = jch.r;
    p[6] = jch.g;
    p[7] = jch.b;
}

kernel void gen_index (
                       device IMIndex *ind [[buffer(0)]],
                       device uint *size [[buffer(1)]],
                       uint2  gid [[thread_position_in_grid]])
                       //uint v_id [[vertex_id]])
{
    if (gid.x >= size[0] || gid.y >= size[1] ) return ;

    uint v_id = size[0]  * gid.y + gid.x;
    uint width = size[0] + 1;
    uint pos = gid.y * width + gid.x ;
    
    device uint* p = (device uint*)((device char*)ind + v_id*sizeof(IMIndex) );
    p[0] = pos;
    p[1] = pos + width + 1; //width;
    p[2] = pos + width ; //1;
    p[3] = pos; // + width + 1;
    p[4] = pos +  1 ;
    p[5] = pos + width + 1; //+ 1;
}

vertex Vertex_out vertex_main(
                        device Vertex_in* posr [[buffer(0)]],
                        constant float4x4 &projectMatrix [[buffer(1)]],
                        constant uint* size [[buffer(2)]],
                        constant  uint &jchlayer [[buffer(3)]],
                        constant bool* jchdisplay [[buffer(4)]],
                        constant bool &optimization[[buffer(5)]],
                        uint v_id [[vertex_id]])
{
    Vertex_in point = posr[v_id];
    Vertex_out  v ;
    float height;
    float heightcoef = float(max(size[0],size[1])) / 1000.0 ;
    float3 tempjch;
    if (optimization) {
        tempjch = optimizejch(posr,size,v_id);
    } else {
        tempjch = point.colorjch;
    }
    if (jchlayer == 0) {
        height = -tempjch[0] * heightcoef ;
    } else if (jchlayer == 1) {
        height = -tempjch[1] / 1.5 * heightcoef ; //- 250;
    } else if (jchlayer == 2) {
        height = -(fmod((tempjch[2] + 80.0) , 360.0) / 3.6) *heightcoef ; //+ 250;
    } else {
        height = -tempjch[0] * heightcoef;
    }
    v.pos = projectMatrix * float4(point.position[0],point.position[1],height  , 1.0) ;
    v.colorrgb = point.colorrgb;
    //v.colorjch = jch2rgb(float3(point.colorjch[0],point.colorjch[0]*1.5,point.colorjch[0]*6.0));//float4(point.colorjch,1.0);
    //v.colorjch = jch2rgb(float3(point.colorjch[0],0.0,0.0));//point.colorjch[1],point.colorjch[2]));
    float j = 50.0;
    float c = 0.0;
    float h = 0.0;
    if (jchdisplay[0]) {
        j = tempjch[0];
    }
    if (jchdisplay[1]) {
        //c = pow(point.colorjch[1] / 150.0, 1.5) / 0.8 * 150.0;
        c = tempjch[1];
    }
    if (jchdisplay[2]) {
        h = tempjch[2];
    }
    
    if (jchdisplay[1] && !jchdisplay[0] && !jchdisplay[2]) {
        j = tempjch[1] / 1.5;
        c = 0.0;
        h = 0.0;
    }
    
    if (jchdisplay[2] && !jchdisplay[0] && !jchdisplay[1]) {
        j = tempjch[2] / 3.6;
        c = 0.0;
        h = 0.0;
    }
    
    v.colorjch = jch2rgb(float3(j,c,h));
    return v;
}

fragment float4 fragment_main(Vertex_out in [[stage_in]] ) {

    
    return float4(in.colorjch,1.0);
}

float3 optimizejch(device Vertex_in* posr, constant uint* size, uint v_id) {
    Vertex_in point = posr[v_id];
    return point.colorjch * 2;
}
















