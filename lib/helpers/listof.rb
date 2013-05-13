# $Id: listof.rb,v 66d56aa07e6c 2013/04/14 19:37:20 roberto $
#
# Given a prefix, generate a list of links

module ListOfHelper
  require 'nanoc/helpers/link_to'
  include Nanoc::Helpers::LinkTo

  def list_of(prefix, attr = :short_name, sorting = 'asc')
    if sorting == 'desc'
      list = @items.select{|i|
        i.identifier.start_with?(prefix) unless i[:slug]
      }.sort_by{|i| i.identifier}.reverse.inject('<ul>') {|memo,i|
        memo + "<li>#{link_to(i[attr], i)}\n"
      }
      list + "</ul>"
    else
      list = @items.select{|i|
        i.identifier.start_with?(prefix) unless i[:slug]
      }.sort_by{|i| i.identifier}.inject('<ul>') {|memo,i|
        memo + "<li>#{link_to(i[attr], i)}\n"
      }
      list + "</ul>"
    end
  end
end # -- ListHelper
