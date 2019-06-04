require_relative 'panos_provider'

# Implementation for the panos_static_route_base type using the Resource API, which has been implemented to remove the common functionality of the ipv4 and ipv6 static routes.
class Puppet::Provider::PanosStaticRouteBase < Puppet::Provider::PanosProvider
  def initialize(version_label)
    super()
    @version_label = version_label
  end

  def munge(entry)
    entry[:no_install] = entry[:no_install].nil? ? false : true
    entry[:path_monitoring] = entry[:path_monitoring].nil? ? false : true
    entry[:nexthop_type] = 'none' if entry[:nexthop_type].nil?
    entry[:enable] = string_to_bool(entry[:enable])
    entry[:admin_distance] = entry[:admin_distance].to_i unless entry[:admin_distance].nil?
    entry[:hold_time] = entry[:hold_time].to_i unless entry[:hold_time].nil?
    entry[:metric] =  if entry[:metric].nil?
                        10
                      else
                        entry[:metric].to_i
                      end
    entry
  end

  def xml_from_should(name, should)
    builder = Builder::XmlMarkup.new
    builder.entry('name' => name[:route]) do
      unless should[:nexthop_type] == 'none'
        builder.nexthop do
          builder.__send__(should[:nexthop_type], should[:nexthop]) unless should[:nexthop_type] == 'discard'
          builder.discard if should[:nexthop_type] == 'discard'
        end
      end
      if should[:bfd_profile]
        builder.bfd do
          builder.profile(should[:bfd_profile])
        end
      end
      if should[:path_monitoring]
        builder.__send__('path-monitor') do
          builder.enable('yes') if should[:enable]
          builder.__send__('failure-condition', should[:failure_condition]) if should[:failure_condition]
          builder.__send__('hold-time', should[:hold_time]) if should[:hold_time]
        end
      end
      builder.interface(should[:interface]) if should[:interface]
      builder.metric(should[:metric]) if should[:metric]
      builder.__send__('admin-dist', should[:admin_distance]) if should[:admin_distance]
      builder.destination(should[:destination]) if should[:destination]
      if should[:route_type]
        builder.__send__('route-table') do
          builder.__send__(should[:route_type])
        end
      end
      if should[:no_install]
        builder.option do
          builder.__send__('no-install')
        end
      end
    end
  end

  def validate_should(should)
    raise Puppet::ResourceError, 'Interfaces must be provided if no Next Hop or Virtual Router is specified for next hop.' if should[:interface].nil? && should[:nexthop_type] != 'discard'
    raise Puppet::ResourceError, "BFD requires a nexthop_type to be `#{@version_label}-address`" if should[:bfd_profile] != 'None' && should[:nexthop_type] !~ %r{^ip(?:v6)?-address$}
  end

  # Overiding the get method, as the base xpath points towards virtual routers, and therefore the base provider's get will only return once for each VR.
  def get(context)
    results = []
    config = context.transport.get_config(context.type.definition[:base_xpath] + '/entry')
    config.elements.collect('/response/result/entry') do |entry| # rubocop:disable Style/CollectionMethods
      vr_name = REXML::XPath.match(entry, 'string(@name)').first
      # rubocop:disable Style/CollectionMethods
      config.elements.collect("/response/result/entry[@name='#{vr_name}']/routing-table/#{@version_label}/static-route/entry") do |static_route_entry|
        result = {}
        context.type.attributes.each do |attr_name, attr|
          result[attr_name] = match(static_route_entry, attr, attr_name) unless attr_name == :vr_name
        end
        result[:vr_name] = vr_name
        result[:title] = vr_name + '/' + result[:route]
        results.push(result)
        defined?(munge) ? munge(result) : result
      end
      # rubocop:enable Style/CollectionMethods
    end
    results
  end

  # Overiding the following methods to point the xpath into the correct VR.
  def create(context, name, should)
    context.type.definition[:base_xpath] = "/config/devices/entry/network/virtual-router/entry[@name='#{name[:vr_name]}']/routing-table/#{@version_label}/static-route"
    validate_should(should)
    context.transport.set_config(context.type.definition[:base_xpath], xml_from_should(name, should))
  end

  def update(context, name, should)
    context.type.definition[:base_xpath] = "/config/devices/entry/network/virtual-router/entry[@name='#{name[:vr_name]}']/routing-table/#{@version_label}/static-route"
    validate_should(should)
    context.transport.set_config(context.type.definition[:base_xpath], xml_from_should(name, should))
  end

  def delete(context, name)
    context.transport.delete_config(context.type.definition[:base_xpath] + "/entry[@name='#{name[:vr_name]}']/routing-table/#{@version_label}/static-route/entry[@name='#{name[:route]}']")
  end

  def canonicalize(_context, resources)
    resources.each do |resource|
      resource[:hold_time] = resource[:hold_time].to_i unless resource[:hold_time].nil?
      resource[:metric] = resource[:metric].to_i unless resource[:metric].nil?
      resource[:admin_distance] = resource[:admin_distance].to_i unless resource[:admin_distance].nil?
    end
  end
end
