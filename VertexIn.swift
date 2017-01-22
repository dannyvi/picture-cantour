//
//  VertexIn.swift
//  PicAnalyze
//
//  Created by DannyV on 16/4/9.
//  Copyright © 2016年 YuDan. All rights reserved.
//

import Foundation

struct VertexIn {
    var x,y: Float32
    var r,g,b: Float32
    var j,c,h: Float32
    
    func floatBuffer() -> [Float32] {
        return [x,y,r,g,b,j,c,h]
    }
};
