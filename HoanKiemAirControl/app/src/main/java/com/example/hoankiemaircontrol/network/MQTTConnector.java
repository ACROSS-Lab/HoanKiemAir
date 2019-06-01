package com.example.hoankiemaircontrol.network;

import android.content.Context;
import android.util.Log;

import com.thoughtworks.xstream.XStream;
import com.thoughtworks.xstream.io.xml.DomDriver;

import org.eclipse.paho.android.service.MqttAndroidClient;
import org.eclipse.paho.client.mqttv3.IMqttActionListener;
import org.eclipse.paho.client.mqttv3.IMqttToken;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;

public class MQTTConnector {
    private static MQTTConnector sMQTTConnector;
    private static Context sContext;

    private static MqttAndroidClient sClient;

    private MQTTConnector(Context context) {
        sContext = context;
    }

    public static MQTTConnector getInstance(Context context) {
        if (sMQTTConnector == null) {
            sMQTTConnector = new MQTTConnector(context);
        }
        return sMQTTConnector;
    }

    public void connectToBroker(String serverIp, int port, IMqttActionListener callback) {
        String serverURI = "tcp://" + serverIp + ":" + port;
        String clientId = MqttClient.generateClientId();
        sClient = new MqttAndroidClient(sContext.getApplicationContext(), serverURI, clientId);
        try {
            Log.d("connectToBroker", "connecting...");
            sClient.connect().setActionCallback(callback);
        } catch (MqttException e) {
            e.printStackTrace();
        }
    }

    public void sendMessage(String topic, Object data) {
        final XStream dataStreamer = new XStream(new DomDriver());
        final String dataS = dataStreamer.toXML(data);
        MqttMessage message = new MqttMessage(dataS.getBytes());
        try {
            sClient.publish(topic, message);
            Log.d("mqtt","Sent message: " + topic + " " + message);
        } catch (MqttException e) {
            e.printStackTrace();
        }
    }

    public void disconnect() {
        try {
            IMqttToken token = sClient.disconnect();
            token.setActionCallback(new IMqttActionListener() {
                @Override
                public void onSuccess(IMqttToken asyncActionToken) {
                    Log.d("mqtt", "Disconnect successfully");
                }

                @Override
                public void onFailure(IMqttToken asyncActionToken, Throwable exception) {
                    Log.d("mqtt", "Disconnect failed");
                }
            });
        } catch (MqttException e) {
            e.printStackTrace();
        }
    }
}
