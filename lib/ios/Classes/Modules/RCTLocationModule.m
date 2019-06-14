#import <React/RCTEventEmitter.h>
#import <BMKLocationkit/BMKLocationComponent.h>
#import "RCTUserLocation.h"

@interface RCTLocationModule : RCTEventEmitter <RCTBridgeModule, BMKLocationManagerDelegate>
@end

@implementation RCTLocationModule {
    BMKLocationManager *_service;
    RCTUserLocation *_location;
    BOOL _initialized;
}

RCT_EXPORT_MODULE(BaiduMapLocation)

RCT_EXPORT_METHOD(setOptions:(NSDictionary *)options) {
    if (options[@"distanceFilter"]) {
        _service.distanceFilter = [options[@"distanceFilter"] doubleValue];
    }
}

RCT_REMAP_METHOD(init, resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    if (!_initialized) {
        _initialized = YES;
        _location = [[RCTUserLocation alloc] init];
        dispatch_async(dispatch_get_main_queue(), ^{
            _service = [[BMKLocationManager alloc] init];
            _service.delegate = self;
            _service.coordinateType = BMKLocationCoordinateTypeBMK09LL;
            _service.desiredAccuracy = kCLLocationAccuracyBest;
            _service.activityType = CLActivityTypeAutomotiveNavigation;
            _service.pausesLocationUpdatesAutomatically = NO;
            _service.allowsBackgroundLocationUpdates = NO;
            _service.locationTimeout = 10;
            resolve(nil);
        });
    } else {
        resolve(nil);
    }
}

RCT_EXPORT_METHOD(start) {
    [_service startUpdatingLocation];
}

RCT_EXPORT_METHOD(stop) {
    [_service stopUpdatingLocation];
}

RCT_EXPORT_METHOD(getDistance:(CLLocationCoordinate2D)coordinate1 dest:(CLLocationCoordinate2D)coordinate2 resovler:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    BMKMapPoint point1 = BMKMapPointForCoordinate(coordinate1);
    BMKMapPoint point2 = BMKMapPointForCoordinate(coordinate2);
    CLLocationDistance distance = BMKMetersBetweenMapPoints(point1, point2);
    resolve(@{@"distance": [NSNumber numberWithDouble:distance]});
}

#pragma mark - BMKLocationManagerDelegate
/**
 @brief 当定位发生错误时，会调用代理的此方法
 @param manager 定位 BMKLocationManager 类
 @param error 返回的错误，参考 CLError
 */
- (void)BMKLocationManager:(BMKLocationManager * _Nonnull)manager didFailWithError:(NSError * _Nullable)error {
    NSLog(@"定位失败");
}

/**
 @brief 该方法为BMKLocationManager提供设备朝向的回调方法
 @param manager 提供该定位结果的BMKLocationManager类的实例
 @param heading 设备的朝向结果
 */
- (void)BMKLocationManager:(BMKLocationManager *)manager didUpdateHeading:(CLHeading *)heading {
    if (!heading) {
        return;
    }
    NSLog(@"用户方向更新");
}

/**
 @brief 连续定位回调函数
 @param manager 定位 BMKLocationManager 类
 @param location 定位结果，参考BMKLocation
 @param error 错误信息。
 */
- (void)BMKLocationManager:(BMKLocationManager *)manager didUpdateLocation:(BMKLocation *)location orError:(NSError *)error {
    if (error) {
        NSLog(@"locError:{%ld - %@};", (long)error.code, error.localizedDescription);
    }
    if (!location) {
        return;
    }
    [_location updateWithCLLocation:location.location];
    [self sendEventWithName:@"baiduMapLocation" body: _location.json];
}


- (NSArray<NSString *> *)supportedEvents {
    return @[@"baiduMapLocation"];
}

@end
