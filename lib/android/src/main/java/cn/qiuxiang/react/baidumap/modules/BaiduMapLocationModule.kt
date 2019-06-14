package cn.qiuxiang.react.baidumap.modules

import android.util.Log
import com.baidu.location.BDAbstractLocationListener
import com.baidu.location.BDLocation
import com.baidu.location.LocationClient
import com.baidu.location.LocationClientOption
import com.facebook.react.bridge.*
import com.facebook.react.modules.core.DeviceEventManagerModule.RCTDeviceEventEmitter
import java.text.SimpleDateFormat
import java.util.*
import com.baidu.mapapi.utils.DistanceUtil
import cn.qiuxiang.react.baidumap.toLatLng

@Suppress("unused")
class BaiduMapLocationModule(context: ReactApplicationContext) : ReactContextBaseJavaModule(context) {
    private val client = LocationClient(context.applicationContext)
    private val emitter by lazy { context.getJSModule(RCTDeviceEventEmitter::class.java) }
    private val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.CHINA)

    init {

        val mOption = LocationClientOption()
        mOption.locationMode = LocationClientOption.LocationMode.Hight_Accuracy//可选，默认高精度，设置定位模式，高精度，低功耗，仅设备
        mOption.setCoorType("bd09ll")//可选，默认gcj02，设置返回的定位结果坐标系，如果配合百度地图使用，建议设置为bd09ll;
        mOption.setScanSpan(3000)//可选，默认0，即仅定位一次，设置发起连续定位请求的间隔需要大于等于1000ms才是有效的
        mOption.setIsNeedAddress(false)//可选，设置是否需要地址信息，默认不需要
        mOption.setIsNeedLocationDescribe(false)//可选，设置是否需要地址描述
        mOption.setNeedDeviceDirect(false)//可选，设置是否需要设备方向结果
        mOption.isLocationNotify = false//可选，默认false，设置是否当gps有效时按照1S1次频率输出GPS结果
        mOption.setIgnoreKillProcess(false)//可选，默认true，定位SDK内部是一个SERVICE，并放到了独立进程，设置是否在stop的时候杀死这个进程，默认不杀死
        mOption.setIsNeedLocationDescribe(false)//可选，默认false，设置是否需要位置语义化结果，可以在BDLocation.getLocationDescribe里得到，结果类似于“在北京天安门附近”
        mOption.setIsNeedLocationPoiList(false)//可选，默认false，设置是否需要POI结果，可以在BDLocation.getPoiList里得到
        mOption.SetIgnoreCacheException(false)//可选，默认false，设置是否收集CRASH信息，默认收集
        mOption.isOpenGps = true//可选，默认false，设置是否开启Gps定位
        mOption.setIsNeedAltitude(false)//可选，默认false，设置定位时是否需要海拔信息，默认不需要，除基础定位版本都可用
        client.locOption = mOption
        client.registerLocationListener(object : BDAbstractLocationListener() {
            override fun onReceiveLocation(location: BDLocation) {
                Log.e("Location", "获取到定位信息："+location.toString());
                val data = Arguments.createMap()
                data.putInt("timestamp", (dateFormat.parse(location.time).time / 1000).toInt())
                data.putString("coordinateType", location.coorType)
                data.putDouble("accuracy", location.radius.toDouble())
                data.putDouble("latitude", location.latitude)
                data.putDouble("longitude", location.longitude)
                data.putDouble("altitude", location.altitude)
                data.putDouble("speed", location.speed.toDouble())
                data.putDouble("direction", location.direction.toDouble())
                data.putInt("locationType", location.locType) // todo: to string
                emitter.emit("baiduMapLocation", data)
            }

            override fun onConnectHotSpotMessage(p0: String?, p1: Int) {
                super.onConnectHotSpotMessage(p0, p1)
                Log.e("Location", p0+p1)
            }

            override fun onLocDiagnosticMessage(p0: Int, p1: Int, p2: String?) {
                super.onLocDiagnosticMessage(p0, p1, p2)
                Log.e("Location", p2+p0+p1)
            }
        })
    }

    override fun getName(): String {
        return "BaiduMapLocation"
    }

    override fun canOverrideExistingModule(): Boolean {
        return true
    }

    @ReactMethod
    fun setOptions(options: ReadableMap) {
        val option = client.locOption

        if (options.hasKey("gps")) {
            option.isOpenGps = options.getBoolean("gps")
        }

        if (options.hasKey("distanceFilter")) {
            option.autoNotifyMinDistance = options.getInt("distanceFilter")
        }

        client.locOption = option
    }

    @ReactMethod
    fun start() {
        client.start()
    }

    @ReactMethod
    fun stop() {
        client.stop()
    }

    @ReactMethod
    fun getDistance(coordinate1: ReadableMap, coordinate2: ReadableMap, promise: Promise?){
        var c1 = coordinate1.toLatLng()
        var c2 = coordinate2.toLatLng()
        var distance = DistanceUtil.getDistance(c1, c2)
        val data = Arguments.createMap()
        data.putDouble("distance", distance)
        promise?.resolve(data)
    }

}
