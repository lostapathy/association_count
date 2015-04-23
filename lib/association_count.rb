require 'association_count/version'
require 'active_record'

ActiveRecord::Base.extend AssociationCount
module AssociationCount
  def association_count(counted_model, distinct)
    table_name    = self.table_name
    counted_table = counted_model.table_name
    counted_name  = counted_table.singularize
    distinct_sql  = distinct ? 'DISTINCT' : ''

    joins(counted_table.to_sym)
      .select("#{table_name}.*, COUNT(#{distinct_sql} #{counted_table}.id) as #{counted_name}_count_raw")
      .group("#{table_name}.id")
  end

  def can_count(model_name, opts = {})
    model_name = model_name.to_s
    reflection = reflections[model_name]
    fail "No such reflection: '#{model_name}'" unless reflection

    options       = { distinct: true }.merge!(opts)
    singular_name = model_name.singularize

    define_association_count_method(model_name, singular_name)
    define_count_scope(singular_name, reflection, options[:distinct])
  end

  def define_association_count_method(model_name, singular_name)
    define_method "#{singular_name}_count" do
      raw_count_name = "#{singular_name}_count_raw"
      return send(raw_count_name) if self.respond_to?(raw_count_name)
      send(model_name).count
    end
  end

  def define_count_scope(singular_name, reflection, distinct)
    scope_name = "include_#{singular_name}_count"
    class_eval do
      scope scope_name, -> { association_count(reflection.klass, distinct) }
    end
  end
end
