package com.example.nfc_tag_app;

import android.os.Bundle;
import io.flutter.embedding.android.FlutterActivity;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import android.util.Log;
import android.nfc.NfcAdapter;
import android.content.IntentFilter;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.app.PendingIntent;
import io.flutter.plugin.common.MethodChannel;
import android.content.Context;


public class MainActivity extends FlutterActivity {
    // private BroadcastReceiver myReceiver = null;
    // private NfcAdapter nfcAdapter;

    // @Override
    // public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    //     super.configureFlutterEngine(flutterEngine);
    //     new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
    //     .setMethodCallHandler(
    //       (call, result) -> {
    //         // Log.d("Lol", call.method.toString());
    //         // This method is invoked on the main thread.
    //         // TODO
    //       }
    //     );
    // } 

    @Override
    protected void onResume(){
        super.onResume();
        // Intent intent = new Intent(this, MainActivity.class);
        // intent.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP);
        // NfcAdapter.getDefaultAdapter(this).enableForegroundDispatch(this,PendingIntent.getActivity(this, 0, intent, PendingIntent.FLAG_MUTABLE),null,null);
        // processNFC();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState){
        super.onCreate(savedInstanceState);
        // Log.e("On Create","");
        // processNFC();
    }

    @Override
    protected void onPause(){
        super.onPause();
        // Log.e("On Pause",getIntent().toString());
        
    }

    // void processNFC() {
    //     // code to be executed
    //     Bundle bundle = getIntent().getExtras();
    //     if (bundle != null) {
    //         for (String key : bundle.keySet()) {
    //             Log.e("On resume", key + " : " + (bundle.get(key) != null ? bundle.get(key) : "NULL"));
    //         }
    //     }
    // }
}
