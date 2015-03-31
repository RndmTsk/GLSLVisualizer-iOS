//
//  GLViewController.m
//  GLSLVisualizer
//
//  Created by Terry Latanville on 2015-03-27.
//  Copyright (c) 2015 Rndm.Studio(). All rights reserved.
//

#import <OpenGLES/ES2/glext.h>

#import "ShaderCode.h"
#import "GLViewController.h"

@interface GLViewController ()

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

- (void)setupGL;
- (void)tearDownGL;

@end

@implementation GLViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    [self setupGL];
}

- (void)dealloc
{
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    [ShaderCode.sharedInstance buildShader];
}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    [ShaderCode.sharedInstance removeShader];
}

#pragma mark - GLKView and GLKViewController Delegate methods
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    [ShaderCode.sharedInstance render:self.timeSinceLastUpdate];
}

#pragma mark - IBActions
- (IBAction)onTripleTapped:(UITapGestureRecognizer *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITouch Methods
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [ShaderCode.sharedInstance setLastTap:[touches.anyObject locationInView:self.view]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [ShaderCode.sharedInstance setLastTap:[touches.anyObject locationInView:self.view]];
}

@end