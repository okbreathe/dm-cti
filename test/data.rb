class Animal
  include DataMapper::Resource
  property :id, Serial 
  property :name, String
end

class Canine
  include DataMapper::Resource
  property :id, Serial
  property :legs, Integer, :max => 4
  property :color, String

  descendant_of "Animal"
end

class Dog
  include DataMapper::Resource
  property :id, Serial
  property :owner, String

  descendant_of "Canine"
end

class Wolf
  include DataMapper::Resource
  property :id, Serial
  property :power_level, Integer

  descendant_of "Canine"
end

class Drink
  include DataMapper::Resource

  property :id,    Serial 
  property :name,  String,  :length  => 512, :required => true
  property :abv,   Float, :max => 100.00, :min => 0.00, :precision => 4, :scale => 2

  belongs_to :user
  has n, :ratings
end

class Whiskey
  include DataMapper::Resource

  property :id,      Serial 
  property :age,     Integer, :max    => 100
  property :bottled, Date

  descendant_of :drink

end

class Beer
  include DataMapper::Resource

  property :id,     Serial 
  property :srm,    Integer
  property :ibu,    Integer, :min => 1, :max => 70

  descendant_of :drink

end

class User
  include DataMapper::Resource

  property :id,    Serial 
  property :name,  String,  :length  => 512, :required => true

  has n, :drinks

end

class Rating
  include DataMapper::Resource

  property :id,    Serial 
  property :score, Integer

  belongs_to :drink
  belongs_to :user
end

DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.auto_migrate! if defined?(DataMapper)
