#import <React/RCTBridgeModule.h>
#import <BaiduMapAPI_Search/BMKGeocodeSearch.h>
#import <BaiduMapAPI_Search/BMKSearchComponent.h>
#import <BaiduMapAPI_Utils/BMKUtilsComponent.h>

@interface RCTGeocodeModule : NSObject <RCTBridgeModule, BMKGeoCodeSearchDelegate, BMKPoiSearchDelegate>
@end

@implementation RCTGeocodeModule {
    BMKGeoCodeSearch *_search;
    BMKPoiSearch* _poiSearch;
    CLLocationCoordinate2D selfLocation;
    RCTPromiseResolveBlock _resolve;
    RCTPromiseRejectBlock _reject;
    RCTPromiseResolveBlock _poiresolve;
    RCTPromiseRejectBlock _poireject;
}

RCT_EXPORT_MODULE(BaiduMapGeocode)

RCT_EXPORT_METHOD(search:(NSString *)address
                    city:(NSString *)city
      searchWithResolver:(RCTPromiseResolveBlock)resolve
                rejecter:(RCTPromiseRejectBlock)reject) {
    BMKGeoCodeSearchOption *option = [[BMKGeoCodeSearchOption alloc] init];
    option.city = city;
    option.address = address;
    _resolve = resolve;
    _reject = reject;
    if (!_search) {
        _search = [[BMKGeoCodeSearch alloc] init];
        _search.delegate = self;
    }
    [_search geoCode:option];
}

RCT_EXPORT_METHOD(reverse:(CLLocationCoordinate2D)coordinate
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    BMKReverseGeoCodeSearchOption *option = [[BMKReverseGeoCodeSearchOption alloc] init];
    option.location = coordinate;
    _resolve = resolve;
    _reject = reject;
    if (!_search) {
        _search = [BMKGeoCodeSearch new];
        _search.delegate = self;
    }
    [_search reverseGeoCode:option];
}

RCT_EXPORT_METHOD(suggestPois:(CLLocationCoordinate2D)coordinate mycoord:(CLLocationCoordinate2D)mycoord 
                  keyword:(NSString*)keyword radius:(int)bounds page:(int)page pageSize:(int)pageSize sortType:(int)sortType
                  resovler:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    _poiresolve = resolve;
    _poireject = reject;
    if (!_poiSearch){
        _poiSearch = [[BMKPoiSearch alloc] init];
        _poiSearch.delegate = self;
    }
    selfLocation = mycoord;
    BMKPOINearbySearchOption* option = [[BMKPOINearbySearchOption alloc] init];
    option.location = coordinate;
    option.keywords = [keyword componentsSeparatedByString:@"$"];
    option.radius = bounds;
    option.pageIndex = page;
    option.pageSize = pageSize;
    [_poiSearch poiSearchNearBy:option];
}

RCT_EXPORT_METHOD(searchByKeyWord:(CLLocationCoordinate2D)mycoord city:(NSString*)city keyword:(NSString*)keyword page:(int)page pageSize:(int)pageSize
                  resovler:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject){
    _poiresolve = resolve;
    _poireject = reject;
    if (!_poiSearch){
        _poiSearch = [[BMKPoiSearch alloc] init];
        _poiSearch.delegate = self;
    }
    selfLocation = mycoord;
    BMKPOICitySearchOption* option = [[BMKPOICitySearchOption alloc] init];
    option.city = city;
    option.keyword = keyword;
    option.pageIndex = page;
    option.pageSize = pageSize;
    [_poiSearch poiSearchInCity:option];
}

RCT_EXPORT_METHOD(cancelSearch){
        _reject = nil;
        _resolve = nil;
        _poiresolve = nil;
        _poireject = nil;
}

- (void)onGetGeoCodeResult:(BMKGeoCodeSearch *)searcher result:(BMKGeoCodeSearchResult *)result errorCode:(BMKSearchErrorCode)error {
    if (error == BMK_SEARCH_NO_ERROR) {
        if (_resolve){
            _resolve(@{
                @"latitude": @(result.location.latitude),
                @"longitude": @(result.location.longitude),
                @"address": @"",
            });
        }
        _resolve = nil;
        _reject = nil;
    } else {
        // TODO: provide error message
        if (_reject){
             _reject(@"", @"", nil);
        }
        _resolve = nil;
        _reject = nil;
    }
}

- (void)onGetReverseGeoCodeResult:(BMKGeoCodeSearch *)searcher
                           result:(BMKReverseGeoCodeSearchResult *)result
                        errorCode:(BMKSearchErrorCode)error {
    if (error == BMK_SEARCH_NO_ERROR) {
        if (_resolve){
            _resolve(@{
                @"latitude": @(result.location.latitude),
                @"longitude": @(result.location.longitude),
                @"country": result.addressDetail.country,
                @"countryCode": result.addressDetail.countryCode,
                @"province": result.addressDetail.province,
                @"city": result.addressDetail.city,
                @"cityCode": result.cityCode,
                @"street": result.addressDetail.streetName,
                @"streetNumber": result.addressDetail.streetNumber,
                @"adCode": result.addressDetail.adCode,
                @"businessCircle": result.businessCircle,
                @"address": result.address,
                @"description": result.sematicDescription,
            });
            _resolve = nil;
            _reject = nil;
        }
    } else {
        // TODO: provide error message
        if (_reject){
            _reject(@"", @"", nil);
        }
        _resolve = nil;
        _reject = nil;
    }
}

- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPOISearchResult*)poiResult errorCode:(BMKSearchErrorCode)errorCode{
    if (errorCode == BMK_SEARCH_NO_ERROR){
        NSMutableArray* arr = [NSMutableArray arrayWithCapacity:10];
        for (int i = 0; i < poiResult.poiInfoList.count;++i){
            BMKPoiInfo* info = [poiResult.poiInfoList objectAtIndex:i];
            CLLocationDistance distance = 0;
            if (selfLocation.latitude > 0){
                BMKMapPoint point1 = BMKMapPointForCoordinate(selfLocation);
                BMKMapPoint point2 = BMKMapPointForCoordinate(info.pt);
                distance = BMKMetersBetweenMapPoints(point1, point2);
            }
            [arr addObject: @{
                              @"latitude":@(info.pt.latitude),
                              @"longitude":@(info.pt.longitude),
                              @"address":info.address,
                              @"name":info.name,
                              @"distance":[NSNumber numberWithDouble:distance]
                              }];
        }
        if (_poiresolve){
            _poiresolve(arr);
        }
        _poireject = nil;
        _poiresolve = nil;
    }else {
        if (_poireject){
            _poireject(@"Find Error", @"", nil);
        }
        _poireject = nil;
        _poiresolve = nil;
    }
}



@end
