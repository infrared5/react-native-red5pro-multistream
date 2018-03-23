package com.red5pro.reactnative.stream;

import android.util.DisplayMetrics;
import android.util.Log;
import android.view.ViewGroup;
import android.widget.FrameLayout;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.WritableNativeMap;
import com.facebook.react.uimanager.ThemedReactContext;
import com.red5pro.reactnative.view.EventEmitterProxy;
import com.red5pro.reactnative.view.R5MultiStreamLayout;
import com.red5pro.streaming.R5Connection;
import com.red5pro.streaming.R5Stream;
import com.red5pro.streaming.config.R5Configuration;
import com.red5pro.streaming.event.R5ConnectionEvent;
import com.red5pro.streaming.event.R5ConnectionListener;
import com.red5pro.streaming.media.R5AudioController;
import com.red5pro.streaming.view.R5VideoView;

/**
 * Created by toddanderson on 3/22/18.
 */

public class SubscriberStream implements Stream, R5ConnectionListener {

    public int mLogLevel;

    protected String mStreamName;
    protected boolean mIsStreaming;

    protected R5Connection mConnection;
    protected R5Stream mStream;
    protected R5VideoView mVideoView;

    protected ThemedReactContext mContext;
    protected EventEmitterProxy mEventEmitter;


    public SubscriberStream(ThemedReactContext context, EventEmitterProxy eventEmitterProxy, R5VideoView view) {

        mContext = context;
        mEventEmitter = eventEmitterProxy;
        mVideoView = view; // can be null

    }

    protected void cleanup() {

        Log.d("SubscriberStream", ":cleanup (" + mStreamName + ")!");
        if (mStream != null) {
            mStream.client = null;
            mStream.setListener(null);
            mStream = null;
        }

        if (mConnection != null) {
            mConnection.removeListener();
            mConnection = null;
        }
        if (mVideoView != null) {
            mVideoView.attachStream(null);
            mVideoView = null;
        }

        mIsStreaming = false;

    }

    public void init(R5Configuration configuration) {

        mStreamName = configuration.getStreamName();
        mConnection = new R5Connection(configuration);
        mStream = new R5Stream(mConnection);

        mStream.setListener(this);
        mStream.client = this;

        mStream.setLogLevel(mLogLevel);

        if (mVideoView != null) {
            mVideoView.attachStream(mStream);
        }

    }

    @Override
    public void start() {

        mStream.audioController = new R5AudioController();
        mStream.play(mStreamName);

    }

    @Override
    public void stop() {

        if (mVideoView != null) {
            mVideoView.attachStream(null);
        }

        if (mStream != null && mIsStreaming) {
            mStream.stop();
        }
        else {
            WritableMap map = Arguments.createMap();
            mEventEmitter.dispatchEvent(mStreamName, R5MultiStreamLayout.Events.UNSUBSCRIBE_NOTIFICATION.toString(), map);
            Log.d("R5MultiStreamLayout", "UNSUBSCRIBE");
            cleanup();
        }

    }

    @Override
    public void updateScaleSize(final int width, final int height, final int screenWidth, final int screenHeight) {

        if (mVideoView != null) {

            Log.d("PublisherStream", "rescaling...");

            final float xscale = (float)width / (float)screenWidth;
            final float yscale = (float)height / (float)screenHeight;

            final FrameLayout layout = mVideoView;
            final DisplayMetrics displayMetrics = new DisplayMetrics();
            mContext.getCurrentActivity().getWindowManager()
                    .getDefaultDisplay()
                    .getMetrics(displayMetrics);

            final int dwidth = displayMetrics.widthPixels;
            final int dheight = displayMetrics.heightPixels;

            layout.post(new Runnable() {
                @Override
                public void run() {
                    ViewGroup.LayoutParams params = (ViewGroup.LayoutParams) layout.getLayoutParams();
                    params.width = Math.round((displayMetrics.widthPixels * 1.0f) * xscale);
                    params.height = Math.round((displayMetrics.heightPixels * 1.0f) * yscale);
                    layout.setLayoutParams(params);
                }
            });

        }

    }

    @Override
    public int getLogLevel() {
        return mLogLevel;
    }
    public void setLogLevel(int level) {
        mLogLevel = level;
        if (mStream != null) {
            mStream.setLogLevel(level);
        }
    }

    @Override
    public R5VideoView getView () {
        return mVideoView;
    }

    @Override
    public void onConnectionEvent(R5ConnectionEvent event) {

        Log.d("SubscriberStream", ":onConnectionEvent " + event.name());
        WritableMap map = new WritableNativeMap();
        WritableMap statusMap = new WritableNativeMap();
        statusMap.putInt("code", event.value());
        statusMap.putString("message", event.message);
        statusMap.putString("name", event.name());
        map.putMap("status", statusMap);
        mEventEmitter.dispatchEvent(mStreamName, R5MultiStreamLayout.Events.SUBSCRIBER_STATUS.toString(), map);

        if (event == R5ConnectionEvent.START_STREAMING) {
            mIsStreaming = true;
        }
        else if (event == R5ConnectionEvent.DISCONNECTED && mIsStreaming) {
            WritableMap evt = new WritableNativeMap();
            mEventEmitter.dispatchEvent(mStreamName, R5MultiStreamLayout.Events.UNSUBSCRIBE_NOTIFICATION.toString(), evt);
            Log.d("R5MultiStreamLayout", "DISCONNECT");
            cleanup();
            mIsStreaming = false;
        }

    }

}