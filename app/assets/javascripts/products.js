// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

var ready;
ready = function() {


  $('.btn-checkbox input:disabled').parent().addClass('disabled');
  $('.btn-checkbox input:checked:not(:disabled)').parent().addClass('active');

  $('.btn-checkbox input:checkbox').on('change', function() {
    $(this).parent().toggleClass('active', $(this).prop('checked'));
  });

  $('.btn-checkbox input:radio').on('change', function() {
    $('input:radio[name="'+$(this).attr('name')+'"]').parent().removeClass('active');
    $(this).parent().addClass('active');
  });


};

$(document).ready(ready);
$(document).on('page:load', ready);
