# #!/usr/bin/env python3
# import time
# from datetime import datetime, timedelta
# from praytimes import PrayTimes
# import subprocess
#
# latitude = 30.0444
# longitude = 31.2357
# timezone = 2  # توقيت القاهرة UTC+2
#
# pt = PrayTimes("Egypt")
#
#
# def send_notification(prayer_name, prayer_time):
#     message = f"الصلاة {prayer_name.capitalize()} هتبدأ الساعة {prayer_time.strftime('%I:%M %p')}\nجهز نفسك للتوضيء!"
#     subprocess.run(["notify-send", "تذكير الصلاة", message])
#
#
# def main():
#     notified_for = None  # لتجنب إرسال إشعار مكرر لنفس الصلاة
#
#     while True:
#         now = datetime.now()
#         times = pt.getTimes(
#             (now.year, now.month, now.day), (latitude, longitude), timezone
#         )
#
#         prayer_names = ["fajr", "dhuhr", "asr", "maghrib", "isha"]
#         prayer_times = {}
#
#         for name in prayer_names:
#             time_str = times[name]
#             hour, minute = map(int, time_str.split(":"))
#             prayer_time = now.replace(hour=hour, minute=minute, second=0, microsecond=0)
#             if prayer_time < now:
#                 prayer_time += timedelta(days=1)
#             prayer_times[name] = prayer_time
#
#         next_prayer = min(prayer_times.items(), key=lambda x: x[1])
#         prayer_name, prayer_time = next_prayer
#
#         # احسب الفرق بين الوقت الحالي ووقت الصلاة
#         diff = prayer_time - now
#
#         # لو باقي أقل من 15 دقيقة و لم نرسل إشعار للصلاة دي قبل كده
#         if (
#             timedelta(minutes=14, seconds=50) < diff <= timedelta(minutes=15)
#             and notified_for != prayer_name
#         ):
#             send_notification(prayer_name, prayer_time)
#             notified_for = prayer_name
#
#         # بعد الصلاة نعيد تعيين الإشعار
#         if diff < timedelta(minutes=0):
#             notified_for = None
#
#         time.sleep(30)  # تحقق كل 30 ثانية
#
#
# if __name__ == "__main__":
#     main()
