/*
 * Small library for dealing with multivariate image data using WebGL.
 * 
 * Requires WebGLUtils:
 * http://code.google.com/p/webglsamples/source/browse/book/webgl-utils.js?r=41401f8a69b1f8d32c6863ac8c1953c8e1e8eba0
 * Extended with a function to load shaders (from here):
 * https://developer.mozilla.org/en-US/docs/Web/WebGL/Adding_2D_content_to_a_WebGL_context
 * or here respectively:
 * http://webreflection.blogspot.de/2010/09/fragment-and-vertex-shaders-my-way-to.html
 */

mvi = function () {

// constants
var RENDER_NORMAL = 0,
// don't redraw the scene
   RENDER_IDLE = -1,
// clear the rtt texture (overwirte with 0)
   RTT_CLEAR = -2,
   RTT_ACTIVE_R = 10,
   RTT_ACTIVE_G = 20,
   RTT_ACTIVE_B = 30,
   RTT_PASSIVE_R = 1,
   RTT_PASSIVE_G = 2,
   RTT_PASSIVE_B = 4,
// different shader modes (depends on individual program)
   METHOD_DEFAULT = 0,
   METHOD_ANGLE = 0,
   METHOD_MINK = 10,
   METHOD_MINK_IGNORE_0 = 11;

// id of the animation frame while rendering
var animFrameID;

// object for measuring and displaying the fps
var time = {prev: 0, curr: 0, interval: 0, stor: []};

// function called before rendering. if it returns false, rendering is stopped
// (but the animation continues)
var prerenderCallback;

// callback for displaying errors
var messageCallback;

// current webgl context
var gl;

// texture information object (see below)
var texInfo;

var renderState = RENDER_NORMAL;
/*
 * constructor for an object with information about the data set and gl context
 */
 function mvTexInfo(input) {
   // width of one channel in pixels
   var width = 0;
   // height of one channel in pixels
   height = 0;

   // number of channels in every image
   var channels = 0;
   // number of images
   var noImgs = 0;

   // dimension of one WebGL texture image unit (squared)
   var dimTexImUnit = 0;
   // number of WebGL texture image units
   var noAvailTexImUnits = 0;
   // number of texture tiles per image
   var noTiles = 0;
   // number of tiles that fit in one row in texture image unit
   var noTilesPerRow = 0;
   // number of tile rows in the texture image unit
   var noRows = 0;
   // number of tile rows per texture image unit
   var noRowsPerTexImUnit = 0;
   // number of used channels in the last tile of the last row
   var noChannelsLastTile = 0;
   // number of needed texture image units
   var noTexImUnits = 0;
   // maximal occuring euclidean distance on this image
   var maxEuclDist = 0;
   // maximal occuring angle distance on this image
   var maxAngleDist = 0;

   // in case of there are multiple images as input
   var multipleImages, noImgsPerRow, noImgsRows;

   var hasValidProperties = function() {
      return !(width <= 0
         || height <= 0
         || channels <= 0
         || noImgs <= 0
         || dimTexImUnit <= 0
         || noAvailTexImUnits <= 0);
   };

   // extracts the information of an array of multivariate images
   // (array of arrays of images) and fills the MVTexInfo object with it
   var extractInfo = function(input) {
      if(!(input.images instanceof Array) || input.images.length == 0) {
         message("extractInfo: No input files!", 'error');
         return false;
      }

      var images = input.images;
      
      noImgs = images.length;
      channels = input.channels;
      maxEuclDist = input.maxEuclDist;
      maxAngleDist = input.maxAngleDist;

      for (var i = 0; i < images.length; i++) {         
         for (var j = 0; j < images[i].length; j++) {
            if ((width > 0 && images[i][j].width != width) || images[i][j].width == 0) {
               message("extractInfo: Inconsistent channel width!", 'error');
               return false;
            } else if (width == 0) {
               width = images[i][j].width;
            }

            if (input.channels && channels != input.channels) {
               message("extractInfo: Inconsistent channel width!" +
                  ' Given: ' + width + ', expected: ' + input.width + '.', 'error');
               return false;
            }
            
            if ((height > 0 && images[i][j].height != height) || images[i][j].height == 0) {
               message("extractInfo: Inconsistent channel height!", 'error');
               return false;
            } else if (height == 0) {
               height = images[i][j].height;
            }

            if (input.channels && channels != input.channels) {
               message("extractInfo: Inconsistent channel height!" +
                  ' Given: ' + height + ', expected: ' + input.height + '.', 'error');
               return false;
            }
         }
      }

      // in case of there are multiple images, calculate merged size
      if (noImgs > 1) {
         multipleImages = true;
         // calculate naive square textures
         noImgsPerRow = Math.ceil(Math.sqrt(noImgs));
         noImgsRows = Math.ceil(noImgs / noImgsPerRow);

         // now alter the values so the texture approximates a real square by pixels
         while (noImgsPerRow * width - noImgsRows * height > width) {
            noImgsPerRow--;
            noImgsRows += Math.ceil(noImgsRows / noImgsPerRow);
         }

         while (noImgsRows * height - noImgsPerRow * width > height) {
            noImgsRows--;
            noImgsPerRow += Math.ceil(noImgsPerRow / noImgsRows);
         }

         // new dimensions of merged images
         width *= noImgsPerRow;
         height *= noImgsRows;

      } else {
         multipleImages = false;
         noImgsPerRow = NaN;
         noImgsRows = NaN;
      }

      var gl = WebGLUtils.setupWebGL(document.createElement('canvas'));
      
      dimTexImUnit = gl.getParameter(gl.MAX_TEXTURE_SIZE);
      // last image unit is preserved for the custom framebuffer
      noAvailTexImUnits = gl.getParameter(gl.MAX_TEXTURE_IMAGE_UNITS) - 1;

      if (!hasValidProperties()) {
         message('extractInfo: Bad image properties.', 'error')
         return false;
      }

      if (dimTexImUnit < width || dimTexImUnit < height) {
         message('extractInfo: Not enough space in texture register!\n' +
            width + 'x' + height + ' needed but only ' +
            dimTexImUnit + 'x' + dimTexImUnit + ' available.', 'error');
         return false;
      }

      if (noAvailTexImUnits < noTexImUnits) {
         message('extractInfo: Not enough texture registers (too many channels/images)!\n' +
            noTexImUnits + ' needed but only ' + noAvailTexImUnits + ' available.', 'error');
         return false;
      }

      noTiles = Math.ceil(channels / 4);

      // calculate equal distrubution of tiles over all available texture
      // image units
      var exactNoTilesPerTexImUnit = noTiles / noAvailTexImUnits;
      var exactNoTilesPerRow = Math.sqrt(exactNoTilesPerTexImUnit)

      // size of a naive tile-square in one texture image unit
      noTilesPerRow = Math.ceil(exactNoTilesPerRow);
      noRowsPerTexImUnit = Math.ceil(exactNoTilesPerTexImUnit / noTilesPerRow);

      // now alter the values so the texture approximates a real square by pixels
      while (noTilesPerRow * width - noRowsPerTexImUnit * height > width) {
         noTilesPerRow--;
         noRowsPerTexImUnit += Math.ceil(noRowsPerTexImUnit / noTilesPerRow);
      }

      while (noRowsPerTexImUnit * height - noTilesPerRow * width > height) {
         noRowsPerTexImUnit--;
         noTilesPerRow += Math.ceil(noTilesPerRow / noRowsPerTexImUnit);
      }

      // check for overflows
      if (Math.floor(dimTexImUnit / width) < noTilesPerRow
         || Math.floor(dimTexImUnit / height) < noRowsPerTexImUnit) {
         message('extractInfo: Not enough space in texture register!\n' +
            width * noTilesPerRow + 'x' + height * noRowsPerTexImUnit +
            ' needed but only ' + dimTexImUnit + 'x' + dimTexImUnit +
            ' available.');
         return false;
      }

      var tmp = channels % 4;
      noChannelsLastTile = (tmp == 0) ? 4 : tmp;

      // calculated at last
      noTexImUnits = Math.ceil(noTiles / (noTilesPerRow * noRowsPerTexImUnit));

      return true;
   };

   // constructor function, call of extractInfo
   if (!input || !extractInfo(input)) {
      return null;
   } else {
      // if everything looks fine, return texInfo singleton
      return {
         noTiles: noTiles,
         noTilesPerRow: noTilesPerRow,
         noChannelsLastTile: noChannelsLastTile,
         width: width,
         height: height,
         noChannels: channels,
         noTexImUnits: noTexImUnits,
         noRowsPerTexImUnit: noRowsPerTexImUnit,
         multipleImages: multipleImages,
         noImgsPerRow: noImgsPerRow,
         maxEuclDist: maxEuclDist,
         maxAngleDist: maxAngleDist
      }   
   }
};//--mvTexInfo

/*
 * Loads and modifies shader, links program, sets texture coordinates,
 * vertex and index buffers, as well as the rtt framebuffer and texture
 */
var prepareGL = function(canvas, scale) {
    canvas.width = texInfo.width * scale;
    canvas.height = texInfo.height * scale;

    // preservedrawingbuffer to be able to export the canvas image as dataURL
    var gl = WebGLUtils.setupWebGL(canvas, {preserveDrawingBuffer: true});

   // index of last texture unit for rttTexture (render to texture)
   var rttTextureIndex = gl.getParameter(gl.MAX_TEXTURE_IMAGE_UNITS) - 1;

   // flip texture y axis so they are displayed correctly
   // not very expensive because the textures are loaded only once
   gl.pixelStorei(gl.UNPACK_FLIP_Y_WEBGL, true);

   // setup a GLSL program
   var program = WebGLUtils.initShaders(gl, function(source) {
      // modify the constants of the fragment shader before compiling
      
      var source = source.replace(/<%=[A-Z_]*=%>/g, function(thisMatch) {
         // remove <%= and =%>
         thisMatch = thisMatch.slice(3, -3);
         switch(thisMatch) {
            case "NO_TILES":
               return texInfo.noTiles;
               break;
            case "NO_TILES_PER_SAMPLER":
               var no = texInfo.noTilesPerRow * texInfo.noRowsPerTexImUnit;
               // append .0 if its a whole number
               return (no % 1 !== 0) ? no : no + '.0';
               break;
            case "NO_LAST_CHANNELS":
               return texInfo.noChannelsLastTile;
               break;
            case "NO_TILES_PER_ROW":
               var no = texInfo.noTilesPerRow;
               no = (texInfo.noTiles < no) ? texInfo.noTiles : no;
               // append .0 if its a whole number
               return (no % 1 !== 0) ? no : no + '.0';
               break;
            case "TILE_HEIGHT":
               var no = 1 / texInfo.noRowsPerTexImUnit;
               // append .0 if its a whole number
               return (no % 1 !== 0) ? no : no + '.0';
               break;
            case "TILE_WIDTH":
               var no = 1 / texInfo.noTilesPerRow
               // append .0 if its a whole number
               return (no % 1 !== 0) ? no : no + '.0';
               break;
            case "SAMPLER_DEF":
               var ret = '';
               for (var i = 0, len = texInfo.noTexImUnits; i < len; i++) {
                  ret += 'uniform sampler2D u_sampler' + i + ';';
               }
               return ret;
               break;
            case "SAMPLER_LOOKUP":
               var ret = '';
               for (var i = 0, len = texInfo.noTexImUnits; i < len; i++) {
                  ret += 'if (samplerNo == ' + i + '.0) return texture2D('
                     + 'u_sampler' + i + ', coords2d);\n\t';
               }
               return ret;
               break;
            case "RTT_SAMPLER":
               return 'u_sampler' + rttTextureIndex;
               break;
            case "MINK_NORMALIZATION":
               // inverse of texInfo.maxEuclDist / 255!
               var no = 255 / texInfo.maxEuclDist;
               return (no % 1 !== 0) ? no : no + '.0';
               break;
            case "ANGLE_NORMALIZATION":
               // inverse of pi/2 -> 1/(pi/2) = 2/pi
               var no = 1 / texInfo.maxAngleDist;
               return (no % 1 !== 0) ? no : no + '.0';
               break;
            default:
               return "";
         }
      });
      //alert(source);
      return source;
   });
   
   // set up texture coordinates
   var texCoordLocation = gl.getAttribLocation(program, "a_texCoord");

   // provide texture coordinates for the rectangle.
   var texCoordBuffer = gl.createBuffer();
   gl.bindBuffer(gl.ARRAY_BUFFER, texCoordBuffer);
   
   // draw arrays is called as TRIANGLE_STRIP so only 4 vertices are defined
   gl.bufferData(
      gl.ARRAY_BUFFER,
      new Float32Array([
         0.0,  0.0,
         1.0,  0.0,
         0.0,  1.0,
         1.0,  1.0]),
      gl.STATIC_DRAW
   );
   
   gl.enableVertexAttribArray(texCoordLocation);
   // texture coordinates are only assigned to texture level 0
   gl.vertexAttribPointer(texCoordLocation, 2, gl.FLOAT, false, 0, 0);

   // Create a buffer and put a single clipspace rectangle in
   // it (2 triangles)
   var buffer = gl.createBuffer();
   gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
   
   // draw arrays is called as TRIANGLE_STRIP so only 4 vertices are defined
   gl.bufferData(
      gl.ARRAY_BUFFER,
      new Float32Array([
         -1.0, -1.0,
         1.0, -1.0,
         -1.0, 1.0,
         1.0, 1.0
         ]),
      gl.STATIC_DRAW
   );
   
   // look up where the vertex data needs to go.
   var positionLocation = gl.getAttribLocation(program, "a_position");
   gl.enableVertexAttribArray(positionLocation);
   gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);
   
   // indexbuffer for re-using the defined vertices above for two triangles
   var indexBuffer = gl.createBuffer();
   gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, indexBuffer);
   gl.bufferData(gl.ELEMENT_ARRAY_BUFFER,
      new Uint16Array([   0, 1, 2, 3 ]),
      gl.STATIC_DRAW
   );

   // create custom framebuffer and rtt texture
   var rttFrameBuffer = gl.createFramebuffer();
   gl.bindFramebuffer(gl.FRAMEBUFFER, rttFrameBuffer);

   var rttTexture = gl.createTexture();
   // use last image unit
   gl.activeTexture(gl.TEXTURE0 + rttTextureIndex);
   gl.bindTexture(gl.TEXTURE_2D, rttTexture);

   gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
   gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
   gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
   gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);

   // zero-fill texture
   gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, texInfo.width, texInfo.height, 0, gl.RGBA, gl.UNSIGNED_BYTE, null);
   // bind uniform sampler to this texutre image unit
   gl.uniform1i(gl.getUniformLocation(program, "u_sampler" + rttTextureIndex), rttTextureIndex);
   // bind rtt texture to the custom framebuffer
   gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, rttTexture, 0);
   // unbind custom framebuffer
   gl.bindFramebuffer(gl.FRAMEBUFFER, null);

   // shader uniform for the render state
   var state = gl.getUniformLocation(program, "u_state");

   // shader uniform for the computing method
   var method = gl.getUniformLocation(program, "u_method");
   gl.uniform1i(method, METHOD_DEFAULT);

   // array for the textures (created on demand while loading)
   var textures = new Array();

   // set properties for further use in external functions
   gl.program = program;
   gl.textures = textures;
   gl.texCoordBuffer = texCoordBuffer;
   gl.vertexBuffer = buffer;
   gl.indexBuffer = indexBuffer;
   gl.rttFrameBuffer = rttFrameBuffer;
   gl.rttTexture = rttTexture;
   gl.renderState = state;
   gl.computingMethod = method;

   return gl;
};

