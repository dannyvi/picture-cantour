//
//  colortransfer.metal
//  PicAnalyze
//
//  Created by DannyV on 16/4/7.
//  Copyright © 2016年 YuDan. All rights reserved.
//

#include <metal_stdlib>
//#include <metal_matrix>
//#include <metal_math>
//#include <metal_geometric>
using namespace metal;

static float trans_XYZ(float c);
static float3 trans2_XYZ_Base_(float3 rgbf);
static float3 rgb2xyz(float3 color);

static float3 xyz2jch(float3 XYZ);
static float3 rgb2jch(float3 rgb);
static float  xyz2rgb_getv(float v);
static float3 xyz2rgb(float3 xyz);
static float3 jch2xyz(float3 jch);
static float3 jch2rgb(float3 jch);

//static float3 test(float3 xyz);


#define M_PI  3.14159265358979323846264338327950288
#define M_E   2.718281828459045
#define JCH_LightInd    80.0
#define JCH_BackGround  16.0

//constant float JCH_LightInd = 80.0;
//constant float JCH_BackGround = 16.0;

//constant float3 JCH_WhitePoint = float3(95.05,100.00,108.88);
//constant float3 JCH_Env = float3(1.0,0.69,1.0);


//constant float JCH_Xw = JCH_WhitePoint.x;
//constant float JCH_Yw = JCH_WhitePoint.y;
//constant float JCH_Zw = JCH_WhitePoint.z;

/*#define JCH_Xw      95.05
#define JCH_Yw      100.00
#define JCH_Zw      108.88

#define JCH_Nc      1.0
#define JCH_c       0.69
#define JCH_F       1.0

#define JCH_LA      JCH_LightInd
#define JCH_Yb      JCH_BackGround

#define JCH_Rw      94.930527999999995
#define JCH_Gw      103.53698800000001
#define JCH_Bw      108.717742
#define JCH_D       0.9262460556133671


#define JCH_Rwc     99.626106444042406
#define JCH_Gwc     100.26086681624821
#define JCH_Bwc     100.64296785864502*/

#define JCH_Nc      1.0
#define JCH_c       0.69

#define JCH_Dr      1.0494633132562206
#define JCH_Dg      0.96835796320681267
#define JCH_Db      0.92572717209896638
#define JCH_FL      0.7368063027650308
#define JCH_Nbb     1.0459574317827298
#define JCH_Ncb     1.0459574317827298
#define JCH_Aw      40.060885458419079

#define JCH_z       1.88
#define JCH_n       0.16

//constant float JCH_D = JCH_F * (1 - (1 / 3.6) * (pow(M_E,(-JCH_LA-42.0) / 92.0)));
//constant float JCH_Dr = JCH_Xw * JCH_D / JCH_Rw + 1 - JCH_D;
//constant float JCH_Dg = JCH_Yw * JCH_D / JCH_Gw + 1 - JCH_D;
//constant float JCH_Db = JCH_Zw * JCH_D / JCH_Bw + 1 - JCH_D;


//constant float JCH_Rwc = JCH_Dr * JCH_Rw;
//constant float JCH_Gwc = JCH_Dg * JCH_Gw;
//constant float JCH_Bwc = JCH_Db * JCH_Bw;

//constant float JCH_k = 1.0 / (5.0 * JCH_LA + 1);
//constant float JCH_FL = 0.2 * (pow(JCH_k,4)) * (5 * JCH_LA) + 0.1 * (pow((1 - (pow(JCH_k,4))),2)) * (pow(5 * JCH_LA,(1 / 3.0)));
//constant float JCH_n  = JCH_Yb / JCH_Yw;
//constant float JCH_Ncb = 0.725 * (pow(1.0 / JCH_n , 0.2));
//constant float JCH_Nbb = 0.725 * (pow(1.0 / JCH_n , 0.2));
//constant float JCH_z    = 1.48 + (pow(JCH_n ,0.5));

