/*
 * Copyright 2010, Google Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


/**
 * @fileoverview This file contains functions every webgl program will need
 * a version of one way or another.
 *
 * Instead of setting up a context manually it is recommended to
 * use. This will check for success or failure. On failure it
 * will attempt to present an approriate message to the user.
 *
 *       gl = WebGLUtils.setupWebGL(canvas);
 *
 * For animated WebGL apps use of setTimeout or setInterval are
 * discouraged. It is recommended you structure your rendering
 * loop like this.
 *
 *       function render() {
 *         window.requestAnimFrame(render, canvas);
 *
 *         // do rendering
 *         ...
 *       }
 *       render();
 *
 * This will call your rendering function up to the refresh rate
 * of your display but will stop rendering if your app is not
 * visible.
 */

WebGLUtils = function() {

/**
 * Creates the HTLM for a failure message
 * @param {string} canvasContainerId id of container of th
 *        canvas.
 * @return {string} The html.
 */
var makeFailHTML = function(msg) {
  return '' +
    '<table style="background-color: #8CE; width: 100%; height: 100%;"><tr>' +
    '<td align="center">' +
    '<div style="display: table-cell; vertical-align: middle;">' +
    '<div style="">' + msg + '</div>' +
    '</div>' +
    '</td></tr></table>';
};

/**
 * Mesasge for getting a webgl browser
 * @type {string}
 */
var GET_A_WEBGL_BROWSER = '' +
  'This page requires a browser that supports WebGL.<br/>' +
  '<a href="http://get.webgl.org">Click here to upgrade your browser.</a>';

/**
 * Mesasge for need better hardware
 * @type {string}
 */
var OTHER_PROBLEM = '' +
  "It doesn't appear your computer can support WebGL.<br/>" +
  '<a href="http://get.webgl.org/troubleshooting/">Click here for more information.</a>';

/**
 * Creates a webgl context. If creation fails it will
 * change the contents of the container of the <canvas>
 * tag to an error message with the correct links for WebGL.
 * @param {Element} canvas. The canvas element to create a
 *     context from.
 * @param {WebGLContextCreationAttirbutes} opt_attribs Any
 *     creation attributes you want to pass in.
 * @return {WebGLRenderingContext} The created context.
 */
var setupWebGL = function(canvas, opt_attribs) {
  function showLink(str) {
    var container = canvas.parentNode;
    if (container) {
      container.innerHTML = makeFailHTML(str);
    }
  };

  if (!window.WebGLRenderingContext) {
    showLink(GET_A_WEBGL_BROWSER);
    return null;
  }

  var context = create3DContext(canvas, opt_attribs);
  if (!context) {
    showLink(OTHER_PROBLEM);
  }
  return context;
};

/**
 * Creates a webgl context.
 * @param {!Canvas} canvas The canvas tag to get context
 *     from. If one is not passed in one will be created.
 * @return {!WebGLContext} The created context.
 */
var create3DContext = function(canvas, opt_attribs) {
  var names = ["webgl", "experimental-webgl", "webkit-3d", "moz-webgl"];
  var context = null;
  for (var ii = 0; ii < names.length; ++ii) {
    try {
      context = canvas.getContext(names[ii], opt_attribs);
    } catch(e) {}
    if (context) {
      break;
    }
  }
  return context;
}

// Extension for loading shaders from file
// our shaders base path
loadShaders.base = "./shader/";

// our shaders loader
function loadShaders(gl, shaders, shaderMod, callback) {
    // (C) WebReflection - Mit Style License
    function onreadystatechange() {
        var
            xhr = this,
            i = xhr.i
        ;
        if (xhr.readyState == 4) {
            shaders[i] = gl.createShader(
                shaders[i].slice(0, 2) == "fs" ?
                    gl.FRAGMENT_SHADER :
                    gl.VERTEX_SHADER
            );
            gl.shaderSource(shaders[i], shaderMod(xhr.responseText));
            gl.compileShader(shaders[i]);
            if (!gl.getShaderParameter(shaders[i], gl.COMPILE_STATUS)) {
                alert("An error occurred compiling the shaders: " + gl.getShaderInfoLog(shaders[i]));
                throw gl.getShaderInfoLog(shaders[i]);
            }
            !--length && typeof callback == "function" && callback(shaders);
        }
    }
    for (var
        shaders = [].concat(shaders),
        asynchronous = !!callback,
        i = shaders.length,
        length = i,
        xhr;
        i--;
    ) {
        (xhr = new XMLHttpRequest).i = i;
        xhr.overrideMimeType("text/plain");
        xhr.open("get", loadShaders.base + shaders[i], asynchronous);
        if (asynchronous) {
            xhr.onreadystatechange = onreadystatechange;
        }
        xhr.send(null);
        onreadystatechange.call(xhr);
    }
    return shaders;
}

/*
 * extension from here: https://developer.mozilla.org/en-US/docs/Web/WebGL/Adding_2D_content_to_a_WebGL_context
 * additionaly with a callback for modifying the shader before compiling.
 */
var getShader =function(gl, id, shaderMod) {
  var shaderScript, theSource, currentChild, shader;
   
  shaderScript = document.getElementById(id);
   
  if (!shaderScript) {
    return null;
  }
   
  theSource = "";
  currentChild = shaderScript.firstChild;
   
  while(currentChild) {
    if (currentChild.nodeType == currentChild.TEXT_NODE) {
      theSource += currentChild.textContent;
    }
     
    currentChild = currentChild.nextSibling;
  }
  
  // modify shader before compiling
  if (shaderMod && shaderMod instanceof Function) {
  	theSource = shaderMod(theSource);
  }
  
  if (shaderScript.type == "x-shader/x-fragment") {
    shader = gl.createShader(gl.FRAGMENT_SHADER);
  } else if (shaderScript.type == "x-shader/x-vertex") {
    shader = gl.createShader(gl.VERTEX_SHADER);
  } else {
     // Unknown shader type
     return null;
  }
  
  gl.shaderSource(shader, theSource);
     
  // Compile the shader program
  gl.compileShader(shader);  
     
  // See if it compiled successfully
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {  
      alert("An error occurred compiling the shaders: " + gl.getShaderInfoLog(shader));  
      return null;  
  }
     
  return shader;
}

/* 
 * extension from here: https://developer.mozilla.org/en-US/docs/Web/WebGL/Adding_2D_content_to_a_WebGL_context
 * additionaly with a callback for modifying the shader before compiling.
 */
var initShaders = function(gl, shaderMod) {
  // get shader from script
  //var fragmentShader = getShader(gl, "shader-fs", shadermodCallback);
  //var vertexShader = getShader(gl, "shader-vs");
  var fragmentShader = loadShaders(gl, "fs/n-dim-distance.glsl", shaderMod)[0];
  var vertexShader = loadShaders(gl, "vs/display-image.glsl", shaderMod)[0];
   
  // Create the shader program
   
  var shaderProgram = gl.createProgram();
  gl.attachShader(shaderProgram, vertexShader);
  gl.attachShader(shaderProgram, fragmentShader);
  gl.linkProgram(shaderProgram);
   
  // If creating the shader program failed, alert
   
  if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
    alert("Unable to initialize the shader program.");
  }
   
  gl.useProgram(shaderProgram);
  shaderProgram.vertexShader = vertexShader;
  shaderProgram.fragmentShader = fragmentShader;
  
  return shaderProgram;
}

return {
  create3DContext: create3DContext,
  setupWebGL: setupWebGL,
  initShaders: initShaders
};
}();

/**
 * Provides requestAnimationFrame in a cross browser way.
 */
window.requestAnimFrame = (function() {
  return window.requestAnimationFrame ||
         window.webkitRequestAnimationFrame ||
         window.mozRequestAnimationFrame ||
         window.oRequestAnimationFrame ||
         window.msRequestAnimationFrame ||
         function(/* function FrameRequestCallback */ callback, /* DOMElement Element */ element) {
           return window.setTimeout(callback, 1000/60);
         };
})();

/**
 * Provides cancelAnimationFrame in a cross browser way.
 */
window.cancelAnimFrame = (function() {
  return window.cancelAnimationFrame ||
         window.webkitCancelAnimationFrame ||
         window.mozCancelAnimationFrame ||
         window.oCancelAnimationFrame ||
         window.msCancelAnimationFrame ||
         window.clearTimeout;
})();


