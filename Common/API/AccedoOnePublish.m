//
//  AccedoOnePublish.m
//  AccedoOne
//
//  Copyright (c) 2017 - present Accedo Broadband AB. All Rights Reserved
//  Unauthorized copying of this file, via any medium is strictly prohibited
//  Proprietary and confidential
//

#import "AccedoOnePublish.h"
#import "AccedoOne.h"
#import "AOCMSOptionalParams.h"
#import "AOPagingMetadata.h"
#import "AOAsynchBlockOperation.h"

static NSString *const kPathContents         = @"content/entries";
static NSString *const kPathLocales          = @"locales";

@interface AccedoOnePublish ()
@property (nonatomic, strong) AccedoOne * service;
@property (nonatomic, strong) NSOperationQueue *queue;
@end

@implementation AccedoOnePublish

-(instancetype) initWithService:(AccedoOne *) service {
    if (self = [super init]){
        _service = service;
        self.queue         = [NSOperationQueue new];
        self.queue.maxConcurrentOperationCount = 1; //FIFO with respect to operation order...
    }
    return self;
}

- (void) entryForId:(NSString*)entryId onComplete:(void (^)(NSDictionary *entry, AOError *err))completionBlock {
    if (! entryId) {
        if (completionBlock) completionBlock(nil, [AOError errorWithMessage:@"AccedoOneService: 'entryId' cannot be null!"]);
        return;
    }
    
    AOCMSOptionalParams * params = [[AOCMSOptionalParams params] paramWithPreview:NO];
    
    [self entryForId:entryId optionalParams:params onComplete:completionBlock];
}

- (void) entryForId:(NSString*)entryId optionalParams:(AOCMSOptionalParams *)params onComplete:(void (^)(NSDictionary *entry, AOError *err))completionBlock {
    if (! entryId) {
        if (completionBlock) completionBlock(nil, [AOError errorWithMessage:@"AccedoOneService: 'entryId' cannot be null!"]);
        return;
    }
    
    [self entriesForIds:@[entryId] optionalParams:params onComplete:^(NSArray *contents, AOError *err) {
        if (completionBlock) completionBlock([contents firstObject], err);
    }];
}

- (void) entriesForIds:(NSArray*)contentIds onComplete:(void (^)(NSArray *entries, AOError *err))completionBlock {
    AOCMSOptionalParams * params = [[AOCMSOptionalParams params] paramWithPreview:NO];
    [self entriesForIds:contentIds optionalParams:params onComplete:completionBlock];
}

- (void) entriesForIds:(NSArray*)contentIds optionalParams:(AOCMSOptionalParams *)params onComplete:(void(^)(NSArray *entries, AOError *err))completionBlock {
    [self entriesForList:contentIds parameter:@"id" optionalParams:params onComplete:completionBlock];
}

- (void) entriesForAliases:(nonnull NSArray<__kindof NSString*>*)aliases onComplete:(nullable void (^)(NSArray *entries, AOError *err))completionBlock {
    AOCMSOptionalParams * params = [[AOCMSOptionalParams params] paramWithPreview:NO];
    [self entriesForAliases:aliases optionalParams:params onComplete:completionBlock];
}

- (void) entriesForAliases:(nonnull NSArray<__kindof NSString*>*)aliases optionalParams:(nullable AOCMSOptionalParams *)params onComplete:(nullable void(^)(NSArray *entries, AOError *err))completionBlock {
    [self entriesForList:aliases parameter:@"alias" optionalParams:params onComplete:completionBlock];
}

- (void) entriesForTypeAlias:(nonnull NSString*)alias onComplete:(nullable void (^)(NSArray *entries, AOError *err))completionBlock {
    AOCMSOptionalParams * params = [[AOCMSOptionalParams params] paramWithPreview:NO];
    [self entriesForTypeAlias:alias optionalParams:params onComplete:completionBlock];
}

- (void) entriesForTypeAlias:(nonnull NSString*)alias optionalParams:(nullable AOCMSOptionalParams *)params onComplete:(nullable void(^)(NSArray *entries, AOError *err))completionBlock {
    [self entriesForList:@[alias] parameter:@"typeAlias" optionalParams:params onComplete:completionBlock];
}

