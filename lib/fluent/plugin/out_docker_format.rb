require 'json'

module Fluent
  class DockerFormatOutput < Output
    Fluent::Plugin.register_output('docker_format', self)
    config_param :tag, :string
    config_param :container_id, :string
    config_param :docker_containers_path, :string, :default => '/var/lib/docker/containers'

    def configure(conf)
      super
      @id_to_name = {}
    end

    def emit(tag, es, chain)
      es.each do |time,record|
        Engine.emit(@tag, time, format_record(tag, record))
      end

      chain.next
    end

    private

    def interpolate(tag, str)
      tag_parts = tag.split('.')

      str.gsub(/\$\{tag_parts\[(\d+)\]\}/) { |m| tag_parts[$1.to_i] }
    end

    def get_name_from_cfg(id)
      begin
        docker_cfg = JSON.parse(File.read("#{@docker_containers_path}/#{id}/config.json"))
        container_name = docker_cfg['Name']
      rescue
        container_name = "<unknown>"
      end
      container_name
    end

    def get_name(id)
      @id_to_name[id] = get_name_from_cfg(id) unless @id_to_name.has_key? id
      @id_to_name[id]
    end

    def format_record(tag, record)
      id = interpolate(tag, @container_id)
      record['container_id'] = id
      record['container_name'] = get_name(id)
      record
    end
  end
end
