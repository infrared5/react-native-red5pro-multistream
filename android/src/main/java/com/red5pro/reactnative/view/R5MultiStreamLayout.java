package com.red5pro.reactnative.view;

import android.app.Activity;
import android.content.res.Configuration;
import android.graphics.Color;
import android.os.Handler;
import android.os.Looper;
import android.support.annotation.NonNull;
import android.util.Log;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.facebook.react.bridge.LifecycleEventListener;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.events.RCTEventEmitter;

import com.red5pro.reactnative.stream.PublisherStream;
import com.red5pro.reactnative.stream.Stream;
import com.red5pro.reactnative.stream.SubscriberStream;
import com.red5pro.streaming.R5Stream;
import com.red5pro.streaming.R5StreamProtocol;
import com.red5pro.streaming.config.R5Configuration;
import com.red5pro.streaming.event.R5ConnectionEvent;
import com.red5pro.streaming.view.R5VideoView;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;


public class R5MultiStreamLayout extends FrameLayout implements EventEmitterProxy, LifecycleEventListener {

    public int logLevel;
    public boolean showDebug;

    protected String mStreamName;
    protected boolean mIsStreaming;
    protected R5VideoView mVideoView;

    protected ThemedReactContext mContext;
    protected RCTEventEmitter mEventEmitter;
    protected R5Stream mStream;

    protected String mLicenseKey;
    protected String mBundleID;
    protected int mBitrate = 750;
    protected int mFramerate = 15;
    protected float mBufferTime = 0.5f;
    protected float mStreamBufferTime = 2.0f;
    protected boolean mUseAdaptiveBitrateController = false;

    protected boolean mOrientationDirty;

    protected int mClientWidth;
    protected int mClientHeight;
    protected int mClientScreenWidth;
    protected int mClientScreenHeight;

    private boolean mIsCheckingPermissions = false;
    private boolean isInBackground = false;
//    private boolean isInShutdownMode = true;
//    private List<String> shutdownTickets;

    protected View.OnLayoutChangeListener mLayoutListener;

    protected Map<String, Stream> streamMap;

    public enum Events {

        CONFIGURED("onConfigured"),
        METADATA("onMetaDataEvent"),
        PUBLISHER_STATUS("onPublisherStreamStatus"),
        SUBSCRIBER_STATUS("onSubscriberStreamStatus"),
        UNPUBLISH_NOTIFICATION("onUnpublishNotification"),
        UNSUBSCRIBE_NOTIFICATION("onUnsubscribeNotification"),
        SHUTDOWN_COMPLETE("onShutdownComplete");

        private final String mName;

        Events(final String name) {
            mName = name;
        }

        @Override
        public String toString() {
            return mName;
        }

    }

    public enum Commands {

        SUBSCRIBE("subscribe", 1),
        PUBLISH("publish", 2),
        UNSUBSCRIBE("unsubscribe", 3),
        UNPUBLISH("unpublish", 4),
        SWAP_CAMERA("swapCamera", 5),
        UPDATE_SCALE_MODE("updateScaleMode", 6),
        PREVIEW("preview", 7),
        UPDATE_SCALE_SIZE("updateScaleSize", 8),
        SHUTDOWN("shutdown", 9),
        PERMISSIONS_FLAG("setPermissionsFlag", 10);

        private final String mName;
        private final int mValue;

        Commands(final  String name, final int value) {
            mName = name;
            mValue = value;
        }

        public final int getValue() {
            return mValue;
        }

        @Override
        public String toString() {
            return mName;
        }

    }

    R5MultiStreamLayout(ThemedReactContext context) {

        super(context);

        streamMap = new HashMap<>();

        mContext = context;
        mEventEmitter = mContext.getJSModule(RCTEventEmitter.class);
        setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        mContext.addLifecycleEventListener(this);

    }

