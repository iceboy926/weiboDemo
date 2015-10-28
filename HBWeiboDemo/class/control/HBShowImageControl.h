//
//  HBShowImageControl.h
//  MyTest
//
//  Created by weqia on 13-8-8.
//  Copyright (c) 2013年 weqia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SDWebImageManager.h"
#import "NSImageUtil.h"
#import "HBImageViewList.h"
#import "HBImageListViewController.h"
#import "DownLoadCenter.h"
#define MAX_WIDTH  200.0
#define MAX_HEIGHT 120.0
#define IMAGE_SIZE 70
#define IMAGE_SPACE 5

@class HBShowImageControl;

@protocol HBShowImageControlDelegate <NSObject>
@optional
-(void)showImageControlFinishLoad:(HBShowImageControl*)control;

-(void)lookImageAction:(HBShowImageControl*)control;

-(void)lookFileAction:(HBShowImageControl*)control files:(NSArray*)files;

@end

@interface HBShowImageControl : UIView
{
    NSMutableArray * _imageViews;
    NSMutableArray * _images;
    NSMutableArray * _bigUrls;

    NSArray * _files;
    NSArray * _imgurls;
    
    
    NSImageUtil *_util;
    HBImageViewList *_imageList;
    HBImageListViewController * _imageListController;
}
@property(nonatomic,strong) id<HBShowImageControlDelegate> delegate;
@property(nonatomic,assign) UIViewController * controller;
@property BOOL bFirstSmall;
@property(nonatomic) int smallTag;
@property(nonatomic) int bigTag;


+(float)heightForFiles:(NSArray*)files;
-(void)setImagesFileStr:(NSString*)fileStr;
-(void)setImagesWithFiles:(NSArray*)files;
+(float)heightForFileStr:(NSString*)fileStr;


@end
