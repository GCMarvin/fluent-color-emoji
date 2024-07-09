#!/bin/bash

# On error, exit immediately.
set -e

# Remove potential leftovers from older builds.
rm -r venv build

# Create clean Python environment.
python -m venv --upgrade-deps venv
source venv/bin/activate
pip install nanoemoji

# Prepare the emoji SVG files for nanoemoji by:
# 1) Renaming them from 'glyph_name.svg' to 'emoji_uxxxx.svg'.
# 2) Removing SVG masks them, as these are not compatible with picosvg.
#    When this happens, a message is printed, specifying the glyph. This
#    will slightly change how the glyph looks. This is preferred over not
#    including the glyph at all.
# 3) Moving them all into one common directory.
python -m prepare

# Patch the nanoemoji package to exclude glyphs with incompatibilites
# instead of aborting completely.
git apply --directory venv/lib/*/site-packages/nanoemoji nanoemoji.patch

# Build the ttf font file using the COLR1 format for the colored glyphs.
pushd build
nanoemoji --color_format glyf_colr_1 --family 'Fluent Color Emoji' --output_file FluentColorEmoji.ttf *.svg

# Patch the font file to also include a CFFI color table, which is required
# by many platforms for correctly displaying the font.
pushd build
maximum_color --bitmaps --output_file FluentColorEmoji.ttf FluentColorEmoji.ttf

popd
popd
mv build/build/build/FluentColorEmoji.ttf build/FluentColorEmoji.ttf
rm -r venv build/build build/*.svg
