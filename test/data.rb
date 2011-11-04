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

class Entity
  include DataMapper::Resource
  property :id, Serial 
  property :name, String

  table_superclass
end

class Humanoid
  include DataMapper::Resource
  property :id, Serial 
  property :strength, Integer

  descendant_of :entity
end

class Elf
  include DataMapper::Resource
  property :id, Serial 
  property :ear_length, Integer

  descendant_of :humanoid
end

class Monster
  include DataMapper::Resource
  property :id, Serial 
  property :fangs, Boolean

  descendant_of :entity
end

class Vampire
  include DataMapper::Resource
  property :id, Serial 
  property :day_walker, Boolean

  descendant_of :monster
end

DataMapper.setup(:default, 'sqlite3::memory:')
DataMapper.auto_migrate! if defined?(DataMapper)
