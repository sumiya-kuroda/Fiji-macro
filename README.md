# Fiji-macro
Useful ImageJ/Fiji macro for quick analysis on ScanImage Tif file

## Macros

### AvgStack
Reads the most recent `.tif` file from your saving location and produces an averaged image for quick inspection.

- Single-plane acquisitions only
- Supports 1 or 2 channels
- **TurboReg motion correction is not implemented yet** (too slow for quick check)

---

### AvgStackMultiPlanes
Extends `AvgStack` to multi-plane acquisitions. Deinterleaves the raw ScanImage tif by plane and channel, averages each plane independently, then recombines them into a scrollable `N x X x Y` stack in ImageJ.

- Supports 1 or 2 channels
- Supports 1–8 planes
- Output is a scrollable stack per channel (use `Analyze → Tools → Synchronize Windows` to scroll Green and Red channels simultaneously)
- Averaging is optional

---

### AvgStackMontage
Reads the most recent `.tif` file and produces a single tiled montage image showing all N planes in one window. Does **not** produce a scrollable stack.

| N planes | Grid |
|----------|------|
| 1        | 1×1  |
| 2        | 1×2  |
| 4        | 2×2  |
| 5        | 2×3  |
| 6        | 2×3  |
| 9        | 3×3  |

- Supports 1 or 2 channels
- Supports 1–8 planes
- Output is a single montage image per channel (no scrollable stack)
- 5px border between tiles
---

## Usage

1. Open Fiji/ImageJ
2. `Plugins → Macros → Run...` and select the desired `.ijm` file
3. Fill in the dialog:
   - **Data path**: folder where ScanImage saves your `.tif` files
   - **Use most recently acquired tif**: if checked, automatically picks the latest `.tif` in the folder; if unchecked, opens a folder browser
   - **Number of channels**: `1` (green only) or `2` (green + red)
   - **Number of planes** *(AvgStackMultiPlanes / AvgStackMontage only)*: must match the number of planes set in ScanImage
   - **Enable Averaging**: Z-project each plane sub-stack using Average Intensity

---

## Requirements

- [Fiji](https://fiji.sc/) (ImageJ with Bio-Formats bundled)
- Bio-Formats Importer (included in Fiji)
- Data acquired with [ScanImage](https://www.mbfbioscience.com/scanimage)

---

## Resources
- https://imagej.net/ij/macros/
- https://imagej.net/ij/developer/macro/functions.html#G
