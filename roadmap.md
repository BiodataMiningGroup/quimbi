# QUIMBI Roadmap


## Issues

- Canvas cannot be scaled down (changing width and height attributes) so the image can be rendered more efficiently. The native canvas size prevents the canvasWrapper to become smaller. If the canvas is position: absolute; the wrapper has no more reference for its size.

- Make canvasWrapper resizing without additional resizer element?

- displayCtrl not needed?

- Make "reset" broadcast for all services on any error?


## Pending features

- Resizing of the canvas.

- Settings.

- Permanent error messages that can be hidden via mouseclick. For this tha angularmsg module has to be extended.

- Overlay image.


## Features

- Some globally visible information about the dataset (name?).

- View with further information about the dataset.

- Display of the color ratios in the hovered pixel.
		  --------------------------------------------
  idea: |rrrrrrrrr|ggg|bbbbbbbbbbbbbbbbbbbbbbbbbbbb|
		  --------------------------------------------