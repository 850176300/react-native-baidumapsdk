package cn.qiuxiang.react.baidumap.modules

import cn.qiuxiang.react.baidumap.toLatLng
import cn.qiuxiang.react.baidumap.toWritableMap
import com.baidu.mapapi.model.LatLng
import com.baidu.mapapi.search.core.PoiInfo
import com.baidu.mapapi.search.core.SearchResult
import com.baidu.mapapi.search.geocode.*
import com.baidu.mapapi.search.poi.*
import com.baidu.mapapi.utils.DistanceUtil
import com.facebook.react.bridge.*

@Suppress("unused")
class BaiduMapGeocodeModule(context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {
    private var selfLocation: LatLng? = null;
    private var promise: Promise? = null
    private var poiPromise: Promise? = null
    private val geoCoder by lazy {
        val geoCoder = GeoCoder.newInstance()
        geoCoder.setOnGetGeoCodeResultListener(object : OnGetGeoCoderResultListener {
            override fun onGetGeoCodeResult(result: GeoCodeResult?) {
                if (result == null || result.error != SearchResult.ERRORNO.NO_ERROR) {
                    // TODO: provide error message
                    promise?.reject("", "")
                } else {
                    val data = Arguments.createMap()
                    data.putString("address", result.address)
                    data.putDouble("latitude", result.location.latitude)
                    data.putDouble("longitude", result.location.longitude)
                    promise?.resolve(data)
                }
                promise = null
            }

            override fun onGetReverseGeoCodeResult(result: ReverseGeoCodeResult?) {
                if (result == null || result.error != SearchResult.ERRORNO.NO_ERROR) {
                    // TODO: provide error message
                    promise?.reject("ReverseGeoCodeError", "resutlt:"+result?.error)
                } else {
                    val data = result.location.toWritableMap()
                    data.putString("country", result.addressDetail.countryName)
                    data.putString("countryCode", result.addressDetail.countryCode.toString())
                    data.putString("province", result.addressDetail.province)
                    data.putString("city", result.addressDetail.city)
                    data.putString("cityCode", result.cityCode.toString())
                    data.putString("district", result.addressDetail.district)
                    data.putString("street", result.addressDetail.street)
                    data.putString("streetNumber", result.addressDetail.streetNumber)
                    data.putString("adCode", result.addressDetail.adcode.toString())
                    data.putString("businessCircle", result.businessCircle)
                    data.putString("address", result.address)
                    data.putString("description", result.sematicDescription)
                    promise?.resolve(data)
                }
                promise = null
            }
        })
        geoCoder
    }

    private val poiSearcher by lazy {
        var searcher = PoiSearch.newInstance()
        searcher.setOnGetPoiSearchResultListener(object : OnGetPoiSearchResultListener{
            override fun onGetPoiResult(p0: PoiResult?)  {
                if (p0 == null || p0.error != SearchResult.ERRORNO.NO_ERROR){
                    poiPromise?.reject("SearchPoiCodeError", "resutlt:"+p0?.error)
                }else {
                    var results = Arguments.createArray()
                    p0?.allPoi.forEach(fun(addr:PoiInfo){
                        var distance = 0.0
                        if (selfLocation !=null){
                            distance = DistanceUtil.getDistance(selfLocation, addr.location)
                        }
                        var data = addr.location.toWritableMap()
                        data.putString("address", addr.address)
                        data.putString("name", addr.name)
                        data.putDouble("distance", distance)
                        data.putString("uid", addr.uid)
                        results.pushMap(data)

                    })
                    poiPromise?.resolve(results)
                }
                poiPromise = null
            }

            override fun onGetPoiDetailResult(var1: PoiDetailSearchResult){

            }

            override fun onGetPoiIndoorResult(var1: PoiIndoorResult){

            }

            override fun onGetPoiDetailResult(var1: PoiDetailResult){

            }
        })
        searcher
    }


    override fun getName(): String {
        return "BaiduMapGeocode"
    }

    override fun canOverrideExistingModule(): Boolean {
        return true
    }

    @ReactMethod
    fun search(address: String, city: String, promise: Promise) {
        if (this.promise == null) {
            this.promise = promise
            geoCoder.geocode(GeoCodeOption().address(address).city(city))
        } else {
            promise.reject("", "This callback type only permits a single invocation from native code")
        }
    }

    @ReactMethod
    fun reverse(coordinate: ReadableMap, promise: Promise) {
        if (this.promise == null) {
            this.promise = promise
            geoCoder.reverseGeoCode(ReverseGeoCodeOption().location(coordinate.toLatLng()))
        } else {
            promise.reject("", "This callback type only permits a single invocation from native code")
        }
    }

    @ReactMethod
    fun suggestPois(coordinate: ReadableMap, mycoord:ReadableMap, keyword: String, bounds:Int, page: Int, pageSize:Int, sortyType:Int, promise: Promise){
        if (this.poiPromise == null){
            this.poiPromise = promise
            selfLocation = mycoord.toLatLng()
            var option = PoiNearbySearchOption()
            option.location(coordinate.toLatLng())
            option.keyword(keyword)
            option.radius(bounds)
            option.pageNum(page)
            option.pageCapacity(pageSize)
            option.sortType = if (sortyType == 1)  PoiSortType.distance_from_near_to_far else PoiSortType.comprehensive
            poiSearcher.searchNearby(option)

        }else {
            promise.reject("", "This callback type only permits a single invocation from native code")
        }
    }

    @ReactMethod
    fun searchByKeyWord(mycoord: ReadableMap, city: String, keyword:String, page:Int, pageSize:Int, promise: Promise){
        if (this.poiPromise == null){
            this.poiPromise = promise
            selfLocation = mycoord.toLatLng()
            var option = PoiCitySearchOption()
            option.mCity = city
            option.mKeyword = keyword
            option.pageNum(page)
            option.pageCapacity(pageSize)
            poiSearcher.searchInCity(option)
        }else {
            promise.reject("", "This callback type only permits a single invocation from native code")
        }
    }

    @ReactMethod
    fun cancelSearch(){
        if (this.poiPromise != null){
            this.poiPromise = null
        }
        if (this.promise != null){
            this.promise = null
        }
    }
}