/*
 * Creates a new empty texture, allocates the next texture image unit,
 * binds the respective uniform sampler and adds the texture reference
 * to the texture array.
 * Used to create new textures on demand while processing the images.
 */
 var addTexture = function(textureNo) {
   // console.log('Tex No. ' + textureNo + ' of ' + texInfo.noTexImUnits);
   if (textureNo >= texInfo.noTexImUnits) {
      message('Texture number exceeding calculated size.', 'error');
      return;
   }

   // all textures with the same size
   // otherwise the TILE_WIDTH and TILE_HEIGHT varies in the fragment shader
   var height = texInfo.noRowsPerTexImUnit * texInfo.height;
   var width = texInfo.noTilesPerRow * texInfo.width;

   var texture = gl.createTexture();
   // activate texture image unit
   gl.activeTexture(gl.TEXTURE0 + textureNo);
   // bind texture to texture image unit. this texture image unit will
   // be specifically reserved for this texture, so this is the only
   // call of bindTexture. further on only activeTexture will be used to
   // work on the different textures
   // see here for more information about texture binding:
   // http://www.arcsynthesis.org/gltut/Texturing/Tutorial%2014.html
   gl.bindTexture(gl.TEXTURE_2D, texture);

   // set the parameters so images that are NPOT (not power of two)
   // can be rendered, too
   gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.CLAMP_TO_EDGE);
   gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.CLAMP_TO_EDGE);
   // enables bilinear filtering if the canvas has a smaller size than the image
   gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR);
   gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST);
   
   // allocate needed space with blank texture
   gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, width, height, 0, gl.RGBA,
      gl.UNSIGNED_BYTE, null);

   //TODO check for out of memory errors!

   // bind respective sampler to texture image unit textureNo
   gl.uniform1i(gl.getUniformLocation(gl.program, "u_sampler" + textureNo), textureNo);

   // call draw elements so the textures are copied to GPU memory
   // and system memory is freed (important!)
   gl.drawElements(gl.TRIANGLE_STRIP, 4, gl.UNSIGNED_SHORT, 0);

   // make sure the texture is ready because it will be needed immediately
   gl.finish();
   gl.textures[textureNo] = texture;
};

