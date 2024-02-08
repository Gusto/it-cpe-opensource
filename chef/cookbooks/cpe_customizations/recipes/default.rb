# SPDX-FileCopyrightText: Facebook, Inc.
# SPDX-FileCopyrightText: Gusto, Inc.
#
# SPDX-License-Identifier: Apache-2.0

# Cookbook:: cpe_customizations
# Recipe:: default

teams = node.gustie.teams.clone

node["cpe_customizations"]["fuzzy_teams"].map(&:downcase).map(&:strip).each do |fuzzy_team|
  teams.prepend(fuzzy_team) if teams.select { |t| t.downcase.include?(fuzzy_team) }.any?
end

teams += node.gustie.self_service_teams.clone.select { |t| node["cpe_customizations"]["allowed_self_service_teams"].include?(t) }

teams.compact.uniq.each do |team|
  tag("team:#{team}")
  begin
    include_recipe "cpe_customizations::#{team}"
  rescue Chef::Exceptions::RecipeNotFound
    Chef::Log.info("RecipeNotFound cpe_customizations::#{team}")
  rescue Exception => e # rubocop:disable Lint/RescueException
    Chef::Log.warn(
      "Error in cpe_customizations::#{team} \n" +
      "#{e.message} \n" +
      "#{e.backtrace.inspect} \n"
    )
  end
end

begin
  user = node.username&.downcase
  include_recipe "cpe_customizations::#{user}" unless user.nil?
rescue Chef::Exceptions::RecipeNotFound
  Chef::Log.info("RecipeNotFound cpe_customizations::#{user}")
rescue Exception => e # rubocop:disable Lint/RescueException
  Chef::Log.warn(
    "Error in cpe_customizations::#{user} \n" +
    "#{e.message} \n" +
    "#{e.backtrace.inspect} \n"
  )
end

return if node.serial.nil?
begin
  include_recipe "cpe_customizations::#{node.serial}"
rescue Chef::Exceptions::RecipeNotFound
  Chef::Log.info("RecipeNotFound cpe_customizations::#{node.serial}")
  return
rescue Exception => e # rubocop:disable Lint/RescueException
  Chef::Log.warn(
    "Error in cpe_customizations::#{node.serial} \n" +
    "#{e.message} \n" +
    "#{e.backtrace.inspect} \n"
  )
end
