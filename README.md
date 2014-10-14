Puppet Fixture Helper
=====================

A ruby script you can add to your build process for Puppet modules that will base your .fixtures.yml on a centralized Puppetfile repository.

Can be added to a Rakefile with something like:

```ruby
desc 'Prepare fixtures'
  RSpec::Core::RakeTask.new(:fixtures) do |t|
  t.pattern = 'spec/fixture_helper.rb'
  t.rspec_opts = ['--color']
end
```

This is designed to support the ideal r10k workflow which utilizes a single repository for managing your module environments. It does actually check out the puppetfile repo locally, which might not be fully necessary, and the '.puppetfile' directory should be added to your '.gitignore', but beyond that it's pretty simple.
