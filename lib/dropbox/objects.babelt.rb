# babelsdk(jinja2)

# DO NOT EDIT THIS FILE.
# This file is auto-generated from the babel template objects.babelt.rb.
# Any changes here will silently disappear.
# And no, this isn't a reference to http://stackoverflow.com/a/740603/3862658,
# changes will actually disappear.

require 'date'

{%- macro struct_doc_ref(s, ns=None) -%}
Dropbox::API::{{ s|class }}
{%- endmacro -%}

{%- macro op_doc_ref(s, ns=None) -%}
Dropbox::API::Client::{{ ns.name|class }}.{{ s|method }}
{%- endmacro -%}

{%- macro field_doc_ref(s, ns=None) -%}
+{{ s }}+
{%- endmacro -%}

{%- macro link_doc_ref(s, ns=None) -%}
{{ s }}
{%- endmacro -%}

{%- macro val_doc_ref(s, ns=None) -%}
{%- if s == 'True' -%}
+true+
{%- elif s == 'False' -%}
+false+
{%- elif s == 'null' -%}
+nil+
{%- endif -%}
{%- endmacro -%}

{%- macro ruby_doc_sub(s, ns=None) -%}
{{ s|doc_sub(ns, struct=struct_doc_ref, op=op_doc_ref, field=field_doc_ref, link=link_doc_ref, val=val_doc_ref) }}
{%- endmacro -%}

{%- macro typename(field) -%}
{%- if field.data_type -%}
{%- if field.data_type.composite_type -%}
{{ ' ' }}(+{{ field.data_type.name|class }}+)
{%- else -%}
{{ ' ' }}(+{{ field.data_type|type }}+)
{%- endif -%}
{%- endif -%}
{%- endmacro -%}

