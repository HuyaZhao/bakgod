# encoding: utf-8
require 'redis'

require_relative 'gems/bigman/lib/bigman/rhash_single'
require_relative 'model/topic_node'

$redis = Redis.new(host: '127.0.0.1', port: 6379)

task :default => [:bbs_node]

TN = BakGod::Model::TopicNode
nodes = %w{Ruby Rails Redis Backbone 电影 游戏 音乐在哪里 我们大家一起来玩玩}

desc 'create node'
task :bbs_node do
   nodes.each do |node|
     instance = TN.new(node)
     instance.save
     puts "创建节点---> #{instance.field} 成功！ 序号为: #{instance.value}"
   end
end