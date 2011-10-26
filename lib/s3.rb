module S3
  class << self
    attr_accessor :key, :secret, :bucket, :s3_host_alias, :s3_protocol

    def key
      @key || ENV['S3_KEY']
    end

    def secret
      @secret || ENV['S3_SECRET']
    end

    def bucket
      @bucket || ENV['S3_BUCKET']
    end

    def s3_host_alias
      @s3_host_alias || ENV['S3_HOST_ALIAS']
    end

    def s3_protocol
      @s3_protocol || ENV['S3_PROTOCOL']
    end

    def enabled?
      true unless key.blank? or secret.blank? or bucket.blank?
    end

    def load_s3_yaml
      path = File.join(::Rails.root, 'config', 's3.yml')
      file = File.read(path) if File.exist? path
      if file
        yaml = YAML.load(ERB.new(file).result)[::Rails.env]
        load_s3_config yaml.with_indifferent_access if yaml
      end
    end

    def load_s3_config(hash)
      self.key = hash[:key].gsub(/\s/, '')
      self.secret = hash[:secret].gsub(/\s/, '')
      self.bucket = hash[:bucket].gsub(/\s/, '')
      if hash[:s3_host_alias]
        self.s3_host_alias = hash[:s3_host_alias].gsub(/\s/, '')
      else
        self.s3_host_alias = nil
      end
      if hash[:s3_protocol]
        self.s3_protocol = hash[:s3_protocol].gsub(/\s/, '')
      else
       self.s3_protocol = 'http'
      end
    end
  end

  module Attachment
    def sends_files_to_s3
      [:attachment, :icon].each do |type|
        definition = self.attachment_definitions[type]
        configure_definition_for_s3(definition) if definition
      end
    end

  private
    def configure_definition_for_s3(definition)
      if S3.s3_host_alias
        definition[:url] = ':s3_alias_url'
        definition[:s3_host_alias] = S3.s3_host_alias
      else
        definition.delete :url
      end
      definition[:path] = definition[:path].gsub(':rails_root/public/', '')
      definition[:storage] = 's3'
      definition[:bucket] = S3.bucket
      definition[:s3_protocol] = S3.s3_protocol
      definition[:s3_credentials] = {:access_key_id => S3.key, :secret_access_key => S3.secret}
    end
  end
end
