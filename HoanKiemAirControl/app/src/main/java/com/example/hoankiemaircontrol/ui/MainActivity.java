package com.example.hoankiemaircontrol.ui;

import android.os.AsyncTask;
import android.os.Bundle;
import android.view.View;
import android.widget.CompoundButton;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.Switch;
import android.widget.TextView;

import com.example.hoankiemaircontrol.R;
import com.example.hoankiemaircontrol.network.MQTTConnector;

import org.adw.library.widgets.discreteseekbar.DiscreteSeekBar;
import org.eclipse.paho.client.mqttv3.MqttException;

import java.lang.ref.WeakReference;

import androidx.appcompat.app.AppCompatActivity;

public class MainActivity extends AppCompatActivity {
    private static final int N_PEOPLE_MIN = 0;
    private static final int N_PEOPLE_MAX = 2000;
    private static final int VEHICLE_RATIO_MIN = 0;
    private static final int VEHICLE_RATIO_MAX = 100;
    private static final int CAR_CAPACITY_MIN = 1;
    private static final int CAR_CAPACITY_MAX = 7;

    private static final int DISPLAY_MODE_TRAFFIC = 0;
    private static final int DISPLAY_MODE_POLLUTION = 1;

    private TextView mTextNumPeopleMin;
    private TextView mTextNumPeopleMax;
    private TextView mTextVehicleRatioMin;
    private TextView mTextVehicleRatioMax;
    private TextView mTextCarCapacityMin;
    private TextView mTextCarCapacityMax;

    private DiscreteSeekBar mSeekBarNumPeople;
    private DiscreteSeekBar mSeekBarVehicleRatio;
    private DiscreteSeekBar mSeekBarCarCapacity;
    private Switch mSwitchCloseRoads;
    private RadioGroup mRadioGroupRoadScenario;

    private MQTTConnector mConnector;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        String ip = getIntent().getStringExtra("ip");
        try {
            mConnector = new MQTTConnector(ip, null, null);
        } catch (MqttException e) {
            e.printStackTrace();
        }

        mTextNumPeopleMin = findViewById(R.id.text_num_people_min);
        mTextNumPeopleMax = findViewById(R.id.text_num_people_max);
        mTextVehicleRatioMin = findViewById(R.id.text_vehicle_ratio_min);
        mTextVehicleRatioMax = findViewById(R.id.text_vehicle_ratio_max);
        mTextCarCapacityMin = findViewById(R.id.text_car_capacity_min);
        mTextCarCapacityMax = findViewById(R.id.text_car_capacity_max);

        mTextNumPeopleMin.setText(Integer.toString(N_PEOPLE_MIN));
        mTextNumPeopleMax.setText((Integer.toString(N_PEOPLE_MAX)));
        mTextVehicleRatioMin.setText(VEHICLE_RATIO_MIN + "%");
        mTextVehicleRatioMax.setText(VEHICLE_RATIO_MAX + "%");
        mTextCarCapacityMin.setText(Integer.toString(CAR_CAPACITY_MIN));
        mTextCarCapacityMax.setText((Integer.toString(CAR_CAPACITY_MAX)));

