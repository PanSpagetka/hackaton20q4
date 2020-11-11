require 'json'

class PetController
  class << self
    attr_accessor :current_id

    def add_new(params)
      new = load_pets
      new.append(
        Pet.new(
          self.current_id, 
          params['name'], 
          params['description'], 
          params['status'], 
          params['tags']
        )
      )
      save_pets(new.to_json)
      self.current_id += 1
    end

    def find_by_id(id)
      load_pets.select { |pet| pet.id == id }
    end

    #Returns all pets having status included in status array
    def find_by_status(status)
      load_pets.select { |pet| status.include?(pet.status) }
    end

    #Returns all pets containing all of the tags
    def find_by_tags(tags)
      load_pets.select do |pet|
        tags.all? do |tag|
          pet.tagged_with?(tag)
        end
      end
    end

    def find_by_tag(tag)
      load_pets.select { |pet| pet.tags.include?(tag) }
    end

    def delete_pet(id)
      size = load_pets.size
      save_pets(load_pets.select { |o| o.id != id }.to_json)
      return size - load_pets.size
    end

    private

    def load_pets
        f =  File.read("pets.json")

      res = Array(JSON.parse(f)).map do |record|
        Pet.new(
          record['id'].to_i, 
          record['name'], 
          record['description'], 
          record['status'], 
          record['tags']) 
      end
      self.current_id = res.last.id.to_i + 1 || 1

      res
    rescue => err
      puts err.message
      raise
    end

    def save_pets(json)
      File.open("pets.json","w") do |file|
        JSON.pretty_generate(JSON.parse(json)).lines do |line|
          file.write(line)
        end
      end
    rescue => err
      puts err.message
      raise
    end
  end
end

class Pet
  attr_accessor :name, :description, :status, :tags
  attr_reader :id

  def initialize(id, name, description, status, tags)
    self.id          = id
    self.name        = name
    self.description = description
    self.status      = status || 'unknown'
    self.tags        = tags || []
  end

  def tagged_with?(tag)
    tags.include?(tag)
  end

  def tag_with(tag)
    self.tags << tag
  end

  def untag(tag)
    tags.delete(tag)
  end

  def ==(other)
    self.id          == other.id &&
    self.name        == other.name &&
    self.description == other.description &&
    self.status      == other.status &&
    self.tags        == other.tags
  end

  def to_json(*a)
    {
      "id"          => id,
      "name"        => name,
      "description" => description,
      "status"      => status,
      "tags"        => tags
  }.to_json(*a)
  end

  private

  attr_writer :id
end


MyApp.add_route('POST', '/v2/pet', {
  "resourcePath" => "/Pet",
  "summary" => "Add a new pet to the store",
  "nickname" => "add_pet", 
  "responseClass" => "Pet",
  "endpoint" => "/pet", 
  "notes" => "",
  "parameters" => [
    {
      "name" => "body",
      "description" => "Pet object that needs to be added to the store",
      "dataType" => "Pet",
      "paramType" => "body",
    }
    ]}) do
  cross_origin
  # the guts live here

  PetController.add_new(params)

  {"message" => "New pet, yay!"}.to_json
end


MyApp.add_route('DELETE', '/v2/pet/{petId}', {
  "resourcePath" => "/Pet",
  "summary" => "Deletes a pet",
  "nickname" => "delete_pet", 
  "responseClass" => "void",
  "endpoint" => "/pet/{petId}", 
  "notes" => "",
  "parameters" => [
    {
      "name" => "pet_id",
      "description" => "Pet id to delete",
      "dataType" => "Integer",
      "paramType" => "path",
    },
    {
      "name" => "api_key",
      "description" => "",
      "dataType" => "String",
      "paramType" => "header",
    },
    ]}) do
  cross_origin
  # the guts live here

  {"message" => "Yes, it worked. #{PetController.delete_pet(params["petId"].to_i)} records deleted."}.to_json
