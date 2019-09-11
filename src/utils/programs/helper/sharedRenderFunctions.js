/**
 *
 * @param gl
 * @param assets
 * @param helpers
 */
export function setUpDistanceTexture(gl, assets, helpers, width, height) {
    if(typeof(assets.framebuffers.distances) === 'undefined') {
        assets.framebuffers.distances = gl.createFramebuffer();
    }
    gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.distances);
    let texture = helpers.newTexture('distanceTexture');
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
    gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
    gl.bindTexture(gl.TEXTURE_2D, null);
    gl.bindFramebuffer(gl.FRAMEBUFFER, null);
};

export function setUpColorMapTexture(gl, assets, helpers, width, height) { if (!assets.framebuffers.colorMapTexture) {
  assets.framebuffers.colorMapTexture = gl.createFramebuffer();
  gl.bindFramebuffer(gl.FRAMEBUFFER, assets.framebuffers.colorMapTexture);
  const texture = helpers.newTexture('colorMapTexture');
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
  gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
  gl.bindTexture(gl.TEXTURE_2D, null);
  return gl.bindFramebuffer(gl.FRAMEBUFFER, null);
} };


export function setUpChannelMask(gl, program, assets, helpers, channelTextureDimension) {
  let channelMaskTexture = null;
  gl.uniform1i(gl.getUniformLocation(program, 'u_channel_mask'), 0);
  gl.uniform1f(gl.getUniformLocation(program, 'u_channel_mask_dimension'), channelTextureDimension);
  gl.uniform1f(gl.getUniformLocation(program, 'u_inv_channel_mask_dimension'), 1 / channelTextureDimension);
  // check if texture already exists
  if (!(channelMaskTexture = assets.textures.channelMaskTexture)) {
    channelMaskTexture = helpers.newTexture('channelMaskTexture');
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, channelTextureDimension,
      channelTextureDimension, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
  }
  return channelMaskTexture;
};

export function setUpRegionMask(gl, program, assets, helpers, width, height) {
  let regionMaskTexture = null;
  gl.uniform1i(gl.getUniformLocation(program, 'u_region_mask'), 1);
  // check if texture already exists
  if (!(regionMaskTexture = assets.textures.regionMaskTexture)) {
    regionMaskTexture = helpers.newTexture('regionMaskTexture');
    // same dimensions as distance texture
    gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA,
      width, height,
      0, gl.RGBA, gl.UNSIGNED_BYTE, null);
  }
  return regionMaskTexture;
};

export function updateChannelMask(gl, mask, texture, channelTextureDimension) {
  gl.activeTexture(gl.TEXTURE0);
  gl.bindTexture(gl.TEXTURE_2D, texture);
  gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, false);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, channelTextureDimension, channelTextureDimension, 0, gl.RGBA, gl.UNSIGNED_BYTE, mask);
  console.log("channelTextureDimension", channelTextureDimension);
  gl.bindTexture(gl.TEXTURE_2D, null);
};

export function updateRegionMask(gl, mask, texture) {
  gl.activeTexture(gl.TEXTURE1);
  gl.bindTexture(gl.TEXTURE_2D, texture);
  gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);
  gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, gl.RGBA, gl.UNSIGNED_BYTE, mask);
  gl.bindTexture(gl.TEXTURE_2D, null);
};
