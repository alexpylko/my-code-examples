class ImageScaledUploader < ImageUploader
  include CarrierWave::MiniMagick

  version :desktop do
    process :resize_to_fit => [500, 350]
  end

  version :tablet do
    process :resize_to_fit => [350, 250]
  end

  version :mobile do
    process :resize_to_fit => [200, 125]
  end
end