end


MyApp.add_route('GET', '/v2/pet/findByStatus', {
  "resourcePath" => "/Pet",
  "summary" => "Finds Pets by status",
  "nickname" => "find_pets_by_status", 
  "responseClass" => "Array<Pet>",
  "endpoint" => "/pet/findByStatus", 
  "notes" => "Multiple status values can be provided with comma separated strings",
  "parameters" => [
    {
      "name" => "status",
      "description" => "Status values that need to be considered for filter",
      "dataType" => "Array<String>",
      "collectionFormat" => "csv",
      "paramType" => "query",
    },
    ]}) do
  cross_origin
  # the guts live here

  {"message" => PetController.find_by_status(params)}.to_json
end


MyApp.add_route('GET', '/v2/pet/findByTags', {
  "resourcePath" => "/Pet",
  "summary" => "Finds Pets by tags",
  "nickname" => "find_by_tags", 
  "responseClass" => "Array<Pet>",
  "endpoint" => "/pet/findByTags", 
  "notes" => "Multiple tags can be provided with comma separated strings. Use tag1, tag2, tag3 for testing.",
  "parameters" => [
    {
      "name" => "tags",
      "description" => "Tags to filter by",
      "dataType" => "Array<String>",
      "collectionFormat" => "csv",
      "paramType" => "query",
    },
    ]}) do
  cross_origin
  # the guts live here

  {"message" => PetController.find_by_tags(params.keys)}.to_json
end


MyApp.add_route('GET', '/v2/pet/{petId}', {
  "resourcePath" => "/Pet",
  "summary" => "Find pet by ID",
  "nickname" => "find_by_id", 
  "responseClass" => "Pet",
  "endpoint" => "/pet/{petId}", 
  "notes" => "Returns a single pet",
  "parameters" => [
    {
      "name" => "pet_id",
      "description" => "ID of pet to return",
      "dataType" => "Integer",
      "paramType" => "path",
    },
    ]}) do
  cross_origin
  # the guts live here

  {"message" => PetController.find_by_id(params['petId'].to_i)}.to_json
end


MyApp.add_route('PUT', '/v2/pet', {
  "resourcePath" => "/Pet",
  "summary" => "Update an existing pet",
  "nickname" => "update_pet", 
  "responseClass" => "Pet",
  "endpoint" => "/pet", 
  "notes" => "",
  "parameters" => [
    {
      "name" => "body",
      "description" => "Pet object that needs to be added to the store",
      "dataType" => "Pet",
      "paramType" => "body",
    }
    ]}) do
  cross_origin
  # the guts live here

  {"message" => "NotImplementedYet"}.to_json
end


MyApp.add_route('POST', '/v2/pet/{petId}', {
  "resourcePath" => "/Pet",
  "summary" => "Updates a pet in the store with form data",
  "nickname" => "update_pet_with_form", 
  "responseClass" => "void",
  "endpoint" => "/pet/{petId}", 
  "notes" => "",
  "parameters" => [
    {
      "name" => "pet_id",
      "description" => "ID of pet that needs to be updated",
      "dataType" => "Integer",
      "paramType" => "path",
    },
    ]}) do
  cross_origin
  # the guts live here

  {"message" => "NotImplementedYet"}.to_json
end


MyApp.add_route('POST', '/v2/pet/{petId}/uploadImage', {
  "resourcePath" => "/Pet",
  "summary" => "uploads an image",
  "nickname" => "upload_file", 
  "responseClass" => "ApiResponse",
  "endpoint" => "/pet/{petId}/uploadImage", 
  "notes" => "",
  "parameters" => [
    {
      "name" => "pet_id",
      "description" => "ID of pet to update",
      "dataType" => "Integer",
      "paramType" => "path",
    },
    ]}) do
  cross_origin
  # the guts live here

  {"message" => "NotImplementedYet"}.to_json
end
