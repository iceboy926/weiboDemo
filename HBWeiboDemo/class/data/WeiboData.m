//
//  WeiboData.m
//  wq
//
//  Created by weqia on 13-8-28.
//  Copyright (c) 2013年 Weqia. All rights reserved.
//

#import "WeiboData.h"
#import "WeiboCell.h"
#import "PartInData.h"
#import "UIColor+setting.h"
@implementation WeiboData
@synthesize content,files,fmt_gmt_create,gmtCreate,gCoId,isPublic
,msgId,replyCnt,source,tMans,tMansName,replys,tag,height,linesLimit,weiboId,owner,uploadFailed,heightOflimit,shouldExtend,miniWidth,numberOfLineLimit,numberOfLinesTotal,willDisplay,imageHeight,replyHeight;

#pragma -mark 接口方法

+(NSString *)getPrimaryKey
{
    return @"weiboId";
}

+(NSString *)getTableName
{
    return @"WeiboData";
}

+(int)newTag
{
    static int tag=1000;
    return tag++;
}

+(NSCache*)shareCacheForWeibo;
{
    static NSCache * cache=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cache=[[NSCache alloc]init];
        cache.totalCostLimit=0.1*1024*1024;
    });
    return cache;
}

-(MatchParser*)getMatch
{
    if (_match&&[_match isKindOfClass:[MatchParser class]]) {
        _match.data=self;
        return _match;
    }else{
        NSString *key=[NSString stringWithFormat:@"%@:local=%d:content=%@",self.msgId,self.local,self.content];
        MatchParser *parser=[[WeiboData shareCacheForWeibo] objectForKey:key];
        if (parser) {
            _match=parser;
            self.height=parser.height;
            self.heightOflimit=parser.heightOflimit;
            self.miniWidth=parser.miniWidth;
            self.numberOfLinesTotal=parser.numberOfTotalLines;
            self.numberOfLineLimit=parser.numberOfLimitLines;
            parser.data=self;
            if (_match.numberOfTotalLines>_match.numberOfLimitLines) {
                self.shouldExtend=YES;
            }else{
                self.shouldExtend=NO;
            }
            return parser;
        }else{
            parser=[self createMatch:252];
            if (parser) {
                [[WeiboData shareCacheForWeibo]  setObject:parser forKey:key];
            }
            return parser;
        }
    }
}
-(MatchParser*)getMatch:(void(^)(MatchParser *parser,id data))complete data:(id)data
{
    if (_match&&[_match isKindOfClass:[MatchParser class]]) {
        _match.data=self;
        return _match;
    }else{
        NSString *key=[NSString stringWithFormat:@"%@:local=%d:content=%@",self.msgId,self.local,self.content];
        MatchParser *parser=[[WeiboData shareCacheForWeibo] objectForKey:key];
        if (parser) {
            _match=parser;
            self.height=parser.height;
            self.heightOflimit=parser.heightOflimit;
            self.miniWidth=parser.miniWidth;
            self.numberOfLinesTotal=parser.numberOfTotalLines;
            self.numberOfLineLimit=parser.numberOfLimitLines;
            parser.data=self;
            if (_match.numberOfTotalLines>_match.numberOfLimitLines) {
                self.shouldExtend=YES;
            }else{
                self.shouldExtend=NO;
            }
            return parser;
        }else{
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                MatchParser*parser=[self createMatch:252];
                if (parser) {
                    _match=parser;
                    [[WeiboData shareCacheForWeibo]  setObject:parser forKey:key];
                    if (complete) {
                        complete(parser,data);
                    }
                }
            });
            return nil;
        }
    }
}

-(void)setMatch
{
    if (_match&&[_match isKindOfClass:[MatchParser class]]) {
        _match.data=self;
        return;
    }else{
        NSString *key=[NSString stringWithFormat:@"%@:local=%d:content=%@",self.msgId,self.local,self.content];
        MatchParser *parser=[[WeiboData shareCacheForWeibo] objectForKey:key];
        if (parser) {
            _match=parser;
            self.height=parser.height;
            self.heightOflimit=parser.heightOflimit;
            self.miniWidth=parser.miniWidth;
            self.numberOfLinesTotal=parser.numberOfTotalLines;
            self.numberOfLineLimit=parser.numberOfLimitLines;
            parser.data=self;
            if (_match.numberOfTotalLines>_match.numberOfLimitLines) {
                self.shouldExtend=YES;
            }else{
                self.shouldExtend=NO;
            }
            parser.data=self;
        }else{
            MatchParser* parser=[self createMatch:252];
            if (parser) {
                [[WeiboData shareCacheForWeibo]  setObject:parser forKey:key];
            }
        }
    }
}
-(void)setMatch:(MatchParser *)match
{
    _match=match;
}


