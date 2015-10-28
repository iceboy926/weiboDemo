//
//  WeiboViewControlle.m
//  wq
//
//  Created by weqia on 13-8-28.
//  Copyright (c) 2013年 Weqia. All rights reserved.
//

#import "WeiboViewControlle.h"
#import "PageHeadView.h"
#import "CoInfoData.h"
#import "WeiboCell.h"
#import "LoginUserData.h"
#import "ObjUrlData.h"
#import "PartInData.h"
#import "NewMessage.h"
#import "MessageCenterViewController.h"
#import "CellUnreadMsg.h"
#import "BrowseViewController.h"
#import "MsgUploadData.h"
#import "MsgUploadCenter.h"
#import "FileUploadCenter.h"
@interface WeiboViewControlle ()
{
    PageLoadFootView *_footView;
    PageHeadView *_headView;
    BOOL _first;
    int _lastId;
    
    int unReadCount;
    int failedCount;
    
    NSString * phoneNumber;
    UIWebView * webView;
}

@end

@implementation WeiboViewControlle
@synthesize weiboData,replyData,superView,deleteWeibo=_deleteWeibo;


-(int)getUnreadCount
{
    return unReadCount;
}
-(int)getFailedCount
{
    return failedCount;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_footView animmation];
    [_headView animmation];
}
-(void)viewWillDisappear:(BOOL)animated
{
}
-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_backBtn removeFromSuperview];
    if(_rightBtn){
        [_rightBtn removeFromSuperview];
    }
}
- (void)viewDidLoad
{
    self.bReceiveNotify=YES;
    [super viewDidLoad];
    [self setBackButton];
    
    animationEnd=YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(cellUpdate) name:HBWeiboContentUpdateNofication object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firstGetData) name:WeiboUpdateNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(uploadStatusChanged:) name:MsgUploadStatusStatusChangeNofiticion object:nil];
    
    UIImage * image=[UIImage imageNamed:@"title_publish.png"];
    CGSize size=image.size;
    image=[UIImage imageWithCGImage:image.CGImage scale:(size.height/30) orientation:UIImageOrientationUp];
    
    UIImage * selImage=[UIImage imageNamed:@"title_publish_sel.png"];
    size=selImage.size;
    selImage=[UIImage imageWithCGImage:selImage.CGImage scale:(size.height/30) orientation:UIImageOrientationUp];
    
    [self setRightBtn:nil withImg:image withSelImg:selImage withSel:@selector(publicWeiboAction)];
    
    _headView=[[PageHeadView alloc]initWithFrame:CGRectMake(0, -60, 320, 60)];
    [self.tableView addSubview:_headView];
    [_headView setTarget:self];
    [_headView loadFinish];
    [_headView addBeginLoadAction:@selector(pageHeadBeginLoad:)];
    
    _footView=[[PageLoadFootView alloc]initWithFrame:CGRectMake(0, 0, 320, 40)];
    self.tableView.tableFooterView=_footView;
    [_footView loadFinish];
    _footView.delegate=self;
    
    _toolBar=[WeiboToolBar newToolBar];
    _toolBar.delegate=self;
   
    [self loadFromDb:YES];
    [self.tableView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    _first=NO;
}
// 从本地加载数据  update : 加载结束之后是否需要从后台更新数据， 第一次进入时需要更新。
-(void)loadFromDb:(BOOL)update
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        failedCount=[[WeqiaAppDelegate App].dbUtil rowCount:[MsgUploadData class] where:[NSString stringWithFormat:@"mid='%@' and coId='%@' and msgType=0 and uploadStatus=3",[WeqiaAppDelegate App].mid,[WeqiaAppDelegate App].coId]];
        unReadCount=[NewMessage getWeiboUnread];
        NSArray *ary = nil;
        if ([WeqiaAppDelegate App].loginUser.joinStatus == 1) {
            int count=6;
            if(!update&&_datas){
                count=[_datas count];
                if (count>40) {
                    count=40;
                }
            }
            ary=[[ WeqiaAppDelegate  App].dbUtil search:[WeiboData class] where:[NSString stringWithFormat:@"coId='%@' and owner='%@' ",[WeqiaAppDelegate App].coId,[WeqiaAppDelegate App].mid]
                                                orderBy:@"msgId desc" offset:0 count:count];
            [self loadWeboData:ary complete:^{
                if(update){
                    int count=6;
                    [self firstGetData:count];
                }
            } formDb:YES];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                _datas=nil;
                [self.tableView reloadData];
            });
        }
    });
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    //#warning Potentially incomplete method implementation.
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    //#warning Incomplete method implementation.
    // Return the number of rows in the section.
    int count=[_datas count];
    if(unReadCount>0){
        count++;
    }
    if(failedCount>0){
        count++;
    }
    return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WeiboData * weibo=nil;
    if(unReadCount>0){
        if(indexPath.row==0){
           CellUnreadMsg*cell = [[[NSBundle mainBundle] loadNibNamed:@"CellUnreadMsg" owner:self options:nil] lastObject];
           [cell.button addTarget:self action:@selector(msgCenterAction) forControlEvents:UIControlEventTouchUpInside];
            cell.msgCount.text=[NSString stringWithFormat:@"%d条新消息",unReadCount];
            NewMessage * msg=[[WeqiaAppDelegate App].dbUtil searchSingle:[NewMessage class] where:[NSString stringWithFormat:@"type=0 or type=1 and readed=0 and mid='%@' and coId='%@'",[WeqiaAppDelegate App].mid,[WeqiaAppDelegate App].coId] orderBy:@"gmtCreate desc"];
            ContactData * contact=[[WeqiaAppDelegate App].dbUtil searchSingle:[ContactData class] where:[NSString stringWithFormat:@"mid='%@'",msg.up_mid] orderBy:nil];
            if(contact&&[NSStrUtil notEmptyOrNull:contact.mLogo]){
                [cell.mLogo setImageWithURL:[NSURL URLWithString:contact.mLogo] placeholderImage:[UIImage imageNamed:@"people"]];
            }else{
                cell.mLogo.image=[UIImage imageNamed:@"people"];
            }
            cell.mLogo.layer.cornerRadius=3;
            cell.mLogo.clipsToBounds=YES;
            UIImage * image=[UIImage imageNamed:@"AlbumTimeLineTipBkg@2x"];
            [cell.button setBackgroundImage:image forState:UIControlStateNormal];
            [cell.button setBackgroundImage:[UIImage imageNamed:@"AlbumTimeLineTipBkgHL"] forState:UIControlStateHighlighted];
            UIImageView * line=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"dv_line.png"]];
            line.frame=CGRectMake(0, 59, 320, 1);
            [cell.contentView  addSubview:line];
            return cell;
        }
    }if(failedCount>0)
    {
        if(unReadCount>0){
            if(indexPath.row==1){
                CellUploadFailed*cell = [[[NSBundle mainBundle] loadNibNamed:@"CellUploadFailed" owner:self options:nil] lastObject];
                [cell.button addTarget:self action:@selector(uploadFailedCenterAction) forControlEvents:UIControlEventTouchUpInside];
                cell.message.text=[NSString stringWithFormat:@"%d条发送失败",failedCount];
                [cell.button setBackgroundImage:[UIImage imageNamed:@"AlbumTimeLineTipBkg@2x"] forState:UIControlStateNormal];
                [cell.button setBackgroundImage:[UIImage imageNamed:@"AlbumTimeLineTipBkgHL"] forState:UIControlStateHighlighted];
                UIImageView * line=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"dv_line.png"]];
                line.frame=CGRectMake(0, 59, 320, 1);
                [cell.contentView  addSubview:line];
                return cell;
            }
        }else{
            if(indexPath.row==0){
                CellUploadFailed*cell = [[[NSBundle mainBundle] loadNibNamed:@"CellUploadFailed" owner:self options:nil] lastObject];
                [cell.button addTarget:self action:@selector(uploadFailedCenterAction) forControlEvents:UIControlEventTouchUpInside];
                cell.message.text=[NSString stringWithFormat:@"%d条发送失败",failedCount];
                [cell.button setBackgroundImage:[UIImage imageNamed:@"AlbumTimeLineTipBkg@2x"] forState:UIControlStateNormal];
                [cell.button setBackgroundImage:[UIImage imageNamed:@"AlbumTimeLineTipBkgHL"] forState:UIControlStateHighlighted];
                UIImageView * line=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"dv_line.png"]];
                line.frame=CGRectMake(0, 59, 320, 1);
                [cell.contentView  addSubview:line];
                return cell;
            }
        }
    }
    if(unReadCount>0&&failedCount>0){
        if(indexPath.row>=2){
            weibo=[_datas objectAtIndex:indexPath.row-2];
        }
    }else if(unReadCount>0||failedCount>0){
        if(indexPath.row>=1){
            weibo=[_datas objectAtIndex:indexPath.row-1];
        }
    }else{
        weibo=[_datas objectAtIndex:indexPath.row];
    }
    
    WeiboCell *cell = nil;
    static NSString *CellIdentifier = @"WeiboCell";
    if (IOS_VERSION >= 6.0) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    } else {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    }
    // Configure the cell...
    cell.controller=self;
    [cell setCellContent:weibo];
    float height=[self tableView:tableView heightForRowAtIndexPath:indexPath];
    UIView * view=[cell.contentView viewWithTag:1200];
    if(view==nil){
        UIImageView * line=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"dv_line.png"]];
        
        line.frame=CGRectMake(0, height-1, 320, 1);
        [cell.contentView  addSubview:line];
        line.tag=1200;
    }else{
        view.frame=CGRectMake(0, height-1, 320, 1);
    }
    return cell;
}
#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WeiboData * data;
    if(unReadCount>0&&failedCount>0){
        if(indexPath.row>=2){
            data=[_datas objectAtIndex:indexPath.row-2];
        }
        if(indexPath.row==1||indexPath.row==0)
            return 61;
    }else if(unReadCount>0||failedCount>0){
        if(indexPath.row==0)
            return 61;
        else if(indexPath.row>=1){
            data=[_datas objectAtIndex:indexPath.row-1];
        }
    }else{
        data=[_datas objectAtIndex:indexPath.row];
    }
    return [WeiboCell getHeightByContent:data];
}
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    WeiboData * data=nil;
    if(unReadCount>0&&failedCount>0){
        if(indexPath.row>=2){
            data=[_datas objectAtIndex:indexPath.row-2];
        }
    }else if(unReadCount>0||failedCount>0){
        if(indexPath.row>=1){
            data=[_datas objectAtIndex:indexPath.row-1];
        }
    }else{
        data=[_datas objectAtIndex:indexPath.row];
    }
    if (data) {
        data.willDisplay=YES;
    }
}

