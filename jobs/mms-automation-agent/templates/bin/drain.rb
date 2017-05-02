require 'rubygems'
require 'json'

def cluster_healty?

  str = `mongo localhost:<%= p('mongodb.port') %>/admin -u <%= p('mongodb.health.user') %> -p '<%= p('mongodb.health.password') %>' --eval 'JSON.stringify(rs.status())' --quiet`
  puts str

  parsed = JSON.parse(str)

  if parsed['errmsg'] == 'not running with --replSet'
    puts 'not in cluster mode, proceeding'
    `/var/vcap/bosh/bin/monit stop mms-automation-agent`
    `pkill mongo`
    exit 0
  end

  cluster_healty = true

  parsed['members'].each { |member|
    if member['health'] == 0
      puts 'unhealthy node: ' + member['name']
      cluster_healty = false
    end

  }
  cluster_healty
end


# wait up to 10 minutes for cluster to get healty
i = 0
while i < 60 do
  if cluster_healty?
    puts 'cluster OK, proceeding'
    `/var/vcap/bosh/bin/monit stop mms-automation-agent`
    `pkill mongo`
    exit 0
  else
    puts 'cluster unhealty; wait and try again. try: ' + i.to_s
    sleep 10
    i += 1
  end
end
puts 'Timeout: no healty cluster state could be reached.'
exit 1