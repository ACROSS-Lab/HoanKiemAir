package com.example.hoankiemaircontrol.ui;

import android.content.Intent;
import android.os.Bundle;

import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;

import com.example.hoankiemaircontrol.R;
import com.example.hoankiemaircontrol.network.MQTTConnector;
import com.example.hoankiemaircontrol.utils.LocaleHelper;

import org.eclipse.paho.client.mqttv3.MqttException;

public class ConnectActivity extends BaseActivity {
    private MQTTConnector mConnector;
    private EditText mEditTextIpAddress;
    private Button connectButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_connect);

        mEditTextIpAddress = findViewById(R.id.edit_text_ip_address);

        connectButton = findViewById(R.id.button_connect);
        connectButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String ip = mEditTextIpAddress.getText().toString();
                if (ip.length() == 0) {
                    Toast.makeText(ConnectActivity.this, getResources().getString(R.string.toast_blank_ip), Toast.LENGTH_SHORT).show();
                } else {
                    // Connect to MQTT server
                    try {
                        mConnector = new MQTTConnector(ip, null, null);
                        Toast.makeText(ConnectActivity.this, getResources().getString(R.string.toast_connection_established), Toast.LENGTH_SHORT).show();

                        Intent intent = new Intent(ConnectActivity.this, MainActivity.class);
                        intent.putExtra("ip", ip);
                        mConnector = null;
                        startActivity(intent);
                    } catch (MqttException e) {
                        e.printStackTrace();
                        Toast.makeText(ConnectActivity.this, getResources().getString(R.string.toast_connection_failed), Toast.LENGTH_SHORT).show();
                    }
                }
            }
        });
    }
}
