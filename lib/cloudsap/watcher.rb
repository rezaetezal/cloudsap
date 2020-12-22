# frozen_string_literal: true

module Cloudsap
  class WatcherError < StandardError; end

  class Watcher
    attr_reader :api_group, :api_version, :client, :stack, :metrics

    include Common

    def self.run(api_group, api_version, metrics)
      new(api_group, api_version, metrics).watch
    end

    # apiVersion: k8s.groundstate.io/v1alpha1
    def initialize(api_group, api_version, metrics)
      @metrics     = metrics
      @api_group   = api_group
      @api_version = api_version
      @client      = csa_client
      @stack       = {}
    end

    def watch
      version ||= fetch_resource_version
      while true
        logger.info("Watching #{@client.api_endpoint.to_s} [#{version}]")
        @client.watch_cloud_service_accounts(resource_version: version) do |event|
          if check_error_status(event, version)
            process_event(event, version)
          end
        end
        version = fetch_resource_version
        logger.warn("Restarting watch ... [#{version}]")
      end
    end

    private

    def fetch_resource_version
      @client.get_cloud_service_accounts.resourceVersion
    end

    def process_event(event, version)
      name      = event[:object][:metadata][:name]
      namespace = event[:object][:metadata][:namespace]
      operation = event[:type].downcase.to_sym
      identity  = "#{namespace}/#{name}"
      logger.debug("#{event[:type]}, event for #{identity} [#{version}]")

      if stack[identity]
        stack[identity].refresh(event)
      else
        stack[identity] = csa_load(event)
      end

      stack[identity].async.send(operation)
    end

    def check_error_status(event, version)
      return true unless event[:type] == 'ERROR'
      status = event[:object][:status]
      reason = event[:object][:reason]
      if status == 'Failure' && reason == 'Expired'
        message = event[:object][:message]
        logger.warn("#{status}, reason: #{reason}, #{message} [#{version}]")
        return false
      end
      raise WatcherError.new("An unknown error occurred: #{event}")
    end

    def csa_load(event)
      CloudServiceAccount.load(stack, metrics, client, event)
    end
  end
end
