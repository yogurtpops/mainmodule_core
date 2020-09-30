package com.example.fluttermodular

import android.annotation.SuppressLint
import android.app.PendingIntent
import android.content.Intent
import android.content.pm.PackageManager
import android.os.AsyncTask
import android.os.Bundle
import android.os.Messenger
import android.os.SystemClock
import android.util.Log
import android.view.View
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import src.com.DownloaderService
import src.com.DownloaderServiceBroadcastReceiver
import src.com.android.vending.expansion.zipfile.ZipResourceFile
import src.com.google.android.vending.expansion.downloader.*
import java.io.*
import java.util.zip.CRC32
import java.util.zip.ZipEntry
import java.util.zip.ZipInputStream


class MainActivity: FlutterActivity(), IDownloaderClient, MethodChannel.MethodCallHandler {

    val TAG = "Main Activity....."
    val DOWNLOAD_TAG_METHOD = "updateDownloadState"
    val DONE_EXTRACT = "done_extraxt"
    val EXTRACT_FAILED = "extract_failed"
    val START_EXTRACT = "start_extraxt"

    val CHANNEL = "basictomodular/downloadservice"
    var myReceiver: DownloaderServiceBroadcastReceiver? = null
    var keepResult: MethodChannel.Result? = null
    var serviceConnected = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        methodChannel = MethodChannel(flutterEngine?.dartExecutor?.binaryMessenger, CHANNEL)
        methodChannel.setMethodCallHandler(::onMethodCall)
        Log.d(TAG, "ONCRETE");
    }


    private var mRemoteService: IDownloaderService? = null
    var mDownloaderClientStub: IStub? = null
    private var mState = 0
    private var mCancelValidation = false
    lateinit var methodChannel: MethodChannel

    // region Expansion Downloader
    private class XAPKFile internal constructor(val mIsMain: Boolean, val mFileVersion: Int, val mFileSize: Long)
    
    private val SMOOTHING_FACTOR = 0.005f

    /**
     * Connect the stub to our service on start.
     */
    override fun onStart() {
        Log.d(TAG, "ONSTART");

        if (null != mDownloaderClientStub) {
            mDownloaderClientStub!!.connect(this)
        }
        super.onStart()
    }

    /**
     * Disconnect the stub from our service on stop
     */
    override fun onStop() {
        Log.d(TAG, "ONSTOP");

        if (null != mDownloaderClientStub) {
            mDownloaderClientStub!!.disconnect(this)
        }
        super.onStop()
    }

    /**
     * Critical implementation detail. In onServiceConnected we create the
     * remote service and marshaler. This is how we pass the client information
     * back to the service so the client can be properly notified of changes. We
     * must do this every time we reconnect to the service.
     */
    override fun onServiceConnected(m: Messenger?) {
        Log.d(TAG, "ONCONNECTED");
        mRemoteService = DownloaderServiceMarshaller.CreateProxy(m)
        mRemoteService!!.onClientUpdated(mDownloaderClientStub!!.messenger)
    }

    /**
     * The download state should trigger changes in the UI --- it may be useful
     * to show the state as being indeterminate at times. This sample can be
     * considered a guideline.
     */
    override fun onDownloadStateChanged(newState: Int) {
        Log.d(TAG, "onDownloadStateChanged");

        setState(newState)
        var showDashboard = true
        var showCellMessage = false
        val paused: Boolean
        val indeterminate: Boolean

        methodChannel.invokeMethod(TAG, newState)

        when (newState) {

            IDownloaderClient.STATE_IDLE -> {
                paused = false
                indeterminate = true
                methodChannel.invokeMethod("updateDownloadState", "STATE_IDLE")
            }
            IDownloaderClient.STATE_CONNECTING, IDownloaderClient.STATE_FETCHING_URL -> {
                showDashboard = true
                paused = false
                indeterminate = true
                methodChannel.invokeMethod("updateDownloadState", "STATE_CONNECTING")
            }

            IDownloaderClient.STATE_DOWNLOADING -> {
                paused = false
                showDashboard = true
                indeterminate = false
                methodChannel.invokeMethod("updateDownloadState", "STATE_DOWNLOADING")
            }

            IDownloaderClient.STATE_FAILED_CANCELED -> {
                paused = true
                showDashboard = false
                indeterminate = false
                methodChannel.invokeMethod("updateDownloadState", "STATE_FAILED_CANCELED")
            }
            IDownloaderClient.STATE_FAILED -> {
                paused = true
                showDashboard = false
                indeterminate = false
                methodChannel.invokeMethod("updateDownloadState", "STATE_FAILED")
            }
            IDownloaderClient.STATE_FAILED_FETCHING_URL -> {
                paused = true
                showDashboard = false
                indeterminate = false
                methodChannel.invokeMethod("updateDownloadState", "STATE_FAILED_FETCHING_URL")
            }
            IDownloaderClient.STATE_FAILED_UNLICENSED -> {
                paused = true
                showDashboard = false
                indeterminate = false
                methodChannel.invokeMethod("updateDownloadState", "STATE_FAILED_UNLICENSED")
            }
            IDownloaderClient.STATE_PAUSED_NEED_CELLULAR_PERMISSION, IDownloaderClient.STATE_PAUSED_WIFI_DISABLED_NEED_CELLULAR_PERMISSION -> {
                showDashboard = false
                paused = true
                indeterminate = false
                showCellMessage = true
                methodChannel.invokeMethod("updateDownloadState", "STATE_PAUSED_NEED_CELLULAR_PERMISSION")
            }
            IDownloaderClient.STATE_PAUSED_BY_REQUEST -> {
                paused = true
                indeterminate = false
                methodChannel.invokeMethod("updateDownloadState", "STATE_PAUSED_BY_REQUEST")
            }
            IDownloaderClient.STATE_PAUSED_ROAMING, IDownloaderClient.STATE_PAUSED_SDCARD_UNAVAILABLE -> {
                paused = true
                indeterminate = false
                methodChannel.invokeMethod("updateDownloadState", "STATE_PAUSED_ROAMING")
            }
            IDownloaderClient.STATE_COMPLETED -> {
                showDashboard = false
                paused = false
                indeterminate = false
                validateXAPKZipFiles()
                methodChannel.invokeMethod("updateDownloadState", "STATE_COMPLETED")
                return
            }
            else -> {
                paused = true
                indeterminate = true
                showDashboard = true
            }
        }
        val newDashboardVisibility = if (showDashboard) View.VISIBLE else View.GONE
//        if (mDownloadViewGroup!!.visibility != newDashboardVisibility) {
//            mDownloadViewGroup!!.visibility = newDashboardVisibility
//        }
//        mDownloadProgressBar!!.isIndeterminate = indeterminate
    }

    /**
     * Sets the state of the various controls based on the progressinfo object
     * sent from the downloader service.
     */
    override fun onDownloadProgress(progress: DownloadProgressInfo) {
        Log.d(TAG, "onDownloadProgress");

//        mDownloadProgressBar!!.max = (progress.mOverallTotal shr 8).toInt()
//        mDownloadProgressBar!!.progress = (progress.mOverallProgress shr 8).toInt()
//        mProgressPercentTextView!!.text = java.lang.Long.toString(progress.mOverallProgress * 100 / progress.mOverallTotal) + "%"
    }

    /**
     * Go through each of the Expansion APK files and open each as a zip file.
     * Calculate the CRC for each file and return false if any fail to match.
     *
     * @return true if XAPKZipFile is successful
     */
    fun validateXAPKZipFiles() {
        Log.d(TAG, "validateXAPKZipFiles");
        methodChannel.invokeMethod(DOWNLOAD_TAG_METHOD, START_EXTRACT)
        val validationTask: AsyncTask<Any, DownloadProgressInfo, Boolean> = object : AsyncTask<Any, DownloadProgressInfo, Boolean>() {
            override fun onPreExecute() {
//                mDownloadViewGroup!!.visibility = View.VISIBLE
                super.onPreExecute()
            }

            override fun doInBackground(vararg params: Any): Boolean {
                val xAPKS = arrayOf(
                        XAPKFile(
                                true,  // true signifies a main file
                                2020507, //getPackageManager().getPackageInfo(getPackageName(), 0).versionCode,  // the version of the APK that the file was uploaded against
                                15446074L // the length of the file in bytes
                        )
                )

                for (xf in xAPKS) {
                    var fileName = Helpers.getExpansionAPKFileName(context, xf.mIsMain, xf.mFileVersion)
                    if (!Helpers.doesFileExist(context, fileName, xf.mFileSize, false)) return false
                    fileName = Helpers.generateSaveFileName(context, fileName)
                    Log.d(TAG, "new filename " + fileName);
                    var zrf: ZipResourceFile
                    val buf = ByteArray(1024 * 256)
                    try {
                        zrf = ZipResourceFile(fileName)
                        val entries = zrf.allEntries

                        /**
                         * First calculate the total compressed length
                         */
                        var totalCompressedLength: Long = 0
                        for (entry in entries) {
                            totalCompressedLength += entry.mCompressedLength
                        }
                        var averageVerifySpeed = 0f
                        var totalBytesRemaining = totalCompressedLength
                        var timeRemaining: Long
                        /**
                         * Then calculate a CRC for every file in the Zip file,
                         * comparing it to what is stored in the Zip directory.
                         * Note that for compressed Zip files we must extract
                         * the contents to do this comparison.
                         */
                        for (entry in entries) {
                            if (-1L != entry.mCRC32) {
                                var length = entry.mUncompressedLength
                                val crc = CRC32()
                                var dis: DataInputStream? = null
                                try {
                                    dis = DataInputStream(zrf.getInputStream(entry.mFileName))
                                    var startTime = SystemClock.uptimeMillis()
                                    while (length > 0) {
                                        val seek = (if (length > buf.size) buf.size else length.toInt())
                                        dis.readFully(buf, 0, seek)
                                        crc.update(buf, 0, seek)
                                        length -= seek.toLong()
                                        val currentTime = SystemClock.uptimeMillis()
                                        val timePassed = currentTime - startTime
                                        if (timePassed > 0) {
                                            val currentSpeedSample = seek.toFloat() / timePassed.toFloat()
                                            averageVerifySpeed = if (0f != averageVerifySpeed) {
                                                SMOOTHING_FACTOR * currentSpeedSample + (1 - SMOOTHING_FACTOR) * averageVerifySpeed
                                            } else {
                                                currentSpeedSample
                                            }
                                            totalBytesRemaining -= seek.toLong()
                                            timeRemaining = (totalBytesRemaining / averageVerifySpeed).toLong()
                                            publishProgress(DownloadProgressInfo(totalCompressedLength, totalCompressedLength - totalBytesRemaining, timeRemaining, averageVerifySpeed))
                                        }
                                        startTime = currentTime
                                        if (mCancelValidation) return true
                                    }
                                    if (crc.value != entry.mCRC32) {
                                        Log.e(Constants.TAG, "CRC does not match for entry: " + entry.mFileName)
                                        Log.e(Constants.TAG, "In file: " + entry.zipFileName)
                                        return false
                                    }
                                } finally {
                                    dis?.close()
                                }
                            }
                        }

                        Log.d(TAG, "file extraction start from " + fileName);

                        var path = "/storage/emulated/0/com.dididi.basictomodular/"
                        var `is`: InputStream?
                        var zis: ZipInputStream
                        try {
                            val folder = "/storage/emulated/0";
                            val f = File(folder, "com.dididi.basictomodular")
                            f.mkdir()

                            `is` = FileInputStream(fileName)
                            zis = ZipInputStream(BufferedInputStream(`is`))
                            while(true) {
                                var ze = zis?.getNextEntry()
                                if (ze == null){
                                    break
                                }
                                val baos = ByteArrayOutputStream()
                                val buffer = ByteArray(1024)
                                val filename: String = ze.getName()
                                val fout = FileOutputStream(path + filename)

                                // reading and writing
                                while(true){
                                    var count = zis.read(buffer)
                                    if (count == -1){
                                        break
                                    }
                                    baos.write(buffer, 0, count)
                                    val bytes: ByteArray = baos.toByteArray()
                                    fout.write(bytes)
                                    baos.reset()
                                }

                                fout.close()
                                zis.closeEntry()
                            }
                            zis.close()
                        } catch (e: IOException) {
                            e.printStackTrace()
                            return false
                        }
                    } catch (e: IOException) {
                        e.printStackTrace()
                        Log.d(TAG, "file extraction err " + e.message);
                        return false
                    }
                }
                return true
            }

            override fun onProgressUpdate(vararg values: DownloadProgressInfo) {
                onDownloadProgress(values[0])
                super.onProgressUpdate(*values)
            }

            override fun onPostExecute(result: Boolean) {
                if (result) {
                    methodChannel.invokeMethod(DOWNLOAD_TAG_METHOD, DONE_EXTRACT)
                } else {
                    methodChannel.invokeMethod(DOWNLOAD_TAG_METHOD, EXTRACT_FAILED)
                }
                super.onPostExecute(result)
            }
        }
        validationTask.execute(Any())
    }

    fun expansionFilesDelivered(): Boolean {
        val xAPKS = arrayOf(
                XAPKFile(
                        true,  // true signifies a main file
                        2020507, //getPackageManager().getPackageInfo(getPackageName(), 0).versionCode,  // the version of the APK that the file was uploaded against
                        15446074L // the length of the file in bytes
                )
        )

        for (xf in xAPKS) {
            val fileName = Helpers.getExpansionAPKFileName(this, xf.mIsMain, xf.mFileVersion)
            Log.d(TAG, "filename " + fileName);
            if (!Helpers.doesFileExist(this, fileName, xf.mFileSize, false)) {
                Log.d(TAG, "expansionFilesDelivered " + false);
                return false
            }
        }
        Log.d(TAG, "expansionFilesDelivered " + true);
        return true
    }

    private fun setState(newState: Int) {
        if (mState != newState) {
            mState = newState
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy");

        mCancelValidation = true
        super.onDestroy()
    }

    override fun onResume() {
        super.onResume()
        if (null != mDownloaderClientStub) {
            mDownloaderClientStub?.connect(this);
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        try {
            Log.d("methodcall", call.method);
            if (call.method == "connect") {
                mDownloaderClientStub = DownloaderClientMarshaller.CreateStub(this, DownloaderService::class.java)

                if (!expansionFilesDelivered()) {
                    try {
                        val launchIntent: Intent = getIntent()
                        val intentToLaunchThisActivityFromNotification: Intent = Intent(this, this.javaClass)
                        intentToLaunchThisActivityFromNotification.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                        intentToLaunchThisActivityFromNotification.action = launchIntent.action
                        if (launchIntent.categories != null) {
                            for (category in launchIntent.categories) {
                                intentToLaunchThisActivityFromNotification.addCategory(category)
                            }
                        }
                        // Build PendingIntent used to open this activity from
                        // Notification
                        val pendingIntent = PendingIntent.getActivity(this, 0, intentToLaunchThisActivityFromNotification, PendingIntent.FLAG_UPDATE_CURRENT)
                        // Request to start the download
                        val startResult = DownloaderClientMarshaller.startDownloadServiceIfRequired(this, pendingIntent, DownloaderService::class.java)
                        Log.d(TAG, "download");

                        if (startResult != DownloaderClientMarshaller.NO_DOWNLOAD_REQUIRED) {
                            Log.d(TAG, "DOWNLOAD_REQUIRED");
                            result.success(DOWNLOADING_FILE)
                            mDownloaderClientStub?.connect(this);
                            return
                        }
                        Log.d(TAG, "NO DOWNLOAD_REQUIRED");
                        // cancel notif
                        result.success(NO_FILE)
                    } catch (e: PackageManager.NameNotFoundException) {
                        Log.e("errr", "Cannot find package!", e)
                    }
                } else {
                    validateXAPKZipFiles()
                }

            }
        } catch (e: Exception) {
            result.error(null, e.message, null)
        }
    }

    val NO_FILE = "no_file_to_download";
    val DOWNLOADING_FILE = "is_downloading_file";

}