        mSeekBarNumPeople = findViewById(R.id.seek_bar_num_people);
        mSeekBarNumPeople.setMin(N_PEOPLE_MIN);
        mSeekBarNumPeople.setMax(N_PEOPLE_MAX);
        mSeekBarNumPeople.setOnProgressChangeListener(new DiscreteSeekBar.OnProgressChangeListener() {
            @Override
            public void onProgressChanged(DiscreteSeekBar seekBar, int value, boolean fromUser) {
                Bundle bundle = new Bundle();
                bundle.putCharSequence("topic", "nb_people");
                bundle.putInt("intData", value);
                new SendMessageTask(MainActivity.this).execute(bundle);
            }

            @Override
            public void onStartTrackingTouch(DiscreteSeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(DiscreteSeekBar seekBar) {

            }
        });

        mSeekBarVehicleRatio = findViewById(R.id.seek_bar_vehicle_ratio);
        mSeekBarVehicleRatio.setMin(VEHICLE_RATIO_MIN);
        mSeekBarVehicleRatio.setMax(VEHICLE_RATIO_MAX);
        mSeekBarVehicleRatio.setOnProgressChangeListener(new DiscreteSeekBar.OnProgressChangeListener() {
            @Override
            public void onProgressChanged(DiscreteSeekBar seekBar, int value, boolean fromUser) {
                Bundle bundle = new Bundle();
                bundle.putCharSequence("topic", "nb_moto");
                bundle.putInt("intData", value);
                new SendMessageTask(MainActivity.this).execute(bundle);
            }

            @Override
            public void onStartTrackingTouch(DiscreteSeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(DiscreteSeekBar seekBar) {

            }
        });

        mSeekBarCarCapacity = findViewById(R.id.seek_bar_car_capacity);
        mSeekBarCarCapacity.setMin(CAR_CAPACITY_MIN);
        mSeekBarCarCapacity.setMax(CAR_CAPACITY_MAX);
        mSeekBarCarCapacity.setOnProgressChangeListener(new DiscreteSeekBar.OnProgressChangeListener() {
            @Override
            public void onProgressChanged(DiscreteSeekBar seekBar, int value, boolean fromUser) {
                Bundle bundle = new Bundle();
                bundle.putCharSequence("topic", "nb_people_car");
                bundle.putInt("intData", value);
                new SendMessageTask(MainActivity.this).execute(bundle);
            }

            @Override
            public void onStartTrackingTouch(DiscreteSeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(DiscreteSeekBar seekBar) {

            }
        });

        mRadioGroupRoadScenario = findViewById(R.id.radio_group_road_scenarios);
        mSwitchCloseRoads = findViewById(R.id.switch_close_roads);
        mSwitchCloseRoads.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                Bundle bundle = new Bundle();
                bundle.putCharSequence("topic", "close_roads");
                bundle.putBoolean("booleanData", isChecked);
                new SendMessageTask(MainActivity.this).execute(bundle);

                // Show the road scenarios RadioGroup when checked
                if (isChecked) {
                    mRadioGroupRoadScenario.setVisibility(View.VISIBLE);
                } else {
                    mRadioGroupRoadScenario.setVisibility(View.GONE);
                }
            }
        });
    }

    public void onRoadScenarioRadioButtonClicked(View v) {
        boolean checked = ((RadioButton) v).isChecked();

        Bundle bundle = new Bundle();
        bundle.putString("topic", "road_scenario");
        // Check which radio button was clicked
        switch(v.getId()) {
            case R.id.radio_button_scenario_0:
                if (checked)
                    bundle.putInt("intData", 0);
                break;
            case R.id.radio_button_scenario_1:
                if (checked)
                    bundle.putInt("intData", 1);
                break;
            case R.id.radio_button_scenario_2:
                if (checked)
                    bundle.putInt("intData", 2);
                break;
        }
        new SendMessageTask(MainActivity.this).execute(bundle);
    }

    public void onDisplayModeRadioButtonClicked(View v) {
        boolean checked = ((RadioButton) v).isChecked();

        Bundle bundle = new Bundle();
        bundle.putString("topic", "display_mode");
        // Check which radio button was clicked
        switch(v.getId()) {
            case R.id.radio_button_traffic:
                if (checked)
                    bundle.putInt("intData", DISPLAY_MODE_TRAFFIC);
                    break;
            case R.id.radio_button_pollution:
                if (checked)
                    bundle.putInt("intData", DISPLAY_MODE_POLLUTION);
                    break;
        }
        new SendMessageTask(MainActivity.this).execute(bundle);
    }

    private static class SendMessageTask extends AsyncTask<Bundle, Void, Void> {
        private WeakReference<MainActivity> mActivityWeakReference;

        SendMessageTask(MainActivity context) {
            mActivityWeakReference = new WeakReference<>(context);
        }

        @Override
        protected Void doInBackground(Bundle... bundles) {
            MainActivity mainActivity = mActivityWeakReference.get();
            MQTTConnector connector = mainActivity.mConnector;

            Bundle bundle = bundles[0];
            String topic = bundle.getString("topic");
            Object data;
            if (bundle.containsKey("intData")) {
                data = bundle.getInt("intData");
            } else {
                data = bundle.getBoolean("booleanData");
            }

            if (connector != null) {
                try {
                    connector.sendMessage(topic, data);
                } catch (MqttException e) {
                    e.printStackTrace();
                }
            }
            return null;
        }
    }
}
