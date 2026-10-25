#!/usr/bin/env -S uv run --quiet --script
# /// script
# dependencies = ["hijri-converter"]
# ///

"""The Hijri date, in Arabic by default."""

ARABIC_DIGITS = str.maketrans("0123456789", "٠١٢٣٤٥٦٧٨٩")


def format_hijri(day: int, month_name: str, year: int, *, lang: str = "ar") -> str:
    """The Hijri date as one line, in Arabic or English."""
    if lang == "ar":
        text = f"{day} {month_name} {year} هـ"
        return text.translate(ARABIC_DIGITS)
    return f"{day} {month_name} {year} AH"


def main(argv: list[str] | None = None) -> int:
    import argparse

    from hijri_converter import Gregorian

    parser = argparse.ArgumentParser(description="the Hijri date")
    parser.add_argument("--english", action="store_true", help="print the English form")
    args = parser.parse_args(argv)

    hijri = Gregorian.today().to_hijri()
    lang = "en" if args.english else "ar"
    print(format_hijri(hijri.day, hijri.month_name(lang), hijri.year, lang=lang))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
