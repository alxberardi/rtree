# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{rtree}
  s.version = "0.2.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Alessandro Berardi,,,"]
  s.date = %q{2011-08-26}
  s.email = %q{berardialessandro@gmail.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["rtree.gemspec", "Gemfile.lock", "Rakefile", "README", "Gemfile", "spec/rtree_spec.rb", "lib/acts_as_rtree.rb", "lib/rtree.rb"]
  s.homepage = %q{http://github.com/AlessandroBerardi/rtree}
  s.rdoc_options = ["--main", "README"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.6.2}
  s.summary = %q{Ruby implementation of tree structures with ActiveRecord acts_as module}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<i18n>, [">= 0.6.0"])
      s.add_runtime_dependency(%q<activesupport>, [">= 2.3.8"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<i18n>, [">= 0.6.0"])
      s.add_dependency(%q<activesupport>, [">= 2.3.8"])
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<i18n>, [">= 0.6.0"])
    s.add_dependency(%q<activesupport>, [">= 2.3.8"])
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
