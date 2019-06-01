package com.example.hoankiemaircontrol.ui;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.KeyEvent;
import android.view.Menu;
import android.view.View;
import android.widget.EditText;
import android.widget.Toast;

import com.example.hoankiemaircontrol.R;
import com.example.hoankiemaircontrol.network.MQTTConnector;

import org.eclipse.paho.client.mqttv3.IMqttActionListener;
import org.eclipse.paho.client.mqttv3.IMqttToken;

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
                String serverIp = mEditTextIpAddress.getText().toString();
                if (serverIp.length() == 0) {
                    Toast.makeText(ConnectActivity.this,
                                    getResources().getString(R.string.toast_blank_ip),
                                    Toast.LENGTH_SHORT).show();
                } else {
                    mConnectButton.startAnimation(() -> null);
                    MQTTConnector.getInstance(ConnectActivity.this).connectToBroker(serverIp, 1883,
                        new IMqttActionListener() {
                            @Override
                            public void onSuccess(IMqttToken asyncActionToken) {
                                mConnectButton.revertAnimation(() -> null);
                                Toast.makeText(ConnectActivity.this,
                                                getResources().getString(R.string.toast_connection_established),
                                                Toast.LENGTH_SHORT).show();
                                Log.d("connectToBroker", "success");
                                Intent intent = new Intent(ConnectActivity.this, MainActivity.class);
                                startActivity(intent);
                            }

                            @Override
                            public void onFailure(IMqttToken asyncActionToken, Throwable exception) {
                                mConnectButton.revertAnimation(() -> null);
                                Toast.makeText(ConnectActivity.this,
                                                getResources().getString(R.string.toast_connection_failed),
                                                Toast.LENGTH_SHORT).show();
                                Log.d("connectToBroker", "success");
                            }
                        });
                }
            }
        });
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        super.onCreateOptionsMenu(menu);
        menu.findItem(R.id.reset_params).setVisible(false);
        return true;
    }
}
