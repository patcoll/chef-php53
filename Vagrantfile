Vagrant::Config.run do |config|
  # All Vagrant configuration is done here. For a detailed explanation
  # and listing of configuration options, please check the documentation
  # online.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "base"
  
  config.chef.enabled = true
  config.chef.cookbooks_path = "cookbooks"
  config.chef.json.merge!({
    :mysql => {
      :server_root_password => "root"
    }
  })
  
  config.vm.forward_port("web", 80, 4567)
end