- (void) entriesForType:(NSString *)typeId onComplete:(void (^)(AOPageResult *result, AOError *err))completionBlock {
    if (! typeId) {
        if (completionBlock) completionBlock(nil, [AOError errorWithMessage:@"AccedoOneService: 'typeId' cannot be null!"]);
        return;
    }
    
    AOCMSOptionalParams *params = [[AOCMSOptionalParams params] paramWithPreview:NO];
    [self entriesForType:typeId optionalParams:params onComplete:completionBlock];
}

- (void) entriesForType:(NSString *)typeId optionalParams:(AOCMSOptionalParams *)params onComplete:(void(^)(AOPageResult *result, AOError *err))completionBlock {
    if (! typeId) {
        if (completionBlock) completionBlock(nil, [AOError errorWithMessage:@"AccedoOneService: 'typeId' cannot be null!"]);
        return;
    }
    
    if (!params) {
        //if not provided, set to default...
        params = [[AOCMSOptionalParams params] paramWithPreview:NO];
    }
    
    NSMutableDictionary * paramsDict = [params paramsDictionary];
    
    paramsDict[@"typeId"] = typeId; //entryTypeId
    
    [self.service sendAuthenticatedGETRequest:kPathContents queryParams:paramsDict allowCache:NO onSuccess:^(id response)
     {
         NSArray * entries = @[];
         
         if (response[@"entries"]) {
             entries = response[@"entries"];
         }
         
         AOPageData * pageData = nil;
         
         NSUInteger total = [entries count];
         
         if (response[@"pagination"]) {
             total             = [response[@"pagination"][@"total"] unsignedLongValue];
             NSUInteger offset = [response[@"pagination"][@"offset"] unsignedLongValue];
             NSUInteger size   = [response[@"pagination"][@"size"] unsignedLongValue];
             
             pageData = [AOPageData pageDataWithOffset:offset pageSize:size];
         }
         
         AOPageResult * pageResult = [AOPageResult pageResultWithContent:entries pageData:pageData totalCount:total];
         
         if (completionBlock) {
             completionBlock(pageResult, nil);
         }
     }
                         failureBlock:^(AOError *error)
     {
         if (completionBlock) {
             completionBlock(nil, error);
         }
     }];
}

- (void) allEntries:(void (^)(AOPageResult *result, AOError *err))completionBlock
{
    AOCMSOptionalParams *params = [AOCMSOptionalParams params];
    [self allEntriesForParams:params onComplete:completionBlock];
}

- (void) allEntriesForParams:(AOCMSOptionalParams *)params onComplete:(void (^)(AOPageResult *result, AOError *err))completionBlock
{
    NSMutableDictionary * paramsDict = [params paramsDictionary];
    
    [self.service sendAuthenticatedGETRequest:kPathContents queryParams:paramsDict allowCache:NO onSuccess:^(id response)
     {
         NSArray * entries = @[];
         
         if (response[@"entries"]) {
             entries = response[@"entries"];
         }
         
         AOPageData * pageData = nil;
         
         NSUInteger total = [entries count];
         
         if (response[@"pagination"]) {
             total             = [response[@"pagination"][@"total"] unsignedLongValue];
             NSUInteger offset = [response[@"pagination"][@"offset"] unsignedLongValue];
             NSUInteger size   = [response[@"pagination"][@"size"] unsignedLongValue];
             
             pageData = [AOPageData pageDataWithOffset:offset pageSize:size];
         }
         
         AOPageResult * pageResult = [AOPageResult pageResultWithContent:entries pageData:pageData totalCount:total];
         
         if (completionBlock) {
             completionBlock(pageResult, nil);
         }
     }
                         failureBlock:^(AOError *error)
     {
         if (completionBlock) {
             completionBlock(nil, error);
         }
     }];
}

-(void) localesOnComplete:(nullable void (^)(NSArray *_Nullable locales, AOError *_Nullable err))completionBlock
{
    if (self.service.serviceAvailability == AccedoOneServiceAvailabilityOnline)
    {
        [self.service sendAuthenticatedGETRequest:kPathLocales queryParams:nil allowCache:NO onSuccess:^(NSDictionary *response)
         {
             [self.service addDictionary:response toOfflineAccedoOneConfigWithKey:kPathLocales];
             
             if (completionBlock) {
                 completionBlock(response[@"locales"], nil);
             }
         }
                             failureBlock:^(AOError *error)
         {
             if (completionBlock) {
                 completionBlock(nil, error);
             }
         }];
    }
    else
    {
        NSDictionary * cachedResource = [self.service dictionaryFromOfflineAccedoOneConfigWithKey:kPathLocales];
        
        if (completionBlock) {
            completionBlock(cachedResource[@"locales"], cachedResource[@"locales"] ? nil : [AOError errorWithMessage:@"Offline metadata not present!"]);
        }
    }
}

