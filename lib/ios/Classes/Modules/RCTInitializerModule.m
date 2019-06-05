#import <React/RCTBridgeModule.h>
#import <BaiduMapAPI_Base/BMKMapManager.h>
#import <BMKLocationKit/BMKLocationComponent.h>

@interface RCTInitializerModule : NSObject <RCTBridgeModule, BMKLocationAuthDelegate, BMKGeneralDelegate>
@end

@implementation RCTInitializerModule {
    BMKMapManager *_manager;
    RCTPromiseResolveBlock _resolve;
    RCTPromiseRejectBlock _reject;
}

RCT_EXPORT_MODULE(BaiduMapInitializer)

RCT_REMAP_METHOD(init, key:(NSString *)key resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    if (!_manager) {
        _manager = [[BMKMapManager alloc] init];
    }
    [[BMKLocationAuth sharedInstance] checkPermisionWithKey:key authDelegate:self];
    _resolve = resolve;
    _reject = reject;
    BOOL isInit = [_manager start:key generalDelegate:self];
    if (isInit == NO){
        NSLog(@"百度地图引擎初始化失败");
    }
}

- (void)onGetPermissionState:(int)error {
    if (error) {
        // TODO: provide error message
        _reject([NSString stringWithFormat:@"%d", error], @"", nil);
    } else {
        _resolve(nil);
    }
}

-(void)onCheckPermissionState:(BMKLocationAuthErrorCode)iError{
    NSLog(@"权限检测结果：%d", (int)iError);
}

@end