var unpackTexture = function(channels, displayCall, progressCall) {
   // defines number of parallel running webworkers
   var pack = 5;
   // in case there are < pack tiles to process
   pack = (pack > texInfo.noTiles) ? texInfo.noTiles : pack;

   // set premultiply alpha explicitly to preserve the exact color values
   gl.pixelStorei(gl.UNPACK_PREMULTIPLY_ALPHA_WEBGL, false);

   // use timeout to slow down the loop and don't freeze the UI
   var index = 0;
   var len = texInfo.noTiles;

   function step() {
      var pack = 1000;

      while (pack-- && index < len) {
         applyTexture(channels[index], index);
         index++;
         progressCall(index / len);
      }

      if (index < len) {
         setTimeout(step, 500);
      } else {
         displayCall();
      }
   }
   // init processing
   step();
};

/*
 * Fills the texture defined in gl with the given channels which were merged
 * to RGBA images. The texture is filled "row major" with the RGBA images.
 */
 var applyTexture = function(item, index) {
   // index of the tile on its respective texture
   var indexOnTexImUnit = index % (texInfo.noTilesPerRow * texInfo.noRowsPerTexImUnit);
   // number of the texture to draw this tile on
   var textureIndex = Math.floor(index / (texInfo.noTilesPerRow * texInfo.noRowsPerTexImUnit));

   // add new texture unit if needed
   // (so not all units are created and occupy the system memory at once)
   if (gl.textures[textureIndex] == undefined) {
      addTexture(textureIndex);
   }

   var xoffset = indexOnTexImUnit % texInfo.noTilesPerRow * item.width;
   var yoffset = Math.floor(indexOnTexImUnit / texInfo.noTilesPerRow) * item.height;

   // activate respective texture image unit. this unit is reserved for a
   // single texture, so only the correct texture will be affected.
   gl.activeTexture(gl.TEXTURE0 + textureIndex);
   gl.texSubImage2D(gl.TEXTURE_2D, 0, xoffset, yoffset, gl.RGBA,
      gl.UNSIGNED_BYTE, item);
   gl.finish();

   // NO unbinding! all non-active/non-bound textures will be held in system memory.
   // so if all are active the memory is not overly occupied
   // one texture image unit is reserved only for a single texture
   //gl.bindTexture(gl.TEXTURE_2D, null);
};