//constant float3 JCH_Rw_Gw_Bw_ =  MH * (M1Cat02() * float3(JCH_Rwc,JCH_Gwc,JCH_Bwc));
//constant float JCH_Rwa_  = (400.0 * (pow((JCH_FL * JCH_Rw_Gw_Bw_.r / 100.0),0.42))) / (27.13 +(pow((JCH_FL * JCH_Rw_Gw_Bw_.r / 100.0),0.42))) + 0.1;
//constant float JCH_Gwa_  = (400.0 * (pow((JCH_FL * JCH_Rw_Gw_Bw_.g / 100.0),0.42))) / (27.13 +(pow((JCH_FL * JCH_Rw_Gw_Bw_.g / 100.0),0.42))) + 0.1;
//constant float JCH_Bwa_  = (400.0 * (pow((JCH_FL * JCH_Rw_Gw_Bw_.b / 100.0),0.42))) / (27.13 +(pow((JCH_FL * JCH_Rw_Gw_Bw_.b / 100.0),0.42))) + 0.1;
//constant float JCH_Aw  = JCH_Nbb * ( 2.0 * JCH_Rwa_ + JCH_Gwa_ + (JCH_Bwa_ / 20.0) - 0.305);

//constant float JCH_Nc = JCH_Env.x;
//constant float JCH_c  = JCH_Env.y;
//constant float JCH_F  = JCH_Env.z;
//constant float JCH_LA = JCH_LightInd;
//constant float JCH_Yb = JCH_BackGround;
//constant float3 JCH_RwGwBw = MCat02() * JCH_WhitePoint;
//constant float JCH_Rw = JCH_RwGwBw.r;
//constant float JCH_Gw = JCH_RwGwBw.g;
//constant float JCH_Bw = JCH_RwGwBw.b;




static float3x3 MCat02 () {return float3x3(float3(0.7328,0.4296,-0.1624),
                                           float3(-0.7036,1.6975,0.0061),
                                           float3(0.0030,0.0136,0.9834));}

/*constant float3x3 MCat02 = {
    {0.7328,0.4296,-0.1624},
    {-0.7036,1.6975,0.0061},
    {0.0030,0.0136,0.9834}};*/

static float3x3 M1Cat02 () {return float3x3(float3(1.096241, -0.278869, 0.182745),
                                           float3(0.454369,  0.473533, 0.072098),
                                           float3(-0.009628,-0.005698, 1.015326)); }

/*constant float3x3 M1Cat02 = {
    {1.096241, -0.278869, 0.182745},
    {0.454369,  0.473533, 0.072098},
    {-0.009628,-0.005698, 1.015326}};*/

static float3x3 MH ()     {return float3x3(float3(0.38971,    0.68898, -0.07868),
                                           float3(-0.22981,   1.18340, 0.04641),
                                           float3(0.000000,   0.00000, 1.00000));}

//constant float3x3 MH      = {
//    {0.38971,    0.68898, -0.07868},
//    {-0.22981,   1.18340, 0.04641},
//    {0.000000,   0.00000, 1.00000}};

static float3x3 M_1hpe () {return  float3x3(float3(1.910197, -1.112124, 0.201908),
                                              float3(0.370950, 0.629054 , -0.000008),
                                              float3(0.000000, 0.000000 , 1.000000));}

/*constant float3x3 M_1hpe  = {
    {1.910197, -1.112124, 0.201908},
    {0.370950, 0.629054 , -0.00000},
    {0.000000, 0.000000 , 1.000000}};*/





constant float3 JCH_C_Data_1 = float3(20.14, 0.8, 0);
constant float3 JCH_C_Data_2 = float3(90.0,  0.7, 100);
constant float3 JCH_C_Data_3 = float3(164.25,  1.0, 200);
constant float3 JCH_C_Data_4 = float3(237.53,  1.2, 300);
constant float3 JCH_C_Data_5 = float3(380.14,  0.8, 400);


static float3x3 M_1 ()
{return float3x3(float3(3.2406, -1.5372, -0.4986),
                 float3(-0.9689, 1.8758,  0.0415),
                 float3(0.0557, -0.2040,  1.0570));}

float trans_XYZ(float c)
{
    float result;
    if (c > 0.04045) { result = pow((c+0.055)/1.055 , 2.4); }
    else { result = c / 12.92; }
    return result;
}

float3 trans2_XYZ_Base_(float3 rgbf)
{
    float3 interv;
    interv.x = trans_XYZ(rgbf.r);
    interv.y = trans_XYZ(rgbf.g);
    interv.z = trans_XYZ(rgbf.b);
    return interv;
}


static float3x3 MatXYZ ()
{return float3x3(float3(0.4124,0.3576,0.1805),
                 float3(0.2126,0.7152,0.0722),
                 float3(0.0193,0.1192,0.9505));};

float3 rgb2xyz(float3 color)
{

    float3 interv = trans2_XYZ_Base_(color);
    float3x3 s = MatXYZ();
    float3 xyz =  ( interv  * s) * 100.0;
    return xyz;
}

