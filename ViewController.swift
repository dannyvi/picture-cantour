//
//  ViewController.swift
//  PicAnalyze
//
//  Created by DannyV on 16/3/24.
//  Copyright © 2016年 YuDan. All rights reserved.
//

import UIKit
import Metal
import MetalKit


let kVelocityScale:CGFloat = 1.0;
let kDamping:CGFloat = 0.3;
//let image_name = "IMG_14831.jpg"
//let images = ["IMG_1483.jpg","IMG_14831.jpg","IMG_14832.jpg","image_1.jpg","image_2.jpg","image_3.jpg","image_4.jpg","image_5.jpg","image_6.jpg","image_7.jpg","image_8.jpg","image_9.jpg","image_10.jpg","image_11.jpg","image_12.jpg","image_13.jpg","image_14.jpg","image_15.jpg","image_16.jpg","land_1.jpg","render_1.jpg","render_2.jpg","render_3.jpg","render_4.jpg","render_6.jpg","render_7.jpg","render_8.jpg","render_9.jpg","render_10.jpg","render_11.jpg"]

//let images = ["IMG_14831.jpg","image_15.jpg"]

//let images = ["v1_0.jpg","v1_1.jpg","v1_2.jpg","v1_3.jpg","v1_4.jpg","v1_5.jpg","v1_6.jpg","v1_7.jpg","v1_8.jpg",
//"v1_9.jpg","v1_10.jpg","v1_11.jpg","v1_12.jpg","v1_13.jpg","v1_14.jpg","v1_15.jpg","v1_16.jpg",
//"v1_17.jpg","v1_18.jpg","v1_19.jpg","v1_20.jpg","v1_21.jpg","v1_22.jpg","v1_23.jpg","v1_24.jpg",
//"v1_25.jpg","v1_26.jpg","v1_27.jpg","v1_28.jpg","v1_29.jpg"]

//let images = ["compare_1.jpg","compare_2.jpg","compare_3.jpg","compare_4.jpg"]

let images = ["compare_1.jpg","compare_3.jpg"]  //,"compare_4.jpg"]

let SELECTOR_J = 0
let SELECTOR_C = 1
let SELECTOR_H = 2

class ViewController: UIViewController,MTKViewDelegate {
    
    @IBOutlet var HueButton: UIButton!
    @IBOutlet var JButton: UIButton!
    @IBOutlet var ChromeButton: UIButton!
    
    @IBOutlet var displayHue: UIButton!
    @IBOutlet var displayJ: UIButton!
    @IBOutlet var displayChrome: UIButton!
    
    @IBOutlet var OptimizeButton: UIButton!
    
    var metalView: MTKView!
    var commandQueue: MTLCommandQueue!
    var sourceTexture: MTLTexture!
    var originTexture: MTLTexture!
    var carrierComputePipelineState: MTLComputePipelineState!
    var genMapComputePipelineState: MTLComputePipelineState!
    var genIndexComputePipelineState: MTLComputePipelineState!
    var renderPipelineState: MTLRenderPipelineState!
    
    var depthState: MTLDepthStencilState!
    
    var posit: UnsafeMutablePointer<Void>!

    var index_count: Array<UInt32>!

    var vertexA: MTLBuffer!

    var vertexSize: MTLBuffer!

    
    var indexBuffer: MTLBuffer!
    var indexSize: MTLBuffer!
    
    var vxForRender: MTLBuffer!
    var ixForRender: MTLBuffer!
    
    var projBuffer: MTLBuffer!
    
    var jchBuffer:MTLBuffer!
    var optimizeBuffer: MTLBuffer!
    
    var i_size_width: Int!
    var i_size_height: Int!
    var bufferReady:Bool! = false
    var renderCount: Int! = 0
    
    var angle: CGPoint!
    var angularVelocity: CGPoint!
    var lastFrameTime: NSTimeInterval!
    
