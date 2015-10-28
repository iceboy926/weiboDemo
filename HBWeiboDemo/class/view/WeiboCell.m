//
//  WeiboCell.m
//  wq
//
//  Created by weqia on 13-8-28.
//  Copyright (c) 2013年 Weqia. All rights reserved.
//

#import "WeiboCell.h"
#import "UIImageView+WebCache.h"
#import "TimeUtil.h"
#import <QuartzCore/QuartzCore.h>
#import "NSStrUtil.h"
#import "CoInfoData.h"
#import "HBHttpServer.h"
#import "ObjUrlData.h"
#import "PartInData.h"
#import "DownLoadViewController.h"
#import "MsgUploadData.h"
#import "NSTextUtil.h"

@implementation ReplyCell
@synthesize label;
-(void)prepareForReuse
{
    self.label.match=nil;
   
}

@end


@implementation WeiboCell
@synthesize controller,toolBar;

+(id)drawImageDispatchQueue
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue=dispatch_queue_create("com.Weqia.drawImage", NULL);
    });
    return (__bridge id)(queue);
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self=[super initWithCoder:aDecoder];
    if(self){
       
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}
#pragma -mark 私有方法

-(void) prepare
{
    [super prepareForReuse];
    _time.text=@"";
    _title.text=@"";
    for(UIView * view in _imageContent.subviews)
        [view removeFromSuperview];
    UIView * view=[self.contentView viewWithTag:191];
    if(view){
        [view removeFromSuperview];
    }
    view=[self.contentView viewWithTag:192];
    if(view){
        [view removeFromSuperview];
    }
    linesLimit=NO;
}

+(float) heightForReply:(NSArray*)replys
{
    float height=6;
    for(WeiboReplyData * data in replys){
        height+=data.height+4;
    }
    return height;
}

-(void)addImagesWithFiles:(float)offset
{
    if(_weibo.imageHeight==0){
        self.imageContent.hidden=YES;
        CGRect  frame=self.imageContent.frame;
        frame.origin.y=self.content.frame.origin.y+self.content.frame.size.height+offset+5;
        frame.size.height=0;
        self.imageContent.frame=frame;
        return;
    }else{
        self.imageContent.hidden=NO;
        CGRect  frame=self.imageContent.frame;
        frame.origin.y=self.content.frame.origin.y+self.content.frame.size.height+offset+5;
        frame.size.height=_weibo.imageHeight;
        self.imageContent.frame=frame;
    }
    __weak WeiboCell * wself=self;
    __weak WeiboData * wweibo=_weibo;
    dispatch_queue_t queue=dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    if (IOS_VERSION>=6.0) {
        queue=(__bridge dispatch_queue_t)([WeiboCell drawImageDispatchQueue]);
    }
    dispatch_async(queue, ^{
        if (wself&&wweibo.willDisplay&&wweibo) {
            __strong WeiboCell * sself=wself;
            __strong WeiboData * sweibo=wweibo;
            dispatch_async(dispatch_get_main_queue(), ^{
                HBShowImageControl * control=[[HBShowImageControl alloc]initWithFrame: sself.imageContent.bounds];
                control.controller=sself.controller;
                control.smallTag=THUMB_WEIBO_SMALL_1;
                control.bigTag=THUMB_WEIBO_BIG;
                [control setImagesFileStr:sweibo.files];
                [sself.imageContent addSubview:control];
                control.delegate=sself;
            });
        }
    });
}


#pragma -mark 接口方法
-(void)loadReply
{
    _replys=_weibo.replys;
    [self.tableReply reloadData];
}

