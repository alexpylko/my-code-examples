module SignIn
  module Components
    class SignInForm < ::Base::Components::Element
      include Base::Components::App::Item

      def click(page, name, selector)
        source.find(:xpath, xpath(name, selector)).click
      end

      def xpath(name, selector)
        case safe_name(selector)
          when /^input$/, /^button$/ then %(//input[@placeholder = "#{name}" or @value = "#{name}"])
          else super(name, selector)
        end
      end

    end
  end
end