var $ = require('jquery')
// var strftime = require('strftime')

require('phoenix_html')
require('unpoly')

// Although ^=parent is not technically correct,
// we need to use it in order to get IE8 support.
up.compiler('[data-submit^=parent]', function(element) {
  element.addEventListener('click', function(event) {
    var message = this.getAttribute("data-confirm")
    if (message === null || confirm(message)) {
      this.parentNode.submit()
    }
    event.preventDefault()
    return false
  }, false)
})

// Although ^=parent is not technically correct,
// we need to use it in order to get IE8 support.
// var elements = document.querySelectorAll('[data-submit^=parent]');
// var len = elements.length;
//
// for (var i = 0; i < len; ++i) {
//   elements[i].addEventListener('click', function(event) {
//     var message = this.getAttribute("data-confirm")
//     if (message === null || confirm(message)) {
//       this.parentNode.submit()
//     }
//     event.preventDefault();
//     return false;
//   }, false);
// }

$(document).ready(function() {
  $('.navbar-burger').click(function() {
    $(this).toggleClass('is-active');
    $(this).closest('.navbar-brand').siblings('.navbar-menu').toggleClass('is-active');
  });

  $('.infinite-scroll').each(function() {
    var scroll = require('./infinite-scroll');

    scroll($(this));
  });

  // $('time').each(function() {
  //   let $element = $(this)
  //   let datetime = new Date($element.attr('datetime'))
  //   let localised = strftime('%B %e, %Y at %l:%M%P', datetime)
  //
  //   $element.text(localised)
  // });

  $('.switch input').change(function(e) {
    var form = $(this).closest('form');
    var csrf = $('input[name="_csrf_token"]', form).val();
    var command = $('input[name="command"]', form).val();
    var value = $('input[name="value"]', form).val();
    var url = form.attr('action');

    $.ajax({
      url: url,
      type: "post",
      data: {
        command: command,
        value: value,
      },
      headers: {
        "X-CSRF-TOKEN": csrf
      },
      dataType: "json"
    });
  })

  $('.modal-button').click(function(e) {
    var modal = $(this).data('modal');
    $('#' + modal).toggleClass('is-active');

    e.preventDefault();
    return false;
  });

  $('.modal-close, .modal-cancel').click(function() {
    $(this).closest('.modal').toggleClass('is-active');
  });
});
