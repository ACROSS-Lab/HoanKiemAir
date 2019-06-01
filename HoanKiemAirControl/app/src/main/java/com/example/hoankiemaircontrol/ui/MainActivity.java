package com.example.hoankiemaircontrol.ui;

import android.app.AlertDialog;
import android.content.DialogInterface;
import android.os.Bundle;
import android.util.Log;
import android.view.MenuItem;
import android.view.View;
import android.widget.RadioButton;
import android.widget.TextView;

import com.example.hoankiemaircontrol.R;
import com.example.hoankiemaircontrol.network.MQTTConnector;

import org.adw.library.widgets.discreteseekbar.DiscreteSeekBar;

import info.hoang8f.android.segmented.SegmentedGroup;

public class MainActivity extends BaseActivity {
    private static final int N_CARS_MIN = 0;
    private static final int N_CARS_MAX = 500;
    private static final int N_MOTORBIKES_MIN = 0;
    private static final int N_MOTORBIKES_MAX = 1000;

    private static final int DISPLAY_MODE_TRAFFIC = 0;
    private static final int DISPLAY_MODE_POLLUTION = 1;

    private TextView mTextNumCarsMin;
    private TextView mTextNumCarsMax;
    private TextView mTextNumMotorbikesMin;
    private TextView mTextNumMotorbikesMax;

    private DiscreteSeekBar mSeekBarNumCars;
    private DiscreteSeekBar mSeekBarNumMotorbikes;
    private SegmentedGroup mRadioGroupRoadScenario;
    private SegmentedGroup mRadioGroupDisplayMode;

    private MQTTConnector mConnector;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mTextNumCarsMin = findViewById(R.id.text_num_cars_min);
        mTextNumCarsMax = findViewById(R.id.text_num_cars_max);
        mTextNumMotorbikesMin = findViewById(R.id.text_num_motorbikes_min);
        mTextNumMotorbikesMax = findViewById(R.id.text_num_motorbikes_max);


        mTextNumCarsMin.setText(Integer.toString(N_CARS_MIN));
        mTextNumCarsMax.setText("MAX");
        mTextNumMotorbikesMin.setText(Integer.toString(N_MOTORBIKES_MIN));
        mTextNumMotorbikesMax.setText("MAX");


        mSeekBarNumCars = findViewById(R.id.seek_bar_num_people);
        mSeekBarNumCars.setMin(N_CARS_MIN);
        mSeekBarNumCars.setMax(N_CARS_MAX);
        mSeekBarNumCars.setOnProgressChangeListener(new DiscreteSeekBar.OnProgressChangeListener() {
            @Override
            public void onProgressChanged(DiscreteSeekBar seekBar, int value, boolean fromUser) {
                MQTTConnector.getInstance(MainActivity.this).sendMessage("n_cars", value);
            }

            @Override
            public void onStartTrackingTouch(DiscreteSeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(DiscreteSeekBar seekBar) {

            }
        });

        mSeekBarNumMotorbikes = findViewById(R.id.seek_bar_vehicle_ratio);
        mSeekBarNumMotorbikes.setMin(N_MOTORBIKES_MIN);
        mSeekBarNumMotorbikes.setMax(N_MOTORBIKES_MAX);
        mSeekBarNumMotorbikes.setOnProgressChangeListener(new DiscreteSeekBar.OnProgressChangeListener() {
            @Override
            public void onProgressChanged(DiscreteSeekBar seekBar, int value, boolean fromUser) {
                MQTTConnector.getInstance(MainActivity.this).sendMessage("n_motorbikes", value);
            }

            @Override
            public void onStartTrackingTouch(DiscreteSeekBar seekBar) {

            }

            @Override
            public void onStopTrackingTouch(DiscreteSeekBar seekBar) {

            }
        });

        mRadioGroupRoadScenario = findViewById(R.id.radio_group_road_scenario);
        mRadioGroupDisplayMode = findViewById(R.id.radio_group_display_mode);
    }

    public void onRoadScenarioRadioButtonClicked(View v) {
        boolean checked = ((RadioButton) v).isChecked();

        // Check which radio button was clicked
        switch(v.getId()) {
            case R.id.radio_button_scenario_0:
                if (checked)
                    MQTTConnector.getInstance(MainActivity.this).sendMessage("road_scenario", 0);
                break;
            case R.id.radio_button_scenario_1:
                if (checked)
                    MQTTConnector.getInstance(MainActivity.this).sendMessage("road_scenario", 1);
                break;
            case R.id.radio_button_scenario_2:
                if (checked)
                    MQTTConnector.getInstance(MainActivity.this).sendMessage("road_scenario", 2);
                break;
        }
    }

    public void onDisplayModeRadioButtonClicked(View v) {
        boolean checked = ((RadioButton) v).isChecked();

        // Check which radio button was clicked
        switch(v.getId()) {
            case R.id.radio_button_traffic:
                if (checked)
                    MQTTConnector.getInstance(MainActivity.this).sendMessage("display_mode", DISPLAY_MODE_TRAFFIC);
                break;
            case R.id.radio_button_pollution:
                if (checked)
                    MQTTConnector.getInstance(MainActivity.this).sendMessage("display_mode", DISPLAY_MODE_POLLUTION);
                break;
        }
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.reset_params:
                Log.d("MainActivity", "reset pressed!");
                AlertDialog.Builder builder = new AlertDialog.Builder(MainActivity.this);
                builder.setMessage(R.string.reset_params_prompt);
                // Add the buttons
                builder.setPositiveButton(R.string.ok, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        mSeekBarNumCars.setProgress(0);
                        mSeekBarNumMotorbikes.setProgress(0);
                        mRadioGroupRoadScenario.check(R.id.radio_button_scenario_0);
                        mRadioGroupDisplayMode.check(R.id.radio_button_traffic);
                        onRoadScenarioRadioButtonClicked(findViewById(R.id.radio_button_scenario_0));
                        onDisplayModeRadioButtonClicked(findViewById(R.id.radio_button_traffic));
                    }
                });
                builder.setNegativeButton(R.string.cancel, new DialogInterface.OnClickListener() {
                    public void onClick(DialogInterface dialog, int id) {
                        // User cancelled the dialog
                    }
                });
                // Create the AlertDialog
                AlertDialog dialog = builder.create();
                dialog.show();
                return true;
            case R.id.language_setting:
                showLanguageOptions();
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        MQTTConnector.getInstance(this).disconnect();
    }
}
