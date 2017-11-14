# Copyright (C) 2012-2016 Zammad Foundation, http://zammad-foundation.org/
module ApplicationModel::CanAssociations
  extend ActiveSupport::Concern

=begin

set relations of model based on params

  model = Model.find(1)
  result = model.associations_from_param(params)

returns

  result = true|false

=end

  def associations_from_param(params)

    # special handling for group access association
    {
      groups:    :group_names_access_map=,
      group_ids: :group_ids_access_map=
    }.each do |param, setter|
      map = params[param]
      next if map.blank?
      next if !respond_to?(setter)
      send(setter, map)
    end

    # set relations by id/verify if ref exists
    self.class.reflect_on_all_associations.map { |assoc|
      assoc_name = assoc.name
      next if association_attributes_ignored.include?(assoc_name)
      real_ids = assoc_name[0, assoc_name.length - 1] + '_ids'
      real_ids = real_ids.to_sym
      next if !params.key?(real_ids)
      list_of_items = params[real_ids]
      if !params[real_ids].instance_of?(Array)
        list_of_items = [ params[real_ids] ]
      end
      list = []
      list_of_items.each { |item_id|
        next if !item_id
        lookup = assoc.klass.lookup(id: item_id)

        # complain if we found no reference
        if !lookup
          raise ArgumentError, "No value found for '#{assoc_name}' with id #{item_id.inspect}"
        end
        list.push item_id
      }
      send("#{real_ids}=", list)
    }

    # set relations by name/lookup
    self.class.reflect_on_all_associations.map { |assoc|
      assoc_name = assoc.name
      next if association_attributes_ignored.include?(assoc_name)
      real_ids = assoc_name[0, assoc_name.length - 1] + '_ids'
      next if !respond_to?(real_ids)
      real_values = assoc_name[0, assoc_name.length - 1] + 's'
      real_values = real_values.to_sym
      next if !respond_to?(real_values)
      next if !params[real_values]
      next if !params[real_values].instance_of?(Array)
      list = []
      class_object = assoc.klass
      params[real_values].each { |value|
        lookup = nil
        if class_object == User
          if !lookup
            lookup = class_object.lookup(login: value)
          end
          if !lookup
            lookup = class_object.lookup(email: value)
          end
        else
          lookup = class_object.lookup(name: value)
        end

        # complain if we found no reference
        if !lookup
          raise ArgumentError, "No lookup value found for '#{assoc_name}': #{value.inspect}"
        end
        list.push lookup.id
      }
      send("#{real_ids}=", list)
    }
  end

=begin

get relations of model based on params

  model = Model.find(1)
  attributes = model.attributes_with_association_ids

returns

  hash with attributes and association ids

=end

  def attributes_with_association_ids

    key = "#{self.class}::aws::#{id}"
    cache = Cache.get(key)
    return cache if cache

    # get relations
    attributes = self.attributes
    self.class.reflect_on_all_associations.map { |assoc|
      next if association_attributes_ignored.include?(assoc.name)
      real_ids = assoc.name.to_s[0, assoc.name.to_s.length - 1] + '_ids'
      next if !respond_to?(real_ids)
      attributes[real_ids] = send(real_ids)
    }

    # special handling for group access associations
    if respond_to?(:group_ids_access_map)
      attributes['group_ids'] = send(:group_ids_access_map)
    end

    filter_attributes(attributes)

    Cache.write(key, attributes)
    attributes
  end

=begin

get relation name of model based on params

  model = Model.find(1)
  attributes = model.attributes_with_association_names

returns

  hash with attributes, association ids, association names and relation name

=end

  def attributes_with_association_names

    # get relations
    attributes = attributes_with_association_ids
    self.class.reflect_on_all_associations.map { |assoc|
      next if !respond_to?(assoc.name)
      next if association_attributes_ignored.include?(assoc.name)
      ref = send(assoc.name)
      next if !ref
      if ref.respond_to?(:first)
        attributes[assoc.name.to_s] = []
        ref.each { |item|
          if item[:login]
            attributes[assoc.name.to_s].push item[:login]
            next
          end
          next if !item[:name]
          attributes[assoc.name.to_s].push item[:name]
        }
        if ref.count.positive? && attributes[assoc.name.to_s].empty?
          attributes.delete(assoc.name.to_s)
        end
        next
      end
      if ref[:login]
        attributes[assoc.name.to_s] = ref[:login]
        next
      end
      next if !ref[:name]
      attributes[assoc.name.to_s] = ref[:name]
    }

    # special handling for group access associations
    if respond_to?(:group_names_access_map)
      attributes['groups'] = send(:group_names_access_map)
    end

    # fill created_by/updated_by
    {
      'created_by_id' => 'created_by',
      'updated_by_id' => 'updated_by',
    }.each { |source, destination|
      next if !attributes[source]
      user = User.lookup(id: attributes[source])
      next if !user
      attributes[destination] = user.login
    }

    filter_attributes(attributes)

    attributes
  end

  def filter_attributes(attributes)
    # remove forbitten attributes
    %w(password token tokens token_ids).each { |item|
      attributes.delete(item)
    }
  end