-(MatchParser*)createMatch:(float)width
{
    MatchParser * parser=[[MatchParser alloc]init];
    parser.keyWorkColor=[UIColor colorWithIntegerValue:HEIGHT_TEXT_COLOR alpha:1];
    parser.width=width;
    parser.numberOfLimitLines=5;
    self.numberOfLineLimit=5;
    [parser match:self.content atCallBack:^BOOL(NSString * string) {
        NSString *partInStr;
        if (![tMans isKindOfClass:[NSString class]]) {
            partInStr = [tMans JSONString];
        } else {
            partInStr = (NSString*)tMans;
        }
        NSArray *tmansArr = [ResultEx getDataArray:[PartInData class] withStr:partInStr];
        for(PartInData* part in tmansArr){
            if([NSStrUtil notEmptyOrNull:part.mid]){
                ContactData * contact=[[WeqiaAppDelegate App].dbUtil searchSingle:[ContactData class] where:[NSString stringWithFormat:@"mid='%@'",part.mid] orderBy:nil];
                if([contact.mName isEqualToString:string]){
                    return YES;
                }
            }else{
                return NO;
            }
        }
        return NO;
    }];
    _match=parser;
    self.height=_match.height;
    self.heightOflimit=parser.heightOflimit;
    self.miniWidth=parser.miniWidth;
    self.numberOfLinesTotal=parser.numberOfTotalLines;
    parser.data=self;
    if (_match.numberOfTotalLines>_match.numberOfLimitLines) {
        self.shouldExtend=YES;
    }else{
        self.shouldExtend=NO;
    }
    return parser;
}
-(void)updateMatch:(void(^)(NSMutableAttributedString * string, NSRange range))link
{
    [_match match:self.content atCallBack:^BOOL(NSString * string) {
        NSString *partInStr;
        if (![tMans isKindOfClass:[NSString class]]) {
            partInStr = [tMans JSONString];
        } else {
            partInStr = (NSString*)tMans;
        }
        NSArray *tmansArr = [ResultEx getDataArray:[PartInData class] withStr:partInStr];
        for(PartInData* part in tmansArr){
            ContactData * contact=[[WeqiaAppDelegate App].dbUtil searchSingle:[ContactData class] where:[NSString stringWithFormat:@"mid='%@' ",part.mid] orderBy:nil];
            if([contact.mName isEqualToString:string]){
                return YES;
            }
        }
        return NO;
    } title:nil link:link];
}


-(void)getWeiboReplysByType:(int)type1
{
    type=type1;
    _isGetReply=YES;
    if([NSStrUtil notEmptyOrNull:self.msgId]){
        NSArray * ary=[[WeqiaAppDelegate App].dbUtil search:[WeiboReplyData class] where:[NSString stringWithFormat:@"msgId='%@'",self.msgId]orderBy:@"gmtCreate asc" offset:0 count:MAXFLOAT];
        NSMutableArray * array=[NSMutableArray arrayWithArray:ary];
        for(WeiboReplyData * data in array){
            if(type1==2){
                data.type=2;
                [data setMatch];
            }else if(type1==1){
                data.type=1;
                [data setMatch];
            }
        }
        self.replys=array;
    }
    [self updateRepleys];
} 
-(void)deleteByReplyId:(NSString*)replyId
{
    int count=[self.replys count];
    for(int i=0;i<count;i++){
        WeiboReplyData * data=[self.replys objectAtIndex:i];
        if([data.replyId isEqual:replyId]){
            NSMutableArray * array=[NSMutableArray arrayWithArray:self.replys];
            [array removeObjectAtIndex:i];
            self.replys=array;
            [[WeqiaAppDelegate App].dbUtil deleteToDB:data];
            self.replyHeight=[WeiboCell heightForReply:self.replys];
            [[NSNotificationCenter defaultCenter] postNotificationName:HBWeiboContentUpdateNofication object:self];
            break;
        }
    } 
    ServiceParam * param=[[ServiceParam alloc]initWithMid:[WeqiaAppDelegate App].mid withItype:WEBO_DELETE_REPLY withRequestTag:WEBO_DELETE_REPLY];
    [param put:@"reId" withValue:replyId];
    [[UserService sharedInstance] getDataFromServer:nil  withParam:param withDelegate:self];
}

