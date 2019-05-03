var L = require('leaflet');
require('drmonty-leaflet-awesome-markers');
var polylineDecoder = require('polyline-encoded');

function renderMap(elementId, config) {
  var map = new L.Map(elementId);
  L.tileLayer(
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      {
          attribution: '&copy; <a href="http://openstreetmap.org">OpenStreetMap</a> contributors, <a href="http://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>',
          maxZoom: 18
      }
  ).addTo(map);

  var decodedPolyline = polylineDecoder.decode(config.polyline);
  var polyline = L.polyline(decodedPolyline, {color: '#FC4C02'}).addTo(map);

  var startMarker = L.AwesomeMarkers.icon({
    icon: 'flag',
    prefix: 'fa',
    markerColor: '#FC4C02'
  });

  var endMarker = L.AwesomeMarkers.icon({
    icon: 'flag-checkered',
    prefix: 'fa',
    markerColor: '#FC4C02'
  });

  var startMarker = L.marker(config.start, {icon: startMarker}).addTo(map);
  var endMarker = L.marker(config.end, {icon: endMarker}).addTo(map);

  startMarker.bindPopup('<h1 class="title">Start</h1>').openPopup();
  endMarker.bindPopup('<h1 class="title">Finish</h1>').openPopup();

  map.fitBounds(polyline.getBounds());
}

window.SegmentChallenge = window.SegmentChallenge || {};
window.SegmentChallenge.renderMap = renderMap;

module.exports = renderMap;
