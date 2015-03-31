//
//  ShaderCode.h
//  GLSLVisualizer
//
//  Created by Terry Latanville on 2015-03-27.
//  Copyright (c) 2015 Rndm.Studio(). All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ShaderCode : NSObject

@property (nonatomic, strong) NSString *fragmentShaderCode;
@property (nonatomic, strong) NSString *vertexShaderCode;

+ (ShaderCode *)sharedInstance;

- (BOOL)buildShader;
- (void)removeShader;
- (void)render:(CGFloat)elapsedTime;
- (void)setLastTap:(CGPoint)lastTap;

@end