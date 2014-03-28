define ["jquery", "jquery.ui", "backbone", "js/views/feedback_prompt", "js/views/feedback_notification",
    "coffee/src/views/module_edit", "js/models/module_info", "js/utils/module"],
($, ui, Backbone, PromptView, NotificationView, ModuleEditView, ModuleModel, ModuleUtils) ->
  class TabsEdit extends Backbone.View

    initialize: =>
      @$('.component').each((idx, element) =>
          model = new ModuleModel({
              id: $(element).data('locator')
          })

          new ModuleEditView(
              el: element,
              onDelete: @deleteTab,
              model: model
          )
      )

      @options.mast.find('.new-tab').on('click', @addNewTab)
      $('.add-pages .new-tab').on('click', @addNewTab)
      $('.toggle-checkbox').on('click', @toggleVisibilityOfTab)
      @$('.course-nav-list').sortable(
        handle: '.drag-handle'
        update: @tabMoved
        helper: 'clone'
        opacity: '0.5'
        placeholder: 'component-placeholder'
        forcePlaceholderSize: true
        axis: 'y'
        items: '> .is-movable'
      )

    toggleVisibilityOfTab: (event, ui) =>
      checkbox_element = event.srcElement
      tab_element = $(checkbox_element).parents(".course-tab")[0]

      saving = new NotificationView.Mini({title: gettext("Saving&hellip;")})
      saving.show()

      $.ajax({
        type:'POST',
        url: @model.url(),
        data: JSON.stringify({
          tab_id_locator : {
            tab_id: $(tab_element).data('tab-id'),
            tab_locator: $(tab_element).data('locator')
          },
          is_hidden : $(checkbox_element).is(':checked')
        }),
        contentType: 'application/json'
      }).success(=> saving.hide())

    tabMoved: (event, ui) =>
      tabs = []
      @$('.course-tab').each((idx, element) =>
          tabs.push(
            {
              tab_id: $(element).data('tab-id'),
              tab_locator: $(element).data('locator')
            }
          )
      )

      analytics.track "Reordered Pages",
        course: course_location_analytics

      saving = new NotificationView.Mini({title: gettext("Saving&hellip;")})
      saving.show()

      $.ajax({
        type:'POST',
        url: @model.url(),
        data: JSON.stringify({
          tabs : tabs
        }),
        contentType: 'application/json'
      }).success(=> saving.hide())

    addNewTab: (event) =>
      event.preventDefault()

      editor = new ModuleEditView(
        onDelete: @deleteTab
        model: new ModuleModel()
      )

      $('.new-component-item').before(editor.$el)
      editor.$el.addClass('course-tab is-movable')
      editor.$el.addClass('new')
      setTimeout(=>
        editor.$el.removeClass('new')
      , 500)

      editor.createItem(
        @model.get('id'),
        {category: 'static_tab'}
      )

      analytics.track "Added Page",
        course: course_location_analytics

    deleteTab: (event) =>
      confirm = new PromptView.Warning
        title: gettext('Delete Component Confirmation')
        message: gettext('Are you sure you want to delete this component? This action cannot be undone.')
        actions:
          primary:
            text: gettext("OK")
            click: (view) ->
              view.hide()
              $component = $(event.currentTarget).parents('.component')

              analytics.track "Deleted Page",
                course: course_location_analytics
                id: $component.data('locator')
              deleting = new NotificationView.Mini
                title: gettext('Deleting&hellip;')
              deleting.show()
              $.ajax({
                type: 'DELETE',
                url: ModuleUtils.getUpdateUrl($component.data('locator'))
              }).success(=>
                $component.remove()
                deleting.hide()
              )
          secondary: [
            text: gettext('Cancel')
            click: (view) ->
              view.hide()
          ]
      confirm.show()
