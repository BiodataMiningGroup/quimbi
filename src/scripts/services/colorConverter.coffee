angular.module('quimbi').service 'colorConverter', ->

	XYZ_COMPARE = 0.008856
	RGB_COMPARE = 0.0031308

	lchFromBytes = (bytes) ->
		[
			bytes[0] / 255 * 100
			bytes[1] / 255 * 100
			bytes[2] / 255 * 360
		]

	labFromLch = (lch) ->
		h_rad = lch[2] * (Math.PI / 180)

		[
			lch[0]
			Math.cos(h_rad) * lch[1]
			Math.sin(h_rad) * lch[1]
		]

	xyzFromLab = (lab) ->
		Y = (lab[0] + 16) / 116
		X = lab[1] / 500 + Y
		Z = Y - lab[2] / 200

		tmp = Math.pow X, 3
		X = if tmp > XYZ_COMPARE then tmp else (X - 16 / 116) / 7.787

		tmp = Math.pow Y, 3
		Y = if tmp > XYZ_COMPARE then tmp else (Y - 16 / 116) / 7.787

		tmp = Math.pow Z, 3
		Z = if tmp > XYZ_COMPARE then tmp else (Z - 16 / 116) / 7.787

		[
			X * 95.047
			Y * 100
			Z * 108.883
		]

	rgbFromXyz = (xyz) ->
		tmp_X = 0.01 * xyz[0]
		tmp_Y = 0.01 * xyz[1]
		tmp_Z = 0.01 * xyz[2]

		R =  3.2406 * tmp_X - 1.5372 * tmp_Y - 0.4986 * tmp_Z
		R = if R > RGB_COMPARE then 1.055 * Math.pow(R, 1 / 2.4) - 0.055 else 12.92 * R

		G = -0.9689 * tmp_X + 1.8758 * tmp_Y + 0.0415 * tmp_Z
		G = if G > RGB_COMPARE then 1.055 * Math.pow(G, 1 / 2.4) - 0.055 else 12.92 * G

		B =  0.0557 * tmp_X - 0.2040 * tmp_Y + 1.0570 * tmp_Z
		B = if B > RGB_COMPARE then 1.055 * Math.pow(B, 1 / 2.4) - 0.055 else 12.92 * B

		[
			Math.max 0, Math.round R * 255
			Math.max 0, Math.round G * 255
			Math.max 0, Math.round B * 255
		]

	@rgbFromLchBytes = (bytes...) ->
		rgbFromXyz xyzFromLab labFromLch lchFromBytes bytes

	return