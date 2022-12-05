class CertificateService
  include Virtus.model

  TEMPLATE_FOLDER = 'config/caddy.erb'.freeze

  attribute :certificate, Certificate

  def enable
    create_vhost
    certificate.update is_active: true unless certificate.is_active?

    system 'sudo service caddy reload'
  end

  def disable
    delete_vhost
    certificate.update is_active: false if certificate.is_active?

    system 'sudo service caddy reload'
  end

  def delete_vhost
    File.delete vhost_path if File.exist? vhost_path
  end

  private

  def create_vhost
    erb = ERB.new File.read(template_path)

    cert_file = certificate.cert_file.path
    key_file = certificate.key_file.path
    domain = certificate.domain

    File.write vhost_path, erb.result(binding)
  end

  def vhost_path
    vhosts_folder.join "#{certificate.domain}.conf"
  end

  def vhosts_folder
    Pathname.new Settings.vhosts_path
  end

  def template_path
    Rails.root.join TEMPLATE_FOLDER
  end
end
