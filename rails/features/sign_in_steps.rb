Given /^(?:|I )login with valid credentials$/ do
  get_page('SignIn').visit
  get_page.fill_in('Email', 'input', get_user.email, nil)
  get_page.fill_in('Password', 'input', get_user.password, nil)
  get_page.click(page, 'Sign in', 'button')
end