-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    WeiboData * data=nil;
    if(unReadCount>0&&failedCount>0){
        if(indexPath.row>=2&&indexPath.row-2<[_datas count]){
            data=[_datas objectAtIndex:indexPath.row-2];
        }
    }else if(unReadCount>0||failedCount>0){
        if(indexPath.row>=1&&indexPath.row-1<[_datas count]){
            data=[_datas objectAtIndex:indexPath.row-1];
        }
    }else{
        if (indexPath.row<[_datas count]) {
            data=[_datas objectAtIndex:indexPath.row];
        }
    }
    if (data) {
        data.willDisplay=NO;
    }
}

#pragma -mark 回调方法

-(void)coreLabel:(HBCoreLabel*)coreLabel linkClick:(NSString*)linkStr
{
    UIStoryboard * story=[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    BrowseViewController * controller=[story instantiateViewControllerWithIdentifier:@"BrowseViewController"];
    controller.url=linkStr;
    [self.navigationController pushViewController:controller animated:YES];
}
-(void)coreLabel:(HBCoreLabel *)coreLabel phoneClick:(NSString *)linkStr
{
    UIActionSheet * action=[[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"打电话",nil, nil];
    action.tag=102;
    phoneNumber=linkStr;
    [action showInView:self.view.window];
}
-(void)coreLabel:(HBCoreLabel *)coreLabel mobieClick:(NSString *)linkStr
{
    UIActionSheet * action=[[UIActionSheet alloc]initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"打电话",@"发短信",nil, nil];
    action.tag=103;
    phoneNumber=linkStr;
    [action showInView:self.view.window];
}


-(void)contactViewControllerBackAction:(ContactViewController*)contactViewController
{

}
- (void)contactViewController:(ContactViewController *)contactViewController getDataMutilSelect:(NSArray *)datas {
    if(datas != nil) {
        for (ContactData *tmpContact in datas) {
            [self addArtContent:tmpContact];
        }
    }
}

-(void)weiboToolBar:(WeiboToolBar*)toolBar atButtonClickBlock:(void(^)(NSString*string))block
{
    _block=block;
    [self performSegueWithIdentifier:@"SelectContact" sender:nil];
}

-(void)weiboToolBarSendButtonClick:(WeiboToolBar *)toolBar
{
    NSMutableString * contentStr=[NSMutableString stringWithString:self.toolBar.textView.text];
    if (_artDic != nil) {
        NSArray *keys = [_artDic allKeys];
        for (int i = 0; i < [keys count]; i++) {
            NSString *key = [keys objectAtIndex:i];
            NSString *value = [_artDic objectForKey:key];
            NSRange range = [contentStr rangeOfString:key];
            if (range.location != NSNotFound) {
                [contentStr replaceOccurrencesOfString:key withString:value options:NSCaseInsensitiveSearch range:NSMakeRange(0, contentStr.length)];
            }
        }
    }
    ServiceParam *param = [[ServiceParam alloc] initWithMid:[WeqiaAppDelegate App].mid withItype:WEBO_REPLY withRequestTag:WEBO_REPLY];
    [param put:@"content" withValue:contentStr];
    if(self.replyData!=nil){
        [param put:@"msId" withValue:replyData.msgId];
        [param put:@"upId" withValue:replyData.replyId];
    }else if(self.weiboData!=nil){
        [param put:@"msId" withValue:weiboData.msgId];
        [param put:@"upId" withValue:@""];
    }
    [[UserService sharedInstance] getDataFromServer:self.view withParam:param withDelegate:self];
    _artArr=nil;
    _artDic=nil;
}
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{

    if(![_headView scrollViewDidEndDecelerating:scrollView])
        [_footView scrollViewDidEndDecelerating:scrollView];
}


-(void)footViewBeginLoad:(PageLoadFootView*)footView
{
    ServiceParam * param=[[ServiceParam alloc]initWithMid:[WeqiaAppDelegate App].mid withItype:GET_WEBO_LIST withPrevId:nil  withNextId:[NSNumber numberWithInt:_lastId] withSize:[NSNumber numberWithInt:6] withRequestTag:GET_WEBO_LIST];
    [[UserService sharedInstance] getDataFromServer:nil withParam:param withDelegate:self];
}

-(void)pageHeadBeginLoad:(PageHeadView*)headView
{
    _first=YES;
    ServiceParam * param=[[ServiceParam alloc]initWithMid:[WeqiaAppDelegate App].mid withItype:GET_WEBO_LIST withPrevId:nil withNextId:nil withSize:[NSNumber numberWithInt:[_datas count]] withRequestTag:GET_WEBO_LIST];
    [[UserService sharedInstance] getDataFromServer:nil withParam:param withDelegate:self];

}


-(void)loadWeboData:(NSArray*)webos complete:(void(^)())complete formDb:(BOOL)fromDb
{
    for(WeiboData * weibo in webos){
        weibo.match=nil;
        [weibo setMatch];
        NSString *tmans;
        if (![weibo.tMans isKindOfClass:[NSString class]]) {
            tmans = [weibo.tMans JSONString];
        } else {
            tmans = weibo.tMans;
        }
        NSArray *mansArr = [ResultEx getDataArray:[PartInData class] withStr:tmans];
        weibo.tMansName = @"name";
        if (mansArr != nil && mansArr.count > 0) {
            PartInData *partIn = [mansArr objectAtIndex:0];
            if (partIn != nil) {
                weibo.tMansName = partIn.name;
            }
        }
        weibo.uploadFailed=NO;
        [weibo getWeiboReplysByType:1];
        weibo.linesLimit=YES;
        weibo.imageHeight=[HBShowImageControl heightForFileStr:weibo.files];
        weibo.replyHeight=[WeiboCell heightForReply:weibo.replys];
    }
    NSMutableArray * ary=nil;
    if(fromDb){
        ary=[[NSMutableArray alloc]init];
        NSArray * array=[[WeqiaAppDelegate App].dbUtil   search:[MsgUploadData class] where:[NSString stringWithFormat:@"mid='%@' and coId='%@' and msgType='%d' and uploadStatus=1",[WeqiaAppDelegate App].mid,[WeqiaAppDelegate App].coId,0] orderBy:nil offset:0 count:10000];
        for(MsgUploadData * data in array){
            NSDictionary * dic=[data.entity objectFromJSONString];
            if(dic){
                WeiboData*weibo=[[WeiboData alloc]initWithDictionary:dic];
                if(weibo){
                    weibo.local=YES;
                    weibo.linesLimit=YES;
                    [weibo setMatch];
                    weibo.files=(NSString*)[[FileUploadCenter shareUpload] getFailedUpladImages:data.msgId];
                    weibo.imageHeight=[HBShowImageControl heightForFileStr:weibo.files];
                    weibo.replyHeight=0;
                    if(data.uploadStatus==MsgUploadStatusUploadFailed){
                        weibo.uploadFailed=YES;
                    }else{
                        weibo.uploadFailed=NO;
                    }
                    [ary addObject:weibo];
                }
            }
        }
    }else{
        if(!_first){
            ary=[NSMutableArray arrayWithArray:_datas];
        }else{
            ary=[[NSMutableArray alloc]init];
            NSArray * array=[[WeqiaAppDelegate App].dbUtil   search:[MsgUploadData class] where:[NSString stringWithFormat:@"mid='%@' and coId='%@' and msgType='%d' and uploadStatus=1",[WeqiaAppDelegate App].mid,[WeqiaAppDelegate App].coId,0] orderBy:nil offset:0 count:10000];
            for(MsgUploadData * data in array){
                NSDictionary * dic=[data.entity objectFromJSONString];
                if(dic){
                    WeiboData*weibo=[[WeiboData alloc]initWithDictionary:dic];
                    if(weibo){
                        weibo.local=YES;
                        weibo.linesLimit=YES;
                        [weibo setMatch];
                        weibo.files=(NSString*)[[FileUploadCenter shareUpload] getFailedUpladImages:data.msgId];
                        weibo.imageHeight=[HBShowImageControl heightForFileStr:weibo.files];
                        weibo.replyHeight=0;
                        if(data.uploadStatus==MsgUploadStatusUploadFailed){
                            weibo.uploadFailed=YES;
                        }else{
                            weibo.uploadFailed=NO;
                        }
                        [ary addObject:weibo];
                    }
                }
            }
        }
    }
    if (!fromDb) {
        int count=[webos count];
        for (int i=0; i<count; i++) {
            WeiboData * webo=[webos objectAtIndex:i];
            BOOL has=NO;
            for (WeiboData * data in _datas) {
                if (data.msgId.intValue==webo.msgId.intValue&&!data.local) {
                    if(_first){
                        [data setMatch];
                        [ary addObject:data];
                    }
                    has=YES;
                    break;
                }
            }
            if (!has) {
                 [ary addObject:webo];
            }
        }
         _first=NO;
    }else{
        [ary addObjectsFromArray:webos];
    }
    [ary sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        WeiboData *  weibo1=(WeiboData *)obj1;
        WeiboData *  weibo2=(WeiboData *)obj2;
        if(weibo1.msgId.intValue>weibo2.msgId.intValue){
            return NSOrderedAscending;
        }else if(weibo1.msgId.intValue<weibo2.msgId.intValue){
            return NSOrderedDescending;
        }else{
            return NSOrderedSame;
        }
    }];
    dispatch_async(dispatch_get_main_queue(), ^{
        [_headView loadFinish];
        [_footView loadFinish];
        _datas=ary;
        _lastId=((WeiboData*)[webos lastObject]).msgId.intValue;
        [self.tableView reloadData];
        UIView * view=[self.tableView viewWithTag:120];
        if(view){
            [view removeFromSuperview];
        }
        if([_datas count]==0){
            UILabel * label=[[UILabel alloc]initWithFrame:CGRectMake(75, 64, 170, 20)];
            label.backgroundColor=[UIColor lightGrayColor];
            label.layer.cornerRadius=3;
            label.textColor=[UIColor whiteColor];
            label.font=[UIFont systemFontOfSize:12];
            label.textAlignment=NSTextAlignmentCenter;
            label.text=@"暂无分享耶,发一条试试呗...";
            [self.tableView addSubview:label];
            label.tag=120;
        }
        if(complete){
            complete();
        }
    });
}

- (void)loadWeboData:(NSArray *) webos {
    [self loadWeboData:webos complete:nil formDb:NO];
}

- (void) onResult:(ASIHTTPRequest *)request withData:(ResultEx *)data
{
    if(request.tag==GET_WEBO_LIST){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSArray * webos=[data getDataArray:[WeiboData class]];
            if(_first){
                [[WeqiaAppDelegate App].dbUtil deleteWithClass:[WeiboData class] where:[NSString stringWithFormat:@"owner='%@' and coId='%@'",[WeqiaAppDelegate App].mid,[WeqiaAppDelegate App].coId]];
            }
            for(WeiboData * weibo in webos){
                weibo.readed=1;
                weibo.coId=[WeqiaAppDelegate App].coId;
                if (![weibo.files isKindOfClass:[NSString class]]) {
                    weibo.files = [weibo.files JSONString];
                }
                if (![weibo.tMansName isKindOfClass:[NSString class]]) {
                    weibo.tMans = [weibo.tMans JSONString];
                }
                NSMutableString * weiboId=[[NSMutableString alloc]init];
                if([NSStrUtil notEmptyOrNull:[WeqiaAppDelegate App].mid] ){
                    [weiboId appendString:[WeqiaAppDelegate App].mid];
                    [weiboId appendString:@"+"];
                }
                if([NSStrUtil notEmptyOrNull:weibo.msgId]){
                    [weiboId appendFormat:@"%@+",weibo.msgId];
                }
                [weiboId appendString:@"show=0"];
                weibo.owner=[WeqiaAppDelegate App].mid;
                weibo.weiboId=weiboId;
                [[WeqiaAppDelegate App].dbUtil insertToDB:weibo];
            }
            [self loadWeboData:webos];
        });
    }
    else if(request.tag==WEBO_REPLY){
        if(weiboData!=nil){
            [weiboData updateRepleys];
        }
        [self.toolBar.textView.internalTextView clearStoragedText:SKEY_WEIBO_REPLY];
    }else if(request.tag==WEBO_DELETE){
        int index=-1;
        for(int i=0;i<[_datas count];i++){
            WeiboData *weibo =[_datas objectAtIndex:i];
            if(!weibo.local&&weibo.msgId.integerValue==_deleteWeibo.msgId.integerValue){
                index=i;
                break;
            }
        }
        NSMutableArray * array=[NSMutableArray arrayWithArray:_datas];
        [array removeObjectAtIndex:index];
        _datas=array;
        int indexPath=0;
        if(unReadCount>0&&failedCount>0){
            indexPath=2+index;
        }else if(unReadCount>0||failedCount>0){
            indexPath=1+index;
        }else{
            indexPath=index;
        }
        [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:indexPath inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
        [[WeqiaAppDelegate App].dbUtil deleteUnreadWithClass:[WeiboData class] where:[NSString stringWithFormat:@"msgId='%@'",_deleteWeibo.msgId]];
        if([_datas count]==0){
            [self firstGetData:[_datas count]];
        }
    }
}

