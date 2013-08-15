SimpleCov.start do
  add_filter '/spec/'
  add_filter '.simplecov'

  add_filter 'lib/picasso/unmarshalling'
end