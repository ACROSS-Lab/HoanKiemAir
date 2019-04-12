package com.example.hoankiemaircontrol.network;

import java.util.Calendar;
import java.util.HashMap;
import java.util.Map;

import org.eclipse.paho.client.mqttv3.IMqttDeliveryToken;
import org.eclipse.paho.client.mqttv3.MqttCallback;
import org.eclipse.paho.client.mqttv3.MqttClient;
import org.eclipse.paho.client.mqttv3.MqttConnectOptions;
import org.eclipse.paho.client.mqttv3.MqttException;
import org.eclipse.paho.client.mqttv3.MqttMessage;
import org.eclipse.paho.client.mqttv3.persist.MemoryPersistence;

import com.thoughtworks.xstream.XStream;
import com.thoughtworks.xstream.io.xml.DomDriver;

public final class MQTTConnector {
    public final static String SERVER_URL = "SERVER_URL";
    public final static String SERVER_PORT = "SERVER_PORT";
    public final static String LOCAL_NAME = "LOCAL_NAME";
    public final static String LOGIN = "LOGIN";
    public final static String PASSWORD = "PASSWORD";

    public static String DEFAULT_USER = "admin";
    public static String DEFAULT_LOCAL_NAME = "gama-ui" + Calendar.getInstance().getTimeInMillis() + "@";
    public static String DEFAULT_PASSWORD = "password";
    public static String DEFAULT_HOST = "localhost";
    public static String DEFAULT_PORT = "1883";

    protected MqttClient sendConnection = null;
    Map<String, Object> receivedData;

    public MQTTConnector(final String server, final String userName, final String password) throws MqttException {
        this.connectToServer(server, null, userName, password);
        receivedData = new HashMap<String, Object>();
    }

    class Callback implements MqttCallback {
        @Override
        public void connectionLost(final Throwable arg0) {
            // throw new MqttException(arg0);
            System.out.println("connection lost");
        }

        @Override
        public void deliveryComplete(final IMqttDeliveryToken arg0) {
//			System.out.println("message sended");
        }

        @Override
        public void messageArrived(final String topic, final MqttMessage message) throws Exception {
            final String body = message.toString();
            storeData(topic, body);
        }
    }

    public Object getLastData(final String topic) {
        final Object data = storeDataS(topic, null);
        return data;
    }

    private synchronized Object storeDataS(final String topic, final Object dts) {
        if (dts == null) {
            final Object tmp = this.receivedData.get(topic);
            this.receivedData.remove(topic);
            return tmp;

        }
        this.receivedData.remove(topic);
        this.receivedData.put(topic, dts);
        return dts;
    }

    private final void storeData(final String topic, final String message) {
        final XStream dataStreamer = new XStream(new DomDriver());
        final Object data = dataStreamer.fromXML(message);
        storeDataS(topic, data);
    }

    public final void releaseConnection() throws MqttException {
        sendConnection.disconnect();
        sendConnection = null;
    }

    public final void sendMessage(final String dest, final Object data) throws MqttException {
        final XStream dataStreamer = new XStream(new DomDriver());
        final String dataS = dataStreamer.toXML(data);
        this.sendFormatedMessage(dest, dataS);
    }

    private final void sendFormatedMessage(final String receiver, final String content) throws MqttException {
        final MqttMessage mm = new MqttMessage(content.getBytes());
        sendConnection.publish(receiver, mm);
    }

    public void subscribeToGroup(final String boxName) throws MqttException {
        sendConnection.subscribe(boxName);
    }

    public void unsubscribeGroup(final String boxName) throws MqttException {
        sendConnection.unsubscribe(boxName);
    }

    protected void connectToServer(String server, String port, String userName, String password) throws MqttException {
        if (sendConnection == null) {
            server = server == null ? DEFAULT_HOST : server;
            port = port == null ? DEFAULT_PORT : port;
            userName = userName == null ? DEFAULT_USER : userName;
            password = password == null ? DEFAULT_PASSWORD : userName;
            final String localName = DEFAULT_LOCAL_NAME + server;
            sendConnection = new MqttClient("tcp://" + server + ":" + port, localName, new MemoryPersistence());
            final MqttConnectOptions connOpts = new MqttConnectOptions();
            connOpts.setCleanSession(true);
            sendConnection.setCallback(new Callback());
            connOpts.setCleanSession(true);
            connOpts.setKeepAliveInterval(30);
            connOpts.setUserName(userName);
            connOpts.setPassword(password.toCharArray());
            sendConnection.connect(connOpts);

        }
    }
}
