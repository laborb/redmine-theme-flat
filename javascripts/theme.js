(function($) {

  // Redmine 6: Der Kern merkt sich die Seitenleiste je Controller und Action. Wie bei sidebar_hide
  // soll sie überall eingeklappt bleiben, deshalb zusätzlich ein Zustand für alle Seiten.
  var collapsibleSidebar = $.fn.collapsibleSidebar;
  var sidebarKey = 'flat-lab-sidebar-state';

  if (collapsibleSidebar) {
    $.fn.collapsibleSidebar = function() {
      var main = this;
      var state = null;

      collapsibleSidebar.call(main);
      try {
        state = localStorage.getItem(sidebarKey);
      } catch (e) {}
      if (state) {
        main.toggleClass('collapsedsidebar', state === 'hidden');
      }

      $(document).ready(function() {
        $('#sidebar-switch-button').on('click', function() {
          try {
            localStorage.setItem(sidebarKey, main.hasClass('collapsedsidebar') ? 'hidden' : 'visible');
          } catch (e) {}
        });
      });
    };
  }

  $(document).ready(function() {
    var update = $('#update')
    var close = $("<div>", {'class': "update-close"}).text('x');

    update.prepend(close);
    close.click(function() {
      update.hide();
    });

    // toggleFieldset();
    $('#update fieldset.tabular legend').click(function() {
      $(this).closest('fieldset').toggleClass('show-children');
    });
  });

})(jQuery);
