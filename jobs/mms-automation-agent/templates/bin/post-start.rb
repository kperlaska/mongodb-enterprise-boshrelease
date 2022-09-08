require 'rubygems'
require 'json'

def cluster_healty?

  str = `mongo localhost:<%= p('mongodb.port') %>/admin -u <%= p('mongodb.health.user') %> -p '<%= p('mongodb.health.password') %>' --eval 'JSON.stringify(rs.status())' --quiet`
  puts str

  cluster_healty = true
  
  parsed = JSON.parse(str)

  parsed['members'].each { |member|
    if member['health'] == 0
      puts 'unhealthy node: ' + member['name']
      cluster_healty = false
    end

  }
  cluster_healty
end


# wait until cluster is healthy 
while true do
  if cluster_healty?
    puts 'cluster OK, proceeding'
    break 
  else
    puts 'cluster unhealty; wait and try again'
    sleep 10
  end
end
