require 'octokit'
require 'pp'
require 'active_support/core_ext/date'
require 'active_support/core_ext/time'
require 'highline/import'
require 'progress_bar'

# Configure
Octokit.auto_paginate = false

# Setup
client = Octokit::Client.new(access_token:  '')
user = client.user
user.login

# Get organizations
organizations = user.rels[:organizations].get.data
organization_names = organizations.map(&:login)
pp organization_names

# Get org repos
organization_repos = {}
organizations.each do |org|
  repos = org.rels[:repos].get.data
  organization_repos.merge!(org.login => repos)
end

# Get org members
organization_members = {}
organizations.each do |org|
  members = org.rels[:members].get.data
  member_names = members.map(&:login)
  organization_members.merge!(org.login => member_names)
end

# Get repo commits
year = 2015
org_index = ask("Org? ", Integer) { |q| q.in = 0..105 }
selected_org = organization_names[org_index]
scores = {
  year => {
    1  => {},
    2  => {},
    3  => {},
    4  => {},
    5  => {},
    6  => {},
    7  => {},
    8  => {},
    9  => {},
    10 => {},
    11 => {},
    12 => {},
  }
}

# p "Year: #{year}"
bar = ProgressBar.new(12 * organization_repos[selected_org].count * organization_members[selected_org].count)

for month in 1..12 do
  # p "Month: #{month}".rjust(3)
  beginning_of_month = Date.new(year, month, 1).beginning_of_month
  end_of_month = Date.new(year, month, 1).end_of_month

  organization_repos[selected_org].each do |repo|
    # p "Repo: #{repo[:name]}".rjust(6)
    organization_members[selected_org].each do |member|
      # p "Member: #{member}".rjust(9)
      begin
        commits = client.commits("#{selected_org}/#{repo[:name]}", author: member, since: beginning_of_month, until: end_of_month, per_page: 100)
        while client.last_response.rels[:next]
          pp '*'
          commits.concat client.last_response.rels[:next].get.data
        end
        if scores[year][month][member]
          scores[year][month][member] += commits.count
        else
          scores[year][month].merge!(member => commits.count)
        end
      rescue
      ensure
        bar.increment!
      end
    end
  end
end

pp scores

employe_of_the_month = {
  year => {
    1  => {},
    2  => {},
    3  => {},
    4  => {},
    5  => {},
    6  => {},
    7  => {},
    8  => {},
    9  => {},
    10 => {},
    11 => {},
    12 => {},
  }
}
scores[year].each do |month, monthly_scores|
  best = monthly_scores.max_by{|k,v| v}
  employe_of_the_month[year][month] = best.first
end

pp employe_of_the_month
