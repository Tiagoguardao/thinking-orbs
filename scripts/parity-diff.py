#!/usr/bin/env python3
"""Compare browser and Swift frozen renders on their intended substrate."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

from PIL import Image, ImageChops, ImageStat


def composite(path: Path, dark: bool) -> Image.Image:
    image = Image.open(path).convert("RGBA")
    substrate = Image.new("RGBA", image.size, (0, 0, 0, 255) if dark else (255, 255, 255, 255))
    return Image.alpha_composite(substrate, image).convert("RGB")


def centroid(image: Image.Image, dark: bool) -> tuple[float, float]:
    grayscale = image.convert("L")
    pixels = list(grayscale.getdata())
    width, height = image.size
    weights = [float(value if dark else 255 - value) for value in pixels]
    total = sum(weights)
    if total == 0:
        return width / 2, height / 2
    x = sum((index % width) * weight for index, weight in enumerate(weights)) / total
    y = sum((index // width) * weight for index, weight in enumerate(weights)) / total
    return x, y


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("web", nargs="?", default="build/parity/web")
    parser.add_argument("swift", nargs="?", default="build/parity/swift")
    # The isolated and overlapping-circle probe stays below 0.23/255 mean
    # and 0.007 px centroid drift. Dense full frames amplify cross-libm
    # subpixel placement and face-on depth-tie ordering, so the recorded
    # cross-rasterizer budget is deliberately separate from the primitive
    # raster budget.
    parser.add_argument("--mean-threshold", type=float, default=5.0)
    parser.add_argument("--centroid-threshold", type=float, default=0.8)
    parser.add_argument("--report", default="build/parity/report.json")
    parser.add_argument("--expected-count", type=int, default=144)
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    web_directory = (root / args.web).resolve()
    swift_directory = (root / args.swift).resolve()
    web_files = {path.name: path for path in web_directory.glob("*.png")}
    swift_files = {path.name: path for path in swift_directory.glob("*.png")}
    names = sorted(set(web_files) | set(swift_files))
    failures: list[str] = []
    cases: list[dict[str, object]] = []

    for name in names:
        if name not in web_files or name not in swift_files:
            failures.append(f"missing {name}")
            continue
        dark = "-d-" in name
        web = composite(web_files[name], dark)
        swift = composite(swift_files[name], dark)
        if web.size != swift.size:
            failures.append(f"size {name}: {web.size} != {swift.size}")
            continue
        difference = ImageChops.difference(web, swift)
        mean = sum(ImageStat.Stat(difference).mean) / 3
        web_centroid = centroid(web, dark)
        swift_centroid = centroid(swift, dark)
        drift = ((web_centroid[0] - swift_centroid[0]) ** 2 + (web_centroid[1] - swift_centroid[1]) ** 2) ** 0.5
        cases.append({"name": name, "mean255": mean, "centroidDriftPx": drift})
        if mean > args.mean_threshold or drift > args.centroid_threshold:
            failures.append(f"{name}: mean={mean:.4f}/255 centroid={drift:.4f}px")

    report = {
        "caseCount": len(cases),
        "meanThreshold255": args.mean_threshold,
        "centroidThresholdPx": args.centroid_threshold,
        "worstMean255": max((case["mean255"] for case in cases), default=None),
        "worstCentroidDriftPx": max((case["centroidDriftPx"] for case in cases), default=None),
        "failures": failures,
        "cases": cases,
    }
    report_path = (root / args.report).resolve()
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n")
    print(json.dumps({key: report[key] for key in report if key != "cases"}, indent=2))
    if len(cases) != args.expected_count:
        failures.append(f"expected {args.expected_count} compared cases, found {len(cases)}")
    if failures:
        raise SystemExit(1)


if __name__ == "__main__":
    main()
