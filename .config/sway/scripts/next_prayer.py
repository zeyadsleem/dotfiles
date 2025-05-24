# #!/usr/bin/env python3
# from praytimes import PrayTimes
# from datetime import datetime, timedelta
#
# latitude = 30.0444
# longitude = 31.2357
# timezone = 2  # توقيت القاهرة UTC+2
#
# pt = PrayTimes("Egypt")
#
# now = datetime.now()
#
# times = pt.getTimes((now.year, now.month, now.day), (latitude, longitude), timezone)
#
# prayer_names = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
#
# prayer_times = {}
# for name in prayer_names:
#     time_str = times[name]
#     hour, minute = map(int, time_str.split(":"))
#     prayer_time = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
#     if prayer_time < now:
#         prayer_time += timedelta(days=1)
#     prayer_times[name] = prayer_time
#
# next_prayer = min(prayer_times.items(), key=lambda x: x[1])
#
# print(f"🕌 {next_prayer[0].capitalize()} {next_prayer[1].strftime('%I:%M %p')}")