- (void)onError:(ASIHTTPRequest *)request withCode:(NSInteger)errCode {
    [_headView loadFinish];
    [_footView loadFinish];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.toolBar hideWithAnimation:YES];
}

-(void)weiboToolBarWillShow:(WeiboToolBar*)toolBar
{
}

-(void)weiboToolBarWillHide:(WeiboToolBar*)toolBar  animation:(BOOL)animation
{
    [toolBar.textView.internalTextView saveToFile:toolBar.textView.text withKey:SKEY_WEIBO_REPLY];
    [UIView animateWithDuration:0.25 animations:^{
        self.tableView.transform=CGAffineTransformIdentity;
    } completion:nil ];
}
-(void)weiboToolBarFrameDidChange:(WeiboToolBar *)toolBar  height:(float)height
{
    NSInteger index=-1;
    for(int i=0;i<[_datas count];i++){
        WeiboData * data =[_datas objectAtIndex:i];
        if(data.msgId.intValue==self.weiboData.msgId.intValue)
        {
            index=i;
            break;
        }
    }
    UITableViewCell * cell=[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
    float y=cell.frame.origin.y+cell.frame.size.height;
    float temp=self.tableView.contentSize.height>self.tableView.frame.size.height?self.tableView.contentSize.height:self.tableView.frame.size.height;
    if(temp-y>height){
        if(y>self.tableView.frame.size.height-height){
            [UIView animateWithDuration:animationTime animations:^{
                self.tableView.contentOffset=CGPointMake(0, y-(self.view.frame.size.height-height));
            }];
            
        }
    }
    else{
        if(self.tableView.contentSize.height>self.tableView.frame.size.height)
        {
            self.tableView.contentOffset=CGPointMake(0, self.tableView.contentSize.height-self.tableView.frame.size.height);
        }
        [UIView animateWithDuration:animationTime animations:^{
            self.tableView.transform=CGAffineTransformMakeTranslation(0,-(height-(self.tableView.contentSize.height-y)));
        }];
    }
}

-(void)weiboToolBar:(WeiboToolBar *)toolBar textDidChange:(NSString *)text
{
    NSArray * keys=[_artDic allKeys];
    for(NSString * key in keys){
        NSRange range=[text rangeOfString:key];
        if(range.location==NSNotFound){
            [_artDic removeObjectForKey:key];
            if(_artArr!=nil&&[_artArr count]>0){
                for(ContactData * data in _artArr){
                    NSString * name=[NSString stringWithFormat:@"@%@",data.mName];
                    if([name isEqualToString:key]){
                        [_artArr removeObject:data];
                    }
                }

            }
        }
    }
}
-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (actionSheet.tag==102){
        if(0==buttonIndex){
            NSString * string=[NSString stringWithFormat:@"tel:%@",phoneNumber];
            if(webView==nil)
                webView=[[UIWebView alloc]initWithFrame:self.view.bounds];
            [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:string]]];
            webView.hidden=YES;
            [self.view addSubview:webView];
        }
    }else if (actionSheet.tag==103){
        if(0==buttonIndex){
            NSString * string=[NSString stringWithFormat:@"tel:%@",phoneNumber];
            if(webView==nil)
                webView=[[UIWebView alloc]initWithFrame:self.view.bounds];
            [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:string]]];
            webView.hidden=YES;
            [self.view addSubview:webView];
        }else if(1==buttonIndex){
            MFMessageComposeViewController* contrller=[[MFMessageComposeViewController alloc]init];
            contrller.messageComposeDelegate=self;
            contrller.recipients=[NSArray arrayWithObject:phoneNumber];
            [self presentViewController:contrller animated:YES completion:nil];
        }
    }
}
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller1 didFinishWithResult:(MessageComposeResult)result
{
    [controller1 dismissViewControllerAnimated:YES completion:nil];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
}

