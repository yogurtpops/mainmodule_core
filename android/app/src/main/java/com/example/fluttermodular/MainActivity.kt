package com.example.fluttermodular

import android.os.Bundle
import android.util.Log
import com.google.android.play.core.assetpacks.*
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.*

class MainActivity: FlutterActivity(), MethodChannel.MethodCallHandler {

    val FLUTTER_METHOD = "playasset"
    val CHANNEL = "basictomodular/downloadservice"
    lateinit var methodChannel: MethodChannel
    lateinit var assetPackManager: AssetPackManager

//    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
//        super.configureFlutterEngine(flutterEngine)
//        GeneratedPluginRegistrant.registerWith(flutterEngine)
//    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        methodChannel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler(::onMethodCall)
        assetPackManager = AssetPackManagerFactory.getInstance(this.applicationContext)
//        assetPackManager!!.registerListener(mAssetPackStateUpdateListener)
    }

//    var mAssetPackStateUpdateListener: AssetPackStateUpdateListener = object : AssetPackStateUpdateListener {
//        override fun onStateUpdate(state: AssetPackState) {
//            Log.d("puzzle", "mAssetPackStateUpdateListener onStateUpdate state: " + state.status())
//        }
//    }

//    override fun onDestroy() {
//        assetPackManager!!.unregisterListener(mAssetPackStateUpdateListener)
//        super.onDestroy()
//    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method=="get_asset"){
            getAbsoluteAssetPath(call.arguments.toString())
        } else if (call.method=="download_asset"){
            downloadPack(call.arguments.toString())
        }
    }

    private fun getAbsoluteAssetPath(assetPack: String) {
        methodChannel.invokeMethod(FLUTTER_METHOD, "Checking asset path...")
        val assetPackPath = assetPackManager!!.getPackLocation(assetPack)
        val assetsFolderPath = assetPackPath?.assetsPath()
        if (assetsFolderPath!=null){
            try {
                val file = File(assetsFolderPath)
                if (file.isDirectory) {
                    methodChannel.invokeMethod(FLUTTER_METHOD, assetsFolderPath)
                } else {
                    methodChannel.invokeMethod(FLUTTER_METHOD, "Error: " +assetsFolderPath+" not directory...")
                }
            } catch (e: Exception){
                methodChannel.invokeMethod(FLUTTER_METHOD, "Error: " + e.message + "...")
            }
        } else {
            methodChannel.invokeMethod(FLUTTER_METHOD, assetsFolderPath+" is null...")
            downloadPack(assetPack)
        }
    }

    private fun downloadPack(assetPack: String){
        methodChannel.invokeMethod(FLUTTER_METHOD, "Start download pack "+ assetPack +"...")
        val list: MutableList<String> = ArrayList()
        list.add(assetPack)
        assetPackManager!!.fetch(list).addOnSuccessListener {
            methodChannel.invokeMethod(FLUTTER_METHOD, "Success download pack "+ assetPack +"...")
            getAbsoluteAssetPath(assetPack)
        }.addOnFailureListener {
            methodChannel.invokeMethod(FLUTTER_METHOD, "Failed download pack "+ assetPack +"...")
        }
    }
}