{%- macro arg_doc(fields, ns) -%}
{% for field in fields %}
# * +{{ field.name }}+{{ typename(field) }}{{ ' ' }}
{%- if field.has_default %}(defaults to {{ field.default|pprint }})
{% else %}{# blank block for a newline here #}

{% endif %}
{% if field.doc %}
#   {{ ruby_doc_sub(field.doc, ns)|wordwrap(70)|replace('\n', '\n#   ') }}
{% endif %}
{% endfor %}
{%- endmacro -%}

{%- macro struct_docs(data_type, ns) -%}
{% if data_type.doc %}
# {{ ruby_doc_sub(data_type.doc, ns)|wordwrap(70)|replace('\n', '\n# ') }}
#
{% endif %}
# Required fields:
{{ arg_doc(data_type.all_required_fields, ns) -}}
{% if data_type.all_optional_fields|length > 0 %}
#
# Optional fields:
{{ arg_doc(data_type.all_optional_fields, ns) -}}
{% endif %}
{%- endmacro -%}

{%- macro union_docs(data_type, ns) -%}
{% if data_type.doc %}
# {{ ruby_doc_sub(data_type.doc, ns)|wordwrap(70)|replace('\n', '\n# ') }}
#
{% endif %}
# Member types:
{{ arg_doc(data_type.all_fields, ns) -}}
{%- endmacro -%}

{%- macro arg_list(args, defaults=True) -%}
{% for arg in args %}
{{ arg.name }}
{%- if defaults %}{% if arg.has_default %} = {{ arg.default|pprint }}{% elif arg.optional %} = nil{% endif %}{% endif %},
{% endfor %}
{%- endmacro -%}

{%- macro struct_def(data_type, indent_spaces, ns) -%}
{%- filter indent(indent_spaces, indentfirst=True) -%}
{{ struct_docs(data_type, ns) -}}
class {{ data_type.name|class }}{% if data_type.super_type %} < {{ data_type.super_type.name|class }}{% endif %}

  {% if data_type.fields %}
  attr_accessor(
      {{ data_type.fields|map(attribute='name')|map('inverse_format', ':{0}')|join(',\n      ') }}
  )
  {% endif %}

  def initialize(
      {{ arg_list(data_type.all_fields)|indent(6)|string_slice(0, -1) }}
  )
  {% for field in data_type.all_fields %}
    @{{ field.name }} = {{ field.name }}
  {% endfor %}
  end

  # Initializes an instance of {{ data_type.name|class }} from
  # JSON-formatted data.
  def self.from_json(json)
    self.new(
      {% for field in data_type.all_fields %}
        {%+ if field.nullable -%}
        json['{{ field.name }}'].nil? ? nil :{{ ' ' }}
        {%- elif field.optional -%}
        !json.include?('{{ field.name }}') ? nil :{{ ' ' }}
        {%- endif %}
        {% if field.data_type.composite_type -%}
        {{ field.data_type.name|class }}.from_json(json['{{ field.name }}']),
        {% elif field.data_type.name == 'Timestamp' -%}
        Dropbox::API::convert_date(json['{{ field.name }}']),
        {% elif field.data_type.name == 'List' and field.data_type.data_type.composite_type -%}
        json['{{ field.name }}'].collect { |elem| {{ field.data_type.data_type.name|class }}.from_json(elem) },
        {% else -%}
        json['{{ field.name }}'],
        {% endif %}
      {% endfor %}
    )
  end
end

{% endfilter -%}
{%- endmacro -%}

{%- macro union_def(data_type, indent_spaces, ns) -%}
{%- filter indent(indent_spaces, indentfirst=True) -%}
# This class is a tagged union. For more information on tagged unions,
# see the README.
#
{{ union_docs(data_type, ns) -}}
module {{ data_type.name|class }}

  # Initializes an instance of {{ data_type.name|class }} from
  # JSON-formatted data.
  def self.from_json(json)
    if json.is_a?(Hash)
      array = json.flatten
      if array.length != 2
        fail ArgumentError, 'JSON should have one key/value pair.'
      end
      tag = array[0].to_sym
      val = array[1]
    else
      # json is just a String, so check possible symbol types.
      # If there are no symbol types, this section will be empty.
      tag = json.to_sym
      val = nil
    end

  {% for field in data_type.all_fields %}
    if tag == :{{ field.name|variable }}
    {% if field.symbol %}
      if val.nil?
        return tag
      else
        fail ArgumentError, "Tag '#{ tag }' cannot have a value associated "\
            "because it is a symbol."
      end
    {% elif field.data_type.composite_type %}
      return {{ field.data_type.name|class }}.from_json(val)
    {% elif field.data_type.name == 'Timestamp' %}
      return Dropbox::API::convert_date(val)
    {% elif field.data_type.name == 'List' and field.data_type.data_type.composite_type %}
      return val.collect { |elem| {{field.data_type.data_type.name|class }}.from_json(val) }
    {% else %}
      return val
    {% endif %}
    end
  {% endfor %}
  end
{% for field in data_type.all_fields %}

  # Initializes an instance of the {{ field.name|variable }} tag.
  def self.{{ field.name|method }}
  {%- if not field.symbol %}(
      {{ arg_list(field.data_type.all_fields)|indent(6)|string_slice(0, -1) }}
  )
  {% else %}{# blank block for a newline here #}

  {% endif %}
    {# Don't variable-format these because these need to match the #}
    {# formatting in the documentation #}
    {% if field.symbol %}
    :{{ field.name }}
    {% else %}
    { {{ field.name }}: {{ field.data_type.name|class }}.new(
      {{ arg_list(field.data_type.all_fields, False)|indent(6)|string_slice(0, -1) }}
    ) }
    {% endif %}
  end
{% endfor %}
end

{% endfilter -%}
{%- endmacro %}


module Dropbox
  module API

    # Converts a string date to a Date object
    def self.convert_date(str)
      DateTime.strptime(str, '%a, %d %b %Y %H:%M:%S')
    end

    {% for namespace in api.namespaces.values() %}
      {% for data_type in namespace.data_types %}
        {% if data_type.composite_type == 'struct' and not data_type.name.endswith('Request') %}
          {{- struct_def(data_type, 4, namespace) }}
        {% elif data_type.composite_type == 'union' and not data_type.name.endswith('Error') %}
          {{- union_def(data_type, 4, namespace) }}
        {% endif %}
      {% endfor %}
    {% endfor %}

    # This class is a wrapper around the Dropbox::API::FileInfo object that
    # provides some convenience methods for manipulating files. It includes
    # methods from the Dropbox::API::FileOps module.
    class File

      #include FileOps

      attr_accessor :client

      def initialize(client, folder_info)
        super(*folder_info.instance_variables.collect do |name|
          a.instance_variable_get(name)
        end)
        @client = client
      end
    end

    # This class is a wrapper around the Dropbox::API::FolderInfo object that
    # provides some convenience methods for manipulating folders. It includes
    # methods from the Dropbox::API::FileOps module.
    class Folder

      #include FileOps

      attr_accessor :client

      class << self
        def create
          # TODO client method
        end
        alias_method :mkdir, :create
      end

      def initialize(client, folder_info)
        super(*folder_info.instance_variables.collect do |name|
          a.instance_variable_get(name)
        end)
        @client = client
      end
    end

  end
end