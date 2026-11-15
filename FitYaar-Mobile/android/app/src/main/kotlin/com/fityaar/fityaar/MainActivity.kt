package com.fityaar.fityaar

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity (not FlutterActivity): the `health` plugin requests Health Connect
// permissions via registerForActivityResult, which needs a ComponentActivity.
class MainActivity : FlutterFragmentActivity()
