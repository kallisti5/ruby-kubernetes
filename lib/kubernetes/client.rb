require 'kubernetes/connection'
require 'kubernetes/pod'
require 'kubernetes/replication_controller'
require 'kubernetes/namespace'
require 'kubernetes/stream'
require 'kubernetes/watch_event'

module Kubernetes
  class Client
    DEFAULT_NAMESPACE = "default".freeze

    def initialize(namespace: DEFAULT_NAMESPACE)
      @connection = Connection.new(namespace: namespace)
    end

    def create_pod(pod)
      data = post("pods", body: pod.to_json)
      Pod.new(data)
    end

    def get_pod(name)
      data = get("pods/#{name}")
      Pod.new(data)
    end

    def get_pods
      get("pods").
        fetch("items").
        map {|item| Pod.new(item) }
    end

    def watch_pods
      stream = Stream.new(@connection)

      stream.each("watch/pods") do |line|
        yield WatchEvent.new(JSON.parse(line))
      end
    end

    def create_replication_controller(rc)
      data = post("replicationcontrollers", body: rc.to_json)
      ReplicationController.new(data)
    end

    def get_replication_controller(name)
      data = get("replicationcontrollers/#{name}")
      ReplicationController.new(data)
    end

    def get_replication_controllers
      get("replicationcontrollers").
        fetch("items").
        map {|item| ReplicationController.new(item) }
    end

    def create_namespace(namespace)
      post("namespaces", prefix: nil, body: namespace.to_json)
    end

    def delete_namespace(name)
      delete("namespaces/#{name}", prefix: nil)
    end

    def logs(pod_name)
      get("pods/#{pod_name}/log")
    end

    private

    def get(*args); @connection.get(*args); end
    def post(*args); @connection.post(*args); end
    def delete(*args); @connection.delete(*args); end
  end
end