/*
 * Merges multiple images to one. All equal channels are merged to one image
 * so the result can be treated as a single image with equal channel count.
 */
 var mergeImages = function(images) {
    var ret = new Array(texInfo.noChannels);

   // iteration over channels
   for (var i = 0; i < ret.length; i++) {
      // create a canvas for every new channel
      // as it can be processed like an image object most times
      var c = document.createElement('canvas');
      c.width = texInfo.width;
      c.height = texInfo.height;
      var ctx = c.getContext('2d');

      // iteration over images
      for (var j = 0; j < images.length; j++) {
         var xoffset = j % texInfo.noImgsPerRow;
         var yoffset = Math.floor(j / texInfo.noImgsPerRow);
         var image = images[j][i];
         //console.log('image (' + j + ',' + i + ') put on ' + i + ' ' + xoffset + 'x' + yoffset);
         ctx.drawImage(image, image.width * xoffset, image.height * yoffset);
      }

      ret[i] = c;
   }

   return ret;
};

var calcFPS = function(suffix) {
   var suffix = (suffix) ? suffix : '';
   time.stor.push(time.curr - time.prev);
   
   if (time.curr - time.interval > 1000) {
      time.interval = time.curr;
      // get median
      var tmp = time.stor.sort( function(a,b) {return a - b;} );
      tmp = time.stor[Math.floor(time.stor.length / 2)];
      
      time.stor.length = 0;
      console.info(Math.round(1000 / tmp * 10) / 10 + ' fps' + suffix);
   }
};

