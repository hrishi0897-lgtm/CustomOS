package com.customos.launcher;

import android.app.Activity;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.pm.ResolveInfo;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;
import androidx.annotation.NonNull;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class MainActivity extends Activity {
    private RecyclerView recyclerView;
    private AppAdapter adapter;
    private final List<AppItem> appList = new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        recyclerView = findViewById(R.id.app_recycler_view);
        recyclerView.setLayoutManager(new LinearLayoutManager(this));
        adapter = new AppAdapter();
        recyclerView.setAdapter(adapter);

        loadInstalledApps();
    }

    private void loadInstalledApps() {
        appList.clear();
        PackageManager pm = getPackageManager();
        Intent intent = new Intent(Intent.ACTION_MAIN, null);
        intent.addCategory(Intent.CATEGORY_LAUNCHER);

        List<ResolveInfo> activities = pm.queryIntentActivities(intent, 0);
        for (ResolveInfo ri : activities) {
            if (ri.activityInfo.packageName.equals(getPackageName())) continue;
            appList.add(new AppItem(
                ri.loadLabel(pm).toString(),
                ri.activityInfo.packageName
            ));
        }

        Collections.sort(appList, (a, b) -> a.name.compareToIgnoreCase(b.name));
        adapter.notifyDataSetChanged();
    }

    private static class AppItem {
        final String name;
        final String packageName;
        AppItem(String name, String packageName) {
            this.name = name;
            this.packageName = packageName;
        }
    }

    private class AppAdapter extends RecyclerView.Adapter<AppAdapter.ViewHolder> {
        @NonNull
        @Override
        public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
            View v = LayoutInflater.from(parent.getContext()).inflate(R.layout.item_app, parent, false);
            return new ViewHolder(v);
        }

        @Override
        public void onBindViewHolder(@NonNull ViewHolder holder, int position) {
            AppItem item = appList.get(position);
            holder.title.setText(item.name);
            holder.itemView.setOnClickListener(v -> {
                Intent launchIntent = getPackageManager().getLaunchIntentForPackage(item.packageName);
                if (launchIntent != null) {
                    startActivity(launchIntent);
                }
            });
        }

        @Override
        public int getItemCount() {
            return appList.size();
        }

        class ViewHolder extends RecyclerView.ViewHolder {
            TextView title;
            ViewHolder(View itemView) {
                super(itemView);
                title = itemView.findViewById(R.id.app_title);
            }
        }
    }
}
