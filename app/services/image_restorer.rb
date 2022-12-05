class ImageRestorer
  def self.perform
    S3Bucket.objects.each do |object|
      S3RestoreWorker.perform_async object.key
    end
  end
end