-(void)updateRepleys
{
    ServiceParam * param=[[ServiceParam alloc]initWithMid:[WeqiaAppDelegate App].mid withItype:WEBO_COMMENT withPrevId:nil withNextId:nil withSize:[NSNumber numberWithInt:MAXFLOAT] withRequestTag:WEBO_COMMENT];
    [param put:@"msId" withValue:self.msgId];
    [[UserService sharedInstance] getDataFromServer:param completeBlock:^(ResultEx *result) {
        [self uploadReplySuccessWithData:result];
    } failedBlock:^(NSUInteger errorCode) {
        _isGetReply=YES;
    }];
}

-(void) uploadReplySuccessWithData:(ResultEx *)data
{
    __block NSMutableArray * array=[NSMutableArray arrayWithArray:self.replys];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        _isGetReply=YES;
        BOOL update=YES;
        NSMutableArray * ary=[NSMutableArray arrayWithArray:[data getDataArray:[WeiboReplyData class]]];
        if(ary==nil&&array==nil)
            return ;
        if([ary count]==0&&[array count]==0)
            return;
        if([ary count]==[array count]){
            [array sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                WeiboReplyData * reply1=(WeiboReplyData*)obj1;
                WeiboReplyData * reply2=(WeiboReplyData*)obj2;
                if(reply1.replyId.intValue>reply2.replyId.intValue){
                    return  NSOrderedDescending;
                }else
                    return NSOrderedAscending;
            }];
            [ary sortUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                WeiboReplyData * reply1=(WeiboReplyData*)obj1;
                WeiboReplyData * reply2=(WeiboReplyData*)obj2;
                if(reply1.replyId.intValue>reply2.replyId.intValue){
                    return  NSOrderedDescending;
                }else
                    return NSOrderedAscending;
            }];
            int count=[ary count];
            for(int i=0;i<count;i++){
                WeiboReplyData * reply1=[array objectAtIndex:i];
                WeiboReplyData * reply2=[ary objectAtIndex:i];
                if(reply1.replyId.intValue!=reply2.replyId.intValue)
                {
                    update=YES;
                    break;
                }else{
                    update=NO;
                    continue;
                }
            }
        }
        if(!update)
            return ;
        [[WeqiaAppDelegate App].dbUtil deleteWithClass:[WeiboReplyData class] where:[NSString stringWithFormat:@"msgId='%@'",self.msgId]];
        for(WeiboReplyData * reply in ary)
        {
            reply.readed=1;
            NSString *tmans=nil;
            if (![reply.atmans isKindOfClass:[NSString class]]) {
                tmans = [reply.atmans JSONString];
            } else {
                tmans = reply.atmans;
            }
            reply.atmans=tmans;
            NSMutableString * title=nil;
            if([NSStrUtil notEmptyOrNull:reply.mid]){
                ContactData *contact = [[WeqiaAppDelegate App].dbUtil searchSingle:[ContactData class]where:[NSString stringWithFormat:@"mid='%@' and coId='%@'",reply.mid,[WeqiaAppDelegate App].coId] orderBy:nil];
                if(contact!=nil){
                    if([NSStrUtil notEmptyOrNull:contact.mName]){
                        title=[NSMutableString stringWithString:contact.mName];
                        if([NSStrUtil notEmptyOrNull:reply.up_mid]){
                            ContactData *up_contact = [[WeqiaAppDelegate App].dbUtil searchSingle:[ContactData class]where:[NSString stringWithFormat:@"mid='%@' and coId='%@' ",reply.up_mid,[WeqiaAppDelegate App].coId] orderBy:nil];
                            if(up_contact!=nil){
                                if([NSStrUtil notEmptyOrNull:up_contact.mName]){
                                    [title appendFormat:@" 回复 %@",up_contact.mName ];
                                }
                            }
                        }
                        [title appendFormat:@":"];
                    }
                }
            }
            [[WeqiaAppDelegate App].dbUtil insertToDB:reply];
        }
        array=ary;
        for(WeiboReplyData * data in array){
            if(type==2){
                data.type=2;
                [data setMatch];
            }else if(type==1){
                data.type=1;
                [data setMatch];
            }
        }
        self.replyHeight=[WeiboCell heightForReply:array];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (array) {
                self.replys=array;
            }
            [[NSNotificationCenter defaultCenter] postNotificationName:HBWeiboContentUpdateNofication object:self];
        });

    });
}


#pragma -mark 私有方法


@end