/*
 * Performs a single rendering.
 */
var renderOnce = function(state) {
   state = (typeof state == 'number') ? state : renderState;
   if (state == RENDER_IDLE) {
      //calcFPS(' idle');
      return;
   }
   // assign render state
   gl.uniform1i(gl.renderState, state);
   // set viewport to current canvas size
   gl.viewport(0, 0, gl.drawingBufferWidth, gl.drawingBufferHeight);

   // draw
   gl.drawElements(gl.TRIANGLE_STRIP, 4, gl.UNSIGNED_SHORT, 0);
};

/*
 * Renders the current scene to the rttTexture
 */
var snapshot = function(state) {
   // bind rtt framebuffer
   gl.bindFramebuffer(gl.FRAMEBUFFER, gl.rttFrameBuffer);
   // reset viewport
   gl.viewport(0, 0, texInfo.width, texInfo.height);
   // render
   gl.drawElements(gl.TRIANGLE_STRIP, 4, gl.UNSIGNED_SHORT, 0);
   // unbind rtt framebuffer
   gl.bindFramebuffer(gl.FRAMEBUFFER, null);
   gl.finish();
   // render normally to the canvas
   renderOnce(state);
};

/*
 * Flushes the rtt texture with an empty image.
 */
var clearRttTexture = function() {
   gl.uniform1i(gl.renderState, RTT_CLEAR);
   gl.bindFramebuffer(gl.FRAMEBUFFER, gl.rttFrameBuffer);
   gl.drawElements(gl.TRIANGLE_STRIP, 4, gl.UNSIGNED_SHORT, 0);
   gl.bindFramebuffer(gl.FRAMEBUFFER, null);
   gl.uniform1i(gl.renderState, RENDER_NORMAL);
   gl.finish();
};

