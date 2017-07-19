module SauceWhisk
  def self.load_first_found(key)
    self.instance_variable_get("@#{key}".to_sym) ||
        self.from_yml(key) ||
        ENV["SAUCE_#{key.to_s.upcase}"]
  end
end
