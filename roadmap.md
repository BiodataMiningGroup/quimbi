# QUIMBI Roadmap


## Issues

- Make "reset" broadcast for all services on any error?

- Canvas is scalable >100% and elements break if window is too small.

- Is the default tool active on startup?

- Chrome: MutationObserver doesn't fire on resize. Confirmed bug:
  http://code.google.com/p/chromium/issues/detail?id=293948

- Chrome: Cursor doesn't change on hover over resize handle.

- Chrome: 'image-rendering' is not supported on all systems.
  Workaround: Added renderUpscale option (doesn't work in Chrome until
  MutationObserver issue is solved).


## Pending features

- Overlay image. Implemented but no sources exist!


## Features

- Some globally visible information about the dataset (name?).

- View with further information about the dataset.

- Add feature to export the current image.


## Solved

- Rounding for readPixel isn't accurate. Use Math.floor()?