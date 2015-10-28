//
//  WeiboViewControlle.h
//  wq
//
//  Created by weqia on 13-8-28.
//  Copyright (c) 2013年 Weqia. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BaseTableViewController.h"
#import "WeiboToolBar.h"
#import "ContactViewController.h"
#import "WeiboData.h"
#import "HBCoreLabel.h"
#import "CellUploadFailed.h"
#import "UploadFailedViewController.h"

#define WeiboUpdateNotification  @"WeiboUpdateNotification"
@interface WeiboViewControlle : BaseViewController<PageLoadFootViewDelegate, ContactViewDelegate, WeiboToolBarDelegate,UIActionSheetDelegate,HBCoreLabelDelegate,MFMessageComposeViewControllerDelegate,UITableViewDataSource,UITableViewDelegate>
{
    WeiboToolBar * _toolBar;
    
    NSMutableArray * _artArr;
    
    NSMutableDictionary * _artDic;
    
    void(^_block)(NSString*string);
    
    WeiboData * _deleteWeibo;
    
    NSIndexPath *_deletePath;
    
    BOOL  animationEnd;
}
@property(nonatomic,strong)NSArray*datas;
@property(nonatomic,strong)WeiboToolBar * toolBar;
@property(nonatomic,strong)WeiboData * weiboData;
@property(nonatomic,strong)WeiboReplyData * replyData;
@property(nonatomic,strong)WeiboData * deleteWeibo;
@property(nonatomic,strong) UIView * superView;
@property(nonatomic,weak) IBOutlet UITableView * tableView;

-(int)getUnreadCount;
-(int)getFailedCount;

@end
