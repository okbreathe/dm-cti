require File.expand_path(File.dirname(__FILE__) + '/../helper')

describe "DataMapper::CTI::Inheritable" do
  describe "associations" do
    it "should create a resource chain" do
      new_canine
      assert_respond_to(@canine, :animal)
      assert_respond_to(@canine, :dog)
      assert_respond_to(@canine, :wolf)
     
      new_dog
      assert_respond_to(@dog, :canine)
      
      new_wolf
      assert_respond_to(@wolf, :canine)
    end

    it "should allow you to traverse the resource chain upwards" do
      assert !!new_canine.animal
      assert !!new_dog.canine.animal
      assert !!new_wolf.canine.animal
    end

  end

  describe "class" do
    it "should be a table descendant" do
      assert !Animal.is_table_descendant?
      assert Dog.is_table_descendant?
      assert Wolf.is_table_descendant?
      assert Canine.is_table_descendant?
    end
  end

  describe "properties" do

    it "delegate parent attributes to its ancestors" do
      new_canine
      assert_respond_to(@canine, :name)
      assert_respond_to(@canine, :legs)
      assert_respond_to(@canine, :color)

      new_dog
      assert_respond_to(@dog, :name)
      assert_respond_to(@dog, :legs)
      assert_respond_to(@dog, :color)
      assert_respond_to(@dog, :owner)

      new_wolf
      assert_respond_to(@wolf, :name)
      assert_respond_to(@wolf, :legs)
      assert_respond_to(@wolf, :color)
      assert_respond_to(@wolf, :power_level)
    end

  end

  describe "with relationship" do
    before do
      @user    = User.create(:name => "user")
      @whiskey = Whiskey.create(:name => "whiskey", :abv => 50, :bottled => Date.new(1984), :age => 10, :user => @user)
      @beer    = Beer.create(:name => "whiskey", :abv => 10, :srm => 10, :ibu => 10, :user => @user)
    end

    it "delegate parent attributes to its ancestors" do
      assert_respond_to(@whiskey, :name)
      assert_respond_to(@whiskey, :abv)
      assert_respond_to(@whiskey, :user)
      assert_respond_to(@whiskey, :user_id)
      assert_respond_to(@whiskey, :ratings)

      assert_respond_to(@beer, :name)
      assert_respond_to(@beer, :abv)
      assert_respond_to(@beer, :user)
      assert_respond_to(@beer, :user_id)
      assert_respond_to(@beer, :ratings)

    end

    it "create resources" do
      assert_equal(1, Beer.count)
      assert_equal(1, Whiskey.count)
      assert_equal(2, Drink.count)
    end

    it "should operate correctly with delegated associations" do
      @whiskey.ratings << Rating.new(:score => 10, :user => @user)
      @beer.ratings  << Rating.new(:score => 10, :user => @user)
      @whiskey.save
      @beer.save
      assert_equal(2, Rating.count)
      @whiskey.ratings.destroy
      @beer.ratings.destroy
      assert_equal(0, Rating.count)
    end

    after do
      Whiskey.destroy
      Beer.destroy
      Drink.destroy
      User.destroy
      Rating.destroy
    end
  end

  describe "an instance" do
    before do
      destroy_animals
    end

    it "should be able to get the root" do
      new_canine.save
      assert_equal(Animal.first, @canine.table_root)
    end

    it "should return the combined attributes" do
      new_wolf.save
      @wolf.reload
      assert_same_elements([:name, :legs, :color, :power_level,:animal_id, :canine_id, :id], @wolf.attributes.keys)
    end
  end

  describe "on save" do

    before do
      destroy_animals
    end

    it "should save the model properties to the correct table" do
      new_canine.save
      assert_equal(1, Animal.count)
      assert_equal(1, Canine.count)

      new_dog.save
      assert_equal(2, Animal.count)
      assert_equal(2, Canine.count)
      assert_equal(1, Dog.count)

      new_wolf.save
      assert_equal(3, Animal.count)
      assert_equal(3, Canine.count)
      assert_equal(1, Wolf.count)
    end

    describe "with errors" do

      before do
        new_dog
        @dog.legs = 20
        @dog.save
      end

      it "should not save any objects in the resource chain" do
        assert_equal(0, Animal.count)
        assert_equal(0, Canine.count)
        assert_equal(0, Dog.count)
      end

      it "should bubble errors" do
        assert @dog.errors[:legs].any?
      end
    end

  end

  describe "on update" do
    before do
      destroy_animals
    end

    it "should update the resource chain" do
      new_dog.save
      @dog.update(:name => 'lucky', :legs => 3, :owner => "bob")
      @dog.reload
      assert_equal('bob', @dog.owner)
      assert_equal(3, @dog.legs)
      assert_equal('lucky',@dog.name)
    end
  end
               
  describe "on destroy" do
    before do
      destroy_animals
    end

    it "should destroy the resource chain" do
      new_dog.save
      new_dog.save
     
      assert_equal(2, Animal.count)
      assert_equal(2, Canine.count)
      assert_equal(2, Dog.count)
     
      Dog.all.destroy
     
      assert_equal(0, Dog.count)
      assert_equal(0, Canine.count)
      assert_equal(0, Animal.count)
     
      new_dog.save
     
      assert_equal(1, Animal.count)
      assert_equal(1, Canine.count)
      assert_equal(1, Dog.count)
      
      @dog.destroy
     
      assert_equal(0, Dog.count)
      assert_equal(0, Canine.count)
      assert_equal(0, Animal.count)
    end
  end

  describe "top-down access" do
    it "should add a discriminator column" do
      assert !!Entity.properties[:sub_type]
    end

    it "should allow you to traverse the resource chain downwards" do
      assert !!new_vampire.monster.entity
      assert !!new_elf.humanoid.entity
    end

    it "should set the type on save" do
      new_vampire.save
      assert_equal(1, Entity.count)
      assert_equal(1, Monster.count)
      assert_equal(1, Vampire.count)
      assert_equal("Vampire", Entity.first.sub_type)

      new_elf.save
      assert_equal(2, Entity.count)
      assert_equal(1, Humanoid.count)
      assert_equal(1, Elf.count)
      assert_equal("Elf", Entity.last.sub_type)
    end

    it "should return an instance of the sub-type for Klass.get" do
      new_vampire.save
      e=Entity.first
      assert_equal @vampire, Entity.get_as_descendant(@vampire.monster.entity.id)
      assert_equal @vampire, Entity.get(@vampire.monster.entity.id, :as_descendant => true)
    end

    it "should destroy the entire resource chain" do
      new_vampire.save
      @vampire.destroy
      assert_equal(0, Entity.count)
      assert_equal(0, Monster.count)
      assert_equal(0, Vampire.count)
    end

    after do
      destroy_entities
    end
  end

  def destroy_animals
    Wolf.destroy
    Dog.destroy
    Canine.destroy
    Animal.destroy
  end

  def destroy_entities
    Vampire.destroy
    Monster.destroy
    Elf.destroy
    Humanoid.destroy
    Entity.destroy
  end
end
