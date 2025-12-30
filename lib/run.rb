# frozen_string_literal: true

require 'octokit'

# This class is used to notify reviewers of a pull request.
class PrReviewerNotifier
  def initialize(token:, repo:, pr_number:, comment_template:)
    @token = token
    @repo = repo
    @pr_number = pr_number
    @comment_template = comment_template
    @client = Octokit::Client.new(access_token: token)
    @client.auto_paginate = true
  end

  def run
    puts "Fetching reviewers for PR ##{@pr_number} in #{@repo}..."
    pull_request = @client.pull_request(@repo, @pr_number)

    reviewers = fetch_reviewers(pull_request:)
    mentions = reviewers.join(' ')
    body = @comment_template.sub('{{mentions}}', mentions)

    puts "Posting comment to PR ##{@pr_number}..."
    @client.add_comment(@repo, @pr_number, body)
    puts "Notification sent to #{reviewers.size} reviewers."
  end

  private

  def fetch_reviewers(pull_request:)
    reviewers = []

    # Team reviewers
    if pull_request.requested_teams
      owner = @repo.split('/').first
      reviewers += pull_request.requested_teams.map { |t| "@#{owner}/#{t.slug}" }
    end

    reviewers
  end
end

if __FILE__ == $PROGRAM_NAME
  begin
    pr_number = ENV.fetch('GITHUB_PR_NUMBER', nil)

    if ENV['GITHUB_PR_NUMBER'].nil? || ENV['GITHUB_PR_NUMBER'].empty?
      raise ArgumentError, 'GITHUB_PR_NUMBER is required'
    end

    if ENV['INPUT_GITHUB_TOKEN'].nil? || ENV['INPUT_GITHUB_TOKEN'].empty?
      raise ArgumentError, 'INPUT_GITHUB_TOKEN is required'
    end

    if ENV['GITHUB_REPOSITORY'].nil? || ENV['GITHUB_REPOSITORY'].empty?
      raise ArgumentError, 'GITHUB_REPOSITORY is required'
    end

    notifier = PrReviewerNotifier.new(
      token: ENV['INPUT_GITHUB_TOKEN'],
      repo: ENV['GITHUB_REPOSITORY'],
      pr_number: ENV['GITHUB_PR_NUMBER'],
      comment_template: ENV['INPUT_COMMENT_TEMPLATE']
    )

    notifier.run
  rescue StandardError => e
    puts "Error: #{e.message}"
    exit 1
  end
end