-(BOOL)shouldUpdateForPushData:(PushData *)pushData
{
    if (pushData.msgType==PUSH_PUBLISH_WEIBOMSG||pushData.msgType==PUSH_REPLY_WEIBOMSG||pushData.msgType==PUSH_DELETE_WEIBOREPLY||pushData.msgType==PUSH_DELETE_WEIBOMSG) {
        return YES;
    }else{
        return NO;
    }
}

#pragma -mark 私有方法
-(void)firstGetData:(int)count
{
    _first=YES;
    failedCount=[[WeqiaAppDelegate App].dbUtil rowCount:[MsgUploadData class] where:[NSString stringWithFormat:@"mid='%@' and coId='%@' and msgType=0 and uploadStatus=3",[WeqiaAppDelegate App].mid,[WeqiaAppDelegate App].coId]];
    ServiceParam * param=[[ServiceParam alloc]initWithMid:[WeqiaAppDelegate App].mid withItype:GET_WEBO_LIST withPrevId:nil withNextId:nil withSize:[NSNumber numberWithInt:count] withRequestTag:GET_WEBO_LIST];
    [[UserService sharedInstance] getDataFromServer:nil withParam:param withDelegate:self];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIViewController *send = segue.destinationViewController;
    if ([send isKindOfClass:[ContactViewController class]]) {
        ContactViewController *vc = ((ContactViewController *)send);
        vc.delegate = self;
        vc.showSelf = NO;
        vc.type = ContactTypeMultiSelect;
    }else if([send isKindOfClass:[MessageCenterViewController class]]){
        MessageCenterViewController * vc=(MessageCenterViewController*)send;
        NSMutableString * where=[NSMutableString stringWithString:@"type<2 and readed=0"];
        vc.where=where;
    }
}
- (void) addArtContent:(ContactData *) contact {
    _block([NSString stringWithFormat:@"@%@ ",contact.mName]);
    if(_artArr==nil){
        _artArr=[[NSMutableArray alloc]init];
        [_artArr addObject:contact];
    }else{
        for(ContactData * data in _artArr){
            if([data.mid isEqualToString:contact.mid]){
                return;
            }
        }
        [_artArr addObject:contact];
    }
    //add dic
    NSString *arcType = nil;
    if([NSStrUtil notEmptyOrNull:contact.mNo]) {
        arcType = [[NSString alloc] initWithString:contact.mNo];
    } else if ([NSStrUtil notEmptyOrNull:contact.mobile]) {
        arcType = [[NSString alloc] initWithString:contact.mobile];
    } else if ([NSStrUtil notEmptyOrNull:contact.email]) {
        arcType = [[NSString alloc] initWithString:contact.email];
    }
    if (arcType == nil) {
        return;
    }
    NSString *key = [[NSString alloc] initWithFormat:@"@%@",contact.mName];
    NSString *arcValue = [[NSString alloc] initWithFormat:@"@[%@:%@]",key, arcType];
    
    if(_artDic == nil) {
        _artDic= [[NSMutableDictionary alloc] init];
    }
    [_artDic setObject:arcValue forKey:key];
}