/*
float3 test(float3 color)
{
    float3 jch = rgb2jch(color);
    
       float3 xyz = jch2xyz(jch);
    float3 xyz_ = xyz / 100.0;
    float3 rgb = xyz_ * M_1() ;
    //rgb = clamp(rgb,float3(0.0,0.0,0.0),float3(1.0,1.0,1.0));
    float r = xyz2rgb_getv(rgb.r);
    float g = xyz2rgb_getv(rgb.g);
    float b = xyz2rgb_getv(rgb.b);
    //r = clamp(r,0.0,1.0);
    //g = clamp(g,0.0,1.0);
    //b = clamp(b,0.0,1.0);
    return float3(r,g,b);
    //return jch2rgb(jch);
}*/

float3 xyz2jch(float3 XYZ)
{
    float3 RGB = XYZ * MCat02();
    float3 RcGcBc = RGB * float3(JCH_Dr,JCH_Dg,JCH_Db);
    float3 R_G_B_ = (RcGcBc * M1Cat02()) * MH();
    float3 R_G_B_in = pow(JCH_FL * R_G_B_ / 100.0 , 0.42);
    float3 Ra_Ga_Ba_ = (400.0 * R_G_B_in) / (27.13 + R_G_B_in) + 0.1;
    float a = Ra_Ga_Ba_.r - 12 * Ra_Ga_Ba_.g / 11.0 + Ra_Ga_Ba_.b /11.0;
    float b = (1 / 9.0) * (Ra_Ga_Ba_.r + Ra_Ga_Ba_.g - 2.0 * Ra_Ga_Ba_.b);
    float h = atan2(b,a);
    if (h < 0) {
        h = (h + M_PI *2) * 180 / M_PI;
    } else { h = h * 180 / M_PI;}
    if (h < 20.14) {h = h + 360;}
    float etempp = (cos(h * M_PI / 180.0 + 2) + 3.8) * 0.25;
    float3 C_Data_0;
    float3 C_Data_1;
    if (h < 90.0) {
        C_Data_0 = JCH_C_Data_1;
        C_Data_1 = JCH_C_Data_2;
    } else if (h >= 90.0 && h < 164.25) {
        C_Data_0 = JCH_C_Data_2;
        C_Data_1 = JCH_C_Data_3;
    } else if (h >= 164.25 && h < 237.53) {
        C_Data_0 = JCH_C_Data_3;
        C_Data_1 = JCH_C_Data_4;
    } else  {
        C_Data_0 = JCH_C_Data_4;
        C_Data_1 = JCH_C_Data_5;
    }
    float H =C_Data_0.z + (100.0 * (h - C_Data_0.x) / C_Data_0.y ) / (((h - C_Data_0.x) / C_Data_0.y) + (C_Data_1.x - h) / C_Data_1.y);
    float A = JCH_Nbb * (2 * Ra_Ga_Ba_.x + Ra_Ga_Ba_.y + (Ra_Ga_Ba_.z / 20.0) - 0.305);
    float J = 100.0 * (pow(A / JCH_Aw , JCH_c * JCH_z));
    //float Q = (4.0 / JCH_c) * (pow(J / 100.0 , 0.5)) * (JCH_Aw + 4) * (pow(JCH_FL , 0.25));
    float t = ((50000 / 13.0) * JCH_Nc * JCH_Ncb * etempp * (pow(a*a+b*b , 0.5))) / (Ra_Ga_Ba_.x + Ra_Ga_Ba_.y + 21.0 / 20.0 * Ra_Ga_Ba_.z);
    float C = (pow(t,0.9)) * (pow(J / 100.0, 0.5)) * (pow(1.64 - (pow(0.29 , JCH_n)) , 0.73));
    return float3(J,C,H * 0.9);
}


float3 rgb2jch(float3 rgb)
{
    float3 jch = xyz2jch(rgb2xyz(rgb));
    return jch;
}

float xyz2rgb_getv(float v)
{
    float result;
    if (v > 0.0031308) {
        result = 1.055 * pow(v,0.4166666) - 0.055;
    } else {result = 12.92 * v;}
    return result;
}


float3 xyz2rgb(float3 xyz)
{
    float3 xyz_ = xyz / 100.0;
    float3 rgb = xyz_ * M_1() ;
    rgb = clamp(rgb,float3(0.0,0.0,0.0),float3(1.0,1.0,1.0));
    float r = xyz2rgb_getv(rgb.r);
    float g = xyz2rgb_getv(rgb.g);
    float b = xyz2rgb_getv(rgb.b);
    r = clamp(r,0.0,1.0);
    g = clamp(g,0.0,1.0);
    b = clamp(b,0.0,1.0);
    return float3(r,g,b);
}