/*
 * Function for the rendering loop.
 */
 var render = function() {
    // for calcFPS
    // time.prev = time.curr;
    // time.curr = Date.now();
   // cross-browser animation loop from WebGLUtils
   animFrameID = window.requestAnimFrame(render);

   renderState = mvi.RENDER_NORMAL;
   if (prerenderCallback instanceof Function) {
      renderState = prerenderCallback();
   }

   renderOnce(renderState);
   
   // for testing
   // calcFPS();
};

var stopRendering = function() {
   // cross-browser animation canceling from WebGLUtils
   if (animFrameID) window.cancelAnimFrame(animFrameID);
   animFrameID = undefined;
};


var startRendering = function() {
   stopRendering();
   render();
};

/*
 *   Sets up the mvi object. Initializes the WebGL context, creates and loads
 * the texture and calls readyCall when finished.
 */
 var setUp = function(canv, input, readyCall, progressCall) {
    if (!(readyCall instanceof Function) || !(progressCall instanceof Function)) {
       finish();
       return 'false';
    }

    texInfo = mvTexInfo(input);

    if (texInfo === null) {
       finish();
       return false;
    }

   // merge multiple images to one
   if (texInfo.multipleImages) {
      message('glmvilib:Merging images', 'info');
      input.images = mergeImages(input.images);
   } else {
      input.images = input.images.shift();
   }

   gl = prepareGL(canv, 1);

   if (!gl) {
      finish();
      return false;
   }
   
   //works only with 1 image (so multiple images are merged above)
   unpackTexture(input.images, readyCall, progressCall);

   return true;
};

