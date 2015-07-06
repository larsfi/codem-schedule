class Host < ActiveRecord::Base
  has_many :jobs

  validates :name, :url, presence: true

  before_save :normalize_url

  def self.from_api(opts)
    opts = opts[:host] if opts[:host] # Rails' forms wraps hashes in a root tag
    host = new(name: opts['name'], url: opts['url'])
    host.update_status if host.save
    host
  end

  def self.with_available_slots
    all.map(&:update_status).select { |h| h.available_slots > 0 }.each
  end

  def update_status

    self.available_slots = 0
    self.available = false
    self.status_updated_at = Time.current

    attrs = Transcoder.host_status(self)
    if attrs
      self.total_slots          = attrs['max_slots']
      self.available_slots      = attrs['free_slots']
      self.available            = true
    end

    save

    self
  end

  private

  def normalize_url
    self.url = url.to_s.gsub(/\/$/, '')
  end
end
