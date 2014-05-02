// from https://gist.github.com/emtiu/6098482

// Usage:
//   var someButton = new L.Control.Button(options).addTo(map);
// This calls OnAdd(). See the code for what options are required
// The third parameter passed to L.DomEvent.addListener is the 'this' context
// to use in the callback (second parameter).

L.Control.Button = L.Control.extend({
  options: {
    position: 'topleft'
  },
  initialize: function (options) {
    this._button = {};
    this.setButton(options);
  },

  onAdd: function (map) {
    this._map = map;

    this._container = L.DomUtil.create('div', 'leaflet-control-button leaflet-bar');

    this._update();
    return this._container;
  },

  onRemove: function (map) {
    this._button = {};
    this._update();
  },

  setButton: function (options) {
    var button = {
      'class': options.class,
      'text': options.text,
      'onClick': options.onClick,
      'title': options.title
    };

    this._button = button;
    this._update();
  },

  _update: function () {
    if (!this._map) {
      return;
    }

    this._container.innerHTML = '';
    this._makeButton(this._button);
  },

  _makeButton: function (button) {
    var newButton = L.DomUtil.create('a', 'leaflet-buttons-control-button '+button.class, this._container);
    newButton.href = '#';
    newButton.innerHTML = button.text;
    newButton.title = button.title;

    onClick = function(event) {
      button.onClick(event, newButton);
    };

    L.DomEvent.addListener(newButton, 'click', onClick, this);
    return newButton;

  }

});