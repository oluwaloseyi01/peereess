package com.peereess.app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onSaveInstanceState(outState: Bundle) {
        // Oppo/Realme devices crash with TransactionTooLargeException
        // when Flutter tries to save state — clear it before saving
        super.onSaveInstanceState(outState)
        outState.clear()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
    }
}
