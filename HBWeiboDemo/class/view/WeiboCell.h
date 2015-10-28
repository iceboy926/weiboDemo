//
//  WeiboCell.h
//  wq
//
//  Created by weqia on 13-8-28.
//  Copyright (c) 2013年 Weqia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HBCoreLabel.h"
#import "HBShowImageControl.h"
#import "WeiboData.h"
#import "WeiboToolBar.h"
#import "WeiboViewControlle.h"
#import <QuickLook/QuickLook.h>
#define REPLY_BACK_COLOR 0xd5d5d5


@interface ReplyCell : UITableViewCell
@property(nonatomic,weak) IBOutlet HBCoreLabel * label;

@end

@class WeiboViewControlle;
@interface WeiboCell : UITableViewCell<HBShowImageControlDelegate,UIActionSheetDelegate,UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate>
{
    WeiboData * _weibo;
    
    WeiboReplyData * _reply;

//    HBCellOperation * _operation;
    
    NSArray * _replys;
    
    NSIndexPath * _indexPath;
    
    BOOL linesLimit;
    
    int replyCount;
}
@property(nonatomic,weak) IBOutlet UILabel *  title;
@property(nonatomic,weak) IBOutlet HBCoreLabel * content;
@property(nonatomic,weak) IBOutlet UIView * imageContent;
@property(nonatomic,weak) IBOutlet UILabel * time;
//@property(nonatomic,weak) IBOutlet UILabel * replyCount;
@property(nonatomic,weak) IBOutlet UIImageView * mLogo;
@property(nonatomic,weak) IBOutlet UIView * replyContent;
@property(nonatomic,weak) IBOutlet UIButton * btnReply;
@property(nonatomic,weak) IBOutlet UIImageView * back;
@property(nonatomic,weak) IBOutlet UITableView * tableReply;
@property(nonatomic,weak) IBOutlet UIView * lockView;
@property(nonatomic,weak) IBOutlet UIButton *btnDelete;
@property(nonatomic,weak) IBOutlet UIButton * btnShare;
@property(nonatomic,strong) WeiboViewControlle * controller;
@property(nonatomic,strong) WeiboToolBar * toolBar;
-(void)setCellContent:(WeiboData *)data;

+(float)getHeightByContent:(WeiboData*)data;

+(float) heightForReply:(NSArray*)replys;

-(void)loadReply;

@end