    protected R5VideoView createVideoView () {

        R5VideoView view = new R5VideoView(mContext);
        view.setLayoutParams(new ViewGroup.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT));
        view.setBackgroundColor(Color.BLACK);
        addView(view);
        return view;

    }

    protected R5Configuration createConfiguration (String streamName, String host, String context) {

        R5Configuration configuration = new R5Configuration(R5StreamProtocol.RTSP, host, 8554, context, mBufferTime);
        configuration.setStreamBufferTime(mStreamBufferTime);
        configuration.setBundleID(mBundleID);
        configuration.setLicenseKey(mLicenseKey);
        configuration.setStreamName(streamName);
        return configuration;
    }

    public void setIsCheckingPermissions (boolean flag) {
        Log.d("[R5MultiStreamLayout]", "setting permissions flag to (" + flag + ")");
        this.mIsCheckingPermissions = flag;
    }

    public void subscribe (String streamName, String host, String context, Boolean withVideo, int audioMode) {

        Log.d("[R5MultiStreamLayout]", "subscribe(" + streamName + ")");

        SubscriberStream subscriber = new SubscriberStream(mContext, this, withVideo ? createVideoView() : null);
        subscriber.init(createConfiguration(streamName, host, context));
        streamMap.put(streamName, subscriber);

        if (!isInBackground) {
            subscriber.start();
        }
        onConfigured(streamName, streamName + this.getId());

    }

    public void unsubscribe (String streamName) {

        Log.d("[R5MultiStreamLayout]", "unsubscribe(" + streamName + ")");

        if (streamMap.containsKey(streamName)) {
            Stream stream = streamMap.get(streamName);
            if (stream instanceof SubscriberStream) {
                stream.stop();
            }
            if (stream.getView() != null) {
                removeView(stream.getView());
            }
            streamMap.remove(streamName);
        }

    }

    public void publish (String streamName,
                         String host,
                         String context,
                         Boolean withVideo,
                         int cameraWidth,
                         int cameraHeight,
                         R5Stream.RecordType streamType) {

        Log.d("R5MultiStreamLayout", "publish with video(" + withVideo + ")");

        if (mLayoutListener == null) {
            mLayoutListener = setUpOrientationListener();
        }

        PublisherStream publisher = new PublisherStream(mContext, this, withVideo ? createVideoView() : null);
        publisher.init(createConfiguration(streamName, host, context),
                cameraWidth, cameraHeight,
                mBitrate, mFramerate,
                streamType,
                mUseAdaptiveBitrateController);
        publisher.start();

        streamMap.put(streamName, publisher);
        onConfigured(streamName, streamName + this.getId());

    }

    public void unpublish (String streamName) {

        Log.d("[R5MultiStreamLayout]", "unpublish(" + streamName + ")");

        if (streamMap.containsKey(streamName)) {
            Stream stream = streamMap.get(streamName);
            if (stream instanceof PublisherStream) {
                stream.stop();
                if (stream.getView() != null) {
                    removeView(stream.getView());
                }
            }
            streamMap.remove(streamName);
        }

    }

    public void swapCamera (String streamName) {

        for(Map.Entry<String, Stream>entry : streamMap.entrySet()) {
            String key = entry.getKey();
            Stream stream = (Stream)(entry.getValue());
            if (streamName.equals(key)) {
                ((PublisherStream) stream).swapCamera();
            }
        }

    }

    public void updateScaleSize(String streamName, final int width, final int height, final int screenWidth, final int screenHeight) {

        Log.d("[R5MultiStreamLayout]", "updateScaleSize(" + streamName + ")");
        mClientWidth = width;
        mClientHeight = height;
        mClientScreenWidth = screenWidth;
        mClientScreenHeight = screenHeight;

        if (streamMap.containsKey(streamName)) {
            streamMap.get(streamName).updateScaleSize(width, height, screenWidth, screenHeight);
        }

    }

    public void updateScaleMode(String streamName, int mode) {
        // TODO:
    }

    public void shutdown() {

        Log.d("R5MultiStreamLayout", "shutdown()");

//        isInShutdownMode = true;

        try {

//            if (shutdownTickets == null) {
//                shutdownTickets = new ArrayList<>();
//            }

//            for (Map.Entry<String, Stream> entry : streamMap.entrySet()) {
//                String key = entry.getKey();
//                Stream stream = (Stream) (entry.getValue());
//                shutdownTickets.add(key);
//            }


            for (Map.Entry<String, Stream> ticket : streamMap.entrySet()) {
                Stream stream = (Stream) (ticket.getValue());
                stream.stop();
            }
            streamMap.clear();

        }
        catch (Exception e) {
            e.printStackTrace();
//            isInShutdownMode = false;
//            shutdownTickets.clear();
        }

    }

    protected View.OnLayoutChangeListener setUpOrientationListener() {
        return new View.OnLayoutChangeListener() {
            @Override
            public void onLayoutChange(View v, int left, int top, int right, int bottom, int oldLeft,
                                       int oldTop, int oldRight, int oldBottom) {
                if (mOrientationDirty) {
                    reorient();
                }
            }
        };
    }

    protected void reorient() {

        for(Map.Entry<String, Stream>entry : streamMap.entrySet()) {
            String key = entry.getKey();
            Stream stream = (Stream)(entry.getValue());
            if (stream instanceof PublisherStream) {
                ((PublisherStream) stream).reorient();
            }
        }
        mOrientationDirty = false;

    }

    protected void updateOrientation(int value) {
        // subscriber only.
        value += 90;
        if (this.getVideoView() != null) {
            this.getVideoView().setStreamRotation(value);
        }
    }

    protected void onConfigured(String streamName, String key) {

        Log.d("[R5MultiStreamLayout]", "onConfigured()");
        WritableMap map = new WritableNativeMap();
        map.putString("streamName", streamName);
        map.putString("key", key);
        mEventEmitter.receiveEvent(this.getId(), "onConfigured", map);
    }

    @Override
    public void dispatchEvent(String streamName, String type, WritableMap map) {

//        try {
//            if (shutdownTickets != null) {
//                // TODO: also check map.status.name?
//                ReadableMapKeySetIterator it = map.keySetIterator();
//                while (it.hasNextKey()) {
//                    String key = it.nextKey();
//                    Log.d("[R5MultiStreamLayout]", key);
//                    if (key.equals("status")) {
//                        Log.d("[R5MultiStreamLayout]", "Status: " + map.getMap("status").getString("name"));
//                    }
//                }
//                if (shutdownTickets.contains(streamName) &&
//                        (map.hasKey("status") && map.getMap("status").getString("name").equals(R5ConnectionEvent.CLOSE.name()))) {
//                    Log.d("[R5MultiStreamLayout]", "Close event on (" + streamName + ")");
//                    shutdownTickets.remove(streamName);
//                }
//
//                Log.d("[R5MultiStreamLayout]", "Ticket count? " + shutdownTickets.size());
//                if (shutdownTickets.size() == 0) {
//                    WritableMap shutdownMap = new WritableNativeMap();
//                    mEventEmitter.receiveEvent(this.getId(), R5MultiStreamLayout.Events.SHUTDOWN_COMPLETE.toString(), shutdownMap);
//                }
//            }
//        }
//        catch (Exception e) {
//            e.printStackTrace();
//        }

        map.putString("streamName", streamName);
        mEventEmitter.receiveEvent(this.getId(), type, map);

    }

    @Override
    public void onHostResume() {
        Log.d("[R5MultiStreamLayout]", "onResume()");
        isInBackground = false;
        Activity activity = mContext.getCurrentActivity();
        if (mLayoutListener == null) {
            mLayoutListener = setUpOrientationListener();
        }
        this.addOnLayoutChangeListener(mLayoutListener);

        for(Map.Entry<String, Stream>entry : streamMap.entrySet()) {
            String key = entry.getKey();
            Stream stream = (Stream)(entry.getValue());
            if (stream instanceof SubscriberStream) {
                ((SubscriberStream) stream).resume();
            }
        }
    }

    @Override
    public void onHostPause() {
        Log.d("[R5MultiStreamLayout]", " onPause()");
        isInBackground = true;

        if (mLayoutListener != null) {
            this.removeOnLayoutChangeListener(mLayoutListener);
        }

        Log.d("[R5MultiStreamLayout]", "are we checking permissions?(" + mIsCheckingPermissions + ")");
        if (mIsCheckingPermissions) {
            return;
        }

        PublisherStream publisher = null;
        for(Map.Entry<String, Stream>entry : streamMap.entrySet()) {
            String key = entry.getKey();
            Stream stream = (Stream)(entry.getValue());
            R5VideoView view = null;
            if (stream instanceof PublisherStream) {
                publisher = ((PublisherStream) stream);
                view = publisher.getView();
            }
            stream.pause();
            if (view != null) {
                removeView(view);
            }
        }
        if (publisher != null) {
            streamMap.remove(publisher);
        }

    }

    @Override
    public void onHostDestroy() {
        Log.d("[R5MultiStreamLayout]", "onDestroy()");
    }

    @Override
    public void onConfigurationChanged(Configuration config) {
        for(Map.Entry<String, Stream>entry : streamMap.entrySet()) {
            String key = entry.getKey();
            Stream stream = (Stream)(entry.getValue());
            if (stream instanceof PublisherStream) {
                ((PublisherStream) stream).updateDeviceOrientationOnLayoutChange();
            }
        }
    }

    public void updateShowDebug(boolean show) {
        this.showDebug = show;
    }

    public void updateLogLevel(int level) {
        this.logLevel = level;
    }

    public void updateLicenseKey(String licenseKey) {
        this.mLicenseKey = licenseKey;
    }

    public void updateBundleID(String bundleID) {
        this.mBundleID = bundleID;
    }

    public void updatePublishBitrate(int value) {
        this.mBitrate = value;
    }

    public void updatePublishFramerate(int value) {
        this.mFramerate = value;
    }

    public void updatePublisherUseAdaptiveBitrateController(boolean value) {
        this.mUseAdaptiveBitrateController = value;
    }

    public void updateBufferTime(float bufferTime) {
        this.mBufferTime = bufferTime;
    }

    public void updateStreamBufferTime(float streamBufferTime) {
        this.mStreamBufferTime = streamBufferTime;
    }

    public R5VideoView getVideoView() {
        return mVideoView;
    }

    /*
     * [Red5Pro]
     *
     * Start silly hack of enforcing layout of underlying GLSurface for view.
     */
    @Override
    public void requestLayout() {
        super.requestLayout();
        post(measureAndLayout);
    }

    private final Runnable measureAndLayout = new Runnable() {
        @Override
        public void run() {
            measure(
                    MeasureSpec.makeMeasureSpec(getWidth(), MeasureSpec.EXACTLY),
                    MeasureSpec.makeMeasureSpec(getHeight(), MeasureSpec.EXACTLY));
            layout(getLeft(), getTop(), getRight(), getBottom());
            if (mOrientationDirty) {
                reorient();
            }
        }
    };
    /*
     * [/Red5Pro]
     */

}


