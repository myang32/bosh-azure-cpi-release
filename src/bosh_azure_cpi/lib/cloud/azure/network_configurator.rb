# Copyright (c) 2009-2012 VMware, Inc.

module Bosh::AzureCloud
  ##
  # Represents Azure instance network config. Azure VM has single NIC
  # with dynamic IP address and (optionally) Azure cloud service has a single 
  # public IP address which VM is not aware of (vip).
  #
  class NetworkConfigurator
    include Helpers

    attr_reader :vip_network, :network
    attr_accessor :logger

    ##
    # Creates new network spec
    #
    # @param [Hash] spec raw network spec passed by director
    def initialize(spec)
      unless spec.is_a?(Hash)
        raise ArgumentError, "Invalid spec, Hash expected, " \
                             "#{spec.class} provided"
      end

      @logger = Bosh::Clouds::Config.logger
      @network = nil
      @vip_network = nil

      logger.debug ("networks: #{spec}")
      spec.each_pair do |name, network_spec|
        network_type = network_spec["type"] || "manual"

        case network_type
          when "dynamic"
            cloud_error("Must have exactly one dynamic or manual network per instance") if @network
            @network = DynamicNetwork.new(name, network_spec)

          when "manual"
            cloud_error("Must have exactly one dynamic or manual network per instance") if @network
            @network = ManualNetwork.new(name, network_spec)

          when "vip"
            cloud_error("More than one vip network for '#{name}'") if @vip_network
            @vip_network = VipNetwork.new(name, network_spec)

          else
            cloud_error("Invalid network type '#{network_type}' for Azure, " \
                        "can only handle 'dynamic', 'vip', or 'manual' network types")
        end
      end

      unless @network
        cloud_error("Exactly one dynamic or manual network must be defined")
      end
    end

    def virtual_network_name
      @network.virtual_network_name
    end

    def subnet_name
      @network.subnet_name
    end

    def vnet?
      @network.vnet?
    end

    def private_ip
      (@network.is_a? ManualNetwork) ? @network.private_ip : nil
    end

    def public_ip
      @vip_network.public_ip unless @vip_network.nil?
    end

    def dns
      @network.spec['dns'] if @network.spec.has_key? "dns"
    end
  end
end
