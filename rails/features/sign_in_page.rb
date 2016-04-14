module SignIn
  module Pages
    class SignInPage < ::Base::Pages::BasePage
      path 'users/sign_in'

      component :login_form do
        SignIn::Components::SignInForm.new(source.find(:xpath, '//div[contains(@class, "form-container")]'))
      end

    protected

      def selector(name, selector, &block)
        yield login_form if block_given?
      end

    end
  end
end