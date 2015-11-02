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

    if ($(this).attr('name') === 'product[measure_selection]') {
      $('.pick-measures').toggleClass('hidden', $(this).val() !== 'custom');
    }
  });

  $('#measure_tabs').tabs().addClass("ui-tabs-vertical ui-helper-clearfix");
  $('#measure_tabs li').removeClass("ui-corner-top");
  $('#measure_tabs .ui-tabs-nav').removeClass("ui-corner-all ui-widget-header");

  $('.measure_group_all').on('change', function () {
    var $groupMeasures = $(this).closest('.measure_group').find('.measure-checkbox');
    $groupMeasures.prop('checked', this.checked);

    if (this.checked) {
      $groupMeasures.closest('div.checkbox').clone(true).appendTo('.selected-measure-list'); // FIXME: allows duplicates
    } else {
      var IDs = $groupMeasures.map(function() { return this.id; }).get();
      $('.selected-measure-list .measure-checkbox').filter(function(i) {
        return $.inArray(this.id, IDs) > -1;
      }).closest('div.checkbox').remove();
      $('.measure-list .measure-checkbox').filter(function(i) {
        return $.inArray(this.id, IDs) > -1;
      }).prop('checked', this.checked);
    }
  });

  $('.measure-list .measure-checkbox').on('change', function() {
    if ($(this).closest('.measure_group').find('.measure-checkbox').not('input:checkbox:checked').length) {
      $('.measure_group_all').prop('checked', false);
    } else {
      $('.measure_group_all').prop('checked', true);
    }

    if (this.checked) {
      $(this).closest('div.checkbox').clone(true).appendTo('.selected-measure-list');
    } else {
      $('.selected-measure-list .measure-checkbox').filter('#' + this.id).closest('div.checkbox').remove();
      $('.measure-list .measure-checkbox').filter('#' + this.id).prop('checked', this.checked);
    }
  });

};

$(document).ready(ready);
$(document).on('page:load', ready);
