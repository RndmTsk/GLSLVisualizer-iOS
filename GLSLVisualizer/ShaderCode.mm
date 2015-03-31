//
//  ShaderCode.m
//  GLSLVisualizer
//
//  Created by Terry Latanville on 2015-03-27.
//  Copyright (c) 2015 Rndm.Studio(). All rights reserved.
//

#import <OpenGLES/ES2/gl.h>

#import "ShaderCode.h"

#define NUM_VERTS    4
#define NUM_INDICIES 6

typedef struct
{
    float x;
    float y;
    float z;
} Vec3;

typedef struct
{
    Vec3 position;
} Vertex;

@interface ShaderCode ()
{
    GLuint _program;
    GLuint _vertexBuffer;
    GLuint _indexBuffer;

    GLint _aPosition;
    GLint _uResolution;
    GLint _uTapLocation;
    GLint _uTime;

    GLfloat _screenWidth;
    GLfloat _screenHeight;

    GLubyte _indicies[NUM_INDICIES];
    Vertex _renderables[NUM_VERTS];

    CGPoint _lastTap;
}

@end

@implementation ShaderCode

#pragma mark - Lifecycle Methods
+ (instancetype)sharedInstance
{
    static ShaderCode *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _fragmentShaderCode = @"void main() { vec4(0.0, 0.0, 1.0, 1.0); }";
        _vertexShaderCode = @"attribute vec3 aPosition; void main() { gl_Position = vec4(aPosition, 1.0); }";

        _renderables[0] = {{ -1.0f, -1.0f, 0.0f }};
        _renderables[1] = {{ -1.0f,  1.0f, 0.0f }};
        _renderables[2] = {{  1.0f,  1.0f, 0.0f }};
        _renderables[3] = {{  1.0f, -1.0f, 0.0f }};

        _indicies[0] = 1;
        _indicies[1] = 0;
        _indicies[2] = 2;
        _indicies[3] = 0;
        _indicies[4] = 3;
        _indicies[5] = 2;

        _screenWidth = UIScreen.mainScreen.bounds.size.width;
        _screenHeight = UIScreen.mainScreen.bounds.size.height;
    }
    return self;
}

#pragma mark - Shader Methods
- (BOOL)buildShader
{
    GLuint vertShader, fragShader;
    
    // Create shader program.
    _program = glCreateProgram();

    // Create and compile fragment shader.
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER source:self.fragmentShaderCode]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }

    // Create and compile vertex shader.
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER source:self.vertexShaderCode]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }

    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }

    // Set up Attributes
    _aPosition = glGetAttribLocation(_program, "aPosition");

    // Set up Uniforms
    _uResolution = glGetAttribLocation(_program, "u_resolution");
    _uTime = glGetAttribLocation(_program, "u_time");
    _uTapLocation = glGetAttribLocation(_program, "u_mouse");

    // Start using the shader
    glUseProgram(_program);

    // Create vertex and index buffers
    glGenBuffers(1, &_vertexBuffer);
    glGenBuffers(1, &_indexBuffer);

    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type source:(NSString *)shaderSource
{
    GLint status;
    const GLchar *source;

    source = (GLchar *)[shaderSource UTF8String];
    if (!source) {
        NSLog(@"Failed to load shader");
        return NO;
    }

    NSLog(@"Building Shader [%d]:\n%@", type, shaderSource);

    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    return YES;
}

- (void)removeShader
{
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}

- (void)render:(CGFloat)elapsedTime
{
    if(_uTapLocation > -1)
    {
        glUniform2f(_uTapLocation, _lastTap.x, _lastTap.y);
    }
    if(_uResolution > -1)
    {
        glUniform2f(_uResolution, _screenWidth, _screenHeight);
    }
    if(_uTime > -1)
    {
        glUniform1f(_uTime, elapsedTime);
    }

    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, NUM_VERTS * sizeof(Vertex), _renderables, GL_DYNAMIC_DRAW);
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, NUM_INDICIES * sizeof(GLubyte), _indicies, GL_DYNAMIC_DRAW);

    glEnableVertexAttribArray(_aPosition);
    glVertexAttribPointer(_aPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), 0);

    glDrawElements(GL_TRIANGLES, NUM_INDICIES, GL_UNSIGNED_BYTE, 0);

    glDisableVertexAttribArray(_aPosition);
}

- (void)setLastTap:(CGPoint)lastTap
{
    _lastTap = lastTap;
}

@end