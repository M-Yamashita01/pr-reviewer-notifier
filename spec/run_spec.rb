require 'spec_helper'

RSpec.describe PrReviewerNotifier do
  let(:token) { 'dummy_token' }
  let(:repo) { 'owner/repo' }
  let(:pr_number) { '123' }
  let(:comment_template) { 'cc: {{mentions}}' }

  let(:client_double) { instance_double(Octokit::Client) }

  subject {
    described_class.new(
      token: token,
      repo: repo,
      pr_number: pr_number,
      comment_template: comment_template
    )
  }

  before do
    allow(Octokit::Client).to receive(:new).with(access_token: token).and_return(client_double)
    allow(client_double).to receive(:auto_paginate=)
    allow(subject).to receive(:puts) # Suppress stdout
  end

  describe '#run' do
    context 'when a requested team is assigned' do
      let(:comment_template) {
        <<~TEMPLATE
        This is a test comment.
        cc: {{mentions}}
        TEMPLATE
      }
      let(:pr_data) {
        double('PullRequest',
          requested_teams: [double('Team', slug: 'team-a')]
        )
      }

      before do
        allow(client_double).to receive(:pull_request).with(repo, pr_number).and_return(pr_data)
      end

      it 'posts a comment with mentions' do
        expected_body = "This is a test comment.\ncc: @owner/team-a\n"
        expect(client_double).to receive(:add_comment).with(repo, pr_number, expected_body)

        subject.run
      end
    end

    context 'when some requested teams are assigned' do
      let(:comment_template) {
        <<~TEMPLATE
        This is a test comment.
        cc: {{mentions}}
        TEMPLATE
      }
      let(:pr_data) {
        double('PullRequest',
          requested_teams: [double('Team', slug: 'team-a'), double('Team', slug: 'team-b')]
        )
      }

      before do
        allow(client_double).to receive(:pull_request).with(repo, pr_number).and_return(pr_data)
      end

      it 'posts a comment with mentions' do
        expected_body = "This is a test comment.\ncc: @owner/team-a @owner/team-b\n"
        expect(client_double).to receive(:add_comment).with(repo, pr_number, expected_body)

        subject.run
      end
    end

    context 'when no requested teams are assigned' do
      let(:comment_template) {
        <<~TEMPLATE
        This is a test comment.
        cc: {{mentions}}
        TEMPLATE
      }
      let(:pr_data) {
        double('PullRequest',
          requested_teams: []
        )
      }

      before do
        allow(client_double).to receive(:pull_request).with(repo, pr_number).and_return(pr_data)
      end

      it 'posts a comment with empty mentions' do
        expected_body = "This is a test comment.\ncc: \n"
        expect(client_double).to receive(:add_comment).with(repo, pr_number, expected_body)

        subject.run
      end
    end

    context 'when {{mentions}} is not in the comment template' do
      let(:comment_template) {
        <<~TEMPLATE
        This is a test comment.
        TEMPLATE
      }
      let(:pr_data) {
        double('PullRequest',
          requested_teams: [double('Team', slug: 'team-a')]
        )
      }

      before do
        allow(client_double).to receive(:pull_request).with(repo, pr_number).and_return(pr_data)
      end

      it 'posts a comment with empty mentions' do
        expected_body = "This is a test comment.\n"
        expect(client_double).to receive(:add_comment).with(repo, pr_number, expected_body)

        subject.run
      end
    end
  end
end