-(void) backAction
{
    [super backAction];
    [self.toolBar hideWithAnimation:NO];
}

#pragma -mark 事件响应方法

-(void)update
{
    [self loadFromDb:NO];
}

-(void)uploadStatusChanged:(NSNotification*)notification
{
    MsgUploadData * msg=[notification object];
    if (msg.msgType != MsgTypeWeibo) {
        return;
    }
    if(msg.uploadStatus==MsgUploadStatusIsUploading){
        NSDictionary * dic=[msg.entity objectFromJSONString];
        if(dic){
            WeiboData*weibo=[[WeiboData alloc]initWithDictionary:dic];
            if(weibo){
                for(WeiboData * data in _datas){
                    if(data.local&&[data.msgId isEqual:weibo.msgId])
                        return;
                }
                weibo.local=YES;
                weibo.linesLimit=YES;
                [weibo setMatch];
                weibo.files=(NSString*)[[FileUploadCenter shareUpload] getFailedUpladImages:msg.msgId];
                if(msg.uploadStatus==MsgUploadStatusUploadFailed){
                    weibo.uploadFailed=YES;
                }else{
                    weibo.uploadFailed=NO;
                }
                weibo.imageHeight=[HBShowImageControl heightForFileStr:weibo.files];
                NSMutableArray* array=[NSMutableArray arrayWithArray:_datas];
                [array insertObject:weibo atIndex:0];
                _datas=array;
                int index=0;
                if(unReadCount>0&&failedCount>0){
                    index=2;
                }else if(unReadCount>0||failedCount>0){
                    index=1;
                }else{
                    index=0;
                }
                [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:index inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }else if(msg.uploadStatus==MsgUploadStatusUploadFailed){
        [self loadFromDb:NO];
    }else if(msg.uploadStatus==MsgUploadStatusUploadFinish){
        [self  firstGetData:[_datas count]];
    }
}

-(void)tapAction
{
    [self.toolBar hideWithAnimation:YES];
}
-(void)cellUpdate
{
    for(WeiboData * wb in _datas){
        if(wb.isGetReply==NO)
            return;
    }
    [_headView loadFinish];
    [_footView loadFinish];
    [_footView end];
    [self.tableView reloadData];
}
-(void)publicWeiboAction
{
    if ([WeqiaAppDelegate App].loginUser.joinStatus != 1) {
        [DialogUtil showDlgAlert:NSLocalizedStringFromTable(@"wait_for_search", @"local", nil)];
        return;
    }
    [self.toolBar hideWithAnimation:YES];
    [self performSegueWithIdentifier:@"WeiboPublish" sender:nil];
}

-(void)msgCenterAction
{
    [self performSegueWithIdentifier:@"weiboToMsgCenterAction" sender:nil];
}

-(void)uploadFailedCenterAction
{
    UIStoryboard * story=[UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    UploadFailedViewController* controller=[story instantiateViewControllerWithIdentifier:@"UploadFailedViewController"];
    controller.itype=MsgTypeWeibo;
    controller.navigationItem.title=@"分享待发列表";
    [self.navigationController pushViewController:controller animated:YES];
}


@end