/*
 * Stops rendering, frees allocated memory and cleans up.
 */
 var finish = function() {
    stopRendering();

    if (!gl) return;
    
    gl.deleteBuffer(gl.texCoordBuffer);
    gl.deleteBuffer(gl.vertexBuffer);
    gl.deleteBuffer(gl.indexBuffer);

    for (var i = 0, len = gl.textures.length; i < len; i++) {
       gl.deleteTexture(gl.textures[i]);
    }
    gl.deleteTexture(gl.rttTexture);

   // TODO shader apparently aren't deleted correctly
   gl.deleteShader(gl.program.vertexShader);
   gl.deleteShader(gl.program.fragmentShader);
   gl.deleteProgram(gl.program);
   
   gl = null;
};

/*
 * Set hook for cleaning up when leaving the website.
 */
window.onbeforeunload = function() {
   finish();
};

var message = function(msg, type) {
   type = (type) ? type : '';
   msg = 'glmvilib::' + msg;
   if (messageCallback && messageCallback instanceof Function) {
      messageCallback(msg, type);
      return;
   }
   
   switch (type) {
      case "info":
      console.info(msg);
      break;
      case "warn":
      console.warn(msg);
      break;
      case "error":
      console.error(msg);
      break;
      default:
      console.log(msg);
   }
};

var setComputingMethod = function(value) {
   gl.uniform1i(gl.computingMethod, value);
};

// return singleton
return {
   startRendering: startRendering,
   renderOnce: renderOnce,
   stopRendering: stopRendering,
   finish: finish,
   setUp: setUp,
   snapshot: snapshot,
   clearRttTexture: clearRttTexture,
   getContext: function() { return gl; },
   getProgram: function() { return gl.program; },
   setPrerenderCallback: function(a) { prerenderCallback = a; },
   setMessageCallback: function(a) { messageCallback = a; },
   setComputingMethod: setComputingMethod,
   RENDER_NORMAL: RENDER_NORMAL,
   RENDER_IDLE: RENDER_IDLE,
   RTT_CLEAR: RTT_CLEAR,
   RTT_ACTIVE_R: RTT_ACTIVE_R,
   RTT_ACTIVE_G: RTT_ACTIVE_G,
   RTT_ACTIVE_B: RTT_ACTIVE_B,
   RTT_PASSIVE_R: RTT_PASSIVE_R,
   RTT_PASSIVE_G: RTT_PASSIVE_G,
   RTT_PASSIVE_B: RTT_PASSIVE_B,
   METHOD_DEFAULT: METHOD_DEFAULT,
   METHOD_ANGLE: METHOD_ANGLE,
   METHOD_MINK: METHOD_MINK,
   METHOD_MINK_IGNORE_0: METHOD_MINK_IGNORE_0
}
}();//--mvi
