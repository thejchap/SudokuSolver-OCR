//
//  ViewController.m
//  Sudoku
//
//  Created by Justin Chapman on 1/24/16.
//  Copyright © 2016 Justin Chapman. All rights reserved.
//

#import "ViewController.h"
#import "ImageUtil.h"
#import "GrayscalePreviewViewController.h"
#import "ThresholdPreviewViewController.h"
#import "DetectorPreviewViewController.h"
#import <NSObject+Debounce/NSObject+Debounce.h>

@interface ViewController ()

@property UIImageView *cameraImageView;
@property UIScrollView *scrollView;
@property GrayscalePreviewViewController* grayscaleVc;
@property DetectorPreviewViewController* detectorVc;
@property ThresholdPreviewViewController* threshVc;
@property CvVideoCamera *camera;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initMainImageView];
    [self initCamera];
    [self initSlider];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.camera start];
}

- (void)initMainImageView {
    CGRect frame = self.view.frame;
    self.cameraImageView = [[UIImageView alloc] initWithFrame:frame];
    [self.view addSubview:self.cameraImageView];
}

- (void)initCamera {
    CvVideoCamera* camera = [[CvVideoCamera alloc] initWithParentView:self.cameraImageView];
    camera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    camera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset640x480;
    camera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    camera.defaultFPS = 30;
    camera.grayscaleMode = NO;
    camera.delegate = self;
    self.camera = camera;
}

- (void)processImage:(cv::Mat &)image {
    int maxArea = 0;
    cv::Mat original = image.clone();
    cv::Mat gray, thresh, blur;
    std::vector<cv::Rect> faces;
    cv::Scalar color = cv::Scalar(0, 255, 0);
    cvtColor(original, gray, cv::COLOR_BGR2GRAY);
    cv::GaussianBlur(gray, blur, cv::Size(7, 7), 0.0f);
    cv::adaptiveThreshold(blur, thresh, 255, 1, 1, 15, 2);
    std::vector<std::vector<cv::Point>> contours;
    std::vector<cv::Vec4i> hierarchy;
    cv::findContours(thresh, contours, hierarchy, cv::RETR_TREE, cv::CHAIN_APPROX_NONE);
    std::vector<cv::Point> biggest;
    
    for (int j = 0; j < contours.size(); j++) {
        double area = cv::contourArea(contours[j]);
        
        if (area <= 100) {
            continue;
        }
        
        double peri = cv::arcLength(contours[j], YES);
        std::vector<cv::Point> approx;
        cv::approxPolyDP(contours[j], approx, 0.01f * peri, YES);
        
        if (area > maxArea && approx.size() == 4 && cv::isContourConvex(approx)) {
            biggest = approx;
            maxArea = area;
        }
    }
    
    __weak typeof(self) _weakSelf = self;
    
    if (biggest.size() == 4) {
        cv::polylines(image, cv::Mat(biggest), true, color, 2);
        cv::Mat undist = cv::Mat(cv::Size(300, 300), CV_8UC1);
        cv::Point2f dst[4], src[4];
        
        dst[0] = cv::Point2f(0,0);
        dst[1] = cv::Point2f(299,0);
        dst[2] = cv::Point2f(299,299);
        dst[3] = cv::Point2f(0,299);
        
        for (int i = 0; i < 4; i++) {
            src[i] = cv::Point2f(biggest[i]);
        }
        
        cv::warpPerspective(original,
                            undist,
                            cv::getPerspectiveTransform(src, dst),
                            cv::Size(300, 300));
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            UIImage* img = [[ImageUtil sharedUtil] uiImageFromCVMat:undist];
            [_weakSelf.detectorVc frameReady:img];
        });
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [_weakSelf.grayscaleVc frameReady:[[ImageUtil sharedUtil] uiImageFromCVMat:gray]];
        [_weakSelf.threshVc frameReady:[[ImageUtil sharedUtil] uiImageFromCVMat:thresh]];
    });
}

double angle(cv::Point pt1, cv::Point pt2, cv::Point pt0) {
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

- (void)initSlider {
    [self initScrollView:3];
    
    self.grayscaleVc = [[GrayscalePreviewViewController alloc] init];
    self.detectorVc = [[DetectorPreviewViewController alloc] init];
    self.threshVc = [[ThresholdPreviewViewController alloc] init];
    
    [self addChildViewController:self.threshVc];
    [self.scrollView addSubview:self.threshVc.view];
    [self.threshVc didMoveToParentViewController:self];
    
    [self addChildViewController:self.detectorVc];
    [self.scrollView addSubview:self.detectorVc.view];
    [self.detectorVc didMoveToParentViewController:self];
    
    [self addChildViewController:self.grayscaleVc];
    [self.scrollView addSubview:self.grayscaleVc.view];
    [self.grayscaleVc didMoveToParentViewController:self];
    
    CGRect frame = self.grayscaleVc.view.frame;
    frame.size.height = self.scrollView.frame.size.height;
    frame.origin.y = 0;
    self.grayscaleVc.view.frame = frame;
    CGRect smallFrame = frame;
    smallFrame.origin.y = smallFrame.origin.y + (smallFrame.size.height * 0.1f);
    smallFrame.size.height = smallFrame.size.height * 0.8f;
    self.grayscaleVc.imageView.frame = smallFrame;
    frame.origin.x = frame.size.width;
    self.threshVc.view.frame = frame;
    self.threshVc.imageView.frame = smallFrame;
    frame.origin.x = frame.size.width * 2.0f;
    smallFrame.size.width = 300.0f;
    smallFrame.size.height = 300.0f;
    smallFrame.origin.x = self.view.frame.origin.x + (self.view.frame.size.width - smallFrame.size.width)/2;
    self.detectorVc.view.frame = frame;
    self.detectorVc.imageView.frame = smallFrame;
}

- (void)initScrollView:(int)numPages {
    CGRect frame = self.view.frame;
    frame.origin.y = frame.size.height / 2.0f;
    frame.size.height = frame.size.height / 2.0f;
    UIScrollView* sv = [[UIScrollView alloc] initWithFrame:frame];
    sv.pagingEnabled = YES;
    sv.bounces = NO;
    
    sv.backgroundColor = [UIColor colorWithRed:0.0f
                                         green:0.0f
                                          blue:0.0f
                                         alpha:0.7f];
    
    sv.showsHorizontalScrollIndicator = NO;
    sv.contentSize = CGSizeMake(frame.size.width * (double)numPages, frame.size.height);
    
    UIPanGestureRecognizer* dragRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                     action:@selector(handleDetailDrag:)];
    dragRecognizer.delegate = self;
    [sv addGestureRecognizer:dragRecognizer];
    
    self.scrollView = sv;
    [self.view addSubview:sv];
    [self.view bringSubviewToFront:sv];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// TODO
- (void)handleDetailDrag:(UIPanGestureRecognizer*)sender {
    return;
    //    CGPoint t = [sender translationInView:self.view];
    //    BOOL isX = (std::abs(t.x) > std::abs(t.y));
    
    //    if (isX) {
    //        return;
    //    }
    
    //    UIScrollView* sv = self.scrollView;
    //    CGPoint startPos = sv.center;
    //    CGPoint newPos = CGPointMake(startPos.x, startPos.y + t.y);
    //    [sender setTranslation:t inView:self.view];
    //    sv.center = newPos;
}

@end
