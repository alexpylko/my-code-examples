Feature: Sign-in page
  In order to get access to my data
  As a BitFit user
  I want to see my Dashboard

  Background:
    Given _I am a "BitFit" employee and I have "T1`~!@#$%^-_=S2+\|[]?{};:.,<>t3" password

  Scenario: Open Dashboard page on login with special symbols password
    When I login with valid credentials
    Then _I should be redirected to "AppCenter" page
