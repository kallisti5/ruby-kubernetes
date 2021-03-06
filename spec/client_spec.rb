require 'spec_helper'

describe Kubernetes::Client do
  let(:client) { Kubernetes::Client.new(namespace: namespace) }
  let(:namespace) { "ruby-k8s-#{rand(10000)}" }

  before do
    client.create_namespace(metadata: { name: namespace })
  end

  after do
    client.delete_namespace(namespace)
  end

  it "creates and lists pods" do
    pod = client.create_pod({
      metadata: {
        name: "testing",
      },
      spec: {
        containers: [
          {
            name: "testing-1",
            image: "nginx",
            imagePullPolicy: "IfNotPresent",
          }
        ],
        restartPolicy: "Always",
        dnsPolicy: "Default",
      }
    })

    expect(client.get_pods).to eq [pod]
    expect(client.get_pod("testing")).to eq pod
  end

  it "lists all replication controllers in the namespace" do
    rc = client.create_replication_controller({
      metadata: {
        name: "testing",
      },
      spec: {
        selector: {
          app: "circus"
        },
        template: {
          metadata: {
            labels: {
              app: "circus"
            },
          },
          spec: {
            containers: [
              {
                name: "testing-1",
                image: "nginx",
                imagePullPolicy: "IfNotPresent",
              }
            ],
            restartPolicy: "Always",
            dnsPolicy: "Default",
          }
        },
      }
    })

    expect(client.get_replication_controllers).to eq [rc]
    expect(client.get_replication_controller("testing")).to eq rc
  end

  it "gets the log for a pod" do
    pod = create_pod("testing")

    while pod.status.pending?
      sleep 0.1 
      pod = client.get_pod("testing")
    end

    log = client.logs("testing")

    expect(log).to include "Server started, Redis version"
  end

  it "handles errors" do
    begin
      client.get_pod("does-not-exist")
      fail
    rescue Kubernetes::Error => error
      expect(error.status.reason).to eq "NotFound"
    end
  end

  it "allows watching pods" do
    pod = create_pod("testing")

    events = []

    client.watch_pods do |event|
      events << event
      break if event.object == pod
    end

    expect(events.last.object).to eq pod
  end

  def create_pod(name)
    client.create_pod({
      metadata: {
        name: name,
      },
      spec: {
        containers: [
          {
            name: "testing-1",
            image: "redis",
            imagePullPolicy: "IfNotPresent",
          }
        ],
        restartPolicy: "Always",
        dnsPolicy: "Default",
      }
    })
  end
end
