# frozen_string_literal: true

module Cloudsap
  class CloudServiceAccount
    include Common
    include Kubernetes
    include Aws

    attr_reader :client, :resource, :type, :object, :provider_id

    def self.load(client, resource)
      new(client, resource)
    end

    def initialize(client, resource)
      @client      = client
      @resource    = resource.to_h
      @type        = @resource[:type]
      @object      = @resource[:object]
      @provider_id = @resource[:object][:spec][:cloudProvider].to_sym
    end

    def name
      object[:metadata][:name]
    end

    def namespace
      object[:metadata][:namespace]
    end

    def cluster_id
      options[:cluster_id]
    end

    def create
      logger.info("#{type}, #{self.class}: #{namespace}/#{name}")
      sa = ServiceAccount.new(self)
      sa.apply
      role = IamRole.new(self)
      role.apply
    rescue => error
      logger.error(error.message)
      puts error.backtrace if options[:debug]
    end

    alias update create

    def delete
      role = IamRole.new(self)
      role.delete
      sa = ServiceAccount.new(self)
      sa.delete
      logger.info("#{type}, #{self.class}: #{namespace}/#{name}")
    rescue => error
      logger.error(error.message)
      puts error.backtrace if options[:debug]
    end

    def status
      client.get_cloud_service_account_status(name, namespace)
        .to_h.slice(:status)
    end

    def status=(status)
      client.patch_cloud_service_account_status(name, status, namespace)
    end
  end
end
