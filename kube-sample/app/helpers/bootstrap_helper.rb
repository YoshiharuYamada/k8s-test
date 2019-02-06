module BootstrapHelper
  ALERT_TYPES = %w[danger info success warning].freeze

  def bootstrap_flash
    return if flash.empty?

    flash_messages = flash.each_with_object([]) do |(type, message), messages|
      next if message.blank?

      type = 'success' if type == 'notice'
      type = 'danger'  if %w[alert error].include?(type)
      next unless ALERT_TYPES.include?(type)

      add_message(type, message, messages)
    end
    content_tag(:section, safe_join(flash_messages, "\n"), class: 'flash-messages content-header')
  end

  def bootstrap_form_group(model, attribute, add_style = nil, &block)
    style = ['form-group']
    style << add_style   if add_style
    style << 'has-error' if model.errors.include?(attribute)
    options = { class: style.join(' ') }
    if block_given?
      content_tag(:div, capture(&block), options)
    else
      content_tag(:div, nil, options)
    end
  end

  def bootstrap_error_message_on(model, attribute)
    errors = model.errors
    return unless errors.include?(attribute)

    messages = errors[attribute].map { |message| errors.full_message(attribute, message) }
    content_tag(:span, safe_join(messages, tag(:br)), class: 'help-block')
  end

  private

  def add_message(type, message, flash_messages)
    Array(message).each do |msg|
      next unless msg

      text = content_tag(:div, class: "alert fade in alert-#{type}") do
        concat content_tag(:button, '&times;'.html_safe, class: 'close', data: { dismiss: 'alert' })
        concat msg
      end
      flash_messages << text
    end
  end
end

module ActionView
  module Helpers
    class FormBuilder
      def bootstrap_form_group(method, add_style = nil, &block)
        @template.bootstrap_form_group(@object, method, add_style, &block)
      end

      def bootstrap_error_message_on(method)
        @template.bootstrap_error_message_on(@object, method)
      end
    end
  end
end
