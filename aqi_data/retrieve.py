import requests
import time
import os
import pandas as pd

time_check = 30  # minutes
site_name = {1: "hoan_kiem", 13: "hang_dau"}

while True:
    for site_id in [1, 13]:
        for pollutant in ["NO2", "CO", "SO2", "PM2.5", "PM10", "O3"]:
            r = requests.get(
                "http://moitruongthudo.vn/public/dailystat/" + pollutant + "?site_id=" + str(site_id))
            if len(r.json()) == 0:
                continue

            fpath = os.path.join("concentration", site_name[site_id], pollutant + ".csv")
            if not os.path.exists(fpath):
                os.makedirs(os.path.dirname(fpath), exist_ok=True)
                with open(fpath, "w") as f:
                    pass
                df = pd.DataFrame(columns=["time", "value"])
            else:
                df = pd.read_csv(fpath)

            timestamps = set()
            timestamps.update(df["time"].tolist())

            for entry in r.json():
                if entry["time"] not in timestamps:
                    df.loc[len(df)] = [entry["time"], entry["value"]]
                    df.to_csv(fpath, index=False)
                    print("New entry at " + site_name[site_id] + ", " + entry["time"] + " for " + pollutant + " retrieved")

    print(str(time_check) + "m until next check")
    time.sleep(60 * time_check)
