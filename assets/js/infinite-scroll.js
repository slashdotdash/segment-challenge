var $ = require('jquery');
window.jQuery = $;
var jscroll = require('jscroll');

function scroll($element) {
  $($element).jscroll({
    contentSelector: '.infinite-scroll',
    loadingHtml: '<p class="has-text-centered"><a class="button is-primary is-loading">Fetching</a></p>',
    padding: 200
  });
}

module.exports = scroll;
