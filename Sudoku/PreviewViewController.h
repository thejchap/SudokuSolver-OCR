//
//  PreviewViewController.h
//  Sudoku
//
//  Created by Justin Chapman on 1/24/16.
//  Copyright © 2016 Justin Chapman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreviewViewController : UIViewController

@property UIImageView* imageView;
- (void)frameReady:(UIImage*)image;

@end