float3 jch2xyz(float3 jch)
{
    jch = jch * float3(1.0,1.0,1.0/0.9);
    float H = jch.b;
    float3 C_Data_0;
    float3 C_Data_1;
    if (H < 100.0) {
        C_Data_0 = JCH_C_Data_1;
        C_Data_1 = JCH_C_Data_2;
    } else if (H >= 100.0 && H < 200.0) {
        C_Data_0 = JCH_C_Data_2;
        C_Data_1 = JCH_C_Data_3;
    } else if (H >= 200.0 && H < 300.0) {
        C_Data_0 = JCH_C_Data_3;
        C_Data_1 = JCH_C_Data_4;
    } else  {
        C_Data_0 = JCH_C_Data_4;
        C_Data_1 = JCH_C_Data_5;
    }
    float h = ((H - C_Data_0.z) * (C_Data_1.y * C_Data_0.x - C_Data_0.y*C_Data_1.x) - 100.0 * C_Data_0.x * C_Data_1.y) /((H - C_Data_0.z) * (C_Data_1.y - C_Data_0.y) - 100.0 * C_Data_1.y );
    
    if (h >= 360.0) {
        h -= 360;
    }
    
    float J = jch.r;
    if (J<=0) {J = 0.000001;}
    float C = jch.g;
    float t = pow(C /((pow((J/100.0),0.5))*(pow(1.64 - pow(0.29,JCH_n) , 0.73))) , (1.0/0.9));
    if (t <= 0) {t = 0.000001;}
    float etemp = (cos(h * M_PI / 180 +2) + 3.8) * 0.25;
    float e = (50000.0/13.0) * JCH_Nc * JCH_Ncb * etemp;
    float A = JCH_Aw * (pow((J / 100.0), 1.0 / (JCH_c * JCH_z)));
    float p2 = A/JCH_Nbb + 0.305;
    float p3 = 21.0 / 20.0;
    //float hue = h * M_PI / 180.0;
    float p1 = e / t;
    
    h = h * M_PI /180.0;
    
    float a,b,p;
    if (abs(sin(h)) >= abs(cos(h))) {
        p = p1 / sin(h);
        b = (p2 * (2.0 + p3) * (460.0/1403.0)) / (p + (2 + p3) * (220.0/1403.0) * (cos(h) / sin(h)) - 27.0 / 1403.0 + p3 * (6300.0/1403.0) );
        a = b * (cos(h) / sin(h));
        
        //b = (p2 * (2.0 + p3) * (460.0/1403.0)) / (p + (2 + p3) * (220.0/1403.0) - (27.0/1403.0 - p3 * (6300.0 / 1403.0))* (sin(h) / cos(h)));
        
    } else {
        p = p1 / cos(h);
        a = (p2 * (2.0 + p3) * (460.0/1403.0)) / (p + (2 + p3) * (220.0/1403.0) - (27.0/1403.0 - p3 * (6300.0 / 1403.0))* (sin(h) / cos(h)));
        b = a * (sin(h) / cos(h));
    }
    float Ra_ = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0;
    float Ga_ = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0;
    float Ba_ = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0;
    float R_  = sign(Ra_ - 0.1) * (100.0 / JCH_FL) * (pow(((27.13 * abs(Ra_ - 0.1)) / (400.0 - abs(Ra_ - 0.1))), 1.0/0.42));
    float G_  = sign(Ga_ - 0.1) * (100.0 / JCH_FL) * (pow(((27.13 * abs(Ga_ - 0.1)) / (400.0 - abs(Ga_ - 0.1))), 1.0/0.42));
    float B_  = sign(Ba_ - 0.1) * (100.0 / JCH_FL) * (pow(((27.13 * abs(Ba_ - 0.1)) / (400.0 - abs(Ba_ - 0.1))), 1.0/0.42));
    float3 RcGcBc = float3(R_,G_,B_) * M_1hpe() * MCat02()  ;
    float3 RGB = RcGcBc / float3(JCH_Dr,JCH_Dg,JCH_Db);
    float3 XYZ =  RGB * M1Cat02();
    return XYZ;//float3(R_,G_,B_);//XYZ;
    
}

float3 jch2rgb(float3 jch)
{
    float3 xyz = jch2xyz(jch);
    return xyz2rgb(xyz);
}

































