//
//  ViewController.m
//  GLSLVisualizer
//
//  Created by Terry Latanville on 2015-03-27.
//  Copyright (c) 2015 Rndm.Studio(). All rights reserved.
//

#import "ShaderCode.h"
#import "ShaderCodeViewController.h"

@interface ShaderCodeViewController ()

@end

@implementation ShaderCodeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    ShaderCode.sharedInstance.fragmentShaderCode = self.shaderCodeTextView.text;
}

@end