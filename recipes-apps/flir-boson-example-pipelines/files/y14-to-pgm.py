#!/usr/bin/python3

import struct
import sys

def raw_to_pgm(input_file, output_file, width, height):
    with open(input_file, "rb") as f:
        raw = f.read()

    pixels = struct.unpack_from(f"<{width*height}H", raw)

    min_val = min(pixels)
    max_val = max(pixels)
    scale = 255.0 / (max_val - min_val) if max_val != min_val else 1
    pixels8 = bytes(int((p - min_val) * scale) for p in pixels)

    with open(output_file, "wb") as f:
        f.write(f"P5\n{width} {height}\n255\n".encode())
        f.write(pixels8)

if __name__ == "__main__":
    if len(sys.argv) != 5:
        print(f"Usage: {sys.argv[0]} <input.raw> <output.pgm> <width> <height>")
        sys.exit(1)

    input_file  = sys.argv[1]
    output_file = sys.argv[2]
    width       = int(sys.argv[3])
    height      = int(sys.argv[4])

    raw_to_pgm(input_file, output_file, width, height)
    print(f"Saved {width}x{height} PGM to {output_file}")
