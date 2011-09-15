require 'spree_core'
require 'spree_s3_hooks'
require 'aws/s3'

module SpreeS3
  class Engine < Rails::Engine

    config.autoload_paths += %W(#{config.root}/lib)

    def self.activate
      S3.load_s3_yaml

      AWS::S3::DEFAULT_HOST.replace(S3.host) unless S3.host.blank?

      Paperclip.interpolates(:s3_url) { |attachment, style|
        "#{attachment.s3_protocol}://#{S3.host}/#{attachment.bucket_name}/#{attachment.path(style).gsub(%r{^/}, "")}"
      }

      Image.class_eval do
        extend S3::Attachment
        sends_files_to_s3 if S3.enabled?
      end

# FIXME: causing problems during db:migrate
#      Taxon.class_eval do
#        extend S3::Attachment
#        sends_files_to_s3 if S3.enabled?
#      end
    end

    config.to_prepare &method(:activate).to_proc
  end
end
