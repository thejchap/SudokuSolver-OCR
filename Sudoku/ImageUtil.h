//
//  ImageManipulator.h
//  Sudoku
//
//  Created by Justin Chapman on 1/24/16.
//  Copyright © 2016 Justin Chapman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include <OpenCV/opencv2/opencv.hpp>

@interface ImageUtil : NSObject

+ (id)sharedUtil;

- (cv::Mat)cvMatFromUIImage:(UIImage *)image;
- (cv::Mat)cvMatGrayFromUIImage:(UIImage *)image;
- (UIImage *)uiImageFromCVMat:(cv::Mat)cvMat;

@end
