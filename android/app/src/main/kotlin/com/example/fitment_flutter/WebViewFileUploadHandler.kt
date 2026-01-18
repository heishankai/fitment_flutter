package com.example.fitment_flutter

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.webkit.ValueCallback
import android.webkit.WebChromeClient

class WebViewFileUploadHandler(private val activity: Activity) {
    private var fileUploadCallback: ValueCallback<Array<Uri>>? = null
    private val FILE_CHOOSER_REQUEST_CODE = 100
    
    fun handleFileChooser(
        filePathCallback: ValueCallback<Array<Uri>>,
        fileChooserParams: WebChromeClient.FileChooserParams?
    ): Boolean {
        fileUploadCallback = filePathCallback
        
        val intent = Intent(Intent.ACTION_GET_CONTENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "*/*"
            
            // 如果指定了 accept 类型，使用它
            fileChooserParams?.let { params ->
                if (params.acceptTypes != null && params.acceptTypes.isNotEmpty()) {
                    type = params.acceptTypes[0]
                    if (params.acceptTypes.size > 1) {
                        putExtra(Intent.EXTRA_MIME_TYPES, params.acceptTypes)
                    }
                }
            }
        }
        
        try {
            activity.startActivityForResult(
                Intent.createChooser(intent, "选择文件"),
                FILE_CHOOSER_REQUEST_CODE
            )
            return true
        } catch (e: Exception) {
            filePathCallback.onReceiveValue(null)
            fileUploadCallback = null
            return false
        }
    }
    
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode == FILE_CHOOSER_REQUEST_CODE) {
            val results: Array<Uri>? = when {
                resultCode == Activity.RESULT_OK && data != null -> {
                    val uri = data.data
                    if (uri != null) {
                        arrayOf(uri)
                    } else {
                        null
                    }
                }
                else -> null
            }
            
            fileUploadCallback?.onReceiveValue(results)
            fileUploadCallback = null
            return true
        }
        return false
    }
}

