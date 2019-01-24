class DodosController < ApplicationController

  before_action :set_up_a_date, :set_up_a_location, only: [:create]

  helper_method :resource_name, :resource, :devise_mapping, :resource_class	

  def home
    @minimum_password_length = User.password_length.min
    if user_signed_in? 
      @current_user = current_user
    end

  end

  def create
    location = set_up_a_location
    @city = City.find_by_name(location)
    if (@city.present?)
      redirect_to action: :index
    else
      flash[:alert] = "La ville renseignée n'est pas présente sur le chemin, merci d'essayer avec une autre ville"
      redirect_to root_path
    end 
  end

  def index
    @house = House.all
    location = set_up_a_location	
    @date = set_up_a_date
    @city = City.find_by_name(location)
    @house_of_the_city = House.where(city_id: @city.id).as_json



    @lowest_room_price = price_of_the_lowest_room(@city)
    @latitude_of_the_town = CityGeocalize.new(location).perform[0]
    @longitude_of_the_town = CityGeocalize.new(location).perform[1]
  end

  def show
    @date = set_up_a_date
    @city = set_up_a_location
    @house = House.find(params[:id].to_i)
    @number_of_rooms = @house.number_of_rooms
    @house_name = @house.name
    @count = free_room_available_count(@date, @house) #this is a method use below to count the number of available room
  end

  def new
  end


  private


  def set_up_a_date
    date_array = Array.new
    if params[:date] == "1"
      today = Date.today
      today1 = Date.today + 1
	    session[:date] = today
	    session[:date1] = today1
    elsif params[:date] == "2"
	    tomorrow = Date.today + 1
	    tomorrow1 = Date.today + 2
	    session[:date] = tomorrow
	    session[:date1] = tomorrow1
    elsif params[:date] == "3"
	    puts params[:other_date]
	    autre = Date.parse(params[:otherdate])
	    autre1 = autre + 1
	    session[:date] = autre
	    session[:date1] = autre1
    end

    date_array << session[:date]
    date_array << session[:date1]

    return date_array
  end

  def set_up_a_location
    params[:location] ||= session[:location]
    session[:location] = params[:location]
    return session[:location]
  end

  def available_room
    @house = House.find(params[:id].to_i)
    @free_sleeping_room = []
    @free_bed_in_dormitory_room = []
    @count = @house.free_rooms.count
    j = 1
    @count.times do
      freeroom = FreeRoom.find_by(house_id: @house.id, id: j)
      dormitory_rooms_index = RoomType.find_by(description: 'lit dans un dortoir')
      j += 1

      if (freeroom.status == 'free')
        if (freeroom.room_type_id == dormitory_rooms_index.id)
          @free_bed_in_dormitory_room << freeroom
        else
          @free_sleeping_room << freeroom
        end
      end
    end
  end

  def free_room_available_count(date, house)
    count = 0
    count1 = 0
    count2 = 0 
    count3 = 0
    total_of_room = Array.new
    house.free_rooms.each do |free|
      counter  = 0
      #Search in the database where are the occupied room with the same id as free room
      OccupiedRoom.where("free_room_id = #{free.id}").each do |occuped|
          booking = Booking.find(occuped.booking_id)
	  #Check the date of the occupied room and the date of the pilgrim
          if booking.check_in.to_s == date[0].to_s
            counter = 1
          end
        end
      # If counter == 0 then the room is not occupied for this date
      if counter == 0 && free.room_type_id == 1
        count = count  + 1
      elsif counter == 0 && free.room_type_id == 2
	count1 = count1 + 1
      elsif counter == 0 && free.room_type_id == 3
	count2 = count2 + 1
      elsif counter == 0 && free.room_type_id == 4
	count3 = count3 + 1
      end
    end
    total_of_room << count
    total_of_room << count1
    total_of_room << count2
    total_of_room << count3

    return total_of_room

  end

  def price_of_the_lowest_room(city)
    houses_city = House.where(city_id: city.id)
    price = Array.new
    houses_city.each do |house|
      temporary_price = 0
      house.free_rooms.each do |room|
        if temporary_price == 0
		temporary_price = room.price_of_the_night
	end
  if room.price_of_the_night == nil
    
  else
	  if temporary_price > room.price_of_the_night
		  temporary_price = room.price_of_the_night
	  end
  end
end
      if temporary_price - temporary_price.to_i == 0.0
        price << temporary_price.to_i
      else
        price << temporary_price
      end
    end
    return price
  end


end
