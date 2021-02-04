package com.example.edge2edge

import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onPostResume() {
      super.onPostResume()
      WindowCompat.setDecorFitsSystemWindows(window, false)
      window.navigationBarColor = 0
    }
}