-(void)setCellContent:(WeiboData *)weibo
{
    weibo.willDisplay=YES;
    if(weibo.msgId.intValue==_weibo.msgId.intValue&&weibo.local==_weibo.local&&linesLimit==weibo.linesLimit&&replyCount==[weibo.replys count])
        return;
    [self prepare];
    replyCount=[weibo.replys count];
    linesLimit=weibo.linesLimit;

    self.mLogo.layer.cornerRadius=3;
    self.mLogo.clipsToBounds=YES;
    [self.content registerCopyAction];
    _weibo=weibo;
    self.content.linesLimit=_weibo.linesLimit;
    __weak HBCoreLabel * wcontent=self.content;
    MatchParser* match=[_weibo getMatch:^(MatchParser *parser,id data) {
        if (wcontent) {
            WeiboData * weibo=(WeiboData*)data;
            if (weibo.willDisplay) {
                dispatch_async(dispatch_get_main_queue(), ^{
                   wcontent.match=parser;
                });
            }
        }
    } data:weibo];
    self.content.match=match;
    ContactData *contact = [[WeqiaAppDelegate App].dbUtil searchSingle:[ContactData class]where:[NSString stringWithFormat:@"mid='%@'",weibo.mid] orderBy:nil];
    if (contact != nil) {
        self.title.text=contact.mName;
        if([NSStrUtil notEmptyOrNull:contact.mLogo]){
            [self.mLogo setImageWithURL:[NSURL URLWithString:contact.mLogo] placeholderImage:[UIImage imageNamed:@"people.png"]];
        }else{
            self.mLogo.image=[UIImage imageNamed:@"people.png"];
        }
    }else{
        self.mLogo.image=[UIImage imageNamed:@"people.png"];
    }
    [self.mLogo setMlogoTapAction:contact controller:self.controller];
    NSMutableString * timeStr=[[NSMutableString alloc]init];
    if ([NSStrUtil notEmptyOrNull:weibo.gmtCreate]) {
        long long time=[weibo.gmtCreate longLongValue];
        [timeStr appendString:[TimeUtil getTimeStrStyle1:time/1000]];
    }
    self.time.text=timeStr;
    CGRect frame=self.time.frame;
    frame.size.width=[timeStr sizeWithFont:self.time.font].width+10;
    self.time.frame=frame;
    self.tableReply.scrollEnabled=NO;
    float offset=0.0f;
    if(weibo.numberOfLineLimit<weibo.numberOfLinesTotal){
        UIButton * button=[UIButton buttonWithType:UIButtonTypeCustom];
        [button setTitleColor:self.title.textColor forState:UIControlStateNormal];
        [button setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
        [button.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [self.contentView addSubview:button];
        [button addTarget:self action:@selector(limitAction) forControlEvents:UIControlEventTouchUpInside];
        if(weibo.linesLimit){
            [button setTitle:@"全文" forState:UIControlStateNormal];
            _content.frame=CGRectMake(57, 32, _weibo.miniWidth,_weibo.heightOflimit);
            offset=25;
        }else{
            [button setTitle:@"收起" forState:UIControlStateNormal];
            _content.frame=CGRectMake(57, 32, _weibo.miniWidth,_weibo.height);
            offset=25;
        }
        button.frame=CGRectMake(57, self.content.frame.origin.y+self.content.frame.size.height+6, 50, 20);
        [button setTitleEdgeInsets:UIEdgeInsetsMake(0, 0, 0, 20)];
        button.tag=191;
    }else{
        _content.frame=CGRectMake(57, 32, _weibo.miniWidth,_weibo.height);
    }
    [self addImagesWithFiles:offset];
    if(!weibo.local){
        if(weibo.isGetReply){
            if ([weibo.replys isKindOfClass:[NSArray class]]&&[weibo.replys count]>0) {
                [self.tableReply reloadData];
                [self.back setHidden:NO];
            } else {
                [self.back setHidden:YES];
            }
        }else{
            [self.back setHidden:YES];
            [weibo getWeiboReplysByType:1];
        }
    }else{
        [self.back setHidden:YES];
    }
    float height=_weibo.replyHeight;
    
    frame=self.replyContent.frame;
    frame.origin.y=self.imageContent.frame.origin.y+self.imageContent.frame.size.height+5;
    frame.size.height=_weibo.replyHeight+30;
    self.replyContent.frame=frame;
    
    frame=_back.frame;
    frame.size.height=height;
    frame.origin.y=28;
    _back.frame=frame;
    
    frame=_tableReply.frame;
    frame.size.height=height-6;
    frame.origin.y=35;
    _tableReply.frame=frame;
    if(weibo.isPublic.intValue==1){
        [self.lockView setHidden:YES];
    }else{
        [self.lockView setHidden:NO];
        frame=self.lockView.frame;
        frame.origin.x=self.time.frame.origin.x+self.time.frame.size.width;
        self.lockView.frame=frame;
    }
    LoginUserData * data= [WeqiaAppDelegate App].loginUser;
    if(self.lockView.hidden){
        frame=self.btnDelete.frame;
        frame.origin.x=self.time.frame.origin.x+self.time.frame.size.width+10;
        self.btnDelete.frame=frame;
    }else{
        frame=self.btnDelete.frame;
        frame.origin.x=self.lockView.frame.origin.x+self.lockView.frame.size.width+10;
        self.btnDelete.frame=frame;
    }
    if(data.roleId<=1){
        if(![weibo.mid isEqual:[WeqiaAppDelegate App].mid])
        {
            [self.btnDelete setHidden:YES];
        }else{
            [self.btnDelete setHidden:NO];
        }
    }if(weibo.uploadFailed){
        frame=self.btnDelete.frame;
        frame.origin.x=self.btnDelete.frame.origin.x+self.btnDelete.frame.size.width+20;
        frame.size.width=200;
        UILabel * label=[[UILabel alloc]initWithFrame:frame];
        label.backgroundColor=[UIColor clearColor];
        label.text=@"发送失败";
        label.font=self.btnDelete.titleLabel.font;
        label.textColor=[UIColor redColor];
        label.tag=192;
        [self.replyContent addSubview:label];
    }
    if(weibo.local){
        [self.btnReply setEnabled:NO];
    }else{
        [self.btnReply setEnabled:YES];
    }
}
+(float)getHeightByContent:(WeiboData*)data
{
    float height;
    if(data.shouldExtend){
        if(data.linesLimit){
            height=data.heightOflimit+25;
        }else{
            height=data.height+25;
        }
    }else{
        height=data.height;
    }
    if ([data.replys isKindOfClass:[NSArray class]]&&[data.replys count]>0&&!data.local) {
        return 70.0+data.imageHeight+height+6+data.replyHeight;
    } else  {
        return 70.0+data.imageHeight+height;
    }
}

#pragma -mark 委托方法
-(void)showImageControlFinishLoad:(HBShowImageControl*)control
{
    CGRect frame=self.imageContent.frame;
    frame.size.height=control.frame.size.height;
    self.imageContent.frame=frame;
}


#pragma -mark 事件响应方法

-(void)limitAction
{
    if(_weibo.linesLimit){
        _weibo.linesLimit=NO;
        [controller.tableView reloadData];
    }else{
        _weibo.linesLimit=YES;
        [controller.tableView reloadData];
        [controller.tableView scrollRectToVisible:CGRectMake(0, self.frame.origin.y, 320, controller.tableView.frame.size.height) animated:NO];
    }
    
}

-(IBAction)deleteAction:(id)sender
{
    
    UIAlertView * alert=[[UIAlertView alloc]initWithTitle:@"删除分享"
                                                  message:nil
                                                 delegate:self
                                        cancelButtonTitle:@"取消"
                                        otherButtonTitles:@"确认", nil];
    alert.tag=222;
    [alert show];
}
-(IBAction)btnShareAction:(id)sender
{
    NSString * fileStr=nil;
    NSArray *objArr=nil;
    if (_weibo.files!=nil&&[_weibo.files isKindOfClass:[NSArray class]]) {
        if(((NSArray*)_weibo.files).count>0){
            if([[((NSArray*)_weibo.files) objectAtIndex:0] isKindOfClass:[ObjUrlData class]]){
                objArr=(NSArray*)_weibo.files;
            }else{
                fileStr = [_weibo.files JSONString];
                objArr = [ResultEx getDataArray:[ObjUrlData class] withStr:fileStr];
            }
        }
    }else{
        fileStr=_weibo.files;
        objArr = [ResultEx getDataArray:[ObjUrlData class] withStr:fileStr];
    }
    UIImage * image=nil;
    if (objArr) {
        int count=[objArr count];
        for (int i=0; i<count; i++) {
            ObjUrlData * url=[objArr objectAtIndex:i];
            NSString * Url=[NSString stringWithFormat:@"%@&th=%d",url.url,THUMB_WEIBO_SMALL_1];
            HBHttpRequest * request=[HBHttpRequest shareIntance];
            image=[request getBitmap:Url process:nil complete:nil valueReturn:nil];
            if(image!=nil)
                break;
        }
    }
    [UMSocialData defaultData].extConfig.title=@"hi,给你一条分享!";
    [UMSocialData defaultData].extConfig.wechatSessionData.shareImage=image;
    [UMSocialData defaultData].extConfig.wechatSessionData.shareText=_weibo.content;
    [UMSocialData defaultData].extConfig.wechatTimelineData.shareText=_weibo.content;
    [UMSocialData defaultData].extConfig.wechatTimelineData.shareImage=image;
    [UMSocialData defaultData].extConfig.wechatSessionData.url=@"http://www.weqia.com/d.htm";
    [UMSocialData defaultData].extConfig.wechatTimelineData.webUrl=@"http://www.weqia.com/d.htm";
    [UMSocialData defaultData].extConfig.qqData.webUrl=@"http://www.weqia.com/d.htm";
    [UMSocialData defaultData].extConfig.qqData.qqMessageType=UMSocialQQMessageTypeDefault;
    if (image==nil) {
        [UMSocialData defaultData].extConfig.wechatSessionData.wxMessageType = UMSocialWXMessageTypeText;
        [UMSocialData defaultData].extConfig.wechatTimelineData.wxMessageType=UMSocialWXMessageTypeText;
    }else{
        [UMSocialData defaultData].extConfig.wechatTimelineData.wxMessageType=UMSocialWXMessageTypeWeb;
        [UMSocialData defaultData].extConfig.wechatSessionData.wxMessageType=UMSocialWXMessageTypeWeb;
        
    }
    [UMSocialSnsService presentSnsIconSheetView:self.controller
                                         appKey:WEIQIA_APPLEKEY
                                      shareText:_weibo.content
                                     shareImage:image
                                 shareToSnsNames:[NSArray arrayWithObjects:UMShareToWechatSession,UMShareToWechatTimeline,UMShareToQQ,UMShareToQzone,UMShareToSina,UMShareToTencent/*,UMShareToYXSession,UMShareToYXTimeline,UMShareToLWSession,UMShareToLWTimeline*/,UMShareToDouban,UMShareToSms,nil]
                                       delegate:nil];
}

-(IBAction)btnReplyAction:(id)sender
{
    if(controller){
        controller.weiboData=_weibo;
        controller.replyData=nil;
        UITextView *tv = controller.toolBar.textView.internalTextView;
//        controller.toolBar.textView.text=nil;
        controller.superView=controller.view.superview;
        NSString *str = [tv getStoragedText:SKEY_WEIBO_REPLY];
        controller.toolBar.textView.text = str;
        NSString *placeStr = nil;
        if ([NSStrUtil notEmptyOrNull:str]) {
            placeStr = @"";
        } else {
            placeStr = @"评论:";
        }
        [controller.toolBar  showInView:controller.view withPlaceString:placeStr];
    }
}

-(void)delAndReplyAction
{
    [controller.toolBar hideWithAnimation:YES];
    LoginUserData * data= [WeqiaAppDelegate App].loginUser;
    if(data.roleId<=1){
        if(![_reply.mid isEqual:[WeqiaAppDelegate App].mid]){
            UIActionSheet * action=[[UIActionSheet alloc]initWithTitle:nil
                                                              delegate:self
                                                     cancelButtonTitle:@"取消"
                                                destructiveButtonTitle:nil
                                                     otherButtonTitles:@"回复",@"复制",nil];
            action.tag=100;
            [action showInView:[UIApplication sharedApplication].keyWindow];
            return;
        }
    }
    UIActionSheet * action=[[UIActionSheet alloc]initWithTitle:nil
                                                      delegate:self
                                             cancelButtonTitle:@"取消"
                                        destructiveButtonTitle:@"删除"
                                             otherButtonTitles:@"回复",@"复制",nil];
    action.tag=101;
    [action showInView:[UIApplication sharedApplication].keyWindow];
    
}


#pragma -mark 回调方法

-(void)lookImageAction:(HBShowImageControl*)control
{
    if(controller)
        [controller.toolBar hideWithAnimation:YES];
    if(self.toolBar)
        [self.toolBar hideWithAnimation:YES];
}
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag==221){
        if(buttonIndex==1){
            [_weibo deleteByReplyId:_reply.replyId];
        }
    }else if(alertView.tag==222){
        if (buttonIndex==1) {
            if(_weibo.local){
                MsgUploadData * data=[[WeqiaAppDelegate App].dbUtil searchSingle:[MsgUploadData class] where:[NSString stringWithFormat:@"mid='%@' and coId='%@' and entityId='%d' and msgType=0",[WeqiaAppDelegate App].mid,[WeqiaAppDelegate App].coId,_weibo.msgId.intValue] orderBy:nil];
                [[WeqiaAppDelegate App].dbUtil deleteWithClass:[MsgUploadData class] where:[NSString stringWithFormat:@"mid='%@' and coId='%@' and entityId='%d' and msgType=0",[WeqiaAppDelegate App].mid,[WeqiaAppDelegate App].coId,_weibo.msgId.intValue]];
                [[WeqiaAppDelegate App].dbUtil deleteWithClass:[FileUploadData class] where:[NSString stringWithFormat:@"msgId=%d",data.msgId]];
                int index=-1;
                for (int i=0; i<controller.datas.count; i++) {
                    WeiboData * data=[controller.datas objectAtIndex:i];
                    if (data.local&&data.msgId.intValue==_weibo.msgId.intValue) {
                        index=i;
                    }
                }
                if (index>=0) {
                    NSMutableArray * array=[NSMutableArray arrayWithArray:controller.datas];
                    [array removeObjectAtIndex:index];
                    controller.datas=array;
                    NSIndexPath * indexpath=nil;
                    if([controller getUnreadCount]>0&&[controller getFailedCount]>0){
                        indexpath=[NSIndexPath indexPathForRow:index+2 inSection:0];
                    }else if([controller getUnreadCount]>0||[controller getFailedCount]>0){
                        indexpath=[NSIndexPath indexPathForRow:index+1 inSection:0];
                    }else{
                        indexpath=[NSIndexPath indexPathForRow:index inSection:0];
                    }
                    [controller.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexpath] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }else{
                controller.deleteWeibo=_weibo;
                ServiceParam * param=[[ServiceParam alloc]initWithMid:[WeqiaAppDelegate App].mid withItype:WEBO_DELETE withPrevId:nil withNextId:nil withSize:nil  withRequestTag:WEBO_DELETE];
                [param put:@"msId" withValue:_weibo.msgId];
                [[UserService sharedInstance] getDataFromServer:nil withParam:param withDelegate:controller];
            }
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    ContactData * contact=[[WeqiaAppDelegate App].dbUtil searchSingle:[ContactData class] where:[NSString stringWithFormat:@"mid='%@'",_reply.mid] orderBy:nil];
     [self.tableReply deselectRowAtIndexPath:_indexPath animated:YES];
    if(actionSheet.tag==101){
        if(buttonIndex==0){
            UIAlertView * alert=[[UIAlertView alloc]initWithTitle:@"删除评论"
                                                          message:nil
                                                         delegate:self
                                                cancelButtonTitle:@"取消"
                                                otherButtonTitles:@"确认", nil];
            alert.tag=221;
            [alert show];
        }else if(buttonIndex==1){
            controller.weiboData=_weibo;
            controller.replyData=_reply;
            controller.superView=controller.view.superview;
            [controller.toolBar  showInView:controller.view withPlaceString:[NSString stringWithFormat:@"回复%@:",contact.mName]];
        }else if(buttonIndex==2){
            if([_reply.match.source isKindOfClass:[NSString  class]]){
                [UIPasteboard generalPasteboard].string=_reply.match.source;
            }
        }
    }else{
        if(buttonIndex==0){
            controller.weiboData=_weibo;
            controller.replyData=_reply;
            controller.superView=controller.view.superview;
            [controller.toolBar  showInView:controller.view withPlaceString:[NSString stringWithFormat:@"回复%@:",contact.mName]];
            
        }else if(buttonIndex==1){
            if([_reply.match.source isKindOfClass:[NSString  class]]){
                [UIPasteboard generalPasteboard].string=_reply.match.source;
            }
        }
    }
}

#pragma -mark  tableReply delegate
-(float)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    WeiboReplyData * data=[_weibo.replys objectAtIndex:indexPath.row];
    return data.height+4;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_weibo.replys count];
}
-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString * reuse=@"WeiboReplyCell";
    ReplyCell * cell=[tableView dequeueReusableCellWithIdentifier:reuse];
    if(indexPath.row>=_weibo.replys.count)
        return cell;
    WeiboReplyData * data=[_weibo.replys objectAtIndex:indexPath.row];
    __weak HBCoreLabel * wlabel=cell.label;
    MatchParser * match=[data getMatch:^(MatchParser *parser, id data) {
        if (wlabel) {
            WeiboData * weibo=(WeiboData*)data;
            if (weibo.willDisplay) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    wlabel.match=parser;
                });
            }
        }
    } data:_weibo];
    cell.label.match=match;
    cell.label.userInteractionEnabled=YES;
    CGRect frame=cell.label.frame;
    cell.backgroundColor=[UIColor clearColor];
    frame.size.height=data.height;
    cell.label.frame=frame;
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    _indexPath=indexPath;
    _reply=[_weibo.replys objectAtIndex:indexPath.row];
    [self delAndReplyAction];
}


@end