=begin

reference if association id check

  model = Model.find(123)
  attributes = model.association_id_validation('attribute_id', value)

returns

  true | false

=end

  def association_id_validation(attribute_id, value)
    return true if value.nil?

    attributes.each { |key, _value|
      next if key != attribute_id

      # check if id is assigned
      next if !key.end_with?('_id')
      key_short = key.chomp('_id')

      self.class.reflect_on_all_associations.map { |assoc|
        next if assoc.name.to_s != key_short
        item = assoc.class_name.constantize
        return false if !item.respond_to?(:find_by)
        ref_object = item.find_by(id: value)
        return false if !ref_object
        return true
      }
    }
    true
  end

  private

  def association_attributes_ignored
    @association_attributes_ignored ||= self.class.instance_variable_get(:@association_attributes_ignored) || []
  end

  # methods defined here are going to extend the class, not the instance of it
  class_methods do

=begin

serve methode to ignore model attribute associations

class Model < ApplicationModel
  include AssociationConcern
  association_attributes_ignored :users
end

=end

    def association_attributes_ignored(*attributes)
      @association_attributes_ignored ||= []
      @association_attributes_ignored |= attributes
    end

=begin

do name/login/email based lookup for associations

  params = {
    login: 'some login',
    firstname: 'some firstname',
    lastname: 'some lastname',
    email: 'some email',
    organization: 'some organization',
    roles: ['Agent', 'Admin'],
  }

  attributes = Model.association_name_to_id_convert(params)

returns

  attributes = params # params with possible lookups

  attributes = {
    login: 'some login',
    firstname: 'some firstname',
    lastname: 'some lastname',
    email: 'some email',
    organization_id: 123,
    role_ids: [2,1],
  }

=end

    def association_name_to_id_convert(params)

      data = {}
      params.each { |key, value|
        data[key.to_sym] = value
      }

      data.symbolize_keys!
      available_attributes = attribute_names
      reflect_on_all_associations.map { |assoc|

        assoc_name = assoc.name
        value      = data[assoc_name]
        next if !value # next if we do not have a value
        ref_name = "#{assoc_name}_id"

        # handle _id values
        if available_attributes.include?(ref_name) # if we do have an _id attribute
          next if data[ref_name.to_sym] # next if we have already the _id filled

          # get association class and do lookup
          class_object = assoc.klass
          lookup = nil
          if class_object == User
            if value.instance_of?(String)
              if !lookup
                lookup = class_object.lookup(login: value)
              end
              if !lookup
                lookup = class_object.lookup(email: value)
              end
            else
              raise ArgumentError, "String is needed as ref value #{value.inspect} for '#{assoc_name}'"
            end
          else
            lookup = class_object.lookup(name: value)
          end

          # complain if we found no reference
          if !lookup
            raise ArgumentError, "No lookup value found for '#{assoc_name}': #{value.inspect}"
          end

          # release data value
          data.delete(assoc_name)

          # remember id reference
          data[ref_name.to_sym] = lookup.id
          next
        end

        next if !value.instance_of?(Array)
        next if value.empty?
        next if !value[0].instance_of?(String)

        # handle _ids values
        next if !assoc_name.to_s.end_with?('s')
        ref_names = "#{assoc_name.to_s.chomp('s')}_ids"
        generic_object_tmp = new
        next unless generic_object_tmp.respond_to?(ref_names) # if we do have an _ids attribute
        next if data[ref_names.to_sym] # next if we have already the _ids filled

        # get association class and do lookup
        class_object = assoc.klass
        lookup_ids = []
        value.each { |item|
          lookup = nil
          if class_object == User
            if item.instance_of?(String)
              if !lookup
                lookup = class_object.lookup(login: item)
              end
              if !lookup
                lookup = class_object.lookup(email: item)
              end
            else
              raise ArgumentError, "String is needed in array ref as ref value #{value.inspect} for '#{assoc_name}'"
            end
          else
            lookup = class_object.lookup(name: item)
          end

          # complain if we found no reference
          if !lookup
            raise ArgumentError, "No lookup value found for '#{assoc_name}': #{item.inspect}"
          end
          lookup_ids.push lookup.id
        }

        # release data value
        data.delete(assoc_name)

        # remember id reference
        data[ref_names.to_sym] = lookup_ids
      }

      data
    end
  end
end
