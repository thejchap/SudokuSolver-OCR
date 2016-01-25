//
//  PreviewViewController.m
//  Sudoku
//
//  Created by Justin Chapman on 1/24/16.
//  Copyright © 2016 Justin Chapman. All rights reserved.
//

#import "PreviewViewController.h"

@implementation PreviewViewController

- (void)viewDidLoad {
    [self createImageView];
}

- (void)createImageView {
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.frame];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.clipsToBounds = YES;
    [self.view addSubview:self.imageView];
}

- (void)frameReady:(UIImage *)image {
    self.imageView.image = image;
}

@end
