window.$ = window.jQuery = require('jquery');
require('bootstrap');
require('admin-lte');

import Rails from 'rails-ujs';
Rails.start();

$(document).on('click', '.flash-messages button.close', function() {
  $('.flash-messages').remove();
});
