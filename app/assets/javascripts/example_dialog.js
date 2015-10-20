$(function() {

  var dialogElement        = $('#selector');      // the element as defined by the id passed into the dialog partial
  var dialogTrigger        = $('#trigger');       // the element you click to trigger the dialog

  var dialogOptions = {}
  dialogOptions['title']   = "Specify a title";   // text visible on dialog titlebar
  dialogOptions['width']   = 600;                 // width in pixels. 600 for a small dialog, 900 for a large one.
  dialogOptions['buttons'] = [];                  // these will be the action buttons on the bottom right of the dialog.

  var button1 = {
    text: "Nevermind",                          // text visible on button
    "class": 'btn btn-default',                 // specify bootstrap button class (default, info, warning, danger, success)
    click: function() {
                                                // write some code that actually does things
      $(this).dialog('close');                  // close this dialog.
    }
  }

  var button2 = {
    text: "Try Again Later",
    "class": 'btn btn-warning',
    click: function() {
      $(this).dialog('close');
    }
  }

  var button3 = {
    text: "Save It Now",
    "class": 'btn btn-success',
    click: function() {
      $(this).dialog('close');
    }
  }

  dialogOptions['buttons'].push(button1, button2, button3);  // add the buttons

  // The following does not need customization.
  // Initialize the dialog with options
  dialogElement.dialog({
    autoOpen: false,
    modal: true,
    resizable: false,
    show: { effect: "fade", duration: 600, easing: "easeOutQuint" },
    hide: { effect: "fade", duration: 600, easing: "easeOutQuint" },
    width: dialogOptions['width'],
    title: dialogOptions['title'],
    buttons: dialogOptions['buttons'],
    beforeClose: function() {
      // This lets the overlay background fade out gracefully
      $('.ui-widget-overlay:first').clone().appendTo('body').show().fadeOut(600, function() {
        $(this).remove();
      });
    }
  });

  // Set click event to open dialog
  dialogTrigger.on('click', function() { dialogElement.dialog('open'); });

  // Undo a bunch of styling applied to the dialog by jquery-ui
  dialogElement.on('dialogopen', function() {

    // adjust the close button
    $('.ui-dialog-titlebar, this')
      .find('button[aria-label="Close"]').removeAttr('style')
      .html('<i class="fa fa-fw fa-close" aria-hidden="true"></i>');

    // remove classes so the bootstrap classes will work
    $('.btn, this').removeClass('ui-button ui-state-default ui-button-text-only');
    $('button, this').unbind('mouseenter mouseleave focus blur mousedown mouseup keyup keydown');

    // This lets the overlay background fade in gracefully
    $('.ui-widget-overlay').hide().fadeIn(600);
  });

});