    var transformPoint: CGPoint!
    var transformVelocity: CGPoint!
    var panGestureRecognizer: UIGestureRecognizer!
    
    var scaleFactor: CGFloat!
    var scaleVelocity: CGFloat!
    var pinchGestureRecognizer: UIPinchGestureRecognizer!
    
    //var swipeGestureRecognizer: UISwipeGestureRecognizer!
    var current_image_count:Int! = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.initgestures()
        self.setupMetalView()
        //self.loadAssets()
        self.allocateTextureAndBuffers(self.current_image_count)
        
        //self.doTransformTo3D(self.metalView)
        //self.drawInMTKView(self.metalView)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("bomb")
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(0.2)
        self.metalView.frame.size = size //self.view.frame
        UIView.commitAnimations()
    }
    @IBAction func switchPicForward(sender: AnyObject) {
        if (self.current_image_count < images.count - 1 ) {
            self.current_image_count = self.current_image_count + 1
            self.allocateTextureAndBuffers(self.current_image_count)
        }
        
    }
    @IBAction func switchPicBackward(sender: AnyObject) {
        if (self.current_image_count) > 0 {
            self.current_image_count = self.current_image_count - 1
            self.allocateTextureAndBuffers(self.current_image_count)
            }
    }
    
    @IBAction func hueButtonPressed(sender: AnyObject) {
        self.HueButton.selected = !(self.HueButton.selected)
    }
    
    @IBAction func JButtonPressed(sender: AnyObject) {
        self.JButton.selected = !(self.JButton.selected)
    }
    
    @IBAction func ChromeButtonPressed(sender: AnyObject) {
        self.ChromeButton.selected = !(self.ChromeButton.selected)
    }
    
    @IBAction func displayHuePressed(sender: AnyObject) {
        self.displayHue.selected = !(self.displayHue.selected)
    }
    
    @IBAction func displayJPressed(sender: AnyObject) {
        self.displayJ.selected = !(self.displayJ.selected)
    }
    
    @IBAction func displayChromePressed(sender: AnyObject) {
        self.displayChrome.selected = !(self.displayChrome.selected)
    }
    
    @IBAction func optimizeButtonPressed(sender: AnyObject) {
        self.OptimizeButton.selected = !(self.OptimizeButton.selected)
        self.updateOptimizeBuffer()
        
    }

    func initgestures() {
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: Selector("panDidRecognize:"))
        self.view.addGestureRecognizer(self.panGestureRecognizer)
        self.angle = CGPoint(x:0,y:0)
        self.angularVelocity = CGPoint(x: 0, y: 0)
        self.transformPoint = CGPoint(x: 0, y: 0)
        self.transformVelocity = CGPoint(x: 0, y: 0)
        self.lastFrameTime = CFAbsoluteTimeGetCurrent()
        
        self.scaleFactor = 1.0
        self.scaleVelocity = 1.0
        self.pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: Selector("pinchDidRecognize:"))
        self.view.addGestureRecognizer(self.pinchGestureRecognizer)
        
        //self.swipeGestureRecognizer = UISwipeGestureRecognizer(target: self, action: Selector("swipeDidRecognize:"))
        //self.view.addGestureRecognizer(self.swipeGestureRecognizer)
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
    //    let scale = UIScreen.mainScreen().scale
    //    view.drawableSize = CGSizeMake(size.width * scale, size.height * scale )
    }
    
    func setupMetalView() {
        self.metalView = MTKView(frame: self.view.frame)
            //self.view.addSubview(self.metalView)
        self.view.insertSubview(self.metalView, atIndex: 0)
        self.metalView.device = MTLCreateSystemDefaultDevice()

        self.metalView.delegate = self
        self.metalView.depthStencilPixelFormat = .BGRA8Unorm
        self.metalView.framebufferOnly = false
        //self.metalView.contentScaleFactor = UIScreen.mainScreen().scale
        //self.metalView.layer.contentsScale = UIScreen.mainScreen().scale
        
        
        let defaultLibrary = self.metalView.device!.newDefaultLibrary()
        let carrierKernelProgram = defaultLibrary?.newFunctionWithName("display_on_screen")

        do {
            carrierComputePipelineState = try self.metalView.device!.newComputePipelineStateWithFunction(carrierKernelProgram!)
            
        } catch let err {
            carrierComputePipelineState = nil
            print("failed  to create pipeline state,\(err)")}
        
        let genMapKernelProgram = defaultLibrary?.newFunctionWithName("gen_points")
        do {
            genMapComputePipelineState =  try self.metalView.device!.newComputePipelineStateWithFunction(genMapKernelProgram!)
        } catch let err {
            genMapComputePipelineState = nil
            print("failed to create pipeline state,\(err)")
        }
        
        let genIndexKernelProgram = defaultLibrary?.newFunctionWithName("gen_index")
        do {
            genIndexComputePipelineState =  try self.metalView.device!.newComputePipelineStateWithFunction(genIndexKernelProgram!)
        } catch let err {
            genIndexComputePipelineState = nil
            print("failed to create pipeline state,\(err)")
        }
        
        let vertexProgram   = defaultLibrary?.newFunctionWithName("vertex_main")
        let fragmentProgram = defaultLibrary?.newFunctionWithName("fragment_main")
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = MTLPixelFormat.BGRA8Unorm
        renderPipelineDescriptor.vertexFunction   = vertexProgram
        renderPipelineDescriptor.fragmentFunction = fragmentProgram
        do {
            self.renderPipelineState = try self.metalView.device!.newRenderPipelineStateWithDescriptor(renderPipelineDescriptor)
        } catch let err {
            renderPipelineState = nil
            print("failed to create pipeline state,\(err)")
        }
        
        let depthStateDesc = MTLDepthStencilDescriptor()
        depthStateDesc.depthCompareFunction = MTLCompareFunction.Less
        depthStateDesc.depthWriteEnabled = true

        //do{
            self.depthState =  self.metalView.device!.newDepthStencilStateWithDescriptor(depthStateDesc)
        //} //catch let err {
          //  self.depthState = nil
          //  print("failed to create depthState,\(err)")
        //}
        
        self.commandQueue = self.metalView.device!.newCommandQueue()
    }
    
    /*func loadAssets() {
        let image_name = images[self.current_image_count]
        //let textureLoader = MTKTextureLoader(device: self.metalView.device!)
        let frwidth = Int(self.metalView.drawableSize.width)
        let frheight = Int(self.metalView.drawableSize.height)
        let image = UIImage(named: image_name)
        let imageRef = image?.CGImage
        
        
        let wid = CGImageGetWidth(imageRef)
        let hei = CGImageGetHeight(imageRef)
        let frame = getScaledFrameInRect(CGSize(width: wid, height: hei), contain: CGSize(width: self.metalView.drawableSize.width,height: self.metalView.drawableSize.height))
        let width = Int(frame.width)
        let height = Int(frame.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let rawData = calloc(width * height * 4, sizeof(UInt8))
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo = CGBitmapInfo(rawValue: CGBitmapInfo.ByteOrderDefault.rawValue | CGImageAlphaInfo.PremultipliedLast.rawValue).rawValue
        let context = CGBitmapContextCreate(rawData, width , height , bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo)
        //CGContextTranslateCTM(context, 0, 100) //CGFloat(height))
        //CGContextScaleCTM(context, 1, -1)
        
        //CGContextDrawImage(context, frame, imageRef)
        
        CGContextDrawImage(context, CGRectMake(0, 0, CGFloat(width), CGFloat(height)), imageRef)
        
        //CGContextDrawImage(context, getScaledFrameInRect(CGSize(width: width, height: height), contain: CGSize(width: self.metalView.drawableSize.width,height: self.metalView.drawableSize.height)), imageRef)

        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptorWithPixelFormat(MTLPixelFormat.RGBA8Unorm, width: frwidth , height: frheight, mipmapped: false)
        
        sourceTexture = self.metalView.device!.newTextureWithDescriptor(textureDescriptor)

        let region = MTLRegionMake2D(Int(frame.origin.x) , Int(frame.origin.y) , width, height)
        sourceTexture.replaceRegion(region, mipmapLevel: 0, withBytes: rawData, bytesPerRow: bytesPerRow)
        
    }*/
    
    func getScaledFrameInRect (insize: CGSize, contain: CGSize) -> CGRect {
        if insize.width / insize.height > contain.width / contain.height {
            let width = contain.width
            let height = contain.width * insize.height / insize.width
            let yPos = ( contain.height - height ) / 2
            return CGRectMake(0, yPos, width, height)
        } else {
            let height = contain.height
            let width = height * insize.width / insize.height
            let xPos = ( contain.width - width ) / 2
            return CGRectMake(xPos, 0, width, height)
        }
    }
    

    
    func drawPicInMTKView(view: MTKView) {
        let commandBuffer = self.commandQueue.commandBuffer()
        
        let computeEncoder = commandBuffer.computeCommandEncoder()
        
        computeEncoder.setComputePipelineState(self.carrierComputePipelineState)
        computeEncoder.setTexture(view.currentDrawable!.texture, atIndex: 0)
        computeEncoder.setTexture(self.sourceTexture, atIndex: 1)
        computeEncoder.setTexture(view.currentDrawable!.texture, atIndex: 2)
        
        let threadGroupCount = MTLSizeMake(16, 16, 1)
        
        let threadGroups: MTLSize = MTLSizeMake(Int(view.currentDrawable!.texture.width) / threadGroupCount.width , Int(view.currentDrawable!.texture.height) / threadGroupCount.height , 1)
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        
        computeEncoder.endEncoding()
        
        commandBuffer.presentDrawable(view.currentDrawable!)
        commandBuffer.commit()
    }
    
    func doTransformTo3D(view:MTKView) {
        self.getVertexBuffer()
        self.getIndexBuffer()
        
        //print("render finished")

        self.bufferReady = true

    }
    
    func allocateTextureAndBuffers(index:Int) {
        let image_name = images[index]
        let image = UIImage(named: image_name)
        let imageRef = image?.CGImage
        let textureLoader = MTKTextureLoader(device: self.metalView.device!)
        do {
            self.originTexture = try textureLoader.newTextureWithCGImage(imageRef!, options: nil)
        } catch {fatalError("can't load texture")}
        let count = Int(self.originTexture.width*self.originTexture.height) * sizeof(VertexIn)

        //let posit = calloc(count, 1)
        //var posit: Array<VertexIn> =
        if ((self.posit) != nil) {free(self.posit) }
        self.posit = calloc(count,1)
//        callo
        self.vertexA = self.metalView.device!.newBufferWithBytes(self.posit, length: count , options: MTLResourceOptions.StorageModeShared)

        var v_size = [UInt32](count: 2, repeatedValue: 0)
        v_size[0] = UInt32(self.originTexture.width)
        v_size[1] = UInt32(self.originTexture.height)
        self.vertexSize = self.metalView.device!.newBufferWithBytes(&v_size, length: 2 * sizeof(UInt32), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        let index_length = (Int(self.originTexture.width) - 1) * (Int(self.originTexture.height) - 1) * 6
        self.index_count = [UInt32](count: index_length , repeatedValue: 0)
        //self.index_count = calloc(index_length , sizeof(UInt32))
        //self.indexBuffer = self.metalView.device!.newBufferWithBytes(self.index_count, length: index_length * sizeof(UInt32) , options: MTLResourceOptions.CPUCacheModeDefaultCache)
        self.indexBuffer = self.metalView.device!.newBufferWithLength(index_length * sizeof(UInt32), options: MTLResourceOptions.StorageModeShared)
        
        var i_size = [UInt32](count: 2, repeatedValue: 0)
        i_size[0] = UInt32(self.originTexture.width - 1)
        i_size[1] = UInt32(self.originTexture.height - 1)
        self.i_size_width = Int(i_size[0])
        self.i_size_height = Int(i_size[1])
        self.indexSize = self.metalView.device!.newBufferWithBytes(&i_size, length: 2 * sizeof(UInt32), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        self.jchBuffer = self.metalView.device!.newBufferWithLength(sizeof(UInt32), options: MTLResourceOptions.CPUCacheModeDefaultCache)
        
        self.updateOptimizeBuffer()
         self.doTransformTo3D(self.metalView)
    }
    
    func getVertexBuffer() {
        let commandBuffer = self.commandQueue.commandBuffer()
        
        let computeEncoder = commandBuffer.computeCommandEncoder()
        
        computeEncoder.setComputePipelineState(self.genMapComputePipelineState)
        computeEncoder.setTexture(self.originTexture, atIndex: 0)

        computeEncoder.setBuffer(self.vertexA, offset: 0, atIndex: 0)
        //computeEncoder.setBuffer(self.vertexB, offset: 0, atIndex: 1)
        //computeEncoder.setBuffer(self.vertexC, offset: 0, atIndex: 2)
        computeEncoder.setBuffer(self.vertexSize, offset: 0, atIndex: 1)
        
        let threadGroupCount = MTLSizeMake(16, 16, 1)
        
        let TGWidth = Int(self.originTexture.width) % 16 == 0 ? Int(self.originTexture.width / 16) : Int(self.originTexture.width + 16) / 16
        let TGHeight = Int(self.originTexture.height) % 16 == 0 ? Int(self.originTexture.height) / 16 : Int(self.originTexture.height + 16) / 16
        
        
        let threadGroups: MTLSize = MTLSizeMake(TGWidth , TGHeight, 1)

        
        //let threadGroups: MTLSize = MTLSizeMake(Int(self.originTexture.width) / threadGroupCount.width + 1 , Int(self.originTexture.height) / threadGroupCount.height + 1 , 1)
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        
        computeEncoder.endEncoding()
        
        //commandBuffer.presentDrawable(view.currentDrawable!)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    func getIndexBuffer() {
        let commandBuffer = self.commandQueue.commandBuffer()
        
        let computeEncoder = commandBuffer.computeCommandEncoder()
        
        computeEncoder.setComputePipelineState(self.genIndexComputePipelineState)

        computeEncoder.setBuffer(self.indexBuffer, offset: 0, atIndex: 0)
        computeEncoder.setBuffer(self.indexSize, offset: 0, atIndex: 1)

        let threadGroupCount = MTLSizeMake(16, 16, 1)
        
        let TGWidth = self.i_size_width % 16 == 0 ? self.i_size_width / 16 : (self.i_size_width + 16) / 16
        let TGHeight = self.i_size_height % 16 == 0 ? self.i_size_height / 16 : (self.i_size_height + 16) / 16
        
        
        let threadGroups: MTLSize = MTLSizeMake(TGWidth , TGHeight, 1)
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupCount)
        
        computeEncoder.endEncoding()
            
        //commandBuffer.presentDrawable(view.currentDrawable!)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
    }
    
    func updateOptimizeBuffer() {
        var optimize:Bool = self.OptimizeButton.selected
        self.optimizeBuffer = self.metalView.device!.newBufferWithBytes(&optimize, length: sizeof(Bool), options: .CPUCacheModeDefaultCache)
    }
    
    func panDidRecognize(recognizer:UIPanGestureRecognizer) {
        if (recognizer.numberOfTouches() == 1) {

            let velocity = recognizer.velocityInView(self.view)
            self.angularVelocity = CGPointMake(velocity.x * kVelocityScale, velocity.y * kVelocityScale)
            //print(self.angle)
            //print(velocity,recognizer.translationInView(self.view))
            //print("rotating, \(self.angle), \(self.angularVelocity)")
        } else if (recognizer.numberOfTouches() == 2) {
            /*if (recognizer.state == UIGestureRecognizerState.Ended) {
            let translation = recognizer.translationInView(self.view)
            self.transformPoint = CGPointMake(self.transformPoint.x + translation.x, self.transformPoint.y + translation.y)
            self.transformVelocity = CGPointMake(0, 0)
            } else {
            self.transformVelocity = recognizer.translationInView(self.view)
            }*/
            let velocity = recognizer.velocityInView(self.view)
            self.transformVelocity = CGPointMake(velocity.x * kVelocityScale, velocity.y * kVelocityScale)
            
        }
    }
    
    func pinchDidRecognize(recognizer: UIPinchGestureRecognizer) {
        if (recognizer.state == UIGestureRecognizerState.Ended) {
            self.scaleFactor = self.scaleFactor * recognizer.scale
            self.scaleVelocity = 1.0
            return
        } else {
        self.scaleVelocity = recognizer.scale
        }
    }
    
    
    func updateMotion () {
        let frameTime = CFAbsoluteTimeGetCurrent()
        
        let frameDuration = frameTime - self.lastFrameTime
        self.lastFrameTime = frameTime
        if frameDuration > 0
        {
            self.angle = CGPointMake(self.angle.x + self.angularVelocity.x * CGFloat(frameDuration),
                self.angle.y + self.angularVelocity.y * CGFloat(frameDuration));
            self.angularVelocity = CGPointMake(self.angularVelocity.x * CGFloat(1 - kDamping),
                self.angularVelocity.y * CGFloat(1 - kDamping));
            
            let ang = CGFloat(DegToRad(Float(self.angle.x)))
            
            let x = self.transformVelocity.x * CGFloat(frameDuration) * cos(ang) + self.transformVelocity.y * CGFloat(frameDuration) * sin(ang)
            let y =  (-self.transformVelocity.x * CGFloat(frameDuration) * sin(ang) + self.transformVelocity.y * CGFloat(frameDuration) * cos(ang))
            
            self.transformPoint = CGPointMake(self.transformPoint.x + x, self.transformPoint.y + y)
            self.transformVelocity = CGPointMake(self.transformVelocity.x * CGFloat(1 - kDamping), self.transformVelocity.y * CGFloat(1 - kDamping))

        }

    }
    
    func updateUniforms() {
        let X_AXIS = float3(1,0,0)
        //let Y_AXIS = float3(0,1,0)
        let Z_AXIS = float3(0,0,1)
        var modelMatrix = Identity()
        
        let uniformTranslateMatrix = Translate(-Float(self.originTexture.width) / 2.0, y: -Float(self.originTexture.height) / 2.0, z: -50.0)
        modelMatrix = uniformTranslateMatrix * modelMatrix
        
        let uniformScaleMatrix = Scale(float3(Float(2.0 / Double(max(self.originTexture.width,self.originTexture.height)))))
        
        modelMatrix = uniformScaleMatrix * modelMatrix
        
        let uniformMoveMatrix = Translate((1.0 / Float(self.view.frame.width)) * Float(self.transformPoint.x) , y: (-1.0 / Float(self.view.frame.width)) * Float(self.transformPoint.y), z: 0.0)
        
        modelMatrix = uniformMoveMatrix * modelMatrix
        
        let scaleMatrix = Scale(float3(Float(self.scaleFactor * self.scaleVelocity)))
        modelMatrix = scaleMatrix * modelMatrix

        modelMatrix = RotationL(Z_AXIS,  angle: -Float(self.angle.x )) * modelMatrix
        modelMatrix = RotationL(X_AXIS,  angle: -Float(self.angle.y )) * modelMatrix
        
        
        let eye = float3(0,0,-50)
        let center = float3(0,0,0)
        let up = float3(0,10,0)

        
        let lookAtMatrix = LookAtL(eye, center: center, up: up)
        
        let near:Float = 0.0001
        let far:Float = 100
        let aspect = Float(self.view.bounds.size.width / self.view.bounds.size.height)
        
        //let projectionMatrix = PerspectiveFovL(aspect, fovy: 20, near: near, far: far)
        
        let projectionMatrix = Ortho2DL(left:-aspect, right: aspect, bottom: -1.0, top: 1.0,near:  near , far: far)

        let modelView:float4x4  = lookAtMatrix * modelMatrix //viewMatrix * modelMatrix;

        var modelViewProj:float4x4 =  projectionMatrix * modelView
        
        self.projBuffer = self.metalView.device!.newBufferWithBytes(&modelViewProj, length: sizeof(float4x4), options: .CPUCacheModeDefaultCache)
    }
    
    func renderOnScreen(view:MTKView) {
        let drawable = view.currentDrawable!
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 5.0/255.0, blue: 20.0/255.0, alpha: 1.0)
        renderPassDescriptor.colorAttachments[0].storeAction = .Store
        
        let commandBuffer = self.commandQueue.commandBuffer()
        
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        
        renderEncoder.pushDebugGroup("trying to render")

        renderEncoder.setTriangleFillMode(MTLTriangleFillMode.Fill )//Lines)
        renderEncoder.setFrontFacingWinding(MTLWinding.CounterClockwise)
        renderEncoder.setDepthStencilState(self.depthState)
        renderEncoder.setRenderPipelineState(self.renderPipelineState)
        renderEncoder.setVertexBuffer(self.vertexA, offset: 0, atIndex: 0)
        renderEncoder.setVertexBuffer(self.projBuffer, offset: 0, atIndex: 1)
        renderEncoder.setVertexBuffer(self.vertexSize, offset: 0, atIndex: 2)
        renderEncoder.setVertexBuffer(self.optimizeBuffer, offset: 0, atIndex: 5)
        
        
        if self.HueButton.selected {
            self.encodeEncoder(renderEncoder, jchCommand: 2)
        }
        
        if self.ChromeButton.selected {
            self.encodeEncoder(renderEncoder, jchCommand: 1)
        }
        
        if self.JButton.selected {
            self.encodeEncoder(renderEncoder, jchCommand: 0)
        }
        
        
        renderEncoder.endEncoding()
        
        renderEncoder.popDebugGroup()
        
        commandBuffer.presentDrawable(drawable)
        commandBuffer.commit()
       
    }
    
    func encodeEncoder(renderEncoder: MTLRenderCommandEncoder , jchCommand: Int) {
        var s:UInt32 = UInt32(jchCommand)
        let jchbuffer = self.metalView.device!.newBufferWithBytes(&s, length: sizeof(UInt32), options: .CPUCacheModeDefaultCache)
        renderEncoder.setVertexBuffer(jchbuffer, offset: 0, atIndex: 3)
        var jchdisplay: Array<Bool> = [self.displayJ.selected, self.displayChrome.selected, self.displayHue.selected]

        let displaybuffer = self.metalView.device!.newBufferWithBytes(&jchdisplay,length: 3 * sizeof(Bool), options: .CPUCacheModeDefaultCache)
        renderEncoder.setVertexBuffer(displaybuffer, offset: 0, atIndex: 4)
        
        renderEncoder.drawIndexedPrimitives(MTLPrimitiveType.Triangle,
            indexCount: Int(self.i_size_width) * Int(self.i_size_height) * 6, indexType: MTLIndexType.UInt32, indexBuffer: self.indexBuffer, indexBufferOffset: 0)
    }
    
    func drawInMTKView(view: MTKView) {

        if (self.bufferReady == true ){
            self.updateMotion()
            self.updateUniforms()
            self.renderOnScreen(view)
        }
    }
}



