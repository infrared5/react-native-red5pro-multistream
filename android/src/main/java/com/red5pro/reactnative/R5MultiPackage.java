package com.red5pro.reactnative;

import android.app.Activity;

import com.facebook.react.ReactPackage;
import com.facebook.react.bridge.NativeModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.uimanager.ViewManager;
import com.red5pro.reactnative.view.R5MultiVideoViewManager;

import java.util.Collections;
import java.util.List;

public class R5MultiPackage implements ReactPackage {

    @Override
    public List<ViewManager> createViewManagers(
            ReactApplicationContext reactContext) {
        return Collections.<ViewManager>singletonList(
                new R5MultiVideoViewManager()
        );
    }

    @Override
    public List<NativeModule> createNativeModules(
            ReactApplicationContext reactContext) {
        return Collections.emptyList();
    }

}
