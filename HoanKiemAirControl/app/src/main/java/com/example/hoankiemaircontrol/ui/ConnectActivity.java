package com.example.hoankiemaircontrol.ui;

import android.content.Intent;
import android.os.AsyncTask;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.View;
import android.widget.EditText;
import android.widget.Toast;

import com.example.hoankiemaircontrol.R;
import com.example.hoankiemaircontrol.network.MQTTConnector;

import org.eclipse.paho.client.mqttv3.MqttException;

import java.lang.ref.WeakReference;

import br.com.simplepass.loadingbutton.customViews.CircularProgressButton;

public class ConnectActivity extends BaseActivity {
    private EditText mEditTextIpAddress;
    private CircularProgressButton mConnectButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_connect);

        mEditTextIpAddress = findViewById(R.id.edit_text_ip_address);
        mEditTextIpAddress.setOnKeyListener(new View.OnKeyListener() {
            @Override
            public boolean onKey(View v, int keyCode, KeyEvent event)
            {
                if (event.getAction() == KeyEvent.ACTION_DOWN)
                {
                    switch (keyCode)
                    {
                        case KeyEvent.KEYCODE_DPAD_CENTER:
                        case KeyEvent.KEYCODE_ENTER:
                            mConnectButton.performClick();
                            return true;
                        default:
                            break;
                    }
                }
                return false;
            }
        });

        mConnectButton = findViewById(R.id.button_connect);
        mConnectButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                String ip = mEditTextIpAddress.getText().toString();
                if (ip.length() == 0) {
                    Toast.makeText(ConnectActivity.this, getResources().getString(R.string.toast_blank_ip), Toast.LENGTH_SHORT).show();
                } else {
                    // Connect to MQTT server
                    new ConnectTask(ConnectActivity.this).execute(ip);
                }
            }
        });
    }

    private static class ConnectTask extends AsyncTask<String, Void, MQTTConnector> {
        private WeakReference<ConnectActivity> mActivityWeakReference;

        ConnectTask(ConnectActivity context) {
            mActivityWeakReference = new WeakReference<>(context);
        }

        @Override
        protected MQTTConnector doInBackground(String... strings) {
            try {
                MQTTConnector mqttConnector = new MQTTConnector(strings[0], null, null);
                return mqttConnector;
            } catch (MqttException e) {
                e.printStackTrace();
                return null;
            }
        }

        @Override
        protected void onPreExecute() {
            ConnectActivity connectActivity = mActivityWeakReference.get();
            connectActivity.mConnectButton.startAnimation(() -> null);
        }

        @Override
        protected void onPostExecute(MQTTConnector mqttConnector) {
            ConnectActivity connectActivity = mActivityWeakReference.get();
            if (mqttConnector != null) {
                Toast.makeText(connectActivity, connectActivity.getResources().getString(R.string.toast_connection_established), Toast.LENGTH_SHORT).show();

                Intent intent = new Intent(connectActivity, MainActivity.class);
                intent.putExtra("ip", mqttConnector.serverIp);
                connectActivity.startActivity(intent);
            } else {
                Toast.makeText(connectActivity, connectActivity.getResources().getString(R.string.toast_connection_failed), Toast.LENGTH_SHORT).show();
            }
            connectActivity.mConnectButton.revertAnimation(() -> null);
        }
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);
        menu.findItem(R.id.reset_params).setVisible(false);
        return true;
    }
}
