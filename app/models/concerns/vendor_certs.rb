module VendorCerts
  # https://serverfault.com/questions/661978/displaying-a-remote-ssl-certificate-details-using-cli-tools
  # `echo | openssl s_client -showcerts -servername $domain -connect $domain:443 2>/dev/null | openssl x509 -inform pem -noout -text | grep 'Not After'`
  def get_cert_expiration_time
    cmd = "curl --insecure -vvI https://#{https_custom_domain} 2>&1 | awk 'BEGIN { cert=0 } /^\\* SSL connection/ { cert=1 } /^\\*/ { if (cert) print }' | grep expire"
    date = `#{cmd}`
    return nil unless $CHILD_STATUS.exitstatus.zero?

    Time.zone.parse(date.chomp.gsub(/.+expire date: /, ''))
  end

  def get_cert_domain
    cmd = "curl --insecure -vvI https://#{https_custom_domain} 2>&1 | awk 'BEGIN { cert=0 } /^\\* SSL connection/ { cert=1 } /^\\*/ { if (cert) print }' | grep 'subject: CN='"
    result = `#{cmd}`
    return nil unless $CHILD_STATUS.exitstatus.zero?
    result.gsub(/.+subject: CN=/,'').chomp
  end

  def update_cert_expiration!
    update!(
      cert_expiration_domain: get_cert_domain,
      cert_expiration_at: get_cert_expiration_time
    )
  end

  def update_https_cert!
    output = `sudo certbot -n --nginx -d #{https_custom_domain} -d www.#{https_custom_domain}`
    result = $?

    Rails.logger.info "Update https cert for #{domain} result is #{result}, output is #{output}"

    if result.success?
      update_cert_expiration!
    else
      Rails.logger.error "Got error updating vendor https #{domain} result=#{result}, output=#{output}"
      Bugsnat.notify "Error update https cert" do |b|
        b.meta_data = {
          vendor_id: id,
          vendor_domain: domain,
          result: result,
          output: output
        }
      end
    end
    return result, output
  end

  def https_expired?
    cert_expiration_at.nil? || cert_expiration_at < Time.zone.now
  end
end
