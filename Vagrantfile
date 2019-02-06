Vagrant.configure('2') do |config|
  DOCKER_VERSION     = '18.06'
  REGISTRY_VERSION   = '2.7.1'
  KUBERNETES_VERSION = '1.13'
  STERN_VERSION      = '1.10.0'
  HELM_VERSION       = '2.12.3'

  config.hostmanager.enabled = true
  config.vm.box              = 'ubuntu/bionic64'
  config.vm.box_version      = '20190126.0.0'

  (0..3).each do |i|
    if i == 0 then
      hostname = 'kube-master'
    else
      hostname = "kube-worker#{i}"
    end

    config.vm.define hostname do |server|
      server.vm.hostname    = hostname
      server.vm.network 'private_network',
                        ip: "172.16.0.#{i + 10}",
                        netmask: '255.255.255.0',
                        auto_config: true
      server.disksize.size = '20GB'

      server.vm.provider 'virtualbox' do |v|
        v.cpus = 2
        v.memory = 2048
        #v.memory = if hostname == 'kube-master'
        #             2048
        #           else
        #             1536
        #           end
        v.gui = false
      end
      server.vm.provision 'shell', inline: <<-SHELL
        apt-get update
        apt-get upgrade -y
        apt-get install -y apt-transport-https ca-certificates curl software-properties-common

        # for kube-proxy
        echo net.bridge.bridge-nf-call-iptables = 1 >> /etc/sysctl.conf
        sysctl -p

        # Install Docker-CE
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
        echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee -a /etc/apt/sources.list.d/docker.list
        apt-get update
        apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep #{DOCKER_VERSION} | head -1 | awk '{print $3}')
        apt-mark hold docker-ce
        cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "insecure-registries": ["172.16.0.30:5000"]
}
EOF
        systemctl daemon-reload
        systemctl restart docker.service

        # Install Kubernetes
        curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
        echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list
        apt-get update
        KUBERNETES_VERSION=$(apt-cache madison kubeadm | grep #{KUBERNETES_VERSION} | head -1 | awk '{print $3}')
        apt-get install -y kubelet=$KUBERNETES_VERSION kubeadm=$KUBERNETES_VERSION kubectl=$KUBERNETES_VERSION
        apt-mark hold kubelet kubeadm kubectl

        # Install stern
        curl -o /usr/local/bin/stern -sL https://github.com/wercker/stern/releases/download/#{STERN_VERSION}/stern_linux_amd64
        chmod 755 /usr/local/bin/stern

        # Install helm
        curl -sL https://storage.googleapis.com/kubernetes-helm/helm-v#{HELM_VERSION}-linux-amd64.tar.gz | tar zxf - --strip=1 -C /usr/local/bin/ --wildcards '*/helm'
      SHELL
    end
  end

  config.vm.define hostname = 'docker-registry' do |registry|
    registry.vm.host_name   = hostname
    registry.vm.network 'private_network',
                        ip: '172.16.0.30',
                        netmask: '255.255.255.0',
                        auto_config: true

    registry.vm.provider 'virtualbox' do |v|
      v.cpus   = 1
      v.memory = 1024
      v.gui    = false
    end

    registry.vm.provision 'shell', inline: <<-SHELL
      apt-get update
      apt-get upgrade -y

      # Install Docker-CE
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
      echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee -a /etc/apt/sources.list.d/docker.list
      apt-get update
      apt-get install -y docker-ce=$(apt-cache madison docker-ce | grep #{DOCKER_VERSION} | head -1 | awk '{print $3}')
      apt-mark hold docker-ce
      echo '{ "experimental": true }' | tee -a /etc/docker/daemon.json
      systemctl daemon-reload
      systemctl restart docker.service

      # Install Registry
      mkdir /var/lib/registry
      docker run -d -p 5000:5000 --restart always --name registry --volume /var/lib/registry:/var/lib/registry registry:#{REGISTRY_VERSION}

      # サンプルプロジェクトのbuild & push
      cd /vagrant/kube-sample
      docker build --pull --squash --tag=localhost:5000/kube-sample:1.0.0 .
      docker push localhost:5000/kube-sample:1.0.0
    SHELL
  end
end
