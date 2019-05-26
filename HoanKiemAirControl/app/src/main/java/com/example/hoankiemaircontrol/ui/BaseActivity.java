package com.example.hoankiemaircontrol.ui;

import android.content.Context;
import android.content.DialogInterface;
import android.view.Menu;
import android.view.MenuInflater;
import android.view.MenuItem;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import com.example.hoankiemaircontrol.R;
import com.example.hoankiemaircontrol.utils.LocaleHelper;

public abstract class BaseActivity extends AppCompatActivity {
    @Override
    protected void attachBaseContext(Context newBase) {
        super.attachBaseContext(LocaleHelper.onAttach(newBase, "en"));
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        MenuInflater inflater = getMenuInflater();
        inflater.inflate(R.menu.menu_main, menu);
        return true;
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        switch (item.getItemId()) {
            case R.id.language_setting:
                showLanguageOptions();
                return true;
            default:
                return super.onOptionsItemSelected(item);
        }
    }

    public void showLanguageOptions() {
        String[] languages = new String[]{"English", "Francais", "Tiếng Việt"};
        AlertDialog.Builder builder = new AlertDialog.Builder(this);

        int checkedItem = 0;
        switch (LocaleHelper.getLanguage(BaseActivity.this)) {
            case "en":
                checkedItem = 0;
                break;
            case "fr":
                checkedItem = 1;
                break;
            case "vi":
                checkedItem = 2;
                break;
        }

        builder.setTitle("Language")
                .setSingleChoiceItems(languages, checkedItem, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        switch (which) {
                            case 0:
                                LocaleHelper.setLocale(BaseActivity.this, "en", "");
                                break;
                            case 1:
                                LocaleHelper.setLocale(BaseActivity.this, "fr", "FR");
                                break;
                            case 2:
                                LocaleHelper.setLocale(BaseActivity.this, "vi", "VN");
                                break;
                        }
                        dialog.dismiss();
                        recreate();
                    }
                });
        AlertDialog dialog = builder.create();
        dialog.show();
    }
}
