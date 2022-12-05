module SmsMock
  def stub_sms
    stub_request(:post, /.+service\.qtelecom\.ru.+/)
      .to_return(status: 200,
                 headers: { content_type: 'application/xml' },
                 body: File.new('./spec/fixtures/sms/qtelecom.xml'))

    stub_request(:post, /.+smsc\.ru.+/)
      .to_return(status: 200,
                 headers: { content_type: 'application/xml' },
                 body: File.new('./spec/fixtures/sms/smsc.xml'))

    allow_any_instance_of(SmsWorker).to receive(:current_provider).and_return(SmsDelivery::Sender::PROVIDERS.sample)

    # message = double body: File.open('./spec/fixtures/sms/smsc.xml').read
    # allow_any_instance_of(::Smsc::Sms).to receive(:message).and_return message
  end
end