#pragma mark - Helpers (entry fetching)
//helper used by: entriesForIds, entriesForAliases, entriesForAliasType
- (void) entriesForList:(nonnull NSArray<__kindof NSString*>*)paramList parameter:(NSString *)param optionalParams:(nullable AOCMSOptionalParams *)params onComplete:(nullable void(^)(NSArray *entries, AOError *err))completionBlock {
    
    NSUInteger totalCount = [paramList count];
    
    if (totalCount <= 0) {
        if (completionBlock) completionBlock(nil, [AOError errorWithMessage:@"AccedoOneService: 'contentIds' array cannot be empty!"]);
        return;
    }
    
    if (!params) {
        //if not provided, set to default...
        params = [[AOCMSOptionalParams params] paramWithPreview:NO];
    }
    
    int offset           = 0;
    int defaultPageSize  = 50; //AccedoOne max...
    int calculatedLength = params.size ? [params.size intValue] : defaultPageSize;
    long length          = MIN (calculatedLength, totalCount); // just to make sure, we do not fetch more than what we have...
    
    __block NSMutableArray* result = [NSMutableArray arrayWithCapacity:totalCount];
    __block AOError * blockError = Nil;
    for (long i = offset; i < totalCount; i += length)
    {
        NSArray *paramsToProcess = [paramList subarrayWithRange:NSMakeRange(offset, length)];
        NSString *contentIdsStr  = [paramsToProcess componentsJoinedByString:@","];
        
        NSMutableDictionary *paramsDict = [params paramsDictionary];
        paramsDict[param]     = contentIdsStr; //param could be: "id", "alies", "typeAlias".
        paramsDict[@"offset"] = params.offset ? params.offset : @(offset);
        paramsDict[@"size"]   = params.size   ? params.size   : @(defaultPageSize);
        
        AOAsynchBlockOperation *operation = [AOAsynchBlockOperation new];
        __weak AOAsynchBlockOperation *weakOp = operation;
        
        [operation addOperationBlock:^
         {
             [self.service sendAuthenticatedGETRequest:kPathContents queryParams:paramsDict allowCache:NO onSuccess:^(id response) {
                 if (response[@"entries"]) {
                     [result addObjectsFromArray:response[@"entries"]];
                 }
                 //NSLog(@"total count: %d, entry count: %d", totalCount, result.count);
                 
                 [weakOp markAsFinished];
             } failureBlock:^(AOError *error) {
                 blockError = error;
                 [weakOp markAsFinished];
             }];
         }];
        
        [self.queue addOperation:operation];
        
        offset += length;
        length = MIN (defaultPageSize, totalCount - offset);
        
        if (length <= 0) break;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [_queue waitUntilAllOperationsAreFinished];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            
            NSString *entriesCacheKey = [NSString stringWithFormat:@"%@-%@-%@", kPathContents, [paramList componentsJoinedByString:@"+"], [params stringValue]];
            //cache for AccedoOne offline usage...
            if (result.count > 0) {
                [self.service addDictionary:@{@"kOfflineEntries":result} toOfflineAccedoOneConfigWithKey:entriesCacheKey];
            }
            
            if (completionBlock) {
                if (self.service.serviceAvailability == AccedoOneServiceAvailabilityOnline) {
                    completionBlock(blockError ? nil: result, blockError);
                } else {
                    // attempt to retrieve from cache...
                    NSDictionary * cachedResource = [self.service dictionaryFromOfflineAccedoOneConfigWithKey:entriesCacheKey];
                    AOError * resultError = blockError ? blockError : [AOError errorWithMessage:@"Offline metadata not present!"];
                    completionBlock(cachedResource[@"kOfflineEntries"], cachedResource ? nil : resultError );
                }
            }
            
        });
    });
}

@end