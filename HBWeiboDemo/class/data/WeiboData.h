//
//  WeiboData.h
//  wq
//
//  Created by weqia on 13-8-28.
//  Copyright (c) 2013年 Weqia. All rights reserved.
//

#import "BaseData.h"
#import "ObjUrlData.h"
#import "WeiboReplyData.h"
#import "UserService.h"
#import "WeqiaAppDelegate.h"
#import "MatchParser.h"
#define HBWeiboContentUpdateNofication @"HBWeiboContentUpdateNofication"

@interface WeiboData : BaseData<RequestDelegate,MatchParserDelegate>
{
    int type;
    
    __weak MatchParser* _match;
}
@property(nonatomic,strong) NSString * weiboId;
@property(nonatomic,strong) NSString * content;
@property(nonatomic,strong) NSString * fmt_gmt_create;
@property(nonatomic,strong) NSString * gCoId;
@property(nonatomic,strong) NSString * gmtCreate;
@property(nonatomic,strong) NSString * isPublic;
@property(nonatomic,strong) NSString * msgId;
@property(nonatomic,strong) NSString * replyCnt;
@property(nonatomic,strong) NSString * source;
@property(nonatomic,strong) NSString * files;
@property(nonatomic,strong) NSString * tMans;
@property(nonatomic,strong) NSString * owner;
@property(nonatomic,strong) NSArray * replys;

@property(nonatomic,readonly) BOOL isGetReply;
@property(nonatomic,strong) NSString * tMansName;
@property(nonatomic) float height;
@property(nonatomic) float heightOflimit;
@property(nonatomic) float miniWidth;
@property(nonatomic) float imageHeight;
@property(nonatomic) float replyHeight;
@property(nonatomic) int numberOfLinesTotal;
@property(nonatomic) int numberOfLineLimit;
@property(nonatomic) BOOL uploadFailed;
@property(nonatomic) BOOL shouldExtend;
@property(nonatomic) BOOL willDisplay;
@property(nonatomic,weak,getter =getMatch) MatchParser * match;

@property(nonatomic) int tag;


@property(nonatomic) BOOL linesLimit;

-(void)getWeiboReplysByType:(int)type;

-(void)deleteByReplyId:(NSString*)replyId;

-(void)updateRepleys;

-(MatchParser*)createMatch:(float)width;

-(void)updateMatch:(void(^)(NSMutableAttributedString * string, NSRange range))link;

-(void)setMatch;

+(NSCache*)shareCacheForWeibo;
@end
