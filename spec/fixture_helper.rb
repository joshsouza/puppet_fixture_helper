# Puppet Fixture Helper
#  Repo: https://github.com/joshsouza/puppet_fixture_helper
#  Author: Josh Souza <development@pureinsomnia.com>

require 'yaml'
require 'r10k/puppetfile'
require 'git'

config = YAML.load_file('dependencies.yml')
repopath = config['config']['puppetfile_repo']
branch = config['config']['branch'] || nil
branch_re = config['config']['branch_re'] || "v?([0-9]+\.?[0-9]?)"
branch_re = Regexp.new branch_re
repodir = '.puppetfile'

requested_dependencies=config['dependencies'].sort_by { |key|
  if key.class == Hash then
    result=key.keys[0]
  else
    result=key
  end
}

begin
  repo = Git.clone(repopath,repodir)
  puts "Loaded Puppetfile repository from #{repopath}"
rescue
  repo = Git.open(repodir)
  repo.pull
end

branches=repo.branches.remote
# If it's found, this will change it to the actual branch
# If it's not found, it'll be nil
branch = branches.find{ |i| i.name==branch}

if(branch == nil) then
  branches = branches.select{ |i| i.name[branch_re] }
  highest_dev_branch=branches.max_by{|k,v| k.name.gsub(branch_re,'\1').to_f}
  branch = highest_dev_branch
end
if(branch == nil) then
  puts "Unable to find requested Puppetfile branch, or apply the regex."
  exit
end
puts "Using Puppetfile #{branch.name} for fixture defaults"
branch.checkout

puppet_mods = R10K::Puppetfile.new(repodir)
puppet_mods = puppet_mods.load()
available_mods = {}
puppet_mods.each do |i|
  available_mods[i.name]={
    'repo'=>i.instance_variable_get("@remote").to_s,
    'ref'=>i.instance_variable_get("@ref").to_s
  };
end


actual_dependencies = {}

requested_dependencies.each do |i|
  if i.class == Hash then
    actual_dependencies[i.keys[0]]=i.values[0]
  else
    if available_mods.has_key?(i) then
      actual_dependencies[i]=available_mods[i]
    else
      puts "Unable to provide '#{i}' module from #{highest_dev_branch.name}"
    end
  end
end

fixtures = {
  "fixtures" => {
    "repositories" => actual_dependencies,
    "symlinks" => config['symlinks']
  }
}
File.open('.fixtures.yml','w') { |file|
  file.write("# For puppetlabs_spec_helper documentation - see http://github.com/puppetlabs/puppetlabs_spec_helper")
  file.write(fixtures.to_yaml)
}
puts "Fixtures updated"
